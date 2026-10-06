// D2 schema-hardening tests: triggers, checksums, indexes, versions, chain.
// Disposable databases only. Proves, against the migrated schema:
// append-only audit/operation triggers reject UPDATE/DELETE; posted vouchers
// accept only the posted→cancelled move (other columns frozen) and their
// lines accept no UPDATE/DELETE; vocabulary triggers reject bad status/
// cost-source/action values; voucher-line and party refs must resolve in the
// owning company; migration checksums backfill and refuse edited migrations;
// every C1 index serves its query (EXPLAIN QUERY PLAN); record_version
// increments on each table write; update audits carry old and new values;
// the audit hash chain verifies and detects tampering.
// Traceability: D2 (A1-A3/B1-B3/B5/C1/D1/D2); DB-004/DSS-C-001/C-003/C-007;
// OD-DB-004/006.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/period_lock.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherSeeder seeder;
  final CompanyId companyId = CompanyId('c-h');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    seeder = VoucherSeeder(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Hardening Co',
            deviceId: 'host-test',
            opId: 'op-ch',
            eventId: 'ev-ch',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  int versionOf(String table, String idCol, String id) {
    return db.queryArgs(
      'SELECT record_version AS v FROM $table WHERE $idCol = ?',
      <Object?>[id],
    ).single['v'] as int;
  }

  group('append-only triggers (D2-A1, DB-004)', () {
    test('audit_event and operation reject UPDATE and DELETE', () {
      expect(
        () => db.executeArgs(
          "UPDATE audit_event SET actor = ? WHERE company_id = ?",
          <Object?>['mallory', 'c-h'],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'DELETE FROM audit_event WHERE company_id = ?',
          <Object?>['c-h'],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          "UPDATE operation SET action = ? WHERE company_id = ?",
          <Object?>['forged', 'c-h'],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'DELETE FROM operation WHERE company_id = ?',
          <Object?>['c-h'],
        ),
        throwsException,
      );
      // History survives the attempts.
      expect(audit.forEntity('c-h', 'company', 'c-h'), isNotEmpty);
      expect(ops.forEntity('c-h', 'company', 'c-h'), isNotEmpty);
    });
  });

  group('posted-history triggers (D2-A2, DSS-C-003)', () {
    void postJournal() {
      // A balanced journal needs real ledgers (grounded in-company).
      final AccountGroupRepository groups =
          AccountGroupRepository(ctx, ops: ops, audit: audit);
      final LedgerRepository ledgers =
          LedgerRepository(ctx, ops: ops, audit: audit);
      expect(
        groups
            .create(
              id: EntityId('g-j'),
              companyId: companyId,
              name: 'Journals',
              deviceId: 'host-test',
              opId: 'op-gj',
              eventId: 'ev-gj',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      for (final Map<String, String> l in <Map<String, String>>[
        {'id': 'l-dr', 'side': 'Dr'},
        {'id': 'l-cr', 'side': 'Cr'},
      ]) {
        expect(
          ledgers
              .create(
                id: EntityId(l['id']!),
                companyId: companyId,
                groupId: EntityId('g-j'),
                name: l['id']!,
                openingSide: l['side']!,
                openingPaise: 0,
                deviceId: 'host-test',
                opId: 'op-${l['id']}',
                eventId: 'ev-${l['id']}',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
      }
      final Result<PostingResult> r = seeder.postVoucher(
        id: EntityId('v-j'),
        companyId: companyId,
        type: 'Journal',
        series: 'J',
        date: NiavDate('2026-04-01'),
        lines: <SeedLine>[
          SeedLine(
            ledgerId: EntityId('l-dr'),
            drCr: 'Dr',
            qtyQ4: 10000,
            ratePaise: 1000,
          ),
          SeedLine(
            ledgerId: EntityId('l-cr'),
            drCr: 'Cr',
            qtyQ4: 10000,
            ratePaise: 1000,
          ),
        ],
      );
      expect(r.isOk, isTrue);
    }

    test('posted voucher accepts only the posted→cancelled move', () {
      postJournal();
      // Status regression refused.
      expect(
        () => db.executeArgs(
          "UPDATE voucher SET status = ? WHERE voucher_id = ?",
          <Object?>['draft', 'v-j'],
        ),
        throwsException,
      );
      // Side-column edit on a posted row refused.
      expect(
        () => db.executeArgs(
          "UPDATE voucher SET narration = ? WHERE voucher_id = ?",
          <Object?>['rewritten', 'v-j'],
        ),
        throwsException,
      );
      // The documented transition is allowed.
      db.executeArgs(
        "UPDATE voucher SET status = ? WHERE voucher_id = ?",
        <Object?>['cancelled', 'v-j'],
      );
      expect(
        vouchers.get(companyId, EntityId('v-j'))?.voucher.status,
        'cancelled',
      );
      // Cancelled is terminal, including DELETE.
      expect(
        () => db.executeArgs(
          "UPDATE voucher SET status = ? WHERE voucher_id = ?",
          <Object?>['posted', 'v-j'],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'DELETE FROM voucher WHERE voucher_id = ?',
          <Object?>['v-j'],
        ),
        throwsException,
      );
    });

    test('posted voucher lines accept no UPDATE or DELETE', () {
      postJournal();
      expect(
        vouchers
            .create(
              id: EntityId('v-d'),
              companyId: companyId,
              type: 'Journal',
              series: 'J',
              no: 'v-d',
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-v-d',
              eventId: 'ev-v-d',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers
            .addLine(
              lineId: EntityId('v-d-l1'),
              voucherId: EntityId('v-d'),
              companyId: companyId,
              lineNo: 1,
              qtyQ4: 10000,
              ratePaise: 100,
              deviceId: 'host-test',
              opId: 'op-v-d-l1',
              eventId: 'ev-v-d-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      // Draft rows stay editable (control case).
      db.executeArgs(
        'UPDATE voucher_line SET rate_paise = ? WHERE voucher_line_id = ?',
        <Object?>[200, 'v-d-l1'],
      );
      // Posted rows are frozen.
      expect(
        () => db.executeArgs(
          "UPDATE voucher SET status = ? WHERE voucher_id = ?",
          <Object?>['cancelled', 'v-j'],
        ),
        returnsNormally,
      );
      expect(
        () => db.executeArgs(
          'UPDATE voucher_line SET rate_paise = ? '
          'WHERE voucher_line_id = ?',
          <Object?>[200, 'v-j-l1'],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'DELETE FROM voucher_line WHERE voucher_line_id = ?',
          <Object?>['v-j-l1'],
        ),
        throwsException,
      );
    });
  });

  group('vocabulary triggers (D2-B1)', () {
    test('bad status, cost-source and action values are rejected', () {
      expect(
        () => db.executeArgs(
          'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
          'voucher_no, voucher_date, status, created_at) VALUES '
          "(?, ?, ?, ?, ?, ?, ?, ?)",
          <Object?>[
            'v-bad',
            'c-h',
            'Journal',
            'J',
            'bad',
            '2026-04-01',
            'approved',
            1700000000000,
          ],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'INSERT INTO stock_movement (movement_id, company_id, item_id, '
          'godown_id, qty_delta_q4, cost_paise, cost_source, created_at) '
          "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
          <Object?>[
            'm-bad',
            'c-h',
            'i-x',
            'g-x',
            10000,
            100,
            'made-up',
            1700000000000,
          ],
        ),
        throwsException,
      );
      expect(
        () => db.executeArgs(
          'INSERT INTO operation (op_id, company_id, device_id, seq, entity, '
          'entity_id, action, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            'op-bad',
            'c-h',
            'd1',
            999001,
            'voucher',
            'v-x',
            'forged',
            1700000000000,
          ],
        ),
        throwsException,
      );
      // Documented values still pass.
      db.executeArgs(
        'INSERT INTO operation (op_id, company_id, device_id, seq, entity, '
        'entity_id, action, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'op-ok',
          'c-h',
          'd1',
          999002,
          'voucher',
          'v-x',
          'unlock',
          1700000000000,
        ],
      );
    });
  });

  group('company guards (D2-B2/B3, DSS-C-001)', () {
    test('voucher-line refs must resolve in the voucher company', () {
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-f'),
              name: 'Foreign Co',
              deviceId: 'host-test',
              opId: 'op-cf',
              eventId: 'ev-cf',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final ItemRepository items =
          ItemRepository(ctx, ops: ops, audit: audit);
      expect(
        items
            .create(
              id: EntityId('i-f'),
              companyId: CompanyId('c-f'),
              name: 'Foreign Widget',
              deviceId: 'host-test',
              opId: 'op-if',
              eventId: 'ev-if',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers
            .create(
              id: EntityId('v-x'),
              companyId: companyId,
              type: 'Purchase Invoice',
              series: 'P',
              no: 'v-x',
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-v-x',
              eventId: 'ev-v-x',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<VoucherLine> cross = vouchers.addLine(
        lineId: EntityId('v-x-l1'),
        voucherId: EntityId('v-x'),
        companyId: companyId,
        lineNo: 1,
        itemId: EntityId('i-f'),
        qtyQ4: 10000,
        ratePaise: 100,
        deviceId: 'host-test',
        opId: 'op-v-x-l1',
        eventId: 'ev-v-x-l1',
        actor: 'tester',
      );
      expect(cross.isErr, isTrue);
      expect((cross as Err<VoucherLine>).error.code, 'validation');
    });

    test('party ledger must resolve in the party company', () {
      final LedgerRepository ledgers =
          LedgerRepository(ctx, ops: ops, audit: audit);
      final AccountGroupRepository groups =
          AccountGroupRepository(ctx, ops: ops, audit: audit);
      final PartyRepository parties =
          PartyRepository(ctx, ops: ops, audit: audit);
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-f'),
              name: 'Foreign Co',
              deviceId: 'host-test',
              opId: 'op-cf2',
              eventId: 'ev-cf2',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        groups
            .create(
              id: EntityId('g-cash'),
              companyId: companyId,
              name: 'Cash',
              deviceId: 'host-test',
              opId: 'op-gc',
              eventId: 'ev-gc',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        ledgers
            .create(
              id: EntityId('l-cash'),
              companyId: companyId,
              groupId: EntityId('g-cash'),
              name: 'Cash',
              openingSide: 'Dr',
              openingPaise: 1000,
              deviceId: 'host-test',
              opId: 'op-lc',
              eventId: 'ev-lc',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      // Same-company ledger link is fine (control).
      expect(
        parties
            .create(
              id: EntityId('p-ok'),
              companyId: companyId,
              name: 'Local',
              role: 'customer',
              ledgerId: 'l-cash',
              deviceId: 'host-test',
              opId: 'op-pok',
              eventId: 'ev-pok',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      // Foreign-company ledger link is refused.
      final Result<Party> cross = parties.create(
        id: EntityId('p-bad'),
        companyId: CompanyId('c-f'),
        name: 'Foreign',
        role: 'customer',
        ledgerId: 'l-cash',
        deviceId: 'host-test',
        opId: 'op-pbad',
        eventId: 'ev-pbad',
        actor: 'tester',
      );
      expect(cross.isErr, isTrue);
    });
  });

  group('migration checksums (D2-B5, DSS-C-007)', () {
    test('staged v16 upgrade to v17 preserves rows and fills checksums', () {
      final TestDatabase engine =
          TestDatabase.open(sqlite3.openInMemory());
      final NiavDatabase staged = NiavDatabase(engine, clock: TestClock(1700000000000));
      staged.sqlByVersion = loadMigrationSql();
      engine.execute('PRAGMA foreign_keys = ON');
      migrate(engine, staged.sqlByVersion,
          clockMs: () => 1700000000000, upTo: 16);
      expect(currentVersion(engine), 16);
      engine.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-s', 'Staged Co', 1700000000000],
      );
      final NiavDatabase latest =
          NiavDatabase(engine, clock: TestClock(1700000000000));
      latest.sqlByVersion = loadMigrationSql();
      addTearDown(engine.close);
      latest.bootstrap();
      expect(latest.schemaVersion, 17);
      expect(
        latest.queryArgs(
          'SELECT name FROM company WHERE company_id = ?',
          <Object?>['c-s'],
        ).single['name'],
        'Staged Co',
      );
      expect(
        latest.query('SELECT COUNT(*) AS n FROM schema_migrations '
            'WHERE checksum IS NULL').single['n'],
        0,
      );
      expect(verifyAuditChain(engine, 'c-s'), isEmpty);
    });

    test('editing an applied migration is detected and refused', () {
      final Map<int, String> sql = loadMigrationSql();
      final TestDatabase engine =
          TestDatabase.open(sqlite3.openInMemory());
      addTearDown(engine.close);
      engine.execute('PRAGMA foreign_keys = ON');
      migrate(engine, sql, clockMs: () => 1700000000000);
      expect(currentVersion(engine), kLatestVersion);
      final Map<int, String> tampered = Map<int, String>.of(sql);
      tampered[3] = '${sql[3]} -- tampered';
      expect(
        () => migrate(engine, tampered, clockMs: () => 1700000000000),
        throwsStateError,
      );
      // The refused run changed nothing.
      expect(currentVersion(engine), kLatestVersion);
    });
  });

  group('read indexes serve their queries (D2-C1)', () {
    List<String> plan(String sql, [List<Object?> args = const <Object?>[]]) {
      return <String>[
        for (final Map<String, Object?> r in db.queryArgs(
            'EXPLAIN QUERY PLAN $sql', args))
          r['detail'] as String,
      ];
    }

    test('voucher_line company-scoped lookups use the new indexes', () {
      for (final Map<String, String> c in <Map<String, String>>[
        {'col': 'item_id', 'index': 'idx_voucher_line_company_item'},
        {'col': 'party_id', 'index': 'idx_voucher_line_company_party'},
        {'col': 'ledger_id', 'index': 'idx_voucher_line_company_ledger'},
        {'col': 'godown_id', 'index': 'idx_voucher_line_company_godown'},
      ]) {
        final List<String> details = plan(
          'SELECT voucher_line_id FROM voucher_line '
          'WHERE company_id = ? AND ${c['col']} = ?',
          <Object?>['c-h', 'x'],
        );
        expect(details.join(' '), contains(c['index']),
            reason: '${c['col']} should use ${c['index']}');
      }
    });

    test('voucher fy and type/date lookups use the new indexes', () {
      expect(
        plan(
          'SELECT voucher_id FROM voucher WHERE company_id = ? AND fy_id = ?',
          <Object?>['c-h', 'fy-1'],
        ).join(' '),
        contains('idx_voucher_company_fy'),
      );
      // Day-book register shape: one type in date order.
      expect(
        plan(
          'SELECT voucher_id FROM voucher WHERE company_id = ? '
          'AND voucher_type = ? ORDER BY voucher_date',
          <Object?>['c-h', 'Journal'],
        ).join(' '),
        contains('idx_voucher_company_type_date'),
      );
    });

    test('party name lookup and lineage reads use the new indexes', () {
      expect(
        plan(
          'SELECT party_id FROM party WHERE company_id = ? AND name = ?',
          <Object?>['c-h', 'Buyer'],
        ).join(' '),
        contains('idx_party_company_name_gstin'),
      );
      expect(
        plan(
          'SELECT event_id FROM audit_event WHERE company_id = ? '
          'AND entity = ? AND entity_id = ? ORDER BY created_at, rowid',
          <Object?>['c-h', 'voucher', 'v-1'],
        ).join(' '),
        contains('idx_audit_company_time'),
      );
      // SYNC §3 time-ordered replay scan shape over the operation envelope.
      expect(
        plan(
          'SELECT op_id FROM operation WHERE company_id = ? '
          'AND created_at >= ? ORDER BY created_at, op_id',
          <Object?>['c-h', 1700000000000],
        ).join(' '),
        contains('idx_operation_company_time'),
      );
    });
  });

  group('record_version increments on every table write (D2-D1)', () {
    test('voucher status moves bump the version', () {
      expect(
        vouchers
            .create(
              id: EntityId('v-v'),
              companyId: companyId,
              type: 'sales-invoice',
              series: 'S',
              no: 'v-v',
              date: NiavDate('2026-04-01'),
              status: 'held',
              deviceId: 'host-test',
              opId: 'op-v-v',
              eventId: 'ev-v-v',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(versionOf('voucher', 'voucher_id', 'v-v'), 1);
      final Result<Voucher> moved = vouchers.updateHeldStatus(
        id: EntityId('v-v'),
        companyId: companyId,
        status: 'resumed',
        deviceId: 'host-test',
        opId: 'op-mv-v',
        eventId: 'ev-mv-v',
        actor: 'tester',
      );
      expect(moved.isOk, isTrue);
      expect(versionOf('voucher', 'voucher_id', 'v-v'), 2);
    });

    test('item rename bumps the version', () {
      final ItemRepository items =
          ItemRepository(ctx, ops: ops, audit: audit);
      expect(
        items
            .create(
              id: EntityId('i-v'),
              companyId: companyId,
              name: 'Widget',
              deviceId: 'host-test',
              opId: 'op-iv',
              eventId: 'ev-iv',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(versionOf('item', 'item_id', 'i-v'), 1);
      expect(
        items
            .rename(
              id: EntityId('i-v'),
              companyId: companyId,
              name: 'Gadget',
              unit: 'pcs',
              deviceId: 'host-test',
              opId: 'op-ivr',
              eventId: 'ev-ivr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(versionOf('item', 'item_id', 'i-v'), 2);
    });

    test('allocation reversal and lock unlock bump their versions', () {
      final BillAllocationRepository allocs =
          BillAllocationRepository(ctx, ops: ops, audit: audit);
      final PeriodLockRepository locks =
          PeriodLockRepository(ctx, ops: ops, audit: audit);
      // Minimal posted lines to allocate between (direct allocate path).
      expect(
        vouchers
            .create(
              id: EntityId('v-a'),
              companyId: companyId,
              type: 'Journal',
              series: 'J',
              no: 'v-a',
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-v-a',
              eventId: 'ev-v-a',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      for (final Map<String, String> l in <Map<String, String>>[
        {'id': 'v-a-l1'},
        {'id': 'v-a-l2'},
      ]) {
        expect(
          vouchers
              .addLine(
                lineId: EntityId(l['id']!),
                voucherId: EntityId('v-a'),
                companyId: companyId,
                lineNo: l['id'] == 'v-a-l1' ? 1 : 2,
                qtyQ4: 10000,
                ratePaise: 5000,
                deviceId: 'host-test',
                opId: 'op-${l['id']}',
                eventId: 'ev-${l['id']}',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
      }
      expect(
        allocs
            .allocate(
              id: EntityId('a-1'),
              companyId: companyId,
              sourceLineId: EntityId('v-a-l1'),
              settlementLineId: EntityId('v-a-l2'),
              amountPaise: 2000,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-a-1',
              eventId: 'ev-a-1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
          versionOf('bill_allocation', 'allocation_id', 'a-1'), 1);
      expect(
        allocs
            .reverse(
              id: EntityId('a-1'),
              companyId: companyId,
              reason: 'test',
              deviceId: 'host-test',
              opId: 'op-a-1r',
              eventId: 'ev-a-1r',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
          versionOf('bill_allocation', 'allocation_id', 'a-1'), 2);
      expect(
        locks
            .create(
              id: EntityId('lock-1'),
              companyId: companyId,
              scope: 'company',
              dateFrom: '2026-01-01',
              dateTo: '2026-12-31',
              lockedBy: 'owner',
              deviceId: 'host-test',
              opId: 'op-lock-1',
              eventId: 'ev-lock-1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(versionOf('period_lock', 'lock_id', 'lock-1'), 1);
      expect(
        locks
            .unlock(
              id: EntityId('lock-1'),
              companyId: companyId,
              reason: 'test unlock',
              deviceId: 'host-test',
              opId: 'op-un-1',
              eventId: 'ev-un-1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(versionOf('period_lock', 'lock_id', 'lock-1'), 2);
    });

    test('operation envelope carries base_version (default 1, explicit kept)',
        () {
      final Result<OperationRecord> dflt = ops.append(
        opId: 'op-bv-1',
        companyId: 'c-h',
        deviceId: 'host-test',
        entity: 'voucher',
        entityId: 'v-x',
        action: 'create',
      );
      expect(dflt.isOk, isTrue);
      expect((dflt as Ok<OperationRecord>).value.baseVersion, 1);
      final Result<OperationRecord> explicit = ops.append(
        opId: 'op-bv-2',
        companyId: 'c-h',
        deviceId: 'host-test',
        entity: 'voucher',
        entityId: 'v-x',
        action: 'create',
        baseVersion: 5,
      );
      expect(explicit.isOk, isTrue);
      expect((explicit as Ok<OperationRecord>).value.baseVersion, 5);
      expect(
        db.queryArgs(
          'SELECT base_version AS b FROM operation WHERE op_id = ?',
          <Object?>['op-bv-2'],
        ).single['b'],
        5,
      );
    });
  });

  group('audit update events carry old and new values (D2-D2)', () {
    test('allocation reversal records the status move both ways', () {
      final BillAllocationRepository allocs =
          BillAllocationRepository(ctx, ops: ops, audit: audit);
      expect(
        vouchers
            .create(
              id: EntityId('v-u'),
              companyId: companyId,
              type: 'Journal',
              series: 'J',
              no: 'v-u',
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-v-u',
              eventId: 'ev-v-u',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      for (final String lid in <String>['v-u-l1', 'v-u-l2']) {
        expect(
          vouchers
              .addLine(
                lineId: EntityId(lid),
                voucherId: EntityId('v-u'),
                companyId: companyId,
                lineNo: lid == 'v-u-l1' ? 1 : 2,
                qtyQ4: 10000,
                ratePaise: 5000,
                deviceId: 'host-test',
                opId: 'op-$lid',
                eventId: 'ev-$lid',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
      }
      expect(
        allocs
            .allocate(
              id: EntityId('a-u'),
              companyId: companyId,
              sourceLineId: EntityId('v-u-l1'),
              settlementLineId: EntityId('v-u-l2'),
              amountPaise: 2000,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-a-u',
              eventId: 'ev-a-u',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        allocs
            .reverse(
              id: EntityId('a-u'),
              companyId: companyId,
              reason: 'cheque bounced',
              deviceId: 'host-test',
              opId: 'op-a-ur',
              eventId: 'ev-a-ur',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final List<AuditEvent> trail =
          audit.forEntity('c-h', 'bill_allocation', 'a-u');
      expect(trail, hasLength(2));
      expect(trail.last.oldData, contains('active'));
      expect(trail.last.newData, contains('reversed'));
    });
  });

  group('audit hash chain (D2-A3, OD-DB-004)', () {
    test('appended events verify clean with linked hashes', () {
      expect(
        audit
            .append(
              eventId: 'ev-c1',
              companyId: 'c-h',
              entity: 'voucher',
              entityId: 'v-1',
              newRow: const <String, Object?>{'status': 'posted'},
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        audit
            .append(
              eventId: 'ev-c2',
              companyId: 'c-h',
              entity: 'voucher',
              entityId: 'v-1',
              oldRow: const <String, Object?>{'status': 'posted'},
              newRow: const <String, Object?>{
                'status': 'cancelled',
              },
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(verifyAuditChain(db, 'c-h'), isEmpty);
      final List<Map<String, Object?>> rows = db.queryArgs(
        'SELECT prev_hash, row_hash FROM audit_event WHERE company_id = ? '
        'ORDER BY rowid',
        <Object?>['c-h'],
      );
      // Company creation + 2 appends, all chained (no NULL hashes).
      for (final Map<String, Object?> r in rows) {
        expect(r['row_hash'], isNotNull);
      }
      expect(rows[1]['prev_hash'], rows[0]['row_hash']);
      expect(rows[2]['prev_hash'], rows[1]['row_hash']);
    });

    test('tampering is detected; legacy prefix stays valid', () {
      // A pre-chain database: company + history rows with NULL hashes (no
      // lineage writes, exactly like an upgrade from before m017).
      db.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-old', 'Old Co', 1699999998000],
      );
      db.executeArgs(
        'INSERT INTO audit_event (event_id, company_id, entity, entity_id, '
        'actor, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        <Object?>[
          'ev-legacy',
          'c-old',
          'voucher',
          'v-0',
          'tester',
          1699999999000
        ],
      );
      expect(
        audit
            .append(
              eventId: 'ev-c1',
              companyId: 'c-old',
              entity: 'voucher',
              entityId: 'v-1',
              newRow: const <String, Object?>{'status': 'posted'},
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(verifyAuditChain(db, 'c-old'), isEmpty);
      // Tamper with the trigger dropped (test-only): the chain must catch it.
      db.execute('DROP TRIGGER trg_audit_event_no_update');
      db.executeArgs(
        "UPDATE audit_event SET new_data = ? WHERE event_id = ?",
        <Object?>['{"status":"forged"}', 'ev-c1'],
      );
      final List<String> errors = verifyAuditChain(db, 'c-old');
      expect(errors, isNotEmpty);
      expect(errors.join(' '), contains('ev-c1'));
    });
  });
}
