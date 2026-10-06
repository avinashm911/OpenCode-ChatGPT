// Business-cycle integration fixtures — database tests around business
// invariants (prompt 11). Real repositories + the single posting engine
// over disposable migrated databases: complete sales/purchase cycles with
// stock, cost, receivable/payable consequences; negative-stock fallback
// with later arrival and no restatement; purchase/sales returns; period
// lock → reject → authorised unlock (reason + audit) → post; posted
// immutability with compensating correction. Widget-free by design: these
// prove subsystem behavior, not pixels.
// Traceability: D-M4/D-M5; FR-M05-001/002/003/004; FR-M06-001/002;
// FR-M13-001; FR-M14-001; G0-SCH-001/002/003; DSS-C-001/003/004.

import 'package:flutter_test/flutter_test.dart';

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
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/period_lock.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/test_database.dart';
import '../helpers/seeded_post.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late PeriodLockRepository locks;
  late StockLevels stock;
  final CompanyId companyId = CompanyId('c-g');

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
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    locks = PeriodLockRepository(ctx, ops: ops, audit: audit);
    stock = StockLevels(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Cycle Co',
            deviceId: 'host-test',
            opId: 'op-cg',
            eventId: 'ev-cg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final String t in <String>[
      'Sales Invoice',
      'Purchase Invoice',
      'Sales Return / Credit Note with items',
      'Purchase Return / Debit Note with items',
      'Receipt',
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
    expect(
      parties
          .create(
            id: EntityId('p-g'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pg',
            eventId: 'ev-pg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-g'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ig',
            eventId: 'ev-ig',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-g'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gg',
            eventId: 'ev-gg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-g')]);
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

  void addStockLine(String vid, String lid, int qty,
      {int rate = 1000, int line = 1}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: line,
      itemId: EntityId('i-g'),
      godownId: EntityId('g-g'),
      partyId: EntityId('p-g'),
      qtyQ4: qty,
      ratePaise: rate,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> postStock(String id, StockPolicy policy,
      {List<AllocationSpec> allocs = const <AllocationSpec>[]}) {
    return engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: policy,
      allocations: allocs,
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
  }

  int stockQty() => stock
      .balances(companyId, itemId: EntityId('i-g'))
      .single
      .qtyQ4;

  Map<String, Object?> movement(String id) {
    return db
        .queryArgs(
          'SELECT qty_delta_q4, cost_paise, cost_source FROM stock_movement '
          'WHERE movement_id = ?',
          <Object?>[id],
        )
        .single;
  }

  group('sales cycle (purchase → sale → receipt)', () {
    test('stock, cost, receivable and settlement agree end to end', () {
      // Opening purchase: 10.0 @ ₹1000.
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000);
      expect(postStock('v-buy', StockPolicy.allow).isOk, isTrue);
      expect(stockQty(), 100000);
      expect(
          stock.layerValuePaise(
              companyId, EntityId('i-g'), EntityId('g-g')),
          10000);

      // Sale: 2.0 @ ₹1000 → WA cost 1000, movement average-sourced.
      createVoucher('v-sell', 'Sales Invoice');
      addStockLine('v-sell', 'v-sell-l1', 20000);
      final Result<PostingResult> sold =
          postStock('v-sell', StockPolicy.allow);
      expect(sold.isOk, isTrue);
      expect((sold as Ok<PostingResult>).value.warnings, isEmpty);
      final Map<String, Object?> m = movement('mv-v-sell-l1');
      expect(m['qty_delta_q4'], -20000);
      expect(m['cost_paise'], 1000);
      expect(m['cost_source'], 'average');
      expect(stockQty(), 80000);
      expect(
          stock.layerValuePaise(
              companyId, EntityId('i-g'), EntityId('g-g')),
          8000);
      // Receivable: invoice gross 2000, fully open.
      expect(voucherOpenBalance(db, companyId, EntityId('v-sell')), 2000);

      // Receipt settles it in full: settled, no advance left.
      createVoucher('v-pay', 'Receipt');
      final Result<VoucherLine> settle = vouchers.addLine(
        lineId: EntityId('v-pay-l1'),
        voucherId: EntityId('v-pay'),
        companyId: companyId,
        lineNo: 1,
        partyId: EntityId('p-g'),
        qtyQ4: 10000,
        ratePaise: 2000,
        deviceId: 'host-test',
        opId: 'op-v-pay-l1',
        eventId: 'ev-v-pay-l1',
        actor: 'tester',
      );
      expect(settle.isOk, isTrue);
      final Result<PostingResult> paid = postStock('v-pay', StockPolicy.allow,
          allocs: <AllocationSpec>[
            AllocationSpec(
              sourceLineId: EntityId('v-sell-l1'),
              settlementLineId: EntityId('v-pay-l1'),
              amountPaise: 2000,
            ),
          ]);
      expect(paid.isOk, isTrue);
      expect((paid as Ok<PostingResult>).value.unallocated, isEmpty);
      expect(voucherOpenBalance(db, companyId, EntityId('v-sell')), 0);
    });
  });

  group('purchase cycle (stock, payable, layers, last-known)', () {
    test('receipts layer stock at line cost and track payables', () {
      createVoucher('v-b1', 'Purchase Invoice');
      addStockLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1', StockPolicy.allow).isOk, isTrue);
      createVoucher('v-b2', 'Purchase Invoice');
      addStockLine('v-b2', 'v-b2-l1', 50000, rate: 1200);
      expect(postStock('v-b2', StockPolicy.allow).isOk, isTrue);

      expect(stockQty(), 150000);
      expect(
          stock.layerValuePaise(
              companyId, EntityId('i-g'), EntityId('g-g')),
          16000);
      // Each purchase is a payable: both fully open.
      expect(voucherOpenBalance(db, companyId, EntityId('v-b1')), 10000);
      expect(voucherOpenBalance(db, companyId, EntityId('v-b2')), 6000);
      // Last-known cost follows the latest receipt (1200).
      final List<Map<String, Object?>> known = db.queryArgs(
        'SELECT last_known_cost_paise AS c FROM item_cost_state '
        'WHERE item_id = ?',
        <Object?>['i-g'],
      );
      expect(known.single['c'], 1200);
    });
  });

  group('negative stock (fallback now, no restatement later)', () {
    test('empty-book sale warns, zeroes, then arrival covers cleanly', () {
      createVoucher('v-neg', 'Sales Invoice');
      addStockLine('v-neg', 'v-neg-l1', 20000);
      final Result<PostingResult> warned =
          postStock('v-neg', StockPolicy.warn);
      expect(warned.isOk, isTrue);
      expect(
          (warned as Ok<PostingResult>).value.warnings, hasLength(2));
      final Map<String, Object?> m = movement('mv-v-neg-l1');
      expect(m['cost_source'], 'zero');
      expect(m['cost_paise'], 0);
      expect(stockQty(), -20000);

      // Stock arrives: the prior issue keeps its zero cost (no rewriting).
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000, rate: 1000);
      expect(postStock('v-buy', StockPolicy.allow).isOk, isTrue);
      final Map<String, Object?> again = movement('mv-v-neg-l1');
      expect(again['cost_source'], 'zero');
      expect(again['cost_paise'], 0);
      expect(stockQty(), 80000);
    });
  });

  group('returns (reverse legs with method costing)', () {
    test('purchase return consumes; sales return layers', () {
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000, rate: 1000);
      expect(postStock('v-buy', StockPolicy.allow).isOk, isTrue);

      createVoucher('v-pr', 'Purchase Return / Debit Note with items');
      addStockLine('v-pr', 'v-pr-l1', 30000);
      expect(postStock('v-pr', StockPolicy.allow).isOk, isTrue);
      final Map<String, Object?> out = movement('mv-v-pr-l1');
      expect(out['qty_delta_q4'], -30000);
      expect(out['cost_source'], 'average');
      expect(stockQty(), 70000);

      createVoucher('v-sr', 'Sales Return / Credit Note with items');
      addStockLine('v-sr', 'v-sr-l1', 20000, rate: 1100);
      expect(postStock('v-sr', StockPolicy.allow).isOk, isTrue);
      final Map<String, Object?> back = movement('mv-v-sr-l1');
      expect(back['qty_delta_q4'], 20000);
      expect(back['cost_source'], 'layer');
      expect(stockQty(), 90000);
      // Book: 7000 remaining + 2200 returned = 9200.
      expect(
          stock.layerValuePaise(
              companyId, EntityId('i-g'), EntityId('g-g')),
          9200);
    });
  });

  group('period lock (lock → reject → unlock → post)', () {
    test('authorised unlock with reason and audit reopens posting', () {
      final Result<PeriodLock> locked = locks.create(
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
      );
      expect(locked.isOk, isTrue);
      expect(
          (locked as Ok<PeriodLock>).value.isActive, isTrue);

      createVoucher('v-sale', 'Sales Invoice');
      addStockLine('v-sale', 'v-sale-l1', 10000);
      final Result<PostingResult> refused =
          postStock('v-sale', StockPolicy.allow);
      expect(refused.isErr, isTrue);
      expect((refused as Err<PostingResult>).error.message,
          contains('locked period'));
      expect(vouchers.get(companyId, EntityId('v-sale'))?.voucher.status,
          'draft');

      // Reasonless unlock refused; reasoned unlock audited.
      final Result<PeriodLock> noReason = locks.unlock(
        id: EntityId('lock-1'),
        companyId: companyId,
        reason: '  ',
        deviceId: 'host-test',
        opId: 'op-un-1',
        eventId: 'ev-un-1',
        actor: 'tester',
      );
      expect(noReason.isErr, isTrue);
      final Result<PeriodLock> opened = locks.unlock(
        id: EntityId('lock-1'),
        companyId: companyId,
        reason: 'year-end close posted early',
        deviceId: 'host-test',
        opId: 'op-un-2',
        eventId: 'ev-un-2',
        actor: 'owner',
      );
      expect(opened.isOk, isTrue);
      expect((opened as Ok<PeriodLock>).value.isActive, isFalse);
      final List<AuditEvent> trail =
          audit.forEntity('c-g', 'period_lock', 'lock-1');
      expect(
          trail.any((AuditEvent e) =>
              (e.newData ?? '').contains('year-end close posted early')),
          isTrue);
      final Result<PeriodLock> twice = locks.unlock(
        id: EntityId('lock-1'),
        companyId: companyId,
        reason: 'again',
        deviceId: 'host-test',
        opId: 'op-un-3',
        eventId: 'ev-un-3',
        actor: 'owner',
      );
      expect(twice.isErr, isTrue);

      // Posting works again after the unlock.
      expect(postStock('v-sale', StockPolicy.allow).isOk, isTrue);
      expect(vouchers.get(companyId, EntityId('v-sale'))?.voucher.status,
          'posted');
    });
  });

  group('immutability and correction', () {
    test('posted rows never rewrite; correction compensates', () {
      createVoucher('v-inv', 'Sales Invoice');
      addStockLine('v-inv', 'v-inv-l1', 50000);
      expect(postStock('v-inv', StockPolicy.allow).isOk, isTrue);
      final VoucherWithLines? before =
          vouchers.get(companyId, EntityId('v-inv'));
      expect(before?.voucher.status, 'posted');

      // Re-post refused; reasonless cancel refused.
      final Result<PostedTotals> repost = engine.postDraft(
        id: EntityId('v-inv'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-repost',
        eventId: 'ev-repost',
        actor: 'tester',
      );
      expect(repost.isErr, isTrue);
      final Result<Voucher> noReason = engine.cancelPosted(
        id: EntityId('v-inv'),
        companyId: companyId,
        reason: '  ',
        deviceId: 'host-test',
        opId: 'op-can-0',
        eventId: 'ev-can-0',
        actor: 'tester',
      );
      expect(noReason.isErr, isTrue);

      // Reasoned cancel: status moves, rows and totals identical.
      final Result<Voucher> cancelled = engine.cancelPosted(
        id: EntityId('v-inv'),
        companyId: companyId,
        reason: 'wrong rate entered',
        deviceId: 'host-test',
        opId: 'op-can-1',
        eventId: 'ev-can-1',
        actor: 'tester',
      );
      expect(cancelled.isOk, isTrue);
      final VoucherWithLines? after =
          vouchers.get(companyId, EntityId('v-inv'));
      expect(after?.voucher.status, 'cancelled');
      // Original rows are untouched (first by line order); the cancel appends
      // compensating ledger arms (D3-A6), so the voucher carries more lines.
      expect(after?.lines.first.amountPaise,
          before?.lines.first.amountPaise);
      expect(
          after?.lines
              .where((VoucherLine l) => l.drCr != null)
              .map((VoucherLine l) => l.drCr),
          containsAll(<String>['Dr', 'Cr']));
      final List<AuditEvent> trail =
          audit.forEntity('c-g', 'voucher', 'v-inv');
      expect(
          trail.any((AuditEvent e) =>
              (e.newData ?? '').contains('wrong rate entered')),
          isTrue);

      // Cancelled vouchers never post again; double cancel refused.
      final Result<PostedTotals> afterCancel = engine.postDraft(
        id: EntityId('v-inv'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-repost-2',
        eventId: 'ev-repost-2',
        actor: 'tester',
      );
      expect(afterCancel.isErr, isTrue);
      final Result<Voucher> again = engine.cancelPosted(
        id: EntityId('v-inv'),
        companyId: companyId,
        reason: 'again',
        deviceId: 'host-test',
        opId: 'op-can-2',
        eventId: 'ev-can-2',
        actor: 'tester',
      );
      expect(again.isErr, isTrue);
    });
  });
}
