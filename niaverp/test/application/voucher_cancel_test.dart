// Voucher cancellation tests: compensating reversal, locks, atomicity (D1).
// Disposable in-memory databases only. Proves: cancelling a purchase returns
// on-hand to pre-purchase with a compensating movement (opposite sign, same
// item/godown/value, linked to the original) while original rows keep their
// recorded values (no retro revaluation); the voucher's bill allocations move
// to reversed with audit; a locked voucher date refuses the whole cancel with
// nothing changed; an injected failure after stock reversal rolls everything
// back; movement audit carries the real actor (D6); two companies sharing an
// item code never read each other's costs (D5); a first issue priced at zero
// still locks the costing method (D8).
// Traceability: D1 (D1/D5/D6/D8); D-M5 (no retro revaluation); D-M5(5) locks.

import 'package:flutter_test/flutter_test.dart';

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
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late BillAllocationRepository allocs;
  late VoucherEngine engine;
  final CompanyId companyId = CompanyId('c-x');

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
    allocs = BillAllocationRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: allocs,
    );
    expect(
      companies
          .create(
            id: companyId,
            name: 'Cancel Co',
            deviceId: 'host-test',
            opId: 'op-cx',
            eventId: 'ev-cx',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> t in <Map<String, String>>[
      {'id': 't-pi', 'base': 'Purchase Invoice', 'name': 'Purchase Invoice'},
      {'id': 't-si', 'base': 'Sales Invoice', 'name': 'Sales Invoice'},
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
            id: EntityId('p-x'),
            companyId: companyId,
            name: 'Supplier',
            role: 'supplier',
            deviceId: 'host-test',
            opId: 'op-px',
            eventId: 'ev-px',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
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
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// A posted receipt of [amount] paise; returns its line id.
  String postReceipt(String id, int amount) {
    expect(
      vouchers
          .create(
            id: EntityId(id),
            companyId: companyId,
            type: 'Receipt',
            series: 'R',
            no: id,
            date: NiavDate('2026-04-01'),
            deviceId: 'host-test',
            opId: 'op-$id',
            eventId: 'ev-$id',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      vouchers
          .addLine(
            lineId: EntityId('$id-l1'),
            voucherId: EntityId(id),
            companyId: companyId,
            lineNo: 1,
            partyId: EntityId('p-x'),
            qtyQ4: 10000,
            ratePaise: amount,
            deviceId: 'host-test',
            opId: 'op-$id-l1',
            eventId: 'ev-$id-l1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    final Result<PostingResult> posted = engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: StockPolicy.block,
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
    expect(posted.isOk, isTrue);
    return '$id-l1';
  }

  /// A posted purchase of [qtyQ4] at [ratePaise], optionally allocating
  /// [allocPaise] against [settlementLineId].
  void postPurchase(
    String id,
    int qtyQ4,
    int ratePaise, {
    String? settlementLineId,
    int allocPaise = 0,
  }) {
    expect(
      vouchers
          .create(
            id: EntityId(id),
            companyId: companyId,
            type: 'Purchase Invoice',
            series: 'P',
            no: id,
            date: NiavDate('2026-04-01'),
            deviceId: 'host-test',
            opId: 'op-$id',
            eventId: 'ev-$id',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      vouchers
          .addLine(
            lineId: EntityId('$id-l1'),
            voucherId: EntityId(id),
            companyId: companyId,
            lineNo: 1,
            itemId: EntityId('i-x'),
            godownId: EntityId('g-x'),
            partyId: EntityId('p-x'),
            qtyQ4: qtyQ4,
            ratePaise: ratePaise,
            deviceId: 'host-test',
            opId: 'op-$id-l1',
            eventId: 'ev-$id-l1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    final Result<PostingResult> posted = engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: StockPolicy.block,
      allocations: settlementLineId == null
          ? const <AllocationSpec>[]
          : <AllocationSpec>[
              AllocationSpec(
                sourceLineId: EntityId('$id-l1'),
                settlementLineId: EntityId(settlementLineId),
                amountPaise: allocPaise,
              ),
            ],
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
    expect(posted.isOk, isTrue);
  }

  int onHand() {
    return (db
            .queryArgs(
              'SELECT SUM(qty_delta_q4) AS q FROM stock_movement '
              'WHERE company_id = ? AND item_id = ? AND godown_id = ?',
              <Object?>['c-x', 'i-x', 'g-x'],
            )
            .first['q'] as int?) ??
        0;
  }

  Map<String, Object?> movement(String id) {
    return db.queryArgs(
      'SELECT movement_id, company_id, item_id, godown_id, qty_delta_q4, '
      'cost_paise, cost_source, voucher_line_id, reverses_movement_id '
      'FROM stock_movement WHERE movement_id = ?',
      <Object?>[id],
    ).single;
  }

  Map<String, Object?> layer(String id) {
    return db.queryArgs(
      'SELECT layer_id, qty_q4, value_paise, remaining_qty_q4, '
      'remaining_value_paise FROM stock_cost_layer WHERE layer_id = ?',
      <Object?>[id],
    ).single;
  }

  Result<Voucher> cancel(String id, String tag) {
    return engine.cancelPosted(
      id: EntityId(id),
      companyId: companyId,
      reason: 'quality rejection',
      deviceId: 'host-test',
      opId: 'op-$tag',
      eventId: 'ev-$tag',
      actor: 'tester',
    );
  }

  group('cancelPosted compensating reversal (D1-D1)', () {
    test('cancel restores stock, compensates, reverses allocations, audits',
        () {
      final String settlement = postReceipt('v-r', 100000);
      postPurchase('v-p', 20000, 5000,
          settlementLineId: settlement, allocPaise: 10000);
      expect(onHand(), 20000);
      final Map<String, Object?> beforeMovement = movement('mv-v-p-l1');
      final Map<String, Object?> beforeLayer = layer('cl-v-p-l1');

      final Result<Voucher> cancelled = cancel('v-p', 'cancel-v-p');
      expect(cancelled.isOk, isTrue);
      expect((cancelled as Ok<Voucher>).value.status, 'cancelled');

      // On-hand returns to the pre-purchase quantity.
      expect(onHand(), 0);
      // One compensating movement: opposite sign, same item/godown/value,
      // linked to the original movement and the cancelled voucher's line.
      final Map<String, Object?> reversal = movement('mvr-mv-v-p-l1');
      expect(reversal['qty_delta_q4'], -20000);
      expect(reversal['item_id'], 'i-x');
      expect(reversal['godown_id'], 'g-x');
      expect(reversal['cost_paise'], beforeMovement['cost_paise']);
      expect(reversal['cost_source'], 'reversal');
      expect(reversal['reverses_movement_id'], 'mv-v-p-l1');
      expect(reversal['voucher_line_id'], 'v-p-l1');
      // Original rows keep their recorded values (no retro revaluation);
      // only the live remaining balance is given back.
      final Map<String, Object?> afterMovement = movement('mv-v-p-l1');
      expect(afterMovement['qty_delta_q4'], beforeMovement['qty_delta_q4']);
      expect(afterMovement['cost_paise'], beforeMovement['cost_paise']);
      expect(afterMovement['cost_source'], beforeMovement['cost_source']);
      final Map<String, Object?> afterLayer = layer('cl-v-p-l1');
      expect(afterLayer['qty_q4'], beforeLayer['qty_q4']);
      expect(afterLayer['value_paise'], beforeLayer['value_paise']);
      expect(afterLayer['remaining_qty_q4'], 0);
      expect(afterLayer['remaining_value_paise'], 0);
      // The allocation is reversed, with exactly one new audit event: the
      // allocate write plus the reversal write.
      final List<Map<String, Object?>> allocRows = db.queryArgs(
        'SELECT status FROM bill_allocation WHERE allocation_id = ?',
        <Object?>['al-v-p-1'],
      );
      expect(allocRows.single['status'], 'reversed');
      expect(
        audit.forEntity('c-x', 'bill_allocation', 'al-v-p-1'),
        hasLength(2),
      );
      // The voucher carries create + post + cancel audit events.
      final List<AuditEvent> voucherEvents =
          audit.forEntity('c-x', 'voucher', 'v-p');
      expect(voucherEvents, hasLength(3));
      expect(voucherEvents.last.newData, contains('cancelled'));
      // D6: the compensating movement audit carries the real actor.
      final List<AuditEvent> reversalEvents =
          audit.forEntity('c-x', 'stock_movement', 'mvr-mv-v-p-l1');
      expect(reversalEvents, hasLength(1));
      expect(reversalEvents.single.actor, 'tester');
    });

    test('cancel in a locked period is refused and nothing changes', () {
      postPurchase('v-p', 20000, 5000);
      expect(onHand(), 20000);
      db.executeArgs(
        'INSERT INTO period_lock (lock_id, company_id, scope, date_from, '
        'date_to, status, locked_by, locked_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'lock-x',
          'c-x',
          'all',
          '2026-04-01',
          '2026-04-30',
          'locked',
          'admin',
          1700000000000,
        ],
      );

      final Result<Voucher> refused = cancel('v-p', 'cancel-locked');
      expect(refused.isErr, isTrue);
      expect((refused as Err<Voucher>).error.code, 'validation');
      expect(vouchers.get(companyId, EntityId('v-p'))?.voucher.status,
          'posted');
      expect(onHand(), 20000);
      expect(
        db.queryArgs(
          'SELECT COUNT(*) AS n FROM stock_movement WHERE company_id = ?',
          <Object?>['c-x'],
        ).first['n'],
        1,
      );
      expect(layer('cl-v-p-l1')['remaining_qty_q4'], 20000);
    });

    test('cancel is atomic: allocation failure rolls everything back', () {
      final String settlement = postReceipt('v-r', 100000);
      postPurchase('v-p', 20000, 5000,
          settlementLineId: settlement, allocPaise: 10000);
      // Inject a failure after the stock reversal: the reversal's operation
      // row already exists, so reverseTx cannot append its lineage.
      db.executeArgs(
        'INSERT INTO operation (op_id, company_id, device_id, seq, entity, '
        'entity_id, action, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'op-al-rev-al-v-p-1',
          'c-x',
          'host-test',
          999999,
          'bill_allocation',
          'al-v-p-1',
          'reverse',
          1700000000000,
        ],
      );

      final Result<Voucher> failed = cancel('v-p', 'cancel-atomic');
      expect(failed.isErr, isTrue);
      // Everything rolled back: status, stock, layer, allocation.
      expect(vouchers.get(companyId, EntityId('v-p'))?.voucher.status,
          'posted');
      expect(onHand(), 20000);
      expect(
        db.queryArgs(
          'SELECT COUNT(*) AS n FROM stock_movement WHERE '
          'reverses_movement_id IS NOT NULL',
          <Object?>[],
        ).first['n'],
        0,
      );
      expect(layer('cl-v-p-l1')['remaining_qty_q4'], 20000);
      expect(
        db.queryArgs(
          'SELECT status FROM bill_allocation WHERE allocation_id = ?',
          <Object?>['al-v-p-1'],
        ).single['status'],
        'active',
      );
    });
  });

  group('company cost isolation (D1-D5)', () {
    test('two companies sharing an item code never read each other costs',
        () {
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-y'),
              name: 'Co c-y',
              deviceId: 'host-test',
              opId: 'op-c-y',
              eventId: 'ev-c-y',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final ItemRepository items =
          ItemRepository(ctx, ops: ops, audit: audit);
      final GodownRepository godowns =
          GodownRepository(ctx, ops: ops, audit: audit);
      final PartyRepository parties =
          PartyRepository(ctx, ops: ops, audit: audit);
      expect(
        items
            .create(
              id: EntityId('i-y'),
              companyId: CompanyId('c-y'),
              name: 'Widget',
              deviceId: 'host-test',
              opId: 'op-i-y',
              eventId: 'ev-i-y',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      // Same item code on both sides; ids stay company-scoped rows.
      db.executeArgs('UPDATE item SET code = ? WHERE item_id = ?',
          <Object?>['W1', 'i-x']);
      db.executeArgs('UPDATE item SET code = ? WHERE item_id = ?',
          <Object?>['W1', 'i-y']);
      // Godowns and parties live per company as well.
      expect(
        godowns
            .create(
              id: EntityId('g-y'),
              companyId: CompanyId('c-y'),
              name: 'Branch',
              deviceId: 'host-test',
              opId: 'op-gy',
              eventId: 'ev-gy',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        parties
            .create(
              id: EntityId('p-y'),
              companyId: CompanyId('c-y'),
              name: 'Buyer',
              role: 'customer',
              deviceId: 'host-test',
              opId: 'op-py',
              eventId: 'ev-py',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      for (final Map<String, String> t in <Map<String, String>>[
        {'id': 't-y-pi', 'base': 'Purchase Invoice', 'name': 'Purchase Invoice'},
        {'id': 't-y-si', 'base': 'Sales Invoice', 'name': 'Sales Invoice'},
      ]) {
        expect(
          types
              .create(
                id: EntityId(t['id']!),
                companyId: CompanyId('c-y'),
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

      // c-x buys 1 unit at Rs50: its cost state binds (c-x, i-x).
      postPurchase('v-p', 10000, 5000);
      expect(
        db.queryArgs(
          'SELECT company_id FROM item_cost_state WHERE item_id = ?',
          <Object?>['i-x'],
        ).single['company_id'],
        'c-x',
      );

      // c-y sells the same code from an empty book: it must price from its
      // own (empty) history — zero — never c-x's Rs50.
      expect(
        vouchers
            .create(
              id: EntityId('v-y'),
              companyId: CompanyId('c-y'),
              type: 'Sales Invoice',
              series: 'S',
              no: 'v-y',
              date: NiavDate('2026-04-02'),
              deviceId: 'host-test',
              opId: 'op-v-y',
              eventId: 'ev-v-y',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers
            .addLine(
              lineId: EntityId('v-y-l1'),
              voucherId: EntityId('v-y'),
              companyId: CompanyId('c-y'),
              lineNo: 1,
              itemId: EntityId('i-y'),
              godownId: EntityId('g-y'),
              partyId: EntityId('p-y'),
              qtyQ4: 10000,
              ratePaise: 7000,
              deviceId: 'host-test',
              opId: 'op-v-y-l1',
              eventId: 'ev-v-y-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<PostingResult> posted = engine.postWithStock(
        id: EntityId('v-y'),
        companyId: CompanyId('c-y'),
        policy: StockPolicy.allow,
        deviceId: 'host-test',
        opId: 'op-post-v-y',
        eventId: 'ev-post-v-y',
        actor: 'tester',
      );
      expect(posted.isOk, isTrue);
      final Map<String, Object?> move = db.queryArgs(
        'SELECT cost_paise, cost_source FROM stock_movement '
        'WHERE movement_id = ?',
        <Object?>['mv-v-y-l1'],
      ).single;
      expect(move['cost_paise'], 0);
      expect(move['cost_source'], 'zero');
      // c-x's book is untouched by c-y's sale.
      expect(onHand(), 10000);
      expect(
        db.queryArgs(
          'SELECT last_known_cost_paise AS c FROM item_cost_state '
          'WHERE company_id = ? AND item_id = ?',
          <Object?>['c-x', 'i-x'],
        ).single['c'],
        5000,
      );
    });
  });

  group('method lock on first fallback/zero issue (D1-D8)', () {
    test('a zero-priced first issue still binds the costing method', () {
      db.executeArgs('UPDATE item SET cost_method = ? WHERE item_id = ?',
          <Object?>['fifo', 'i-x']);
      expect(
        vouchers
            .create(
              id: EntityId('v-z'),
              companyId: companyId,
              type: 'Sales Invoice',
              series: 'S',
              no: 'v-z',
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-v-z',
              eventId: 'ev-v-z',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers
            .addLine(
              lineId: EntityId('v-z-l1'),
              voucherId: EntityId('v-z'),
              companyId: companyId,
              lineNo: 1,
              itemId: EntityId('i-x'),
              godownId: EntityId('g-x'),
              partyId: EntityId('p-x'),
              qtyQ4: 10000,
              ratePaise: 7000,
              deviceId: 'host-test',
              opId: 'op-v-z-l1',
              eventId: 'ev-v-z-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<PostingResult> first = engine.postWithStock(
        id: EntityId('v-z'),
        companyId: companyId,
        policy: StockPolicy.allow,
        deviceId: 'host-test',
        opId: 'op-post-v-z',
        eventId: 'ev-post-v-z',
        actor: 'tester',
      );
      expect(first.isOk, isTrue);
      // No cost history: valued at zero, but the resolved method is recorded
      // on the movement (D-M5 locks after the first posted movement).
      expect(
        db.queryArgs(
          'SELECT cost_paise, cost_method FROM stock_movement '
          'WHERE movement_id = ?',
          <Object?>['mv-v-z-l1'],
        ).single,
        containsPair('cost_method', 'fifo'),
      );
      // Switching the master to weighted-average cannot move the lock.
      db.executeArgs('UPDATE item SET cost_method = ? WHERE item_id = ?',
          <Object?>['wa', 'i-x']);
      expect(
        vouchers
            .create(
              id: EntityId('v-z2'),
              companyId: companyId,
              type: 'Sales Invoice',
              series: 'S',
              no: 'v-z2',
              date: NiavDate('2026-04-02'),
              deviceId: 'host-test',
              opId: 'op-v-z2',
              eventId: 'ev-v-z2',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        vouchers
            .addLine(
              lineId: EntityId('v-z2-l1'),
              voucherId: EntityId('v-z2'),
              companyId: companyId,
              lineNo: 1,
              itemId: EntityId('i-x'),
              godownId: EntityId('g-x'),
              partyId: EntityId('p-x'),
              qtyQ4: 10000,
              ratePaise: 7000,
              deviceId: 'host-test',
              opId: 'op-v-z2-l1',
              eventId: 'ev-v-z2-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<PostingResult> second = engine.postWithStock(
        id: EntityId('v-z2'),
        companyId: companyId,
        policy: StockPolicy.allow,
        deviceId: 'host-test',
        opId: 'op-post-v-z2',
        eventId: 'ev-post-v-z2',
        actor: 'tester',
      );
      expect(second.isErr, isTrue);
      expect(
        (second as Err<PostingResult>).error.message,
        contains('locked to fifo'),
      );
    });
  });
}
