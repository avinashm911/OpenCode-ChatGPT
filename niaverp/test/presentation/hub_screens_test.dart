// Widget tests: home dashboard, billing hub and reports hub over real
// queries. Real repositories/queries over a real migrated database — no
// fakes. Proves: home shows the company name, master counts and the open
// position; billing lists open bills with amounts/states and the empty
// state; the reports hub routes to both live report screens.
// Traceability: OD-UI-001; FR-M14-001; UI-009/UI-010.

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
import 'package:niaverp/presentation/billing/new_purchase_screen.dart';
import 'package:niaverp/presentation/home/home_dashboard_screen.dart';
import 'package:niaverp/presentation/inventory/new_transfer_screen.dart';
import 'package:niaverp/presentation/reports/books_report_screen.dart';
import 'package:niaverp/presentation/reports/outstanding_report_screen.dart';
import 'package:niaverp/presentation/reports/reports_hub_screen.dart';
import 'package:niaverp/presentation/reports/stock_report_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-h');
  final NiavDate today = NiavDate('2026-04-01');

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
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
            name: 'Hub Co',
            deviceId: 'host-test',
            opId: 'op-ch',
            eventId: 'ev-ch',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-h'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-ph',
            eventId: 'ev-ph',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-h'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ih',
            eventId: 'ev-ih',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    final Result<Voucher> h = vouchers.create(
      id: EntityId('v-h'),
      companyId: companyId,
      type: 'Sales Invoice',
      series: 'S',
      no: 'v-h',
      date: NiavDate('2026-03-20'),
      status: 'posted',
      deviceId: 'host-test',
      opId: 'op-vh',
      eventId: 'ev-vh',
      actor: 'tester',
    );
    expect(h.isOk, isTrue);
    expect(
      vouchers
          .addLine(
            lineId: EntityId('v-h-l1'),
            voucherId: EntityId('v-h'),
            companyId: companyId,
            lineNo: 1,
            partyId: EntityId('p-h'),
            qtyQ4: 10000,
            ratePaise: 5000,
            deviceId: 'host-test',
            opId: 'op-vh-l1',
            eventId: 'ev-vh-l1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  group('home dashboard (OD-UI-001)', () {
    testWidgets('shows company, counts and the open position',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: HomeDashboardScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Hub Co'), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('home-party-count')),
          findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('₹50.00 outstanding'), findsOneWidget);
    });
  });

  group('billing hub (OD-UI-001)', () {
    testWidgets('lists open bills with amounts and states',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: BillingHubScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('billing-bills-list')),
          findsOneWidget);
      expect(find.text('v-h · Sales Invoice'), findsOneWidget);
      expect(find.text('open · 12d'), findsOneWidget);
      expect(find.text('₹50.00'), findsOneWidget);
    });
  });

  group('billing entries (M04/M05/M11)', () {
    testWidgets('hub routes to sale, purchase and transfer forms',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: BillingHubScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('billing-new-purchase')));
      await t.pumpAndSettle();
      expect(find.byType(NewPurchaseScreen), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('billing-new-transfer')));
      await t.pumpAndSettle();
      expect(find.byType(NewTransferScreen), findsOneWidget);
    });
  });

  group('reports hub (OD-UI-001)', () {
    testWidgets('routes to all three live report screens',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: ReportsHubScreen(companyId: companyId, scope: scope),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('reports-hub-stock')));
      await t.pumpAndSettle();
      expect(find.byType(StockReportScreen), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('reports-hub-outstanding')));
      await t.pumpAndSettle();
      expect(find.byType(OutstandingReportScreen), findsOneWidget);
      expect(find.text('v-h'), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('reports-hub-books')));
      await t.pumpAndSettle();
      expect(find.byType(BooksReportScreen), findsOneWidget);
    });
  });
}
