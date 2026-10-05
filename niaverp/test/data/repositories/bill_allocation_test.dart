// Posting-slice tests: bill-allocation writer (FR-M06, G0-SCH-003).
// Disposable in-memory databases only. Proves: allocation reduces the open
// balance (read back through the outstanding query), over-allocations and
// self-settlement and missing lines are rejected with no residue, and
// reversal reopens the balance with lineage.
// Traceability: FR-M06-001/002 (bill-wise settlement); G0-SCH-003.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late BillAllocationRepository allocations;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    allocations = BillAllocationRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-a'),
            name: 'Alloc Co',
            deviceId: 'host-test',
            opId: 'op-ca',
            eventId: 'ev-ca',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createBill(String id, int amount) {
    final Result<Voucher> h = vouchers.create(
      id: EntityId(id),
      companyId: CompanyId('c-a'),
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
    final Result<VoucherLine> l = vouchers.addLine(
      lineId: EntityId('$id-l1'),
      voucherId: EntityId(id),
      companyId: CompanyId('c-a'),
      lineNo: 1,
      qtyQ4: 10000,
      ratePaise: amount,
      deviceId: 'host-test',
      opId: 'op-$id-l1',
      eventId: 'ev-$id-l1',
      actor: 'tester',
    );
    expect(l.isOk, isTrue);
  }

  Result<void> allocate(String id, String source, String settlement, int amount) {
    return allocations.allocate(
      id: EntityId(id),
      companyId: CompanyId('c-a'),
      sourceLineId: EntityId(source),
      settlementLineId: EntityId(settlement),
      amountPaise: amount,
      date: NiavDate('2026-04-02'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  int openOf(String voucher) =>
      voucherOpenBalance(db, CompanyId('c-a'), EntityId(voucher));

  group('bill allocations (FR-M06)', () {
    test('allocation reduces open; reversal reopens, both with lineage', () {
      createBill('b-1', 5000);
      createBill('r-1', 5000);
      expect(allocate('a-1', 'b-1-l1', 'r-1-l1', 2000).isOk, isTrue);
      expect(openOf('b-1'), 3000);
      expect(ops.forEntity('c-a', 'bill_allocation', 'a-1'), isNotEmpty);

      final Result<void> rev = allocations.reverse(
        id: EntityId('a-1'),
        companyId: CompanyId('c-a'),
        reason: 'wrong bill',
        deviceId: 'host-test',
        opId: 'op-rev',
        eventId: 'ev-rev',
        actor: 'tester',
      );
      expect(rev.isOk, isTrue);
      expect(openOf('b-1'), 5000);
      final Result<void> twice = allocations.reverse(
        id: EntityId('a-1'),
        companyId: CompanyId('c-a'),
        reason: 'again',
        deviceId: 'host-test',
        opId: 'op-rev2',
        eventId: 'ev-rev2',
        actor: 'tester',
      );
      expect(twice.isErr, isTrue);
    });

    test('over-allocation, self-settlement and ghosts rejected', () {
      createBill('b-1', 5000);
      createBill('r-1', 5000);
      final Result<void> over = allocate('a-1', 'b-1-l1', 'r-1-l1', 6000);
      expect(over.isErr, isTrue);
      expect((over as Err<void>).error.code, 'validation');
      final Result<void> self = allocate('a-2', 'b-1-l1', 'b-1-l1', 100);
      expect(self.isErr, isTrue);
      final Result<void> ghost = allocate('a-3', 'b-1-l1', 'l-nope', 100);
      expect(ghost.isErr, isTrue);
      expect(openOf('b-1'), 5000);
      final Result<void> noReason = allocations.reverse(
        id: EntityId('a-9'),
        companyId: CompanyId('c-a'),
        reason: 'x',
        deviceId: 'host-test',
        opId: 'op-r9',
        eventId: 'ev-r9',
        actor: 'tester',
      );
      expect(noReason.isErr, isTrue);
    });
  });
}
