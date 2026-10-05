// Prompt-11 widget tests: stock report over real queries.
// Real StockLevels + item/godown repositories over a real migrated database
// (movements seeded with schema-defined columns) — no fakes. Proves: empty
// state, balances listed with resolved names and formatted quantities, and
// the recoverable-error state with retry. Validation/locked states are N/A
// (read-only screen). Main-app wiring waits on P-SQLIB.
// Traceability: UI-009/UI-010 (report view); M15; OD-UI-001 (Reports tab).

import 'package:flutter/material.dart';
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
import 'package:niaverp/presentation/reports/stock_report_screen.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late StockLevels levels;
  late ItemRepository items;
  late GodownRepository godowns;
  final CompanyId companyId = CompanyId('c-r');

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    items = ItemRepository(ctx, ops: ops, audit: audit);
    godowns = GodownRepository(ctx, ops: ops, audit: audit);
    levels = StockLevels(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Report Co',
            deviceId: 'host-test',
            opId: 'op-cr',
            eventId: 'ev-cr',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-r'),
            companyId: companyId,
            name: 'Screw',
            deviceId: 'host-test',
            opId: 'op-ir',
            eventId: 'ev-ir',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
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
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void insertMovement(String id, int delta, int at) {
    db.executeArgs(
      'INSERT INTO stock_movement (movement_id, company_id, item_id, '
      'godown_id, qty_delta_q4, cost_paise, cost_source, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[id, 'c-r', 'i-r', 'g-r', delta, 100, 'layer', at],
    );
  }

  Widget buildScreen() {
    return MaterialApp(
      home: StockReportScreen(
        companyId: companyId,
        levels: levels,
        items: items,
        godowns: godowns,
      ),
    );
  }

  group('stock report (UI-009/UI-010)', () {
    testWidgets('empty database shows the empty state', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('stock-empty')), findsOneWidget);
      expect(find.text('No stock movements yet.'), findsOneWidget);
    });

    testWidgets('balances list names and formatted quantities',
        (WidgetTester t) async {
      insertMovement('m-1', 50000, 1700000000001);
      insertMovement('m-2', 50000 - 70000, 1700000000002);
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('stock-balances-list')),
          findsOneWidget);
      expect(find.text('Screw'), findsOneWidget);
      expect(find.text('Main'), findsOneWidget);
      // 50000 − 20000 = 30000 ×10⁻⁴ → 3.0000; no layers seeded → ₹0.00.
      expect(find.text('3.0000 · ₹0.00'), findsOneWidget);
    });

    testWidgets('closed database shows recoverable error with retry',
        (WidgetTester t) async {
      db.close();
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.text('Could not load stock'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Retry must not crash (still failing against the closed database).
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Could not load stock'), findsOneWidget);
    });
  });
}
