// Prompt-06 tests: voucher open balances (FR-M14-001 validation side).
// Disposable in-memory databases only (allocations seeded with
// schema-defined columns over repo-created lines). Proves: open amount
// starts at the line total, active allocations reduce it, reversed rows are
// ignored, over-allocation throws instead of clamping, and unknown/foreign
// vouchers report zero.
// Traceability: FR-M14-001 (allocation cannot exceed open balance); G0-SCH-003.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-o', 'c-other']) {
      expect(
        companies
            .create(
              id: CompanyId(c),
              name: 'Co $c',
              deviceId: 'host-test',
              opId: 'op-$c',
              eventId: 'ev-$c',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createBill(String id, String company, List<int> amounts) {
    final Result<Voucher> h = vouchers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      type: 'sales-invoice',
      series: 'SI',
      no: id,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(h.isOk, isTrue);
    int lineNo = 0;
    for (final int amount in amounts) {
      lineNo += 1;
      // amount paise = qty × rate / 10⁴: qty 10000 (1.0) × rate = amount.
      expect(
        vouchers
            .addLine(
              lineId: EntityId('$id-l$lineNo'),
              voucherId: EntityId(id),
              companyId: CompanyId(company),
              lineNo: lineNo,
              qtyQ4: 10000,
              ratePaise: amount,
              deviceId: 'host-test',
              opId: 'op-$id-l$lineNo',
              eventId: 'ev-$id-l$lineNo',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
  }

  void insertAllocation(
    String id,
    String company,
    String sourceLine,
    String settlementLine,
    int amount,
    String status,
  ) {
    final Result<OperationRecord> op = ops.append(
      opId: 'op-$id',
      companyId: company,
      deviceId: 'host-test',
      entity: 'bill_allocation',
      entityId: id,
      action: 'create',
    );
    expect(op.isOk, isTrue);
    db.executeArgs(
      'INSERT INTO bill_allocation (allocation_id, company_id, '
      'source_voucher_line_id, settlement_voucher_line_id, '
      'allocated_amount_paise, allocation_date, status, operation_id, '
      'created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        id,
        company,
        sourceLine,
        settlementLine,
        amount,
        '2026-04-02',
        status,
        'op-$id',
        1700000000000,
      ],
    );
  }

  group('voucher open balances (FR-M14-001)', () {
    test('open starts at the line total across lines', () {
      createBill('b-1', 'c-o', <int>[2000, 3000]);
      expect(
        voucherOpenBalance(db, CompanyId('c-o'), EntityId('b-1')),
        5000,
      );
    });

    test('active allocations reduce, full settlement zeroes', () {
      createBill('b-1', 'c-o', <int>[5000]);
      createBill('r-1', 'c-o', <int>[5000]);
      insertAllocation('a-1', 'c-o', 'b-1-l1', 'r-1-l1', 2000, 'active');
      expect(
        voucherOpenBalance(db, CompanyId('c-o'), EntityId('b-1')),
        3000,
      );
      insertAllocation('a-2', 'c-o', 'b-1-l1', 'r-1-l1', 3000, 'active');
      expect(
        voucherOpenBalance(db, CompanyId('c-o'), EntityId('b-1')),
        0,
      );
    });

    test('reversed allocations are ignored (invalid/denied case)', () {
      createBill('b-1', 'c-o', <int>[5000]);
      createBill('r-1', 'c-o', <int>[5000]);
      insertAllocation('a-1', 'c-o', 'b-1-l1', 'r-1-l1', 5000, 'reversed');
      expect(
        voucherOpenBalance(db, CompanyId('c-o'), EntityId('b-1')),
        5000,
      );
    });

    test('over-allocation throws instead of clamping', () {
      createBill('b-1', 'c-o', <int>[5000]);
      createBill('r-1', 'c-o', <int>[9000]);
      insertAllocation('a-1', 'c-o', 'b-1-l1', 'r-1-l1', 6000, 'active');
      expect(
        () => voucherOpenBalance(db, CompanyId('c-o'), EntityId('b-1')),
        throwsStateError,
      );
    });

    test('unknown and foreign vouchers report zero', () {
      createBill('b-1', 'c-o', <int>[5000]);
      createBill('r-1', 'c-o', <int>[5000]);
      insertAllocation('a-1', 'c-o', 'b-1-l1', 'r-1-l1', 1000, 'active');
      expect(
        voucherOpenBalance(db, CompanyId('c-o'), EntityId('v-nope')),
        0,
      );
      expect(
        voucherOpenBalance(db, CompanyId('c-other'), EntityId('b-1')),
        0,
      );
    });
  });
}
