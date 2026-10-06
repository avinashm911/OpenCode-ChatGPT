// Stock valuation tests: D-M5/D-08 as executable policy (M13/M15, G1).
// Disposable in-memory databases only. Proves: FIFO consumes oldest layers
// first with remaining balances decremented (receipt records immutable);
// item override wins over the group default, unset resolves to WA; the
// method locks at the first layer-priced issue (master edit and engine both
// refuse a change — receipts alone never lock); returns/journal legs follow
// the same IN-layer / OUT-consume path; negative stock prices shortfall at
// last-known cost (fifo-fallback/fallback) or zero with warnings; and the
// valuation query reports movement qty with remaining-layer value.
// Traceability: D-M5/D-08; FR-M05-001/002 (purchase/sale); FR-M05-003/004
// (returns); FR-M07-001/002/003 (delivery/transfer/journal); FR-M13-001
// (policy); M15 (valuation report); OD-DB-002.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/costing.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/unit_group_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late ItemRepository items;
  late ItemGroupRepository itemGroups;
  late StockLevels stock;
  final CompanyId companyId = CompanyId('c-v');

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
    items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    itemGroups = ItemGroupRepository(ctx, ops: ops, audit: audit);
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
            name: 'Valuation Co',
            deviceId: 'host-test',
            opId: 'op-cv',
            eventId: 'ev-cv',
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
      'Stock Transfer',
      'Stock Journal',
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
            id: EntityId('p-v'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pv',
            eventId: 'ev-pv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      itemGroups
          .create(
            id: EntityId('g-i'),
            companyId: companyId,
            name: 'Goods',
            deviceId: 'host-test',
            opId: 'op-gi',
            eventId: 'ev-gi',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-v'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-iv',
            eventId: 'ev-iv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> g in <Map<String, String>>[
      {'id': 'g-a', 'name': 'Main'},
      {'id': 'g-b', 'name': 'Branch'},
    ]) {
      expect(
        godowns
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
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-v')]);
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

  void addLine(String vid, String lid, int qty,
      {int rate = 1000, int line = 1, String godown = 'g-a'}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: line,
      itemId: EntityId('i-v'),
      godownId: EntityId(godown),
      partyId: EntityId('p-v'),
      qtyQ4: qty,
      ratePaise: rate,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> postStock(String id) {
    return engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: StockPolicy.allow,
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
  }

  void setItemMethod(String? method, {String? group}) {
    final Result<Item> r = items.updateMaster(
      companyId: companyId,
      id: EntityId('i-v'),
      groupId: EntityId('g-i'),
      costMethod: method,
      deviceId: 'host-test',
      opId: 'op-m-${method ?? 'null'}-$group',
      eventId: 'ev-m-${method ?? 'null'}-$group',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Map<String, Object?> movement(String id) {
    return db
        .queryArgs(
          'SELECT qty_delta_q4, cost_paise, cost_source FROM stock_movement '
          'WHERE movement_id = ?',
          <Object?>[id],
        )
        .single;
  }

  List<Map<String, Object?>> layers() {
    return db.queryArgs(
      'SELECT layer_id, qty_q4, value_paise, remaining_qty_q4, '
      'remaining_value_paise FROM stock_cost_layer WHERE company_id = ? '
      'ORDER BY created_at, layer_id',
      <Object?>['c-v'],
    );
  }

  group('valuation method (D-M5)', () {
    test('pure helpers: resolve, vocabulary, lock families', () {
      expect(resolveCostMethod(null, null), 'wa');
      expect(resolveCostMethod('fifo', 'wa'), 'fifo');
      expect(resolveCostMethod(null, 'fifo'), 'fifo');
      expect(isValidCostMethod('xx'), isFalse);
      expect(methodOfPricedSource('average'), 'wa');
      expect(methodOfPricedSource('fifo-fallback'), 'fifo');
      expect(methodOfPricedSource('fallback'), isNull);
      expect(methodOfPricedSource('zero'), isNull);
    });

    test('invalid stored methods rejected at masters', () {
      final Result<ItemGroup> badGroup = itemGroups.create(
        id: EntityId('g-x'),
        companyId: companyId,
        name: 'Bad',
        costMethod: 'lifo',
        deviceId: 'host-test',
        opId: 'op-gx',
        eventId: 'ev-gx',
        actor: 'tester',
      );
      expect(badGroup.isErr, isTrue);
      final Result<Item> badItem = items.updateMaster(
        companyId: companyId,
        id: EntityId('i-v'),
        costMethod: 'lifo',
        deviceId: 'host-test',
        opId: 'op-mi-x',
        eventId: 'ev-mi-x',
        actor: 'tester',
      );
      expect(badItem.isErr, isTrue);
    });

    test('FIFO consumes oldest layers first', () {
      setItemMethod('fifo');
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      createVoucher('v-b2', 'Purchase Invoice');
      addLine('v-b2', 'v-b2-l1', 50000, rate: 1200);
      expect(postStock('v-b2').isOk, isTrue);

      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 120000);
      final Result<PostingResult> sold = postStock('v-s');
      expect(sold.isOk, isTrue);
      // L1 full (100000 @ 1000) + L2 partial 20000 @ 1200 = 12400.
      final Map<String, Object?> m = movement('mv-v-s-l1');
      expect(m['qty_delta_q4'], -120000);
      expect(m['cost_paise'], 1033);
      expect(m['cost_source'], 'fifo');
      final List<Map<String, Object?>> ls = layers();
      expect(ls[0]['remaining_qty_q4'], 0);
      expect(ls[0]['remaining_value_paise'], 0);
      expect(ls[0]['qty_q4'], 100000);
      expect(ls[1]['remaining_qty_q4'], 30000);
      expect(ls[1]['remaining_value_paise'], 3600);
      expect(
        stock.layerValuePaise(companyId, EntityId('i-v'), EntityId('g-a')),
        3600,
      );
    });

    test('item override wins over group default', () {
      expect(
        itemGroups
            .create(
              id: EntityId('g-w'),
              companyId: companyId,
              name: 'WA Goods',
              costMethod: 'wa',
              deviceId: 'host-test',
              opId: 'op-gw',
              eventId: 'ev-gw',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<Item> linked = items.updateMaster(
        companyId: companyId,
        id: EntityId('i-v'),
        groupId: EntityId('g-w'),
        costMethod: 'fifo',
        deviceId: 'host-test',
        opId: 'op-mi-f',
        eventId: 'ev-mi-f',
        actor: 'tester',
      );
      expect(linked.isOk, isTrue);
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      createVoucher('v-b2', 'Purchase Invoice');
      addLine('v-b2', 'v-b2-l1', 50000, rate: 1200);
      expect(postStock('v-b2').isOk, isTrue);
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 120000);
      expect(postStock('v-s').isOk, isTrue);
      // FIFO pricing despite the WA group default.
      expect(movement('mv-v-s-l1')['cost_source'], 'fifo');
    });

    test('method locks at first priced issue, not at receipt', () {
      setItemMethod('fifo');
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      // Receipts never lock: switching before any issue is allowed.
      final Result<Item> preIssue = items.updateMaster(
        companyId: companyId,
        id: EntityId('i-v'),
        groupId: EntityId('g-i'),
        costMethod: 'wa',
        deviceId: 'host-test',
        opId: 'op-mi-pre',
        eventId: 'ev-mi-pre',
        actor: 'tester',
      );
      expect(preIssue.isOk, isTrue);
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 20000);
      expect(postStock('v-s').isOk, isTrue);
      expect(movement('mv-v-s-l1')['cost_source'], 'average');
      // Now locked to WA: switching back to FIFO is refused at the master.
      final Result<Item> locked = items.updateMaster(
        companyId: companyId,
        id: EntityId('i-v'),
        groupId: EntityId('g-i'),
        costMethod: 'fifo',
        deviceId: 'host-test',
        opId: 'op-mi-lock',
        eventId: 'ev-mi-lock',
        actor: 'tester',
      );
      expect(locked.isErr, isTrue);
      expect(
          (locked as Err<Item>).error.message, contains('locked'));
    });

    test('engine refuses method mismatching legacy priced history', () {
      setItemMethod('fifo');
      // Legacy priced movement (pre-lock data): WA family.
      db.executeArgs(
        'INSERT INTO stock_movement (movement_id, company_id, item_id, '
        'godown_id, qty_delta_q4, cost_paise, cost_source, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>['m-legacy', 'c-v', 'i-v', 'g-a', -10000, 1000, 'average',
          1700000000000],
      );
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 5000);
      final Result<PostingResult> r = engine.postWithStock(
        id: EntityId('v-s'),
        companyId: companyId,
        policy: StockPolicy.allow,
        deviceId: 'host-test',
        opId: 'op-post-v-s',
        eventId: 'ev-post-v-s',
        actor: 'tester',
      );
      expect(r.isErr, isTrue);
      expect((r as Err<PostingResult>).error.message, contains('locked'));
    });
  });

  group('returns, journals and negative stock', () {
    test('sales return layers IN; purchase return consumes OUT', () {
      setItemMethod('fifo');
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);

      createVoucher('v-sr', 'Sales Return / Credit Note with items');
      addLine('v-sr', 'v-sr-l1', 50000, rate: 1100);
      expect(postStock('v-sr').isOk, isTrue);
      final Map<String, Object?> inMove = movement('mv-v-sr-l1');
      expect(inMove['qty_delta_q4'], 50000);
      expect(inMove['cost_source'], 'layer');

      createVoucher('v-pr', 'Purchase Return / Debit Note with items');
      addLine('v-pr', 'v-pr-l1', 30000);
      expect(postStock('v-pr').isOk, isTrue);
      final Map<String, Object?> outMove = movement('mv-v-pr-l1');
      expect(outMove['qty_delta_q4'], -30000);
      expect(outMove['cost_source'], 'fifo');
      // Oldest layer drawn first: purchase layer retains 70000.
      expect(
        stock.layerValuePaise(companyId, EntityId('i-v'), EntityId('g-a')),
        7000 + 5500,
      );
    });

    test('stock journal adjusts both ways', () {
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);

      createVoucher('v-j1', 'Stock Journal');
      addLine('v-j1', 'v-j1-l1', 20000, rate: 1000);
      expect(postStock('v-j1').isOk, isTrue);
      createVoucher('v-j2', 'Stock Journal');
      addLine('v-j2', 'v-j2-l1', -10000, rate: 0);
      expect(postStock('v-j2').isOk, isTrue);
      expect(
        stock
            .balances(companyId, itemId: EntityId('i-v'))
            .single
            .qtyQ4,
        110000,
      );
      expect(
        stock.layerValuePaise(companyId, EntityId('i-v'), EntityId('g-a')),
        11000,
      );
    });

    test('FIFO shortfall prices at last-known cost', () {
      setItemMethod('fifo');
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 50000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      // last-known is now 1000; issue 8.0 with an empty remainder book.
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 80000);
      final Result<PostingResult> r = engine.postWithStock(
        id: EntityId('v-s'),
        companyId: companyId,
        policy: StockPolicy.warn,
        deviceId: 'host-test',
        opId: 'op-post-v-s',
        eventId: 'ev-post-v-s',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      // 50000 @ 1000 + 30000 @ last-known 1000 = 8000 for 8.0 units.
      final Map<String, Object?> m = movement('mv-v-s-l1');
      expect(m['cost_source'], 'fifo-fallback');
      expect(m['cost_paise'], 1000);
      expect(
        (r as Ok<PostingResult>).value.warnings,
        contains('negative stock warning for item i-v'),
      );
    });

    test('empty book in another godown falls back per item', () {
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 50000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      // Branch book is empty but the item has last-known cost 1000.
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 10000, godown: 'g-b');
      final Result<PostingResult> r = engine.postWithStock(
        id: EntityId('v-s'),
        companyId: companyId,
        policy: StockPolicy.warn,
        deviceId: 'host-test',
        opId: 'op-post-v-s',
        eventId: 'ev-post-v-s',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      final Map<String, Object?> m = movement('mv-v-s-l1');
      expect(m['cost_source'], 'fallback');
      expect(m['cost_paise'], 1000);
    });
  });

  group('valuation report (M15)', () {
    test('valuation follows postings: qty plus remaining value', () {
      createVoucher('v-b1', 'Purchase Invoice');
      addLine('v-b1', 'v-b1-l1', 100000, rate: 1000);
      expect(postStock('v-b1').isOk, isTrue);
      createVoucher('v-s', 'Sales Invoice');
      addLine('v-s', 'v-s-l1', 20000);
      expect(postStock('v-s').isOk, isTrue);

      final List<StockValuation> held = stock.valuation(companyId);
      expect(held, hasLength(1));
      expect(held.single.qtyQ4, 80000);
      expect(held.single.valuePaise, 8000);

      createVoucher('v-t', 'Stock Transfer');
      addLine('v-t', 'v-t-out', -30000, rate: 0, line: 1);
      addLine('v-t', 'v-t-in', 30000, rate: 0, line: 2, godown: 'g-b');
      expect(postStock('v-t').isOk, isTrue);
      final List<StockValuation> after = stock.valuation(companyId);
      expect(after, hasLength(2));
      expect(
        after.fold(0, (int s, StockValuation v) => s + v.qtyQ4),
        80000,
      );
      // Value preserved across godowns: 5000 + 3000 = 8000.
      expect(
        after.fold(0, (int s, StockValuation v) => s + v.valuePaise),
        8000,
      );
    });
  });
}
