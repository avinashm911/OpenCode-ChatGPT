// Posting-pipeline tests: one transaction, no partial states (M05–M07).
// Disposable in-memory databases only. Proves: purchase creates layers and
// sets last-known cost; sales consume at weighted average with movements;
// blocked policy aborts the whole post (status stays draft, no rows);
// warn approves with a recorded warning; transfers post documents with an
// explicit pending leg; unbalanced journals are rejected; allocations ride
// the same transaction (a failing allocation aborts everything); orders
// never post.
// Traceability: FR-M05–M07 posting; D-M5 (WA default, policy); FR-M06-004
// (Dr = Cr); FR-M08-002 (orders close, never post); DSS-C-001.

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
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late StockLevels stock;
  final CompanyId companyId = CompanyId('c-p');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties = PartyRepository(ctx, ops: ops, audit: audit);
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
    stock = StockLevels(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Posting Co',
            deviceId: 'host-test',
            opId: 'op-cp',
            eventId: 'ev-cp',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> t in <Map<String, String>>[
      {'id': 't-si', 'base': 'Sales Invoice', 'name': 'Sales Invoice'},
      {'id': 't-pi', 'base': 'Purchase Invoice', 'name': 'Purchase Invoice'},
      {'id': 't-st', 'base': 'Stock Transfer', 'name': 'Stock Transfer'},
      {'id': 't-j', 'base': 'Journal', 'name': 'Journal'},
      {'id': 't-so', 'base': 'Sales Order', 'name': 'Sales Order'},
      {'id': 't-r', 'base': 'Receipt', 'name': 'Receipt'},
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
            id: EntityId('p-p'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pp',
            eventId: 'ev-pp',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-p'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ip',
            eventId: 'ev-ip',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-p'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gp',
            eventId: 'ev-gp',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-b'),
            companyId: companyId,
            name: 'Branch',
            deviceId: 'host-test',
            opId: 'op-gb',
            eventId: 'ev-gb',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createVoucher(String id, String type, {String status = 'draft'}) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: type,
      series: 'S',
      no: id,
      date: NiavDate('2026-04-01'),
      status: status,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void addStockLine(String vid, String lid, int qty,
      {int rate = 1000,
      int line = 1,
      bool party = true,
      String godown = 'g-p'}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: line,
      itemId: EntityId('i-p'),
      godownId: EntityId(godown),
      partyId: party ? EntityId('p-p') : null,
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

  int movementCount() {
    return db
        .queryArgs(
          'SELECT COUNT(*) AS n FROM stock_movement WHERE company_id = ?',
          <Object?>['c-p'],
        )
        .first['n'] as int;
  }

  group('posting pipeline', () {
    test('purchase layers stock; sale consumes at weighted average', () {
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000);
      final Result<PostingResult> bought =
          postStock('v-buy', StockPolicy.allow);
      expect(bought.isOk, isTrue);
      expect(vouchers.get(companyId, EntityId('v-buy'))?.voucher.status,
          'posted');

      createVoucher('v-sell', 'Sales Invoice');
      addStockLine('v-sell', 'v-sell-l1', 20000);
      final Result<PostingResult> sold =
          postStock('v-sell', StockPolicy.allow);
      expect(sold.isOk, isTrue);
      final PostingResult pr = (sold as Ok<PostingResult>).value;
      expect(pr.movementIds, <String>['mv-v-sell-l1']);
      expect(pr.warnings, isEmpty);
      expect(pr.pendingEffects, contains('gst persistence pending verified schemas'));
      // Book was 10.0 @ 1000 → unit cost 1000, average-sourced.
      final List<Map<String, Object?>> moves = db.queryArgs(
        'SELECT qty_delta_q4, cost_paise, cost_source FROM stock_movement '
        'WHERE movement_id = ?',
        <Object?>['mv-v-sell-l1'],
      );
      expect(moves.single['qty_delta_q4'], -20000);
      expect(moves.single['cost_paise'], 1000);
      expect(moves.single['cost_source'], 'average');
      expect(
        stock
            .balances(companyId, itemId: EntityId('i-p'))
            .single
            .qtyQ4,
        80000,
      );
      // Consumption decremented remaining balances; the receipt record
      // itself is immutable (no retro revaluation).
      final List<Map<String, Object?>> layers = db.queryArgs(
        'SELECT qty_q4, value_paise, remaining_qty_q4, '
        'remaining_value_paise FROM stock_cost_layer '
        'WHERE voucher_line_id = ?',
        <Object?>['v-buy-l1'],
      );
      expect(layers.single['qty_q4'], 100000);
      expect(layers.single['value_paise'], 10000);
      expect(layers.single['remaining_qty_q4'], 80000);
      expect(layers.single['remaining_value_paise'], 8000);
      expect(
        stock.layerValuePaise(
            companyId, EntityId('i-p'), EntityId('g-p')),
        8000,
      );
    });

    test('blocked policy aborts everything; warn approves with warning', () {
      createVoucher('v-neg', 'Sales Invoice');
      addStockLine('v-neg', 'v-neg-l1', 20000);
      final Result<PostingResult> blocked =
          postStock('v-neg', StockPolicy.block);
      expect(blocked.isErr, isTrue);
      expect((blocked as Err<PostingResult>).error.code, 'validation');
      expect(vouchers.get(companyId, EntityId('v-neg'))?.voucher.status,
          'draft');
      expect(movementCount(), 0);

      final Result<PostingResult> warned =
          postStock('v-neg', StockPolicy.warn);
      expect(warned.isOk, isTrue);
      // Empty book: negative-stock warning AND no-cost-history warning.
      expect((warned as Ok<PostingResult>).value.warnings, hasLength(2));
      expect(movementCount(), 1);
    });

    test('transfer posts two legs with value preserved', () {
      // Stock the source first: 10.0 @ 1000 in Main.
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000);
      expect(postStock('v-buy', StockPolicy.allow).isOk, isTrue);

      // 4.0 Main → Branch: OUT leg (negative qty, source) + IN leg.
      // Transfer legs carry zero rate: value flows from the book.
      createVoucher('v-t', 'Stock Transfer');
      addStockLine('v-t', 'v-t-out', -40000, rate: 0, line: 1);
      addStockLine('v-t', 'v-t-in', 40000, rate: 0, line: 2, godown: 'g-b');
      final Result<PostingResult> r =
          postStock('v-t', StockPolicy.allow);
      expect(r.isOk, isTrue);
      final PostingResult pr = (r as Ok<PostingResult>).value;
      expect(pr.movementIds,
          <String>['mv-v-t-out', 'mv-v-t-in']);
      expect(vouchers.get(companyId, EntityId('v-t'))?.voucher.status,
          'posted');
      final List<StockBalance> held = stock.balances(companyId);
      expect(
        held
            .firstWhere((StockBalance b) => b.godownId.value == 'g-p')
            .qtyQ4,
        60000,
      );
      expect(
        held
            .firstWhere((StockBalance b) => b.godownId.value == 'g-b')
            .qtyQ4,
        40000,
      );
      // Value moved with the goods: 6000 + 4000 = 10000 (nothing created).
      expect(stock.layerValuePaise(companyId, EntityId('i-p'), EntityId('g-p')),
          6000);
      expect(stock.layerValuePaise(companyId, EntityId('i-p'), EntityId('g-b')),
          4000);
    });

    test('unbalanced and same-godown transfers rejected atomically', () {
      createVoucher('v-buy', 'Purchase Invoice');
      addStockLine('v-buy', 'v-buy-l1', 100000);
      expect(postStock('v-buy', StockPolicy.allow).isOk, isTrue);

      createVoucher('v-bad', 'Stock Transfer');
      addStockLine('v-bad', 'v-bad-out', -40000, rate: 0, line: 1);
      addStockLine('v-bad', 'v-bad-in', 30000, rate: 0, line: 2, godown: 'g-b');
      final Result<PostingResult> bad =
          postStock('v-bad', StockPolicy.allow);
      expect(bad.isErr, isTrue);
      expect(vouchers.get(companyId, EntityId('v-bad'))?.voucher.status,
          'draft');
      expect(movementCount(), 1);

      createVoucher('v-same', 'Stock Transfer');
      addStockLine('v-same', 'v-same-out', -40000, rate: 0, line: 1);
      addStockLine('v-same', 'v-same-in', 40000, rate: 0, line: 2);
      final Result<PostingResult> same =
          postStock('v-same', StockPolicy.allow);
      expect(same.isErr, isTrue);
      expect(movementCount(), 1);

      // Priced transfer legs are rejected: value flows from the book.
      // (The OUT leg must already be rate-free to be storable at all.)
      createVoucher('v-price', 'Stock Transfer');
      addStockLine('v-price', 'v-price-out', -40000, rate: 0, line: 1);
      addStockLine('v-price', 'v-price-in', 40000, line: 2, godown: 'g-b');
      final Result<PostingResult> priced =
          postStock('v-price', StockPolicy.allow);
      expect(priced.isErr, isTrue);
      expect((priced as Err<PostingResult>).error.message, contains('no price'));
      expect(movementCount(), 1);
    });

    test('unbalanced journal rejected; orders never post', () {
      createVoucher('v-j', 'Journal');
      final Result<VoucherLine> dr = vouchers.addLine(
        lineId: EntityId('v-j-l1'),
        voucherId: EntityId('v-j'),
        companyId: companyId,
        lineNo: 1,
        drCr: 'Dr',
        qtyQ4: 10000,
        ratePaise: 1000,
        deviceId: 'host-test',
        opId: 'op-v-j-l1',
        eventId: 'ev-v-j-l1',
        actor: 'tester',
      );
      expect(dr.isOk, isTrue);
      final Result<VoucherLine> cr = vouchers.addLine(
        lineId: EntityId('v-j-l2'),
        voucherId: EntityId('v-j'),
        companyId: companyId,
        lineNo: 2,
        drCr: 'Cr',
        qtyQ4: 10000,
        ratePaise: 500,
        deviceId: 'host-test',
        opId: 'op-v-j-l2',
        eventId: 'ev-v-j-l2',
        actor: 'tester',
      );
      expect(cr.isOk, isTrue);
      final Result<PostedTotals> bad = engine.postDraft(
        id: EntityId('v-j'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-post-j',
        eventId: 'ev-post-j',
        actor: 'tester',
      );
      expect(bad.isErr, isTrue);
      expect((bad as Err<PostedTotals>).error.code, 'validation');

      createVoucher('v-j2', 'Journal');
      for (final Map<String, Object> arm in <Map<String, Object>>[
        {'id': 'v-j2-l1', 'line': 1, 'side': 'Dr', 'rate': 1000},
        {'id': 'v-j2-l2', 'line': 2, 'side': 'Cr', 'rate': 1000},
      ]) {
        final Result<VoucherLine> l = vouchers.addLine(
          lineId: EntityId(arm['id'] as String),
          voucherId: EntityId('v-j2'),
          companyId: companyId,
          lineNo: arm['line'] as int,
          drCr: arm['side'] as String,
          qtyQ4: 10000,
          ratePaise: arm['rate'] as int,
          deviceId: 'host-test',
          opId: 'op-${arm['id']}',
          eventId: 'ev-${arm['id']}',
          actor: 'tester',
        );
        expect(l.isOk, isTrue);
      }
      final Result<PostedTotals> good = engine.postDraft(
        id: EntityId('v-j2'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-post-j2',
        eventId: 'ev-post-j2',
        actor: 'tester',
      );
      expect(good.isOk, isTrue);

      createVoucher('v-o', 'Sales Order');
      addStockLine('v-o', 'v-o-l1', 10000);
      final Result<PostedTotals> order = engine.postDraft(
        id: EntityId('v-o'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-post-o',
        eventId: 'ev-post-o',
        actor: 'tester',
      );
      expect(order.isErr, isTrue);
      expect((order as Err<PostedTotals>).error.message, contains('not posted'));
    });

    test('allocation rides the same transaction; failure aborts all', () {
      createVoucher('v-bill', 'Sales Invoice');
      addStockLine('v-bill', 'v-bill-l1', 50000);
      createVoucher('v-pay', 'Receipt');
      final Result<VoucherLine> settle = vouchers.addLine(
        lineId: EntityId('v-pay-l1'),
        voucherId: EntityId('v-pay'),
        companyId: companyId,
        lineNo: 1,
        qtyQ4: 10000,
        ratePaise: 5000,
        deviceId: 'host-test',
        opId: 'op-v-pay-l1',
        eventId: 'ev-v-pay-l1',
        actor: 'tester',
      );
      expect(settle.isOk, isTrue);

      // Over-allocation fails: invoice stays draft, no movements, no links.
      final Result<PostingResult> over = postStock('v-bill', StockPolicy.allow,
          allocs: <AllocationSpec>[
            AllocationSpec(
              sourceLineId: EntityId('v-bill-l1'),
              settlementLineId: EntityId('v-pay-l1'),
              amountPaise: 999999,
            ),
          ]);
      expect(over.isErr, isTrue);
      expect(vouchers.get(companyId, EntityId('v-bill'))?.voucher.status,
          'draft');
      expect(movementCount(), 0);
      expect(
        voucherOpenBalance(db, companyId, EntityId('v-bill')),
        5000,
      );

      // Fitting allocation commits with everything.
      final Result<PostingResult> fits = postStock('v-bill', StockPolicy.allow,
          allocs: <AllocationSpec>[
            AllocationSpec(
              sourceLineId: EntityId('v-bill-l1'),
              settlementLineId: EntityId('v-pay-l1'),
              amountPaise: 2000,
            ),
          ]);
      expect(fits.isOk, isTrue);
      expect(vouchers.get(companyId, EntityId('v-bill'))?.voucher.status,
          'posted');
      expect(
        voucherOpenBalance(db, companyId, EntityId('v-bill')),
        3000,
      );
      expect(movementCount(), 1);
    });
  });
}
