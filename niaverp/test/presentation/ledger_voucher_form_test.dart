// Ledger voucher form widget tests (D3-B1/B2): real repositories over a
// real migrated database, no fakes. Proves: a balanced Contra posts through
// the engine and reaches the day book; unbalanced lines are refused with a
// validation state; a locked period shows the locked state; Debit Note
// requires a party; a posted voucher cancels with compensating entries.
// Traceability: FR-M06 (accounting vouchers); D3 (B1/B2).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
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
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/billing/ledger_voucher_form_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-lv');
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
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    scope = CompanyScope(
      companies: companies,
      parties: parties,
      items: items,
      aliases: AliasRepository(ctx, ops: ops, audit: audit),
      search: MasterSearch(db),
      godowns: godowns,
      stock: StockLevels(db),
      books: LedgerBooks(db),
      ledgers: ledgers,
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
            name: 'Ledger Form Co',
            deviceId: 'host-test',
            opId: 'op-clv',
            eventId: 'ev-clv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      groups
          .create(
            id: EntityId('g-lv'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-glv',
            eventId: 'ev-glv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, Object> l in <Map<String, Object>>[
      {'id': 'l-cash', 'name': 'Cash', 'side': 'Dr', 'opening': 0},
      {'id': 'l-cap', 'name': 'Capital', 'side': 'Cr', 'opening': 0},
    ]) {
      expect(
        ledgers
            .create(
              id: EntityId(l['id'] as String),
              companyId: companyId,
              groupId: EntityId('g-lv'),
              name: l['name'] as String,
              openingSide: l['side'] as String,
              openingPaise: l['opening'] as int,
              deviceId: 'host-test',
              opId: "op-${l['id']}",
              eventId: "ev-${l['id']}",
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      parties
          .create(
            id: EntityId('p-lv'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            ledgerId: 'l-cap',
            deviceId: 'host-test',
            opId: 'op-plv',
            eventId: 'ev-plv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// Scroll-then-act: form rows below the fold are offstage to default
  /// finders, so keys resolve with offstage nodes included, then the target's
  /// own Scrollable ancestor brings them into view.
  Future<void> tapVisible(WidgetTester t, ValueKey<String> key) async {
    final Finder f = find.byKey(key, skipOffstage: false);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> enterVisible(
      WidgetTester t, ValueKey<String> key, String text) async {
    final Finder f = find.byKey(key, skipOffstage: false);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.enterText(f, text);
    await t.pumpAndSettle();
  }

  Future<void> fillLine(
    WidgetTester t,
    String prefix,
    int i,
    String ledger,
    String side,
    String amount,
  ) async {
    await tapVisible(t, ValueKey<String>('$prefix-ledger-$i'));
    await t.tap(find.text(ledger).last);
    await t.pumpAndSettle();
    await tapVisible(t, ValueKey<String>('$prefix-side-$i-$side'));
    await enterVisible(t, ValueKey<String>('$prefix-amount-$i'), amount);
  }

  Future<void> fillHeader(WidgetTester t, String prefix, String no) async {
    await enterVisible(t, ValueKey<String>('$prefix-no'), no);
  }

  Future<void> postForm(WidgetTester t, String prefix) async {
    await tapVisible(t, ValueKey<String>('$prefix-post'));
  }

  Future<void> expectVisible(WidgetTester t, ValueKey<String> key) async {
    final Finder f = find.byKey(key, skipOffstage: false);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    expect(f, findsOneWidget);
  }

  group('ledger voucher forms (D3-B1/B2)', () {
    testWidgets('balanced Contra posts and reaches the day book',
        (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: contraFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await fillHeader(t, 'contra', '1');
      await fillLine(t, 'contra', 0, 'Cash', 'Dr', '100');
      await tapVisible(t, const ValueKey<String>('contra-add-line'));
      await fillLine(t, 'contra', 1, 'Capital', 'Cr', '100');
      await postForm(t, 'contra');
      await expectVisible(t, const ValueKey<String>('contra-success'));
      expect(
        scope.books
            .dayBook(companyId, types: <String>['Contra'])
            .single
            .totalPaise,
        20000,
      );
    });

    testWidgets('unbalanced lines are refused with a validation state',
        (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: contraFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await fillHeader(t, 'contra', '1');
      await fillLine(t, 'contra', 0, 'Cash', 'Dr', '100');
      await tapVisible(t, const ValueKey<String>('contra-add-line'));
      await fillLine(t, 'contra', 1, 'Capital', 'Cr', '50');
      await postForm(t, 'contra');
      await expectVisible(t, const ValueKey<String>('contra-error'));
      expect(find.text('Dr total must equal Cr total.'), findsOneWidget);
      expect(scope.vouchers.listByCompany(companyId), isEmpty);
    });

    testWidgets('locked period shows the locked state',
        (WidgetTester t) async {
      db.executeArgs(
        'INSERT INTO period_lock (lock_id, company_id, scope, date_from, '
        'date_to, status, locked_by, locked_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'lock-lv',
          'c-lv',
          'all',
          '2026-04-01',
          '2026-04-30',
          'locked',
          'admin',
          1700000000000,
        ],
      );
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: contraFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await fillHeader(t, 'contra', '1');
      await fillLine(t, 'contra', 0, 'Cash', 'Dr', '100');
      await tapVisible(t, const ValueKey<String>('contra-add-line'));
      await fillLine(t, 'contra', 1, 'Capital', 'Cr', '100');
      await postForm(t, 'contra');
      await expectVisible(t, const ValueKey<String>('contra-locked'));
    });

    testWidgets('Debit Note requires a party', (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: debitNoteFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await fillHeader(t, 'debitnote', '1');
      await fillLine(t, 'debitnote', 0, 'Cash', 'Dr', '100');
      await tapVisible(t, const ValueKey<String>('debitnote-add-line'));
      await fillLine(t, 'debitnote', 1, 'Capital', 'Cr', '100');
      await postForm(t, 'debitnote');
      await expectVisible(t, const ValueKey<String>('debitnote-error'));
      expect(find.textContaining('party'), findsWidgets);
    });

    testWidgets('receipt posts and surfaces as an advance',
        (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: receiptFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await tapVisible(
          t, const ValueKey<String>('receipt-party'));
      await t.tap(find.text('Buyer').last);
      await t.pumpAndSettle();
      await fillHeader(t, 'receipt', '1');
      await fillLine(t, 'receipt', 0, 'Cash', 'Dr', '500');
      await tapVisible(
          t, const ValueKey<String>('receipt-add-line'));
      await fillLine(t, 'receipt', 1, 'Capital', 'Cr', '500');
      await postForm(t, 'receipt');
      await expectVisible(t, const ValueKey<String>('receipt-success'));
      final List<AdvanceLine> advances =
          scope.outstanding.advances(companyId);
      expect(advances, hasLength(2));
      expect(
        advances.fold(0, (int s, AdvanceLine a) => s + a.unallocatedPaise),
        100000,
      );
    });

    testWidgets('posted voucher cancels with compensating entries',
        (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerVoucherFormScreen(
          companyId: companyId,
          scope: scope,
          config: journalFormConfig,
        ),
      ));
      await t.pumpAndSettle();
      await fillHeader(t, 'journal', '1');
      await fillLine(t, 'journal', 0, 'Cash', 'Dr', '100');
      await tapVisible(t, const ValueKey<String>('journal-add-line'));
      await fillLine(t, 'journal', 1, 'Capital', 'Cr', '100');
      await postForm(t, 'journal');
      await expectVisible(t, const ValueKey<String>('journal-success'));
      await enterVisible(
          t,
          const ValueKey<String>('journal-cancel-reason'),
          'entered wrong amount');
      await tapVisible(
          t, const ValueKey<String>('journal-cancel-posted'));
      await expectVisible(t, const ValueKey<String>('journal-notice'));
      final List<Voucher> posted =
          scope.vouchers.listByCompany(companyId);
      expect(posted.single.status, 'cancelled');
      expect(
        scope.vouchers.get(companyId, posted.single.id)!.lines,
        hasLength(4),
      );
    });
  });
}
