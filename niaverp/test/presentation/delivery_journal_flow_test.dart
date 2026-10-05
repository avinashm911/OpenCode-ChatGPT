// Delivery + stock journal flow tests: shared form config and adjustments.
// Real backend (in-memory) + real engine + real queries — no fakes. Proves:
// a delivery note posts through the shared form (customer, lines, auto
// numbering, stock OUT) and offers no settlement button (conversion, not
// settlement); a stock journal layers IN rows at rate and consumes OUT
// rows from the book, with priced OUT rows refused; hub routes to both.
// Traceability: FR-M07-001/003; FR-M04-001/002; FR-M13-001; D-M4/D-M5.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/application/services/numbering.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/alias_repository.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/billing/billing_hub_screen.dart';
import 'package:niaverp/presentation/billing/invoice_view_screen.dart';
import 'package:niaverp/presentation/inventory/new_delivery_screen.dart';
import 'package:niaverp/presentation/inventory/new_stock_journal_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-dj');
  final NiavDate today = NiavDate('2026-04-01');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    final VoucherRepository vouchers =
        VoucherRepository(ctx, ops: ops, audit: audit);
    final VoucherTypeRepository typeRepo =
        VoucherTypeRepository(ctx, ops: ops, audit: audit);
    scope = CompanyScope(
      companies: companies,
      parties: parties,
      items: items,
      aliases: AliasRepository(ctx, ops: ops, audit: audit),
      search: MasterSearch(db),
      godowns: godowns,
      stock: StockLevels(db),
      outstanding: OutstandingReport(db),
      vouchers: vouchers,
      types: typeRepo,
      numbering: SeriesNumbering(db),
      engine: VoucherEngine(
        ctx,
        ops: ops,
        audit: audit,
        vouchers: vouchers,
        types: typeRepo,
        allocationRepo:
            BillAllocationRepository(ctx, ops: ops, audit: audit),
      ),
      write: WriteContext(
        deviceId: 'host-test',
        actor: 'tester',
        idMint: CounterIdMint().call,
      ),
      today: today,
    );
    expect(
      companies
          .create(
            id: companyId,
            name: 'DJ Co',
            deviceId: 'host-test',
            opId: 'op-cdj',
            eventId: 'ev-cdj',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-dj'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pdj',
            eventId: 'ev-pdj',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-dj'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-idj',
            eventId: 'ev-idj',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-dj'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gdj',
            eventId: 'ev-gdj',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> t in <Map<String, String>>[
      {
        'id': 't-dn',
        'base': 'Delivery Note / Delivery Challan',
        'name': 'Delivery Note / Delivery Challan'
      },
      {'id': 't-sj', 'base': 'Stock Journal', 'name': 'Stock Journal'},
      {'id': 't-pi', 'base': 'Purchase Invoice', 'name': 'Purchase Invoice'},
    ]) {
      expect(
        typeRepo
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
    for (final Map<String, String> s in <Map<String, String>>[
      {'id': 's-dn', 'type': 't-dn', 'name': 'DN', 'prefix': 'DN-'},
      {'id': 's-sj', 'type': 't-sj', 'name': 'SJ', 'prefix': 'SJ-'},
    ]) {
      expect(
        typeRepo
            .createSeries(
              seriesId: EntityId(s['id']!),
              companyId: companyId,
              typeId: EntityId(s['type']!),
              name: s['name']!,
              prefix: s['prefix'],
              width: 4,
              mode: 'auto',
              deviceId: 'host-test',
              opId: 'op-${s['id']}',
              eventId: 'ev-${s['id']}',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    // Stock the shelf: 10.0 @ ₹1000 via a posted purchase.
    final Result<Voucher> buy = vouchers.create(
      id: EntityId('v-buy'),
      companyId: companyId,
      type: 'Purchase Invoice',
      series: 'P',
      no: 'v-buy',
      date: NiavDate('2026-03-01'),
      deviceId: 'host-test',
      opId: 'op-v-buy',
      eventId: 'ev-v-buy',
      actor: 'tester',
    );
    expect(buy.isOk, isTrue);
    expect(
      vouchers
          .addLine(
            lineId: EntityId('v-buy-l1'),
            voucherId: EntityId('v-buy'),
            companyId: companyId,
            lineNo: 1,
            itemId: EntityId('i-dj'),
            godownId: EntityId('g-dj'),
            partyId: EntityId('p-dj'),
            qtyQ4: 100000,
            ratePaise: 1000,
            deviceId: 'host-test',
            opId: 'op-v-buy-l1',
            eventId: 'ev-v-buy-l1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      scope.engine
          .postWithStock(
            id: EntityId('v-buy'),
            companyId: companyId,
            policy: StockPolicy.allow,
            deviceId: 'host-test',
            opId: 'op-post-buy',
            eventId: 'ev-post-buy',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// Scroll a lazily built list row into view before interaction.
  Future<void> revealRow(
      WidgetTester t, Finder f, String listKey) async {
    final Finder view = find.byKey(ValueKey<String>(listKey));
    try {
      await t.dragUntilVisible(f, view, const Offset(0, -500));
    } on StateError {
      await t.dragUntilVisible(f, view, const Offset(0, 500));
    }
    await t.pumpAndSettle();
  }

  group('delivery flow (FR-M07-001)', () {
    testWidgets('customer → lines → post moves stock out, no settlement',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: NewDeliveryScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('dn-customer-field')), 'Buy');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('dn-customer-option-p-dj')));
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('dn-item-field')), 'Wid');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('dn-item-option-i-dj')));
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('dn-line-qty-0')), 'dn-form-list');
      await t.enterText(
          find.byKey(const ValueKey<String>('dn-line-qty-0')), '3');
      await t.enterText(
          find.byKey(const ValueKey<String>('dn-line-rate-0')), '1000');
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('dn-post')), 'dn-form-list');
      await t.tap(find.byKey(const ValueKey<String>('dn-post')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('dn-confirm-dialog')),
          findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('dn-confirm-post')));
      await t.pumpAndSettle();

      // Posted delivery with auto number; stock OUT 3.0 → 7.0 left.
      expect(find.byType(InvoiceViewScreen), findsOneWidget);
      expect(find.text('Invoice DN-0001'), findsOneWidget);
      await revealRow(
          t, find.byKey(const ValueKey<String>('invoice-totals')), 'invoice-view');
      expect(find.text('Gross: ₹3000.00 · Net: ₹3000.00'),
          findsOneWidget);
      expect(
        scope.stock
            .balances(companyId, itemId: EntityId('i-dj'))
            .single
            .qtyQ4,
        70000,
      );
      // No settlement affordance: delivery notes convert, never settle.
      expect(find.text('Record receipt'), findsNothing);
      expect(find.text('Record payment'), findsNothing);
    });
  });

  group('stock journal flow (FR-M07-003)', () {
    Future<void> postJournalRow(
      WidgetTester t, {
      required bool stockIn,
      required String qty,
      required String rate,
    }) async {
      // Fresh key per pump: otherwise the previous pump's Navigator state
      // (with the posted view route) survives and the new home never builds.
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: NewStockJournalScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('journal-item-field')), 'Wid');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('journal-item-option-i-dj')));
      await t.pumpAndSettle();
      if (!stockIn) {
        await revealRow(
            t,
            find.byKey(const ValueKey<String>('journal-direction-0')),
            'journal-form-list');
        await t.tap(
            find.byKey(const ValueKey<String>('journal-direction-0')));
        await t.pumpAndSettle();
        await t.tap(find.text('Stock out').last);
        await t.pumpAndSettle();
      }
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('journal-qty-0')),
          'journal-form-list');
      await t.enterText(
          find.byKey(const ValueKey<String>('journal-qty-0')), qty);
      await t.enterText(
          find.byKey(const ValueKey<String>('journal-rate-0')), rate);
      await t.pumpAndSettle();
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('journal-post')),
          'journal-form-list');
      await t.tap(find.byKey(const ValueKey<String>('journal-post')));
      await t.pumpAndSettle();
    }

    testWidgets('in-row layers stock; out-row consumes it',
        (WidgetTester t) async {
      // Surplus found: +2.0 @ ₹1200 → book 12.0 / ₹2500.00.
      await postJournalRow(t, stockIn: true, qty: '2', rate: '1200');
      expect(find.text('Stock Journal SJ-0001'), findsOneWidget);
      expect(find.text('In · Main'), findsOneWidget);
      expect(
        scope.stock
            .balances(companyId, itemId: EntityId('i-dj'))
            .single
            .qtyQ4,
        120000,
      );
      // Wastage: −1.0 at zero rate, priced from the committed book
      // (each posting prices against posted history, never sibling rows).
      await postJournalRow(t, stockIn: false, qty: '1', rate: '0');
      expect(find.text('Stock Journal SJ-0002'), findsOneWidget);
      expect(find.text('Out · Main'), findsOneWidget);
      // 10.0 + 2.0 − 1.0 = 11.0 on hand.
      expect(
        scope.stock
            .balances(companyId, itemId: EntityId('i-dj'))
            .single
            .qtyQ4,
        110000,
      );
      // Layer value: 250000 − 20833 (WA book average) = 229167.
      expect(
          scope.stock
              .layerValuePaise(companyId, EntityId('i-dj'), EntityId('g-dj')),
          229167);
    });

    testWidgets('priced stock-out rows refused with nothing written',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: NewStockJournalScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('journal-item-field')), 'Wid');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('journal-item-option-i-dj')));
      await t.pumpAndSettle();
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('journal-direction-0')),
          'journal-form-list');
      await t.tap(
          find.byKey(const ValueKey<String>('journal-direction-0')));
      await t.pumpAndSettle();
      await t.tap(find.text('Stock out').last);
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('journal-rate-0')), '500');
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('journal-post')), 'journal-form-list');
      await t.tap(find.byKey(const ValueKey<String>('journal-post')));
      await t.pumpAndSettle();
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('journal-error')),
          'journal-form-list');
      expect(find.text('Row 1: stock-out rows carry no price.'),
          findsOneWidget);
      expect(
        scope.stock
            .balances(companyId, itemId: EntityId('i-dj'))
            .single
            .qtyQ4,
        100000,
      );
    });
  });

  group('hub entries (M04/M07)', () {
    testWidgets('hub routes to delivery and journal forms',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: BillingHubScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('billing-new-delivery')));
      await t.pumpAndSettle();
      expect(find.byType(NewDeliveryScreen), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('billing-new-journal')));
      await t.pumpAndSettle();
      expect(find.byType(NewStockJournalScreen), findsOneWidget);
    });
  });
}
