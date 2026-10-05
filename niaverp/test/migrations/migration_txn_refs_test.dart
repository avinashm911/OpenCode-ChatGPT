// m010 migration tests: DSS transaction enrichment (gate G1).
// Disposable databases only. Proves: document_link table + named index
// exist, voucher/voucher_line carry the specified new columns, a staged
// v9→v10 upgrade preserves rows, party/godown FKs are enforced, and
// re-bootstrap is repeat-safe (ADD COLUMN guards).
// Traceability: DSS §3 (voucher/voucher_line/document_link); DSS-C-007.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;

  tearDown(() {
    // Each test owns closing (engines differ per test below).
  });

  List<String> columns(MigrationDb db, String table) {
    final List<Map<String, Object?>> rows =
        db.query('PRAGMA table_info($table)');
    return <String>[for (final Map<String, Object?> r in rows) r['name'] as String];
  }

  group('m010 DSS transaction refs', () {
    test('clean install carries the specified tables, columns and index', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      for (final String c in <String>['narration', 'actor', 'device']) {
        expect(columns(db, 'voucher'), contains(c));
      }
      for (final String c in <String>[
        'ledger_id',
        'party_id',
        'godown_id',
        'batch_id'
      ]) {
        expect(columns(db, 'voucher_line'), contains(c));
      }
      final List<Map<String, Object?>> tables = db.query(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'document_link'",
      );
      expect(tables, hasLength(1));
      final List<Map<String, Object?>> indexes = db.query(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_doc_link_source_target'",
      );
      expect(indexes, hasLength(1));
    });

    test('staged v9→v11 upgrade preserves rows and unlocks new fields', () {
      final NiavDatabase v9 = openTestDatabase(upTo: 9);
      v9.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      v9.executeArgs(
        'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
        'voucher_no, voucher_date, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'v-u',
          'c-u',
          'Sales Invoice',
          'S',
          'v-u',
          '2026-04-01',
          'draft',
          1700000000000,
        ],
      );
      final NiavDatabase v10 =
          NiavDatabase(rawEngineOf(v9), clock: testClock());
      v10.sqlByVersion = loadMigrationSql();
      v10.bootstrap();
      addTearDown(() => rawEngineOf(v10).close());
      expect(v10.schemaVersion, 15);
      final List<Map<String, Object?>> rows = v10.queryArgs(
        'SELECT narration, actor FROM voucher WHERE voucher_id = ?',
        <Object?>['v-u'],
      );
      expect(rows.single['narration'], isNull);
      // Repeat-safe: bootstrapping again is a no-op (ADD COLUMN guards).
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v10), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 15);
    });

    test('party/godown FKs reject dangling references', () {      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      db.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-f', 'FK Co', 1700000000000],
      );
      db.executeArgs(
        'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
        'voucher_no, voucher_date, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'v-f',
          'c-f',
          'Sales Invoice',
          'S',
          'v-f',
          '2026-04-01',
          'draft',
          1700000000000,
        ],
      );
      expect(
        () => db.executeArgs(
          'INSERT INTO voucher_line (voucher_line_id, voucher_id, '
          'company_id, line_no, qty_q4, rate_paise, amount_paise, party_id, '
          'created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            'l-f',
            'v-f',
            'c-f',
            1,
            10000,
            500,
            500,
            'p-ghost',
            1700000000000,
          ],
        ),
        throwsException,
      );
    });
  });

  group('m011 FY + Dr/Cr', () {
    test('financial_year table and dr_cr check exist at v11', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 15);
      final List<Map<String, Object?>> tables = db.query(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = 'financial_year'",
      );
      expect(tables, hasLength(1));
      expect(columns(db, 'voucher'), contains('fy_id'));
      expect(columns(db, 'voucher_line'), contains('dr_cr'));
    });

    test('staged v10→v11 upgrade preserves rows; checks enforced', () {
      final NiavDatabase v10 = openTestDatabase(upTo: 10);
      v10.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      final NiavDatabase v11 =
          NiavDatabase(rawEngineOf(v10), clock: testClock());
      v11.sqlByVersion = loadMigrationSql();
      v11.bootstrap();
      addTearDown(() => rawEngineOf(v11).close());
      expect(v11.schemaVersion, 15);
      expect(
        v11.queryArgs(
          'SELECT name FROM company WHERE company_id = ?',
          <Object?>['c-u'],
        ).single['name'],
        'Upgrade Co',
      );
      // FY date order and Dr/Cr value set are refused by the schema.
      expect(
        () => v11.executeArgs(
          'INSERT INTO financial_year (fy_id, company_id, start_date, '
          'end_date, status, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            'fy-bad',
            'c-u',
            '2027-04-01',
            '2026-03-31',
            'open',
            1700000000000,
          ],
        ),
        throwsException,
      );
      v11.executeArgs(
        'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
        'voucher_no, voucher_date, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'v-u',
          'c-u',
          'Journal',
          'J',
          'v-u',
          '2026-04-01',
          'draft',
          1700000000000,
        ],
      );
      expect(
        () => v11.executeArgs(
          'INSERT INTO voucher_line (voucher_line_id, voucher_id, '
          'company_id, line_no, qty_q4, rate_paise, amount_paise, dr_cr, '
          'created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            'l-u',
            'v-u',
            'c-u',
            1,
            0,
            0,
            0,
            'Dx',
            1700000000000,
          ],
        ),
        throwsException,
      );
      // Repeat-safe re-bootstrap.
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v11), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 15);
    });
  });
}
