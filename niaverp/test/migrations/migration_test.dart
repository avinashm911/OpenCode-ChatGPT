// NiAvERP G0 migration tests — Phase 1.
// Executed only against disposable in-memory SQLite databases (never
// production data). Proves: clean install builds the complete schema;
// upgrade from the pre-G0 baseline preserves data; re-runs are safe;
// failures leave no partial version; CHECK/FK constraints hold; the
// registry maps every G0-SCH delta; validators implement D-M4 arithmetic.
// Traceability: G0-SCH-001…007; DSS §6; DB §8; DSS-C-004/007; D-M4/D-M5.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/migrations/validators.dart';

/// MigrationDb over a disposable package:sqlite3 database.
class SqliteMigrationDb implements MigrationDb {
  SqliteMigrationDb(this.db);
  final Database db;

  @override
  void execute(String sql) => db.execute(sql);

  @override
  void executeArgs(String sql, List<Object?> args) =>
      db.execute(sql, args);

  @override
  List<Map<String, Object?>> query(String sql) => queryArgs(sql, <Object?>[]);

  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    final ResultSet rs = db.select(sql, args);
    return <Map<String, Object?>>[
      for (final Row row in rs)
        <String, Object?>{for (final String c in rs.columnNames) c: row[c]},
    ];
  }

  @override
  void runInTransaction(void Function() body) {
    db.execute('BEGIN');
    try {
      body();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

Map<int, String> loadAllSql() {
  final Map<int, String> out = <int, String>{};
  for (final Migration m in kMigrations) {
    out[m.version] =
        File('lib/data/migrations/${m.fileName}').readAsStringSync();
  }
  return out;
}

bool tableExists(Database db, String table) {
  return db
      .select("SELECT 1 FROM sqlite_master WHERE type='table' AND name='$table'")
      .isNotEmpty;
}

Set<String> columnsOf(Database db, String table) {
  return <String>{
    for (final Row r in db.select('PRAGMA table_info($table)'))
      r['name'] as String,
  };
}

Set<String> indexesOf(Database db) {
  return <String>{
    for (final Row r in db.select("SELECT name FROM sqlite_master WHERE type='index'"))
      r['name'] as String,
  };
}

void main() {
  late Map<int, String> sql;
  setUpAll(() {
    sql = loadAllSql();
  });

  group('registry (G0-SCH-001…007 traceability)', () {
    test('versions are contiguous 1..13 with existing files', () {
      // G0 chain v1..v8 preserved exactly (G0 acceptance); v9 (M03 masters)
      // appended by implementation Phase 02; v10-13 (DSS transaction refs,
      // FY + Dr/Cr, series mode, ledger masters) appended for the
      // voucher-engine milestone.
      expect(kMigrations.map((Migration m) => m.version).toList(),
          <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
      expect(kLatestVersion, 13);
      for (final Migration m in kMigrations) {
        expect(File('lib/data/migrations/${m.fileName}').existsSync(), isTrue,
            reason: m.fileName);
      }
    });

    test('every G0 schema delta is mapped exactly once', () {
      final List<String> ids =
          kMigrations.map((Migration m) => m.g0Id).toList();
      for (final String id in <String>[
        'G0-SCH-001',
        'G0-SCH-002',
        'G0-SCH-003',
        'G0-SCH-004',
        'G0-SCH-005',
        'G0-SCH-006',
        'G0-SCH-007',
      ]) {
        expect(ids.where((String e) => e == id).length, 1, reason: id);
      }
    });
  });

  group('clean install creates the complete schema', () {
    test('migrates to v13 with ordered ledger and all deltas present', () {
      final Database raw = sqlite3.openInMemory();
      raw.execute('PRAGMA foreign_keys = ON');
      final SqliteMigrationDb db = SqliteMigrationDb(raw);
      addTearDown(raw.close);

      migrate(db, sql);
      expect(currentVersion(db), kLatestVersion);

      // Ledger: 13 rows, ordered, one per version (G0 v1..v8 + M03 v9 + DSS v10-13).
      final List<Map<String, Object?>> ledger =
          db.query('SELECT version FROM schema_migrations ORDER BY version');
      expect(ledger.map((Map<String, Object?> r) => r['version']).toList(),
          <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);

      // G0-SCH-001 tables.
      for (final String t in <String>[
        'stock_cost_layer',
        'stock_movement',
        'item_cost_state'
      ]) {
        expect(tableExists(raw, t), isTrue, reason: t);
      }
      expect(columnsOf(raw, 'stock_cost_layer'),
          containsAll(<String>{'qty_q4', 'value_paise', 'record_version'}));
      expect(columnsOf(raw, 'stock_movement'),
          containsAll(<String>{'qty_delta_q4', 'cost_paise', 'cost_source'}));
      // G0-SCH-002.
      expect(tableExists(raw, 'period_lock'), isTrue);
      expect(columnsOf(raw, 'period_lock'),
          containsAll(<String>{'date_from', 'date_to', 'unlock_actor', 'unlock_reason', 'audit_event_id'}));
      // G0-SCH-003.
      expect(tableExists(raw, 'bill_allocation'), isTrue);
      expect(columnsOf(raw, 'bill_allocation'),
          containsAll(<String>{'source_voucher_line_id', 'settlement_voucher_line_id', 'allocated_amount_paise', 'operation_id'}));
      // G0-SCH-004.
      expect(tableExists(raw, 'tax_rate_hsn'), isTrue);
      expect(tableExists(raw, 'layout_profile'), isTrue);
      expect(columnsOf(raw, 'tax_rate_hsn'),
          containsAll(<String>{'hsn_code', 'rate_bps', 'effective_from', 'effective_to'}));
      expect(columnsOf(raw, 'layout_profile'),
          containsAll(<String>{'profile_key', 'version', 'layout_json', 'synced_at', 'backup_manifest_id'}));
      // G0-SCH-004 ships empty: no invented statutory rows.
      expect(raw.select('SELECT COUNT(*) AS n FROM tax_rate_hsn').first['n'], 0);
      // G0-SCH-005.
      expect(columnsOf(raw, 'item'), contains('record_version'));
      expect(columnsOf(raw, 'voucher'), contains('record_version'));
      expect(columnsOf(raw, 'voucher_line'), contains('record_version'));
      expect(columnsOf(raw, 'operation'), contains('base_version'));
      expect(tableExists(raw, 'operation_dependency'), isTrue);
      expect(tableExists(raw, 'sync_conflict'), isTrue);
      expect(columnsOf(raw, 'sync_conflict'),
          containsAll(<String>{'entity', 'entity_id', 'losing_op_id', 'winning_op_id', 'base_version', 'status'}));
      // G0-SCH-006.
      expect(tableExists(raw, 'trial_anchor'), isTrue);
      expect(tableExists(raw, 'denylist_entry'), isTrue);
      expect(columnsOf(raw, 'denylist_entry'), contains('key_hash'));
      // G0-SCH-007.
      expect(columnsOf(raw, 'voucher_line'),
          containsAll(<String>{'discount_amount_paise', 'discount_rate_bps'}));
      // Representative indexes from the design.
      expect(
          indexesOf(raw),
          containsAll(<String>{
            'idx_layer_item_godown',
            'idx_alloc_source',
            'idx_period_lock_company_dates',
            'idx_conflict_entity',
          }));
    });
  });

  group('upgrade from the previous (pre-G0) schema succeeds', () {
    test('v1 data survives; backfills are deterministic defaults', () {
      final Database raw = sqlite3.openInMemory();
      raw.execute('PRAGMA foreign_keys = ON');
      final SqliteMigrationDb db = SqliteMigrationDb(raw);
      addTearDown(raw.close);

      // Stage a pre-G0 install: baseline only, with user rows.
      migrate(db, sql, upTo: 1);
      expect(currentVersion(db), 1);
      raw.execute(
          "INSERT INTO company (company_id, name, created_at) VALUES ('c1','Shop',1000)");
      raw.execute(
          "INSERT INTO item (item_id, company_id, name, unit, created_at) VALUES ('i1','c1','Sugar','kg',1000)");
      raw.execute(
          "INSERT INTO godown (godown_id, company_id, name, created_at) VALUES ('g1','c1','Main',1000)");
      raw.execute(
          "INSERT INTO voucher (voucher_id, company_id, voucher_type, series, voucher_no, voucher_date, status, created_at) VALUES ('v1','c1','sale','A','1','2026-04-01','posted',1000)");
      raw.execute(
          "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, item_id, qty_q4, rate_paise, amount_paise, created_at) VALUES ('l1','v1','c1',1,'i1',20000,5000,10000,1000)");
      raw.execute(
          "INSERT INTO operation (op_id, company_id, device_id, seq, entity, entity_id, action, created_at) VALUES ('o1','c1','d1',1,'voucher','v1','post',1000)");

      // Upgrade to latest.
      migrate(db, sql);
      expect(currentVersion(db), kLatestVersion);

      // Pre-G0 rows intact (DSS: failure leaves source recoverable; success preserves).
      expect(raw.select('SELECT COUNT(*) AS n FROM voucher_line').first['n'], 1);
      final Row line = raw.select('SELECT * FROM voucher_line').first;
      // Backfills: genesis version 1, zero discount.
      expect(line['record_version'], 1);
      expect(line['discount_amount_paise'], 0);
      expect(line['discount_rate_bps'], 0);
      expect(
          raw.select('SELECT base_version FROM operation').first['base_version'], 1);
      // No FK breakage introduced by the upgrade.
      expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
    });
  });

  group('repeat-safe and failure-safe', () {
    test('second full run is a no-op', () {
      final Database raw = sqlite3.openInMemory();
      final SqliteMigrationDb db = SqliteMigrationDb(raw);
      addTearDown(raw.close);

      migrate(db, sql);
      final int ledgerRows = (db
          .query('SELECT COUNT(*) AS n FROM schema_migrations')
          .first['n'] as int);
      migrate(db, sql); // re-run
      expect(currentVersion(db), kLatestVersion);
      expect(
          (db.query('SELECT COUNT(*) AS n FROM schema_migrations').first['n']
              as int),
          ledgerRows);
    });

    test('broken migration fails safely with no partial version', () {
      final Database raw = sqlite3.openInMemory();
      final SqliteMigrationDb db = SqliteMigrationDb(raw);
      addTearDown(raw.close);

      final Map<int, String> bad = Map<int, String>.of(sql);
      bad[8] = 'CREATE TABLE broken (id INTEGER PRIMARY KEY; THIS IS NOT SQL';
      expect(() => migrate(db, bad), throwsA(anything));
      // v8 unwritten; v1..v7 intact; discount columns absent.
      expect(currentVersion(db), 7);
      expect(
          (db.query('SELECT COUNT(*) AS n FROM schema_migrations').first['n']
              as int),
          7);
      expect(columnsOf(raw, 'voucher_line').contains('discount_amount_paise'),
          isFalse);
    });
  });

  group('constraints hold (DB CHECKs + FKs)', () {
    late Database raw;
    setUp(() {
      raw = sqlite3.openInMemory();
      raw.execute('PRAGMA foreign_keys = ON');
      migrate(SqliteMigrationDb(raw), sql);
      raw.execute(
          "INSERT INTO company (company_id, name, created_at) VALUES ('c1','Shop',1000)");
      raw.execute(
          "INSERT INTO item (item_id, company_id, name, unit, created_at) VALUES ('i1','c1','Sugar','kg',1000)");
      raw.execute(
          "INSERT INTO godown (godown_id, company_id, name, created_at) VALUES ('g1','c1','Main',1000)");
      raw.execute(
          "INSERT INTO voucher (voucher_id, company_id, voucher_type, series, voucher_no, voucher_date, status, created_at) VALUES ('v1','c1','sale','A','1','2026-04-01','posted',1000)");
      raw.execute(
          "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, item_id, qty_q4, rate_paise, amount_paise, created_at) VALUES ('l1','v1','c1',1,'i1',20000,5000,10000,1000)");
      raw.execute(
          "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, item_id, qty_q4, rate_paise, amount_paise, created_at) VALUES ('l2','v1','c1',2,'i1',10000,5000,5000,1000)");
      raw.execute(
          "INSERT INTO operation (op_id, company_id, device_id, seq, entity, entity_id, action, created_at) VALUES ('o1','c1','d1',1,'voucher','v1','post',1000)");
    });
    tearDown(() => raw.close());

    test('G0-SCH-003 rejects self-allocation and negative amounts', () {
      expect(
          () => raw.execute(
              "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('a1','c1','l1','l1',100,'2026-04-02','active','o1',1000)"),
          throwsA(anything));
      expect(
          () => raw.execute(
              "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('a1','c1','l1','l2',-5,'2026-04-02','active','o1',1000)"),
          throwsA(anything));
      // Valid allocation persists.
      raw.execute(
          "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('a1','c1','l1','l2',5000,'2026-04-02','active','o1',1000)");
      expect(raw.select('SELECT COUNT(*) AS n FROM bill_allocation').first['n'], 1);
    });

    test('unknown FK targets are rejected', () {
      expect(
          () => raw.execute(
              "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('a9','c1','nope','l2',10,'2026-04-02','active','o1',1000)"),
          throwsA(anything));
    });

    test('G0-SCH-002 rejects inverted date ranges', () {
      expect(
          () => raw.execute(
              "INSERT INTO period_lock (lock_id, company_id, scope, date_from, date_to, status, locked_by, locked_at) VALUES ('p1','c1','company','2026-04-30','2026-04-01','locked','u1',1000)"),
          throwsA(anything));
    });

    test('G0-SCH-004 rejects inverted effective ranges', () {
      expect(
          () => raw.execute(
              "INSERT INTO tax_rate_hsn (rate_id, company_id, hsn_code, rate_bps, effective_from, effective_to) VALUES ('t1','c1','1701',500,'2026-04-01','2026-03-01')"),
          throwsA(anything));
    });

    test('G0-SCH-007 rejects out-of-range discount rate', () {
      expect(
          () => raw.execute(
              "UPDATE voucher_line SET discount_rate_bps = 20000 WHERE voucher_line_id = 'l1'"),
          throwsA(anything));
    });

    test('G0-SCH-001 rejects zero-quantity movements', () {
      expect(
          () => raw.execute(
              "INSERT INTO stock_movement (movement_id, company_id, item_id, godown_id, qty_delta_q4, cost_paise, cost_source, created_at) VALUES ('m1','c1','i1','g1',0,100,'layer',1000)"),
          throwsA(anything));
    });

    test('G0-SCH-006 enforces one anchor per company + unique key hash', () {
      raw.execute(
          "INSERT INTO trial_anchor (anchor_id, company_id, installed_at, trial_ends_at, status, created_at) VALUES ('t1','c1',1000,2000,'trial',1000)");
      expect(
          () => raw.execute(
              "INSERT INTO trial_anchor (anchor_id, company_id, installed_at, trial_ends_at, status, created_at) VALUES ('t2','c1',1000,2000,'trial',1000)"),
          throwsA(anything));
      raw.execute(
          "INSERT INTO denylist_entry (entry_id, key_hash, reason, status, created_at) VALUES ('d1','abc','stolen', 'listed',1000)");
      expect(
          () => raw.execute(
              "INSERT INTO denylist_entry (entry_id, key_hash, reason, status, created_at) VALUES ('d2','abc','other','listed',1000)"),
          throwsA(anything));
    });

    test('duplicate operations are rejected (DSS-C-004 replay safety)', () {
      expect(
          () => raw.execute(
              "INSERT INTO operation (op_id, company_id, device_id, seq, entity, entity_id, action, created_at) VALUES ('o2','c1','d1',1,'voucher','v1','post',1000)"),
          throwsA(anything));
    });
  });

  group('validators implement D-M4 arithmetic (G0-SCH-007)', () {
    test('lineAmount is round-half-up over qty x10^4', () {
      expect(lineAmount(1, 1), 0); // 0.0001 g → 0.0001 p rounds to 0
      expect(lineAmount(5000, 1), 1); // boundary: exactly half-up to 1
      expect(lineAmount(20000, 5000), 10000); // 2 × Rs50 = Rs100
      expect(lineAmount(-20000, 5000), -10000); // returns keep sign
      expect(lineAmount(15000, 199), 299); // 298.5 → 299
    });

    test('explicit amount wins; rate otherwise; net floored at zero', () {
      expect(discountFor(10000, 1500, 500), 1500);
      expect(discountFor(10000, 0, 1000), 1000); // 10%
      expect(discountFor(10000, 0, 0), 0);
      expect(discountFor(0, 100, 100), 0);
      expect(lineNet(1000, 5000, 0), 0); // never negative
      expect(lineNet(10000, 0, 1000), 9000);
    });

    test('input guards report errors without throwing', () {
      expect(validateDiscountInputs(0, 10000), isEmpty);
      expect(validateDiscountInputs(-1, 0), isNotEmpty);
      expect(validateDiscountInputs(0, 10001), isNotEmpty);
      expect(
          validatePeriodLock(dateFrom: '2026-04-01', dateTo: '2026-04-30'),
          isEmpty);
      expect(
          validatePeriodLock(dateFrom: '2026-04-30', dateTo: '2026-04-01'),
          isNotEmpty);
      expect(
          validatePeriodLock(
              dateFrom: '2026-04-01',
              dateTo: '2026-04-30',
              unlockActor: 'u1'),
          isNotEmpty); // partial triple
      expect(
          validateAllocation(
              sourceLineId: 'l1', settlementLineId: 'l2', amountPaise: 5),
          isEmpty);
      expect(
          validateAllocation(
              sourceLineId: 'l1', settlementLineId: 'l1', amountPaise: 5),
          isNotEmpty);
      expect(validateTaxRange('2026-04-01', null), isEmpty);
      expect(validateTaxRange('2026-04-01', '2026-03-01'), isNotEmpty);
    });
  });
}
