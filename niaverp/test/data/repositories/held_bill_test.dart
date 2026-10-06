// Prompt-05 tests: held-bill queue and counter transitions (FR-M11-003).
// Disposable in-memory databases only. Proves: held vouchers persist with
// lines without creating accounting/stock effects, the Held →
// Resumed/Cancelled moves carry lineage, `posted` is refused here (D1-D2:
// posting goes only through the voucher engine) with the voucher left
// unchanged, terminal states and unknown targets are rejected, and the queue
// stays company-scoped.
// Traceability: FR-M11-003 (held data must not affect accounting/stock
// until posting); DSS-C-001 (scope); OD-DB-004 (lineage).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
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

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-h', 'c-other']) {
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

  Result<Voucher> holdBill(String id, String company) {
    return vouchers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      type: 'sales-invoice',
      series: 'QB',
      no: id,
      date: NiavDate('2026-04-01'),
      status: 'held',
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  Result<Voucher> moveBill(String id, String company, String status, String tag) {
    return vouchers.updateHeldStatus(
      id: EntityId(id),
      companyId: CompanyId(company),
      status: status,
      deviceId: 'host-test',
      opId: 'op-$tag',
      eventId: 'ev-$tag',
      actor: 'tester',
    );
  }

  int effectRowCount(String table, String company) {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT COUNT(*) AS n FROM $table WHERE company_id = ?',
      <Object?>[company],
    );
    return rows.first['n'] as int;
  }

  group('held bills (FR-M11-003)', () {
    test('held bill persists with lines and creates no posting effects', () {
      expect(holdBill('h-1', 'c-h').isOk, isTrue);
      expect(
        vouchers
            .addLine(
              lineId: EntityId('h-1-l1'),
              voucherId: EntityId('h-1'),
              companyId: CompanyId('c-h'),
              lineNo: 1,
              qtyQ4: 20000,
              ratePaise: 999,
              deviceId: 'host-test',
              opId: 'op-h-1-l1',
              eventId: 'ev-h-1-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers.heldBills(CompanyId('c-h')).map((Voucher v) => v.no),
        <String>['h-1'],
      );
      // No accounting/stock effect tables gain rows from held data.
      expect(effectRowCount('stock_movement', 'c-h'), 0);
      expect(effectRowCount('stock_cost_layer', 'c-h'), 0);
      expect(effectRowCount('bill_allocation', 'c-h'), 0);
      // Lineage (operation + audit) is still recorded.
      expect(ops.forEntity('c-h', 'voucher', 'h-1'), isNotEmpty);
      expect(audit.forEntity('c-h', 'voucher', 'h-1'), isNotEmpty);
    });

    test('held moves to resumed/cancelled with lineage', () {
      for (final String target in <String>['resumed', 'cancelled']) {
        final String id = 'h-$target';
        expect(holdBill(id, 'c-h').isOk, isTrue);
        final int opsBefore = ops.forEntity('c-h', 'voucher', id).length;
        final Result<Voucher> r = moveBill(id, 'c-h', target, 'm-$target');
        expect(r.isOk, isTrue);
        expect((r as Ok<Voucher>).value.status, target);
        expect(
          ops.forEntity('c-h', 'voucher', id).length,
          opsBefore + 1,
        );
        expect(vouchers.heldBills(CompanyId('c-h')).where(
            (Voucher v) => v.id.value == id), isEmpty);
      }
    });

    test('posted is refused here; the voucher is left unchanged', () {
      // D1-D2: posting goes only through the voucher engine (validation,
      // period lock, stock effects and allocations in one transaction), so
      // the held-bill queue can never produce a posted voucher directly.
      // That engine path is proven by voucher_engine_test.dart
      // ('only draft/resumed post', held → resumed → post).
      expect(holdBill('h-p', 'c-h').isOk, isTrue);
      final int opsBefore = ops.forEntity('c-h', 'voucher', 'h-p').length;
      final Result<Voucher> r = moveBill('h-p', 'c-h', 'posted', 'm-posted');
      expect(r.isErr, isTrue);
      expect((r as Err<Voucher>).error.code, 'validation');
      expect(vouchers.get(CompanyId('c-h'), EntityId('h-p'))?.voucher.status,
          'held');
      expect(ops.forEntity('c-h', 'voucher', 'h-p').length, opsBefore);
      expect(
        vouchers.heldBills(CompanyId('c-h')).map((Voucher v) => v.no),
        contains('h-p'),
      );
    });

    test('terminal and non-held states reject further moves', () {
      expect(holdBill('h-t', 'c-h').isOk, isTrue);
      expect(moveBill('h-t', 'c-h', 'resumed', 'm1').isOk, isTrue);
      final Result<Voucher> again = moveBill('h-t', 'c-h', 'cancelled', 'm2');
      expect(again.isErr, isTrue);
      expect((again as Err<Voucher>).error.code, 'validation');
      // A draft voucher is not movable through the held-bill path either.
      final Result<Voucher> draft = vouchers.create(
        id: EntityId('d-1'),
        companyId: CompanyId('c-h'),
        type: 'sales-invoice',
        series: 'QB',
        no: 'd-1',
        date: NiavDate('2026-04-01'),
        deviceId: 'host-test',
        opId: 'op-d-1',
        eventId: 'ev-d-1',
        actor: 'tester',
      );
      expect(draft.isOk, isTrue);
      final Result<Voucher> bad = moveBill('d-1', 'c-h', 'posted', 'm3');
      expect(bad.isErr, isTrue);
      expect((bad as Err<Voucher>).error.code, 'validation');
    });

    test('unknown status, missing and foreign vouchers are rejected', () {
      expect(holdBill('h-u', 'c-h').isOk, isTrue);
      final Result<Voucher> unknown = moveBill('h-u', 'c-h', 'approved', 'm9');
      expect(unknown.isErr, isTrue);
      expect((unknown as Err<Voucher>).error.code, 'validation');
      final Result<Voucher> missing = moveBill('h-nope', 'c-h', 'posted', 'm8');
      expect(missing.isErr, isTrue);
      expect((missing as Err<Voucher>).error.code, 'validation');
      // Same voucher id is invisible from the other company.
      final Result<Voucher> foreign = moveBill('h-u', 'c-other', 'posted', 'm7');
      expect(foreign.isErr, isTrue);
      expect((foreign as Err<Voucher>).error.code, 'validation');
      // Queue itself stays company-scoped.
      expect(vouchers.heldBills(CompanyId('c-other')), isEmpty);
      expect(
        vouchers.heldBills(CompanyId('c-h')).map((Voucher v) => v.no),
        <String>['h-u'],
      );
    });
  });
}
