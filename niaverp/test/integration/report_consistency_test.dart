// Report-consistency fixtures — every report as a projection of the same
// posted transactions (prompt 12). One posted business story (purchase +
// sale + receipt + balanced journal over two ledgers and two groups), then
// every M13/M14/M15 report read back and cross-checked: stock valuation,
// outstanding, day book, sales register, ledger balances, trial balance
// (sums to zero), group summary and settlement history. No report carries
// its own arithmetic — each number traces to posted rows.
// Traceability: M13/M14.1/14.2/14.6/14.13/M15; D-M4/D-M5; FR-M05-001/002;
// FR-M06-001/002/004; FR-M14-001; G0-SCH-001/003; DSS-C-001.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/test_database.dart';
import '../helpers/seeded_post.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late StockLevels stock;
  late OutstandingReport outstanding;
  late LedgerBooks books;
  final CompanyId companyId = CompanyId('c-x');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    stock = StockLevels(db);
    outstanding = OutstandingReport(db);
    books = LedgerBooks(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'X Co',
            deviceId: 'host-test',
            opId: 'op-cx',
            eventId: 'ev-cx',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final String t in <String>[
      'Sales Invoice',
      'Purchase Invoice',
      'Receipt',
      'Journal',
    ]) {
      expect(
        types
            .create(
              id: EntityId('t-$t'),
              companyId: companyId,
              baseType: t,
              name: t,
              deviceId: 'host-test',
              opId: 'op-t-$t',
              eventId: 'ev-t-$t',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    for (final Map<String, String> e in <Map<String, String>>[
      {'id': 'p-x', 'role': 'customer', 'name': 'Buyer'},
    ]) {
      expect(
        parties
            .create(
              id: EntityId(e['id']!),
              companyId: companyId,
              name: e['name']!,
              role: e['role']!,
              deviceId: 'host-test',
              opId: 'op-${e['id']}',
              eventId: 'ev-${e['id']}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      items
          .create(
            id: EntityId('i-x'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ix',
            eventId: 'ev-ix',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-x'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gx',
            eventId: 'ev-gx',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> g in <Map<String, String>>[
      {'id': 'g-cash', 'name': 'Cash'},
      {'id': 'g-cap', 'name': 'Capital'},
    ]) {
      expect(
        groups
            .create(
              id: EntityId(g['id']!),
              companyId: companyId,
              name: g['name']!,
              deviceId: 'host-test',
              opId: 'op-${g['id']}',
              eventId: 'ev-${g['id']}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    for (final Map<String, Object> l in <Map<String, Object>>[
      {
        'id': 'l-cash',
        'group': 'g-cash',
        'name': 'Cash',
        'side': 'Dr',
        'opening': 10000
      },
      {
        'id': 'l-cap',
        'group': 'g-cap',
        'name': 'Capital',
        'side': 'Cr',
        'opening': 10000
      },
    ]) {
      expect(
        ledgers
            .create(
              id: EntityId(l['id'] as String),
              companyId: companyId,
              groupId: EntityId(l['group'] as String),
              name: l['name'] as String,
              openingSide: l['side'] as String,
              openingPaise: l['opening'] as int,
              deviceId: 'host-test',
              opId: "op-${l['id']}",
              eventId: "ev-${l['id']}",
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-x')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createVoucher(String id, String type) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: type,
      series: 'S',
      no: id,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void addItemLine(String vid, String lid, int qty, {int rate = 1000}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: 1,
      itemId: EntityId('i-x'),
      godownId: EntityId('g-x'),
      partyId: EntityId('p-x'),
      qtyQ4: qty,
      ratePaise: rate,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> postStock(String id,
      {List<AllocationSpec> allocs = const <AllocationSpec>[]}) {
    return engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: StockPolicy.allow,
      allocations: allocs,
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
  }

  group('one story, every report', () {
    test('stock, outstanding, books and history agree', () {
      // Purchase 10.0 @ ₹1000.
      createVoucher('v-buy', 'Purchase Invoice');
      addItemLine('v-buy', 'v-buy-l1', 100000);
      expect(postStock('v-buy').isOk, isTrue);
      // Sale 2.0 @ ₹1000, fully receipted.
      createVoucher('v-sell', 'Sales Invoice');
      addItemLine('v-sell', 'v-sell-l1', 20000);
      expect(postStock('v-sell').isOk, isTrue);
      createVoucher('v-pay', 'Receipt');
      final Result<VoucherLine> settle = vouchers.addLine(
        lineId: EntityId('v-pay-l1'),
        voucherId: EntityId('v-pay'),
        companyId: companyId,
        lineNo: 1,
        partyId: EntityId('p-x'),
        qtyQ4: 10000,
        ratePaise: 2000,
        deviceId: 'host-test',
        opId: 'op-v-pay-l1',
        eventId: 'ev-v-pay-l1',
        actor: 'tester',
      );
      expect(settle.isOk, isTrue);
      expect(
          postStock('v-pay', allocs: <AllocationSpec>[
            AllocationSpec(
              sourceLineId: EntityId('v-sell-l1'),
              settlementLineId: EntityId('v-pay-l1'),
              amountPaise: 2000,
            ),
          ]).isOk,
          isTrue);
      // Balanced journal: Dr Cash 3000 / Cr Capital 3000.
      createVoucher('v-j', 'Journal');
      int lineNo = 0;
      for (final Map<String, Object> arm in <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 3000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 3000},
      ]) {
        lineNo += 1;
        final Result<VoucherLine> l = vouchers.addLine(
          lineId: EntityId('v-j-l$lineNo'),
          voucherId: EntityId('v-j'),
          companyId: companyId,
          lineNo: lineNo,
          ledgerId: EntityId(arm['ledger'] as String),
          drCr: arm['side'] as String,
          qtyQ4: 10000,
          ratePaise: arm['amount'] as int,
          deviceId: 'host-test',
          opId: 'op-v-j-l$lineNo',
          eventId: 'ev-v-j-l$lineNo',
          actor: 'tester',
        );
        expect(l.isOk, isTrue);
      }
      final Result<PostedTotals> journal = engine.postDraft(
        id: EntityId('v-j'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-post-v-j',
        eventId: 'ev-post-v-j',
        actor: 'tester',
      );
      expect(journal.isOk, isTrue);

      // Stock valuation: 8.0 on hand valued at the remaining 8000.
      final List<StockValuation> held = stock.valuation(companyId);
      expect(held, hasLength(1));
      expect(held.single.qtyQ4, 80000);
      expect(held.single.valuePaise, 8000);

      // Outstanding: only the purchase payable stays open.
      final List<OutstandingBill> bills =
          outstanding.bills(companyId, asOf: NiavDate('2026-04-01'));
      expect(
        bills.map((OutstandingBill b) => b.voucherNo),
        <String>['v-buy'],
      );
      expect(bills.single.openPaise, 10000);
      expect(outstanding.advances(companyId), isEmpty);

      // Day book: four posted vouchers, gross sums agree. Posted invoice
      // lines include the D3-A1 ledger arms (journal-consistent SUM over all
      // stored lines): v-buy 10000 + 20000 arms, v-j 6000, v-pay 2000,
      // v-sell 2000 + 4000 arms.
      final List<DayBookEntry> day = books.dayBook(companyId);
      expect(
        day.map((DayBookEntry e) => e.voucherNo),
        <String>['v-buy', 'v-j', 'v-pay', 'v-sell'],
      );
      expect(
        day.fold(0, (int s, DayBookEntry e) => s + e.totalPaise),
        10000 + 6000 + 2000 + 2000 + 20000 + 4000,
      );

      // Sales register: the sale alone, content plus its posting arms.
      final List<DayBookEntry> sales = books.dayBook(companyId,
          types: <String>['Sales Invoice']);
      expect(sales.single.totalPaise, 2000 + 4000);

      // Ledgers: cash 10000 + 3000, capital −10000 − 3000.
      expect(books.ledgerBalance(companyId, EntityId('l-cash')), 13000);
      expect(books.ledgerBalance(companyId, EntityId('l-cap')), -13000);
      final LedgerAccount? cash =
          books.ledgerAccount(companyId, EntityId('l-cash'));
      expect(cash!.entries.single.balanceAfterPaise, 13000);
      expect(cash.closingPaise, 13000);

      // Trial balances to zero; groups each carry their side.
      final List<LedgerBalance> trial = books.trialBalance(companyId);
      expect(
        trial.fold(0, (int s, LedgerBalance b) => s + b.balancePaise),
        0,
      );
      final List<GroupBalance> groups = books.groupTrialBalance(companyId);
      expect(
        groups
            .firstWhere((GroupBalance g) => g.name == 'Cash')
            .balancePaise,
        13000,
      );
      expect(
        groups
            .firstWhere((GroupBalance g) => g.name == 'Capital')
            .balancePaise,
        -13000,
      );

      // Settlement history: the single receipt allocation.
      final List<SettlementEntry> history =
          outstanding.settlementHistory(companyId);
      expect(history, hasLength(1));
      expect(history.single.amountPaise, 2000);
      expect(history.single.status, 'active');
    });
  });
}
