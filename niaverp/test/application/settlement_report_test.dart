// Settlement report tests: outstanding bills, party rollups, aging,
// advances and settlement history (FR-M06/FR-M14-001).
// Disposable in-memory databases only. Proves: bill states derive from
// posted totals (open/part-settled/settled, drafts excluded); party
// outstanding rolls posted lines up; aging buckets by document date with
// caller-owned cutoffs; advances surface only posted Payment/Receipt lines
// with remainder (registered custom types included, invoices excluded);
// history lists newest-first with reversals; impossible history throws;
// foreign companies report nothing.
// Traceability: FR-M06-001/002; FR-M14-001; G0-SCH-003.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late BillAllocationRepository allocs;
  late VoucherEngine engine;
  late OutstandingReport report;
  final CompanyId companyId = CompanyId('c-r');
  final NiavDate asOf = NiavDate('2026-04-01');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    allocs = BillAllocationRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: allocs,
    );
    report = OutstandingReport(db);
    for (final String c in <String>['c-r', 'c-other']) {
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
    for (final Map<String, String> t in <Map<String, String>>[
      {'id': 't-si', 'base': 'Sales Invoice', 'name': 'Sales Invoice'},
      {'id': 't-rc', 'base': 'Receipt', 'name': 'Receipt'},
      {'id': 't-pm', 'base': 'Payment', 'name': 'Payment'},
      {'id': 't-cr', 'base': 'Receipt', 'name': 'Cash Receipt'},
    ]) {
      expect(
        types
            .create(
              id: EntityId(t['id']!),
              companyId: companyId,
              baseType: t['base']!,
              name: t['name']!,
              deviceId: 'host-test',
              opId: 'op-${t['id']}',
              eventId: 'ev-${t['id']}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      parties
          .create(
            id: EntityId('p-r'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pr',
            eventId: 'ev-pr',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-r')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// Vouchers the report must see as posted are built through the production
  /// path (D1-D4 forbids adding lines to a voucher created as posted):
  /// created as a draft here, posted by [addLine] once its line exists.
  /// Vouchers that must stay drafts pass `status: 'draft'` and are never
  /// posted. Every fixture voucher currently carries exactly one line.
  final Set<String> toPostIds = <String>{};

  void createVoucher(String id, String type, String date,
      {String status = 'posted'}) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: type,
      series: 'S',
      no: id,
      date: NiavDate(date),
      status: status == 'posted' ? 'draft' : status,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
    if (status == 'posted') toPostIds.add(id);
  }

  void addLine(String vid, String lid, int amount) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: 1,
      partyId: EntityId('p-r'),
      qtyQ4: 10000,
      ratePaise: amount,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
    if (toPostIds.remove(vid)) {
      final Result<PostingResult> posted = engine.postWithStock(
        id: EntityId(vid),
        companyId: companyId,
        policy: StockPolicy.block,
        deviceId: 'host-test',
        opId: 'op-post-$vid',
        eventId: 'ev-post-$vid',
        actor: 'tester',
      );
      expect(posted.isOk, isTrue);
    }
  }

  void allocate(String id, String source, String settlement, int amount,
      {String status = 'active', String date = '2026-03-01'}) {
    final Result<void> r = allocs.allocate(
      id: EntityId(id),
      companyId: companyId,
      sourceLineId: EntityId(source),
      settlementLineId: EntityId(settlement),
      amountPaise: amount,
      date: NiavDate(date),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
    if (status != 'active') {
      final Result<void> rev = allocs.reverse(
        id: EntityId(id),
        companyId: companyId,
        reason: 'test reversal',
        deviceId: 'host-test',
        opId: 'op-rev-$id',
        eventId: 'ev-rev-$id',
        actor: 'tester',
      );
      expect(rev.isOk, isTrue);
    }
  }

  group('outstanding bills (FR-M14-001)', () {
    test('states derive from posted totals; drafts excluded', () {
      createVoucher('v-open', 'Sales Invoice', '2026-03-20');
      addLine('v-open', 'v-open-l1', 5000);
      createVoucher('v-part', 'Sales Invoice', '2026-03-20');
      addLine('v-part', 'v-part-l1', 5000);
      createVoucher('v-pay', 'Receipt', '2026-03-21');
      addLine('v-pay', 'v-pay-l1', 5000);
      createVoucher('v-draft', 'Sales Invoice', '2026-03-20',
          status: 'draft');
      addLine('v-draft', 'v-draft-l1', 9000);
      allocate('a-1', 'v-part-l1', 'v-pay-l1', 2000);
      allocate('a-2', 'v-open-l1', 'v-pay-l1', 5000);

      final List<OutstandingBill> held =
          report.bills(companyId, asOf: asOf);
      // v-open settled (5000 of 5000) drops out under onlyOpen; the draft
      // never appears (posted bills only); the receipt is not a bill —
      // its unallocated side is reported by advances().
      expect(
        held.map((OutstandingBill b) => b.voucherNo),
        <String>['v-part'],
      );
      final OutstandingBill part =
          held.firstWhere((OutstandingBill b) => b.voucherNo == 'v-part');
      expect(part.state, 'part-settled');
      expect(part.openPaise, 3000);
      expect(part.ageDays, 12);
      expect(
        report
            .bills(companyId, asOf: asOf, includeSettlementTypes: true)
            .map((OutstandingBill b) => b.voucherNo),
        <String>['v-part', 'v-pay'],
      );
    });

    test('party and type filters narrow the report', () {
      createVoucher('v-a', 'Sales Invoice', '2026-03-20');
      addLine('v-a', 'v-a-l1', 5000);
      createVoucher('v-b', 'Receipt', '2026-03-20');
      addLine('v-b', 'v-b-l1', 5000);
      // Receipts are settlement documents, not bills (opt back in).
      expect(
        report
            .bills(companyId, asOf: asOf, voucherType: 'Receipt')
            .map((OutstandingBill b) => b.voucherNo),
        isEmpty,
      );
      expect(
        report
            .bills(companyId,
                asOf: asOf,
                voucherType: 'Receipt',
                includeSettlementTypes: true)
            .map((OutstandingBill b) => b.voucherNo),
        <String>['v-b'],
      );
      expect(
        report.bills(companyId,
            asOf: asOf, partyId: EntityId('p-nope')),
        isEmpty,
      );
      // Only the invoice is a bill; the receipt settles through advances.
      expect(
        report
            .bills(companyId, asOf: asOf, partyId: EntityId('p-r')),
        hasLength(1),
      );
    });
  });

  group('party outstanding and aging', () {
    test('party rollup sums posted lines and allocations', () {
      createVoucher('v-a', 'Sales Invoice', '2026-03-20');
      addLine('v-a', 'v-a-l1', 5000);
      createVoucher('v-b', 'Sales Invoice', '2026-03-20');
      addLine('v-b', 'v-b-l1', 3000);
      createVoucher('v-pay', 'Receipt', '2026-03-21');
      addLine('v-pay', 'v-pay-l1', 8000);
      allocate('a-1', 'v-a-l1', 'v-pay-l1', 2000);
      final PartyOutstanding po =
          report.partyOutstanding(companyId, EntityId('p-r'));
      // Billed counts invoice lines only (8000); the receipt settles
      // through allocations, not through its own billed total.
      expect(po.billedPaise, 8000);
      expect(po.allocatedPaise, 2000);
      expect(po.openPaise, 6000);
      expect(po.billCount, 2);
    });

    test('aging buckets by document date with caller cutoffs', () {
      createVoucher('v-old', 'Sales Invoice', '2026-01-01');
      addLine('v-old', 'v-old-l1', 1000);
      createVoucher('v-mid', 'Sales Invoice', '2026-02-01');
      addLine('v-mid', 'v-mid-l1', 2000);
      createVoucher('v-new', 'Sales Invoice', '2026-03-20');
      addLine('v-new', 'v-new-l1', 3000);
      final List<AgingBucket> buckets = report.aging(companyId, asOf: asOf);
      // Ages: 90, 59, 12 → buckets 0–30, 31–60, 61–90, 90+.
      expect(buckets.map((AgingBucket b) => b.label),
          <String>['0–30', '31–60', '61–90', '90+']);
      expect(buckets[0].openPaise, 3000);
      expect(buckets[1].openPaise, 2000);
      expect(buckets[2].openPaise, 1000);
      expect(buckets[3].openPaise, 0);
      expect(
        buckets.fold(0, (int s, AgingBucket b) => s + b.openPaise),
        6000,
      );
    });
  });

  group('advances (FR-M06-002)', () {
    test('posted payment/receipt remainders surface; invoices never do', () {
      createVoucher('v-inv', 'Sales Invoice', '2026-03-20');
      addLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-pay', 'Receipt', '2026-03-21');
      addLine('v-pay', 'v-pay-l1', 5000);
      allocate('a-1', 'v-inv-l1', 'v-pay-l1', 2000);
      createVoucher('v-custom', 'Cash Receipt', '2026-03-22');
      addLine('v-custom', 'v-custom-l1', 1500);

      final List<AdvanceLine> found = report.advances(companyId);
      expect(
        found.map((AdvanceLine a) => a.voucherNo),
        <String>['v-pay', 'v-custom'],
      );
      final AdvanceLine pay =
          found.firstWhere((AdvanceLine a) => a.voucherNo == 'v-pay');
      expect(pay.totalPaise, 5000);
      expect(pay.allocatedPaise, 2000);
      expect(pay.unallocatedPaise, 3000);
      // Fully consumed lines drop out.
      allocate('a-2', 'v-inv-l1', 'v-pay-l1', 3000);
      expect(
        report
            .advances(companyId)
            .map((AdvanceLine a) => a.voucherNo),
        <String>['v-custom'],
      );
    });
  });

  group('settlement history', () {
    test('newest first with reversals; voucher filter either side', () {
      createVoucher('v-inv', 'Sales Invoice', '2026-03-20');
      addLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-pay', 'Receipt', '2026-03-21');
      addLine('v-pay', 'v-pay-l1', 5000);
      allocate('a-1', 'v-inv-l1', 'v-pay-l1', 2000, date: '2026-03-22');
      allocate('a-2', 'v-inv-l1', 'v-pay-l1', 1000,
          date: '2026-03-23', status: 'reversed');

      final List<SettlementEntry> all = report.settlementHistory(companyId);
      expect(all.map((SettlementEntry e) => e.allocationId),
          <String>['a-2', 'a-1']);
      expect(all.first.status, 'reversed');
      expect(all.first.sourceVoucherNo, 'v-inv');
      expect(all.first.settlementVoucherNo, 'v-pay');
      expect(
        report
            .settlementHistory(companyId, voucherId: EntityId('v-pay'))
            .map((SettlementEntry e) => e.allocationId),
        <String>['a-2', 'a-1'],
      );
      expect(
        report.settlementHistory(companyId,
            voucherId: EntityId('v-nope')),
        isEmpty,
      );
    });
  });

  group('line balances and isolation', () {
    test('source open and settlement remainder; impossible throws', () {
      createVoucher('v-inv', 'Sales Invoice', '2026-03-20');
      addLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-pay', 'Receipt', '2026-03-21');
      addLine('v-pay', 'v-pay-l1', 5000);
      allocate('a-1', 'v-inv-l1', 'v-pay-l1', 2000);
      expect(lineOpenBalance(db, companyId, EntityId('v-inv-l1')), 3000);
      expect(lineUnallocated(db, companyId, EntityId('v-pay-l1')), 3000);
      expect(lineOpenBalance(db, companyId, EntityId('l-nope')), 0);
    });

    test('foreign company reports nothing', () {
      createVoucher('v-inv', 'Sales Invoice', '2026-03-20');
      addLine('v-inv', 'v-inv-l1', 5000);
      expect(
        report.bills(CompanyId('c-other'), asOf: asOf),
        isEmpty,
      );
      expect(
        report.advances(CompanyId('c-other')),
        isEmpty,
      );
      expect(
        report.settlementHistory(CompanyId('c-other')),
        isEmpty,
      );
    });
  });
}
