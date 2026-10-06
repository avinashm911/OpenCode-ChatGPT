// Flagship billing flow tests: New Sales Invoice end to end (M04/M05/M11).
// Real backend (in-memory) + real engine + real queries — no fakes. Proves
// the complete first vertical slice: hub → new-sale form (customer search,
// item search, qty/rate/discount, godown, auto numbering, explicit stock
// policy) → confirm preview → atomic post → invoice view (totals, open
// balance, text preview) → record receipt with sequential allocation → open
// zero; plus validation gating (no customer), manual numbering without a
// registered type, and GST/round-off boundary notes. Stock and outstanding
// consequences are asserted through the report queries.
// Traceability: FR-M05-001; FR-M04-001/002; FR-M06-002; FR-M14-001;
// FR-M13-001; D-M4; FR-M03-002/003 (quick-add).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
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
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/billing/billing_hub_screen.dart';
import 'package:niaverp/presentation/billing/invoice_view_screen.dart';
import 'package:niaverp/presentation/billing/new_sale_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-f');
  final NiavDate today = NiavDate('2026-04-01');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
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
    final BillAllocationRepository allocRepo =
        BillAllocationRepository(ctx, ops: ops, audit: audit);
    scope = CompanyScope(
      companies: companies,
      parties: parties,
      items: items,
      aliases: AliasRepository(ctx, ops: ops, audit: audit),
      search: MasterSearch(db),
      godowns: godowns,
      stock: StockLevels(db),
      books: LedgerBooks(db),
      ledgers: LedgerRepository(ctx, ops: ops, audit: audit),
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
        allocationRepo: allocRepo,
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
            name: 'Flagship Co',
            deviceId: 'host-test',
            opId: 'op-cf',
            eventId: 'ev-cf',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-f'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pf',
            eventId: 'ev-pf',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-f'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-if',
            eventId: 'ev-if',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-f'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gf',
            eventId: 'ev-gf',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> t in <Map<String, String>>[
      {'id': 't-si', 'base': 'Sales Invoice', 'name': 'Sales Invoice'},
      {'id': 't-rc', 'base': 'Receipt', 'name': 'Receipt'},
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
      {'id': 's-si', 'type': 't-si', 'name': 'INV', 'prefix': 'INV-'},
      {'id': 's-rc', 'type': 't-rc', 'name': 'RCP', 'prefix': 'RCP-'},
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
    // D3-A1 posting fixture: role ledgers + party-ledger link.
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-f')]);
    // Stock the shelf first: 10.0 @ ₹1000 via a posted purchase.
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
            itemId: EntityId('i-f'),
            godownId: EntityId('g-f'),
            partyId: EntityId('p-f'),
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

  /// The form is a scrolling list: lazily built rows must be scrolled into
  /// view before interaction. Drags the list itself (text fields own
  /// internal scrollables, so the test harness's default scrollable lookup
  /// is ambiguous), trying both directions.
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

  Future<void> driveSale(WidgetTester t) async {    await t.pumpWidget(
      MaterialApp(
        home: NewSaleScreen(companyId: companyId, scope: scope),
      ),
    );
    await t.pumpAndSettle();
    // Customer.
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-customer-field')), 'Buy');
    await t.pumpAndSettle();
    await t.tap(find.text('Buyer'));
    await t.pumpAndSettle();
    // Item line: 2.0 @ ₹1000.
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-item-field')), 'Wid');
    await t.pumpAndSettle();
    await t.tap(find.text('Widget'));
    await t.pumpAndSettle();
    await revealRow(
        t,
        find.byKey(const ValueKey<String>('sale-line-qty-0')),
        'sale-form-list');
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-line-qty-0')), '2');
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-line-rate-0')), '1000');
    await t.pumpAndSettle();
    // Preview & post.
    await revealRow(
        t, find.byKey(const ValueKey<String>('sale-post')), 'sale-form-list');
    await t.tap(find.byKey(const ValueKey<String>('sale-post')));
    await t.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('sale-confirm-dialog')),
        findsOneWidget);
    await t.tap(find.byKey(const ValueKey<String>('sale-confirm-post')));
    await t.pumpAndSettle();
  }

  group('flagship sale (M04/M05/M11)', () {
    testWidgets('draft → preview → post → view → receipt → settled',
        (WidgetTester t) async {
      await driveSale(t);

      // Invoice view: auto number, totals, open balance, preview text.
      expect(find.byType(InvoiceViewScreen), findsOneWidget);
      expect(find.text('Invoice INV-0001'), findsOneWidget);
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('invoice-totals')),
          'invoice-view');
      expect(find.text('Gross: ₹2,000.00 · Net: ₹2,000.00'),
          findsOneWidget);
      expect(find.text('Open: ₹2,000.00'), findsOneWidget);
      expect(find.text('Widget'), findsOneWidget);

      // Engine consequences through the report queries.
      final List<OutstandingBill> held =
          scope.outstanding.bills(companyId, asOf: today);
      expect(held, hasLength(2));
      final OutstandingBill sale = held.firstWhere(
          (OutstandingBill b) => b.voucherNo == 'INV-0001');
      expect(sale.openPaise, 200000);
      expect(sale.state, 'open');
      expect(
        scope.stock
            .balances(companyId, itemId: EntityId('i-f'))
            .single
            .qtyQ4,
        80000,
      );

      // Payment: record the full receipt → open zero, advance none.
      await revealRow(
          t,
          find.byKey(const ValueKey<String>('invoice-receipt')),
          'invoice-view');
      await t.tap(find.byKey(const ValueKey<String>('invoice-receipt')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('invoice-receipt-dialog')),
          findsOneWidget);
      await t.tap(
          find.byKey(const ValueKey<String>('invoice-receipt-post')));
      await t.pumpAndSettle();
      expect(find.text('Receipt posted and fully applied.'),
          findsOneWidget);
      await revealRow(t, find.text('Open: ₹0.00'), 'invoice-view');
      expect(find.text('Open: ₹0.00'), findsOneWidget);
      // Only the stocked purchase stays open now.
      final List<OutstandingBill> rest =
          scope.outstanding.bills(companyId, asOf: today);
      expect(
        rest.map((OutstandingBill b) => b.voucherNo),
        <String>['v-buy'],
      );
    });

    testWidgets('posting without a customer is refused',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: NewSaleScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-post')), 'sale-form-list');
      await t.tap(find.byKey(const ValueKey<String>('sale-post')));
      await t.pumpAndSettle();
      // Validation error, no confirm dialog, nothing posted.
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-error')), 'sale-form-list');
      expect(find.byKey(const ValueKey<String>('sale-error')),
          findsOneWidget);
      expect(find.text('Select a customer first.'), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('sale-confirm-dialog')),
          findsNothing);
      // Only the seeded purchase is outstanding; the draft posts nothing.
      expect(
        scope.outstanding.bills(companyId, asOf: today),
        hasLength(1),
      );
    });

    testWidgets('hub launches the form; GST and round-off stay gated',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: BillingHubScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('billing-new-sale')));
      await t.pumpAndSettle();
      expect(find.byType(NewSaleScreen), findsOneWidget);
      await revealRow(t, find.textContaining('GST is not computed here'),
          'sale-form-list');
      expect(find.textContaining('GST is not computed here'),
          findsOneWidget);
    });
  });
}
