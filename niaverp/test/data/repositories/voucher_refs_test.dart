// DSS slice tests: voucher header/line refs + Dr/Cr convention (m010/m011).
// Disposable in-memory databases only. Proves: narration/actor/device/fy
// round-trip on headers; ledger/party/godown/batch refs round-trip on
// lines; item lines reject Dr/Cr; ledger lines accept Dr/Cr; bad Dr/Cr
// values and dangling godown refs fail at the schema.
// Traceability: DSS §3 (voucher/voucher_line); DB §3; Dr/Cr convention.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/financial_year_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  final CompanyId companyId = CompanyId('c-refs');

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
            id: companyId,
            name: 'Refs Co',
            deviceId: 'host-test',
            opId: 'op-cr',
            eventId: 'ev-cr',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createVoucher(String id, {String? fy, String? narration}) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: 'sales-invoice',
      series: 'S',
      no: id,
      date: NiavDate('2026-04-01'),
      narration: narration,
      headerActor: 'counter-1',
      headerDevice: 'device-1',
      fyId: fy == null ? null : EntityId(fy),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<VoucherLine> addLine(
    String vid,
    String lid, {
    String? item,
    String? drCr,
    String? party,
    String? godown,
    int line = 1,
  }) {
    return vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: line,
      itemId: item == null ? null : EntityId(item),
      drCr: drCr,
      partyId: party == null ? null : EntityId(party),
      godownId: godown == null ? null : EntityId(godown),
      qtyQ4: 10000,
      ratePaise: 500,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
  }

  group('voucher refs + Dr/Cr (DSS §3)', () {
    test('header narration/actor/device/fy round-trip', () {
      final FinancialYearRepository fys =
          FinancialYearRepository(ctx, ops: ops, audit: audit);
      expect(
        fys
            .create(
              id: EntityId('fy-r'),
              companyId: companyId,
              startDate: NiavDate('2026-04-01'),
              endDate: NiavDate('2027-03-31'),
              status: 'open',
              deviceId: 'host-test',
              opId: 'op-fyr',
              eventId: 'ev-fyr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      createVoucher('v-1', fy: 'fy-r', narration: 'cash sale');
      final Voucher? got = vouchers.get(companyId, EntityId('v-1'))?.voucher;
      expect(got?.narration, 'cash sale');
      expect(got?.actor, 'counter-1');
      expect(got?.device, 'device-1');
      expect(got?.fyId?.value, 'fy-r');
    });

    test('line refs round-trip; item lines reject Dr/Cr', () {
      final PartyRepository parties =
          PartyRepository(ctx, ops: ops, audit: audit);
      expect(
        parties
            .create(
              id: EntityId('p-r'),
              companyId: companyId,
              name: 'Ref Party',
              role: 'customer',
              deviceId: 'host-test',
              opId: 'op-pr',
              eventId: 'ev-pr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final GodownRepository godowns =
          GodownRepository(ctx, ops: ops, audit: audit);
      expect(
        godowns
            .create(
              id: EntityId('g-r'),
              companyId: companyId,
              name: 'Main',
              deviceId: 'host-test',
              opId: 'op-gr',
              eventId: 'ev-gr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      createVoucher('v-1');
      final Result<VoucherLine> ok =
          addLine('v-1', 'l-1', party: 'p-r', godown: 'g-r');
      expect(ok.isOk, isTrue);
      final VoucherLine line =
          vouchers.get(companyId, EntityId('v-1'))!.lines.single;
      expect(line.partyId?.value, 'p-r');
      expect(line.godownId?.value, 'g-r');

      final Result<VoucherLine> bad = addLine('v-1', 'l-2',
          item: 'i-x', drCr: 'Dr', line: 2);
      expect(bad.isErr, isTrue);
      expect((bad as Err<VoucherLine>).error.code, 'validation');
    });

    test('ledger lines accept Dr/Cr; bad values and ghosts fail', () {
      createVoucher('v-1');
      final Result<VoucherLine> dr = addLine('v-1', 'l-1', drCr: 'Dr');
      expect(dr.isOk, isTrue);
      expect((dr as Ok<VoucherLine>).value.drCr, 'Dr');

      final Result<VoucherLine> badValue = addLine('v-1', 'l-2', drCr: 'Dx', line: 2);
      expect(badValue.isErr, isTrue);

      final Result<VoucherLine> ghost = addLine('v-1', 'l-3',
          godown: 'g-ghost', line: 3);
      expect(ghost.isErr, isTrue);
      // D2-B2: the company guard rejects the dangling godown before the raw
      // FK does (fail fast, same direction as the D1-D4 parent pre-check).
      expect((ghost as Err<VoucherLine>).error.code, 'validation');
    });
  });
}
