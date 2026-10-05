// Fixture tests: bill-wise settlement — Phase 2.
// Fixture IDs F-SETL-001…006. Expectations hand-computed and frozen.
// Only status='active' rows consume a balance; reversal marks 'reversed'
// (history preserved, DSS-C-003). Over-allocation and duplicate application
// are rejected, never clamped. Runs against a real migrated disposable DB so
// PK/FK guards are proven, not just engine guards.
// Traceability: G0-SCH-003 (G1); FR-M06; DSS-C-003/004.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/data/accounting/settlement.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

class _Db implements MigrationDb {
  _Db(this.db);
  final Database db;
  @override
  void execute(String sql) => db.execute(sql);
  @override
  void executeArgs(String sql, List<Object?> args) =>
      db.execute(sql, args);
  @override
  List<Map<String, Object?>> query(String sql) =>
      queryArgs(sql, <Object?>[]);
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

List<AllocationView> _readAll(Database db) => <AllocationView>[
      for (final Row r in db.select(
          'SELECT allocation_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, status, operation_id FROM bill_allocation'))
        AllocationView(
          allocationId: r['allocation_id'] as String,
          sourceLineId: r['source_voucher_line_id'] as String,
          settlementLineId: r['settlement_voucher_line_id'] as String,
          amountPaise: r['allocated_amount_paise'] as int,
          status: r['status'] as String,
          operationId: r['operation_id'] as String,
        ),
    ];

void _insertAllocation(
  Database db, {
  required String id,
  required String source,
  required String settlement,
  required int amount,
  required String op,
}) {
  db.execute(
      "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('$id','c1','$source','$settlement',$amount,'2026-04-05','active','$op',4000)");
}

/// Fresh migrated DB with invoice line L1 = Rs100 (10000p) and receipt
/// lines P1 (Rs40), P2 (Rs60), P3 (Rs70), plus operations O1…O4.
Database _settlementDb() {
  final Database raw = sqlite3.openInMemory();
  raw.execute('PRAGMA foreign_keys = ON');
  migrate(
      _Db(raw),
      <int, String>{
        for (final Migration m in kMigrations)
          m.version:
              File('lib/data/migrations/${m.fileName}').readAsStringSync(),
      });
  raw.execute(
      "INSERT INTO company (company_id, name, created_at) VALUES ('c1','Shop',1000)");
  raw.execute(
      "INSERT INTO voucher (voucher_id, company_id, voucher_type, series, voucher_no, voucher_date, status, created_at) VALUES ('V1','c1','sale','A','1','2026-04-01','posted',1000)");
  raw.execute(
      "INSERT INTO voucher (voucher_id, company_id, voucher_type, series, voucher_no, voucher_date, status, created_at) VALUES ('V2','c1','receipt','R','1','2026-04-05','posted',2000)");
  raw.execute(
      "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, qty_q4, rate_paise, amount_paise, created_at) VALUES ('L1','V1','c1',1,10000,10000,10000,1000)");
  raw.execute(
      "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, qty_q4, rate_paise, amount_paise, created_at) VALUES ('P1','V2','c1',1,10000,4000,4000,2000)");
  raw.execute(
      "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, qty_q4, rate_paise, amount_paise, created_at) VALUES ('P2','V2','c1',2,10000,6000,6000,2000)");
  raw.execute(
      "INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, line_no, qty_q4, rate_paise, amount_paise, created_at) VALUES ('P3','V2','c1',3,10000,7000,7000,2000)");
  for (final String op in <String>['O1', 'O2', 'O3', 'O4']) {
    raw.execute(
        "INSERT INTO operation (op_id, company_id, device_id, seq, entity, entity_id, action, created_at) VALUES ('$op','c1','d1',${op.substring(1)},'bill_allocation','$op','create',3000)");
  }
  return raw;
}

void main() {
  group('F-SETL-001 partial settlement', () {
    test('Rs40 against Rs100 leaves Rs60', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      final List<String> errors = checkApplicable(
        allocationId: 'A1',
        sourceLineId: 'L1',
        settlementLineId: 'P1',
        amountPaise: 4000,
        operationId: 'O1',
        sourceAmountPaise: 10000,
        existing: _readAll(raw),
      );
      expect(errors, isEmpty);
      _insertAllocation(raw, id: 'A1', source: 'L1', settlement: 'P1', amount: 4000, op: 'O1');
      expect(remainingBalance(10000, _readAll(raw)), 6000);
    });
  });

  group('F-SETL-002 full settlement to zero', () {
    test('Rs40 + Rs60 closes the Rs100 invoice', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      _insertAllocation(raw, id: 'A1', source: 'L1', settlement: 'P1', amount: 4000, op: 'O1');
      _insertAllocation(raw, id: 'A2', source: 'L1', settlement: 'P2', amount: 6000, op: 'O2');
      expect(remainingBalance(10000, _readAll(raw)), 0);
    });
  });

  group('F-SETL-003 over-allocation rejection', () {
    test('Rs70 against Rs60 remaining is refused, balance untouched', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      _insertAllocation(raw, id: 'A1', source: 'L1', settlement: 'P1', amount: 4000, op: 'O1');
      final List<String> errors = checkApplicable(
        allocationId: 'A2',
        sourceLineId: 'L1',
        settlementLineId: 'P3', // Rs70 receipt line
        amountPaise: 7000,
        operationId: 'O2',
        sourceAmountPaise: 10000,
        existing: _readAll(raw),
      );
      expect(errors, isNotEmpty);
      expect(remainingBalance(10000, _readAll(raw)), 6000);
    });
  });

  group('F-SETL-004 reversal restores the balance', () {
    test('reversing Rs40 of Rs100 settled leaves Rs40 due', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      _insertAllocation(raw, id: 'A1', source: 'L1', settlement: 'P1', amount: 4000, op: 'O1');
      _insertAllocation(raw, id: 'A2', source: 'L1', settlement: 'P2', amount: 6000, op: 'O2');
      expect(remainingBalance(10000, _readAll(raw)), 0);
      final AllocationView target =
          _readAll(raw).firstWhere((AllocationView a) => a.allocationId == 'A1');
      expect(checkReversible(target), isEmpty);
      raw.execute(
          "UPDATE bill_allocation SET status='reversed' WHERE allocation_id='A1'");
      raw.execute(
          "INSERT INTO audit_event (event_id, company_id, entity, entity_id, old_data, new_data, actor, created_at) VALUES ('E1','c1','bill_allocation','A1','{\"status\":\"active\"}','{\"status\":\"reversed\",\"reason\":\"cheque bounced\"}','u1',5000)");
      expect(remainingBalance(10000, _readAll(raw)), 4000);
      // Re-reversal of the same row is refused.
      final AllocationView done =
          _readAll(raw).firstWhere((AllocationView a) => a.allocationId == 'A1');
      expect(checkReversible(done), isNotEmpty);
    });
  });

  group('F-SETL-005 duplicate application is rejected', () {
    test('same id and same lineage both fail', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      _insertAllocation(raw, id: 'A1', source: 'L1', settlement: 'P1', amount: 4000, op: 'O1');
      // Same allocation_id → engine guard + PK guard.
      expect(
          checkApplicable(
            allocationId: 'A1',
            sourceLineId: 'L1',
            settlementLineId: 'P2',
            amountPaise: 1000,
            operationId: 'O2',
            sourceAmountPaise: 10000,
            existing: _readAll(raw),
          ),
          isNotEmpty);
      expect(
          () => _insertAllocation(
              raw, id: 'A1', source: 'L1', settlement: 'P2', amount: 1000, op: 'O2'),
          throwsA(anything));
      // Same lineage, fresh id → replay guard.
      expect(
          checkApplicable(
            allocationId: 'A9',
            sourceLineId: 'L1',
            settlementLineId: 'P1',
            amountPaise: 4000,
            operationId: 'O1',
            sourceAmountPaise: 10000,
            existing: _readAll(raw),
          ),
          isNotEmpty);
    });
  });

  group('F-SETL-006 impossible balances are detected, never clamped', () {
    test('allocated 20000 on 10000 throws StateError', () {
      final Database raw = _settlementDb();
      addTearDown(raw.close);
      // Bypass the engine (simulates corrupt/double-applied history).
      raw.execute(
          "INSERT INTO bill_allocation (allocation_id, company_id, source_voucher_line_id, settlement_voucher_line_id, allocated_amount_paise, allocation_date, status, operation_id, created_at) VALUES ('AX','c1','L1','P3',20000,'2026-04-05','active','O4',4000)");
      expect(() => remainingBalance(10000, _readAll(raw)), throwsStateError);
    });
  });
}
