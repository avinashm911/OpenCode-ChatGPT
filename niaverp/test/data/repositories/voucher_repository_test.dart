// Phase 01 tests: voucher repository over real SQLite.
// Disposable in-memory databases only. Proves: header + line round-trip with
// D-M4-derived amounts, discount validation, atomicity (bad line rolls the
// whole write back), company isolation, lineage, and no-secret failures.
// Traceability: D-M4; DSS-C-001/004; OD-DB-004; G0-SCH-007.

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
  late VoucherRepository vouchers;
  late OperationLog ops;
  late AuditLog audit;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-v'),
            name: 'Vouchers Co',
            deviceId: 'host-test',
            opId: 'op-cv',
            eventId: 'ev-cv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<Voucher> createVoucher(String id, {String no = '1'}) {
    return vouchers.create(
      id: EntityId(id),
      companyId: CompanyId('c-v'),
      type: 'sales-invoice',
      series: 'A',
      no: no,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('voucher header', () {
    test('create then get round-trips with empty lines', () {
      expect(createVoucher('v-1').isOk, isTrue);
      final VoucherWithLines? got =
          vouchers.get(CompanyId('c-v'), EntityId('v-1'));
      expect(got, isNotNull);
      expect(got!.voucher.no, '1');
      expect(got.voucher.status, 'draft');
      expect(got.lines, isEmpty);
    });

    test('duplicate series+number is refused as conflict', () {
      expect(createVoucher('v-a', no: '7').isOk, isTrue);
      final Result<Voucher> again = createVoucher('v-b', no: '7');
      expect(again.isErr, isTrue);
      expect((again as Err<Voucher>).error.code, 'conflict');
    });
  });

  group('voucher lines', () {
    test('line amount derives from D-M4 arithmetic (qty × rate / 10⁴)', () {
      expect(createVoucher('v-l').isOk, isTrue);
      final Result<VoucherLine> r = vouchers.addLine(
        lineId: EntityId('l-1'),
        voucherId: EntityId('v-l'),
        companyId: CompanyId('c-v'),
        lineNo: 1,
        qtyQ4: 25000, // 2.5 units
        ratePaise: 999, // Rs 9.99
        deviceId: 'host-test',
        opId: 'op-l-1',
        eventId: 'ev-l-1',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      // 2.5 × 999 = 2497.5 → half-up 2498.
      expect((r as Ok<VoucherLine>).value.amountPaise, 2498);
      expect(
        vouchers.get(CompanyId('c-v'), EntityId('v-l'))!.lines,
        hasLength(1),
      );
    });

    test('invalid discount inputs are rejected before touching the db', () {
      expect(createVoucher('v-d').isOk, isTrue);
      final Result<VoucherLine> r = vouchers.addLine(
        lineId: EntityId('l-d'),
        voucherId: EntityId('v-d'),
        companyId: CompanyId('c-v'),
        lineNo: 1,
        qtyQ4: 10000,
        ratePaise: 100,
        discountRateBps: 10001,
        deviceId: 'host-test',
        opId: 'op-ld',
        eventId: 'ev-ld',
        actor: 'tester',
      );
      expect(r.isErr, isTrue);
      expect((r as Err<VoucherLine>).error.code, 'validation');
      expect(
        vouchers.get(CompanyId('c-v'), EntityId('v-d'))!.lines,
        isEmpty,
      );
    });

    test('line on a missing voucher fails atomically (no lineage left)', () {
      final Result<VoucherLine> r = vouchers.addLine(
        lineId: EntityId('l-ghost'),
        voucherId: EntityId('v-ghost'),
        companyId: CompanyId('c-v'),
        lineNo: 1,
        qtyQ4: 10000,
        ratePaise: 100,
        deviceId: 'host-test',
        opId: 'op-lg',
        eventId: 'ev-lg',
        actor: 'tester',
      );
      expect(r.isErr, isTrue);
      expect((r as Err<VoucherLine>).error.code, 'foreign-key');
      expect(ops.forEntity('c-v', 'voucher_line', 'l-ghost'), isEmpty);
      expect(audit.forEntity('c-v', 'voucher_line', 'l-ghost'), isEmpty);
    });

    test('failures carry codes, never raw values', () {
      final Result<VoucherLine> r = vouchers.addLine(
        lineId: EntityId('l-s'),
        voucherId: EntityId('v-absent'),
        companyId: CompanyId('c-v'),
        lineNo: 1,
        qtyQ4: 10000,
        ratePaise: 100,
        deviceId: 'host-test',
        opId: 'op-ls',
        eventId: 'ev-ls',
        actor: 'tester',
      );
      final AppError e = (r as Err<VoucherLine>).error;
      expect(e.code, 'foreign-key');
      expect(e.message.contains('v-absent'), isFalse);
    });
  });

  group('isolation', () {
    test('vouchers of another company are invisible', () {
      expect(createVoucher('v-iso').isOk, isTrue);
      expect(
        vouchers.get(CompanyId('c-other'), EntityId('v-iso')),
        isNull,
      );
      expect(vouchers.listByCompany(CompanyId('c-other')), isEmpty);
      expect(vouchers.listByCompany(CompanyId('c-v')), hasLength(1));
    });
  });
}
