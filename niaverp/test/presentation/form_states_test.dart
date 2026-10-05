// Form-state tests: locked/conflict, draft preservation, row actions.
// Real backend (in-memory) + real engine — no fakes. Proves the six-state
// contract on the voucher draft form: duplicate numbers surface the
// conflict with the draft preserved (UX-001/UX-006); period locks refuse
// posting (locked state); blocked stock policy refuses with the draft
// intact; duplicate-row copies a line (UX-002); and the shell carries the
// offline indicator (UX-007).
// Traceability: UX-001/UX-002/UX-006/UX-007; FR-M04-002 (duplicates);
// D-M5 (period lock); FR-M13-001 (explicit policy).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/application/services/numbering.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
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
import 'package:niaverp/presentation/billing/voucher_form_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';
import 'package:niaverp/presentation/shell/niav_shell.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-fs');
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
    companies.create(
      id: companyId,
      name: 'States Co',
      deviceId: 'host-test',
      opId: 'op-cfs',
      eventId: 'ev-cfs',
      actor: 'tester',
    );
    parties.create(
      id: EntityId('p-fs'),
      companyId: companyId,
      name: 'Buyer',
      role: 'customer',
      deviceId: 'host-test',
      opId: 'op-pfs',
      eventId: 'ev-pfs',
      actor: 'tester',
    );
    items.create(
      id: EntityId('i-fs'),
      companyId: companyId,
      name: 'Widget',
      deviceId: 'host-test',
      opId: 'op-ifs',
      eventId: 'ev-ifs',
      actor: 'tester',
    );
    godowns.create(
      id: EntityId('g-fs'),
      companyId: companyId,
      name: 'Main',
      deviceId: 'host-test',
      opId: 'op-gfs',
      eventId: 'ev-gfs',
      actor: 'tester',
    );
    typeRepo.create(
      id: EntityId('t-si'),
      companyId: companyId,
      baseType: 'Sales Invoice',
      name: 'Sales Invoice',
      deviceId: 'host-test',
      opId: 'op-tsi',
      eventId: 'ev-tsi',
      actor: 'tester',
    );
    // Manual series only: numbers are entered, duplicates are possible.
    typeRepo.createSeries(
      seriesId: EntityId('s-man'),
      companyId: companyId,
      typeId: EntityId('t-si'),
      name: 'MAN',
      mode: 'manual',
      deviceId: 'host-test',
      opId: 'op-sman',
      eventId: 'ev-sman',
      actor: 'tester',
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

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

  /// Fill one manual-numbered draft and run it to the confirm dialog.
  Future<void> fillDraft(WidgetTester t, String no) async {
    await t.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: VoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: saleFormConfig,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-customer-field')), 'Buy');
    await t.pumpAndSettle();
    await t.tap(
        find.byKey(const ValueKey<String>('sale-customer-option-p-fs')));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-item-field')), 'Wid');
    await t.pumpAndSettle();
    await t.tap(
        find.byKey(const ValueKey<String>('sale-item-option-i-fs')));
    await t.pumpAndSettle();
    await revealRow(
        t, find.byKey(const ValueKey<String>('sale-line-qty-0')), 'sale-form-list');
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-line-qty-0')), '2');
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-line-rate-0')), '1000');
    await t.pumpAndSettle();
    await revealRow(
        t, find.byKey(const ValueKey<String>('sale-manual-no')), 'sale-form-list');
    await t.enterText(
        find.byKey(const ValueKey<String>('sale-manual-no')), no);
    await t.pumpAndSettle();
    await revealRow(
        t, find.byKey(const ValueKey<String>('sale-post')), 'sale-form-list');
    await t.tap(find.byKey(const ValueKey<String>('sale-post')));
    await t.pumpAndSettle();
  }

  Future<void> confirmPost(WidgetTester t) async {
    expect(
        find.byKey(const ValueKey<String>('sale-confirm-dialog')),
        findsOneWidget);
    await t.tap(find.byKey(const ValueKey<String>('sale-confirm-post')));
    await t.pumpAndSettle();
  }

  group('form states (UX-001/UX-006)', () {
    testWidgets('duplicate numbers conflict with the draft preserved',
        (WidgetTester t) async {
      await fillDraft(t, 'DUP-1');
      await confirmPost(t);
      // First post succeeds (stock goes negative under warn by default).
      expect(find.byType(VoucherFormScreen), findsNothing);

      // Same number again: conflict, draft intact, nothing new posted.
      await fillDraft(t, 'DUP-1');
      await confirmPost(t);
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-error')), 'sale-form-list');
      expect(find.textContaining('duplicate record'), findsOneWidget);
      // Draft preserved (UX-001): customer and line still entered.
      expect(
          find.byKey(const ValueKey<String>('sale-customer-set')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('sale-line-qty-0')),
          findsOneWidget);
      final List<OutstandingBill> held =
          scope.outstanding.bills(companyId, asOf: today);
      expect(held, hasLength(1));
    });

    testWidgets('period lock refuses posting (locked state)',
        (WidgetTester t) async {
      rawEngineOf(db).executeArgs(
        'INSERT INTO period_lock (lock_id, company_id, scope, date_from, '
        'date_to, status, locked_by, locked_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'lock-1',
          'c-fs',
          'company',
          '2026-01-01',
          '2026-12-31',
          'locked',
          'tester',
          1700000000000,
        ],
      );
      await fillDraft(t, 'LOCK-1');
      await confirmPost(t);
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-error')), 'sale-form-list');
      expect(find.textContaining('locked'), findsOneWidget);
      expect(
        scope.outstanding.bills(companyId, asOf: today),
        isEmpty,
      );
    });

    testWidgets('blocked policy refuses negative stock with draft intact',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: VoucherFormScreen(
            companyId: companyId,
            scope: scope,
            config: saleFormConfig,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-customer-field')), 'Buy');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('sale-customer-option-p-fs')));
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-item-field')), 'Wid');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('sale-item-option-i-fs')));
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-line-qty-0')), 'sale-form-list');
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-line-qty-0')), '5');
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-line-rate-0')), '1000');
      await t.pumpAndSettle();
      // Empty shelf + block policy: the post must refuse.
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-policy-block')), 'sale-form-list');
      await t.tap(find.byKey(const ValueKey<String>('sale-policy-block')));
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-manual-no')), 'sale-form-list');
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-manual-no')), 'BLK-1');
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-post')), 'sale-form-list');
      await t.tap(find.byKey(const ValueKey<String>('sale-post')));
      await t.pumpAndSettle();
      await confirmPost(t);
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-error')), 'sale-form-list');
      expect(find.textContaining('blocked'), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('sale-line-qty-0')),
          findsOneWidget);
      expect(
        scope.outstanding.bills(companyId, asOf: today),
        isEmpty,
      );
    });

    testWidgets('duplicate-row copies a line (UX-002)',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: VoucherFormScreen(
            companyId: companyId,
            scope: scope,
            config: saleFormConfig,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-item-field')), 'Wid');
      await t.pumpAndSettle();
      await t.tap(
          find.byKey(const ValueKey<String>('sale-item-option-i-fs')));
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-line-qty-0')), 'sale-form-list');
      await t.enterText(
          find.byKey(const ValueKey<String>('sale-line-rate-0')), '1000');
      await t.pumpAndSettle();
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-line-dupe-0')), 'sale-form-list');
      await t.tap(
          find.byKey(const ValueKey<String>('sale-line-dupe-0')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('sale-line-0')), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('sale-line-1')), findsOneWidget);
      await revealRow(
          t, find.byKey(const ValueKey<String>('sale-totals')), 'sale-form-list');
      // Two identical lines: gross doubles the single-line amount.
      expect(find.text('Gross: ₹2000.00 · Net: ₹2000.00'), findsOneWidget);
    });
  });

  group('offline indicator (UX-007)', () {
    testWidgets('shell shows the offline badge without a scope',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NiavShell(title: 'NiAvERP'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('offline-indicator')),
          findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });
  });
}
