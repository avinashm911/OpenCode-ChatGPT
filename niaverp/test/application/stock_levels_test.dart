// Prompt-06 tests: stock read models (M15 P1).
// Disposable in-memory databases only (movements/layers seeded with
// schema-defined columns). Proves: balances sum deltas per (item, godown),
// movement history ordering and filters, layer value totals, row caps and
// company isolation.
// Traceability: M15 (reports are queries over persisted data); G0-SCH-001.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late StockLevels levels;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    levels = StockLevels(db);
    int n = 0;
    String tag() {
      n += 1;
      return 'k$n';
    }

    for (final String c in <String>['c-k', 'c-other']) {
      expect(
        companies
            .create(
              id: CompanyId(c),
              name: 'Co $c',
              deviceId: 'host-test',
              opId: 'op-${tag()}',
              eventId: 'ev-${tag()}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        items
            .create(
              id: EntityId('i-$c'),
              companyId: CompanyId(c),
              name: 'Screw',
              deviceId: 'host-test',
              opId: 'op-${tag()}',
              eventId: 'ev-${tag()}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        godowns
            .create(
              id: EntityId('g-$c'),
              companyId: CompanyId(c),
              name: 'Main',
              deviceId: 'host-test',
              opId: 'op-${tag()}',
              eventId: 'ev-${tag()}',
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

  void insertMovement(
    String id,
    String company,
    String item,
    String godown,
    int delta,
    int at,
  ) {
    db.executeArgs(
      'INSERT INTO stock_movement (movement_id, company_id, item_id, '
      'godown_id, qty_delta_q4, cost_paise, cost_source, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[id, company, item, godown, delta, 100, 'layer', at],
    );
  }

  void insertLayer(
    String id,
    String company,
    String item,
    String godown,
    int qty,
    int value,
  ) {
    db.executeArgs(
      'INSERT INTO stock_cost_layer (layer_id, company_id, item_id, '
      'godown_id, qty_q4, value_paise, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      <Object?>[id, company, item, godown, qty, value, 1700000000000],
    );
  }

  group('stock levels (M15)', () {
    test('balances sum deltas per item and godown', () {
      insertMovement('m-1', 'c-k', 'i-c-k', 'g-c-k', 50000, 1700000000001);
      insertMovement('m-2', 'c-k', 'i-c-k', 'g-c-k', -20000, 1700000000002);
      final List<StockBalance> all = levels.balances(CompanyId('c-k'));
      expect(all, hasLength(1));
      expect(all.first.qtyQ4, 30000);
      expect(
        levels
            .balances(CompanyId('c-k'), godownId: EntityId('g-nope')),
        isEmpty,
      );
    });

    test('movements list oldest first with filters and cap', () {
      insertMovement('m-1', 'c-k', 'i-c-k', 'g-c-k', 50000, 1700000000001);
      insertMovement('m-2', 'c-k', 'i-c-k', 'g-c-k', -20000, 1700000000002);
      insertMovement('m-3', 'c-k', 'i-c-k', 'g-c-k', 10000, 1700000000003);
      final List<StockMovementView> all =
          levels.movements(CompanyId('c-k'));
      expect(
        all.map((StockMovementView m) => m.movementId),
        <String>['m-1', 'm-2', 'm-3'],
      );
      expect(
        levels.movements(CompanyId('c-k'), limit: 2),
        hasLength(2),
      );
      expect(
        levels.movements(CompanyId('c-k'), itemId: EntityId('i-nope')),
        isEmpty,
      );
    });

    test('layer values total per location, zero when none', () {
      insertLayer('l-1', 'c-k', 'i-c-k', 'g-c-k', 50000, 5000);
      insertLayer('l-2', 'c-k', 'i-c-k', 'g-c-k', 20000, 2200);
      expect(
        levels.layerValuePaise(
            CompanyId('c-k'), EntityId('i-c-k'), EntityId('g-c-k')),
        7200,
      );
      expect(
        levels.layerValuePaise(
            CompanyId('c-k'), EntityId('i-c-k'), EntityId('g-nope')),
        0,
      );
    });

    test('empty and foreign companies report nothing of mine', () {
      expect(levels.balances(CompanyId('c-k')), isEmpty);
      expect(levels.movements(CompanyId('c-k')), isEmpty);
      insertMovement(
          'm-x', 'c-other', 'i-c-other', 'g-c-other', 90000, 1700000000001);
      expect(levels.balances(CompanyId('c-k')), isEmpty);
      expect(levels.balances(CompanyId('c-other')).first.qtyQ4, 90000);
    });
  });
}
