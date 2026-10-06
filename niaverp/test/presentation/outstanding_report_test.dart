// Widget tests: outstanding report over real queries.
// Real OutstandingReport + voucher repository over a real migrated database
// (allocations via the real bill-allocation repository) — no fakes. Proves:
// empty state, open bills listed with open amounts/states/ages plus the
// totals header, and the recoverable-error state with retry.
// Traceability: FR-M14-001 (outstanding reports).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/reports/outstanding_report_screen.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late OutstandingReport report;
  late VoucherRepository vouchers;
  late VoucherEngine engine;
  final CompanyId companyId = CompanyId('c-w');
  final NiavDate asOf = NiavDate('2026-04-01');

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    final VoucherTypeRepository types =
        VoucherTypeRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    report = OutstandingReport(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Report Co',
            deviceId: 'host-test',
            opId: 'op-cw',
            eventId: 'ev-cw',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-w'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pw',
            eventId: 'ev-pw',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// Bills the report must see are built through the production path (D1-D4
  /// forbids adding lines to a voucher created as posted): draft → line →
  /// engine post.
  void createBill(String id, int amount) {
    final Result<Voucher> h = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: 'Sales Invoice',
      series: 'S',
      no: id,
      date: NiavDate('2026-03-20'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(h.isOk, isTrue);
    final Result<VoucherLine> l = vouchers.addLine(
      lineId: EntityId('$id-l1'),
      voucherId: EntityId(id),
      companyId: companyId,
      lineNo: 1,
      partyId: EntityId('p-w'),
      qtyQ4: 10000,
      ratePaise: amount,
      deviceId: 'host-test',
      opId: 'op-$id-l1',
      eventId: 'ev-$id-l1',
      actor: 'tester',
    );
    expect(l.isOk, isTrue);
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
  }

  Widget buildScreen() {
    return MaterialApp(
      home: OutstandingReportScreen(
        companyId: companyId,
        report: report,
        asOf: asOf,
      ),
    );
  }

  group('outstanding report (FR-M14-001)', () {
    testWidgets('empty database shows the empty state',
        (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('outstanding-empty')),
          findsOneWidget);
      expect(find.text('No outstanding bills.'), findsOneWidget);
    });

    testWidgets('open bills list amounts, states and totals',
        (WidgetTester t) async {
      createBill('v-a', 5000);
      createBill('v-b', 3000);
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('outstanding-bills-list')),
          findsOneWidget);
      expect(find.text('v-a'), findsOneWidget);
      expect(find.text('v-b'), findsOneWidget);
      // 5000 + 3000 open, both dated 2026-03-20 → 12 days old.
      expect(find.text('₹50.00'), findsOneWidget);
      expect(find.text('₹30.00'), findsOneWidget);
      expect(
          find.text('Sales Invoice · open · 12d', skipOffstage: false),
          findsWidgets);
      expect(find.text('2 bills · ₹80.00 open'), findsOneWidget);
    });

    testWidgets('closed database shows recoverable error with retry',
        (WidgetTester t) async {
      db.close();
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.text('Could not load outstanding'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Could not load outstanding'), findsOneWidget);
    });
  });
}
