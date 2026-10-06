// Widget tests: books report (day book, trial balance, ledger account) over
// real queries. Real [LedgerBooks] + ledger/account-group repositories over a
// real migrated database — no fakes. Proves: the day book lists posted
// vouchers with gross totals and honours the type filter; the trial balance
// shows signed Dr/Cr rows, states Dr = Cr (or the exact difference) and
// carries the group summary; drilling a ledger shows opening, entries and
// closing; plus the empty, no-ledger, unknown-ledger and recoverable-error
// states. Validation and locked/conflict states are N/A (read-only reports
// post nothing). Main-app wiring waits on P-SQLIB.
// Traceability: M14.1; M14.2; FR-M06-004; OD-UI-001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/reports/books_report_screen.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late LedgerBooks books;
  late LedgerRepository ledgers;
  late VoucherRepository vouchers;
  late VoucherEngine engine;
  final CompanyId companyId = CompanyId('c-b');

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    ledgers = LedgerRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
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
    books = LedgerBooks(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Books Co',
            deviceId: 'host-test',
            opId: 'op-cb',
            eventId: 'ev-cb',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Party-requiring types (e.g. Sales Invoice) need a party on at least one
    // line at post time; every seeded voucher carries it (harmless for
    // Journal, which does not require one).
    expect(
      parties
          .create(
            id: EntityId('p-b'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pb',
            eventId: 'ev-pb',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, String> g in <Map<String, String>>[
      {'id': 'g-cash', 'name': 'Cash'},
      {'id': 'g-cap', 'name': 'Capital'},
      {'id': 'g-sus', 'name': 'Suspense'},
    ]) {
      expect(
        groups
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
    for (final Map<String, Object> l in <Map<String, Object>>[
      {
        'id': 'l-cash',
        'group': 'g-cash',
        'name': 'Cash',
        'side': 'Dr',
        'opening': 10000,
      },
      {
        'id': 'l-cap',
        'group': 'g-cap',
        'name': 'Capital',
        'side': 'Cr',
        'opening': 10000,
      },
    ]) {
      expect(
        ledgers
            .create(
              id: EntityId(l['id'] as String),
              companyId: companyId,
              groupId: EntityId(l['group'] as String),
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
    // D3-A1 posting fixture: role ledgers + party-ledger link (Sales
    // Invoice v-2 posts through the ledger arms).
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-b')]);
  });

  tearDown(() {
    // Idempotent: tests that close the database to read the error state may
    // close it again here without complaint.
    rawEngineOf(db).close();
  });

  /// One posted voucher carrying [arms] as ledger lines (the Dr/Cr arms of a
  /// balanced journal). Goes through the production path (D1-D4 forbids
  /// adding lines to a voucher created as posted): draft → lines → engine
  /// post. Lines go through the real repository, so every entry keeps its
  /// own drill id.
  void post(
    String id,
    String date,
    List<Map<String, Object>> arms, {
    String type = 'Journal',
  }) {
    final Result<Voucher> h = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: type,
      series: 'J',
      no: id,
      date: NiavDate(date),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(h.isOk, isTrue);
    int lineNo = 0;
    for (final Map<String, Object> arm in arms) {
      lineNo += 1;
      expect(
        vouchers
            .addLine(
              lineId: EntityId('$id-l$lineNo'),
              voucherId: EntityId(id),
              companyId: companyId,
              lineNo: lineNo,
              ledgerId: EntityId(arm['ledger'] as String),
              partyId: EntityId('p-b'),
              drCr: arm['side'] as String,
              qtyQ4: 10000,
              ratePaise: arm['amount'] as int,
              deviceId: 'host-test',
              opId: 'op-$id-l$lineNo',
              eventId: 'ev-$id-l$lineNo',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
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

  /// The row with [key], if it renders exactly this signed amount.
  Finder rowWith(String key, String text) => find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.text(text),
      );

  Widget buildScreen() {
    return MaterialApp(
      home: BooksReportScreen(
        companyId: companyId,
        books: books,
        ledgers: ledgers,
      ),
    );
  }

  group('day book (M14.1)', () {
    testWidgets('empty books show the empty state', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('daybook-empty')),
          findsOneWidget);
      expect(find.text('No posted vouchers.'), findsOneWidget);
    });

    testWidgets('lists posted vouchers with gross totals',
        (WidgetTester t) async {
      post('v-1', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 3000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 3000},
      ]);
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('daybook-list')), findsOneWidget);
      expect(find.text('v-1 · Journal'), findsOneWidget);
      expect(find.text('2026-04-01 · J · 2 lines'), findsOneWidget);
      // The row total is the gross of both lines: 3000 + 3000.
      expect(find.text('₹60.00'), findsOneWidget);
      expect(find.text('1 vouchers · gross ₹60.00'), findsOneWidget);
    });

    testWidgets('type filter narrows the register to one type',
        (WidgetTester t) async {
      post('v-1', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 1000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 1000},
      ]);
      post('v-2', '2026-04-02', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Cr', 'amount': 500},
        {'ledger': 'l-cap', 'side': 'Dr', 'amount': 500},
      ],
          type: 'Sales Invoice');
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      // v-1 (journal 1000 + 1000) + v-2 (content 500 + 500 plus D3-A1
      // posting arms Dr Party 1000 + Cr Sales 1000): SUM over all lines.
      expect(find.text('2 vouchers · gross ₹50.00'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('daybook-type-filter')));
      await t.pumpAndSettle();
      await t.tap(find
          .byKey(const ValueKey<String>('daybook-filter-Sales Invoice'))
          .last);
      await t.pumpAndSettle();
      expect(find.text('v-1 · Journal'), findsNothing);
      expect(find.text('v-2 · Sales Invoice'), findsOneWidget);
      expect(find.text('1 vouchers · gross ₹30.00'), findsOneWidget);

      // Back to all types: both rows again.
      await t.tap(find.byKey(const ValueKey<String>('daybook-type-filter')));
      await t.pumpAndSettle();
      await t.tap(find.text('All types').last);
      await t.pumpAndSettle();
      expect(find.text('v-1 · Journal'), findsOneWidget);
      expect(find.text('v-2 · Sales Invoice'), findsOneWidget);
    });

    testWidgets('closed database shows recoverable error with retry',
        (WidgetTester t) async {
      db.close();
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.text('Could not load day book'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Could not load day book'), findsOneWidget);
    });
  });

  group('trial balance (M14.2)', () {
    testWidgets('signed rows, Dr = Cr and group summary',
        (WidgetTester t) async {
      post('v-1', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 3000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 3000},
      ]);
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('trial-list')), findsOneWidget);
      // Cash: 10000 opening + 3000 Dr; Capital: 10000 opening + 3000 Cr.
      // A ledger row and its group row carry the same signed total, so
      // each assertion is scoped to the row it names. Group rows sit below
      // the fold once posting fixtures add masters, so each is scrolled
      // into view before asserting (finders skip offstage widgets).
      expect(rowWith('trial-ledger-l-cash', 'Dr ₹130.00'), findsOneWidget);
      expect(rowWith('trial-ledger-l-cap', 'Cr ₹130.00'), findsOneWidget);
      expect(find.text('Dr = Cr'), findsOneWidget);
      expect(find.text('Group summary'), findsOneWidget);
      await t.scrollUntilVisible(
          find.byKey(const ValueKey<String>('trial-group-g-cash')), 300.0);
      await t.pumpAndSettle();
      expect(rowWith('trial-group-g-cash', 'Dr ₹130.00'), findsOneWidget);
      expect(rowWith('trial-group-g-cash', '1 ledgers'), findsOneWidget);
      await t.scrollUntilVisible(
          find.byKey(const ValueKey<String>('trial-group-g-cap')), 300.0);
      await t.pumpAndSettle();
      expect(rowWith('trial-group-g-cap', 'Cr ₹130.00'), findsOneWidget);
      expect(rowWith('trial-group-g-cap', '1 ledgers'), findsOneWidget);
      await t.scrollUntilVisible(
          find.byKey(const ValueKey<String>('trial-group-g-sus')), 300.0);
      await t.pumpAndSettle();
      expect(rowWith('trial-group-g-sus', 'Dr ₹0.00'), findsOneWidget);
      expect(rowWith('trial-group-g-sus', '0 ledgers'), findsOneWidget);
      await t.scrollUntilVisible(
          find.byKey(const ValueKey<String>('trial-group-g-post')), 300.0);
      await t.pumpAndSettle();
      expect(rowWith('trial-group-g-post', 'Dr ₹0.00'), findsOneWidget);
      expect(rowWith('trial-group-g-post', '6 ledgers'), findsOneWidget);
    });

    testWidgets('cancelled vouchers drop out of the books',
        (WidgetTester t) async {
      post('v-1', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 1000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 1000},
      ]);
      db.executeArgs(
        "UPDATE voucher SET status = 'cancelled' WHERE voucher_id = ?",
        <Object?>['v-1'],
      );
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      // Openings alone: 10000 Dr against 10000 Cr.
      expect(rowWith('trial-ledger-l-cash', 'Dr ₹100.00'), findsOneWidget);
      expect(find.text('Dr = Cr'), findsOneWidget);
      // Only the selected tab is built, so no register list exists here.
      expect(find.byKey(const ValueKey<String>('daybook-list')), findsNothing);
    });

    testWidgets('an unbalanced book states the exact difference',
        (WidgetTester t) async {
      // A one-sided opening cannot come from a balanced posting; it proves
      // the report states the difference instead of hiding it.
      expect(
        ledgers
            .create(
              id: EntityId('l-sus'),
              companyId: companyId,
              groupId: EntityId('g-sus'),
              name: 'Suspense',
              openingSide: 'Dr',
              openingPaise: 4000,
              deviceId: 'host-test',
              opId: 'op-l-sus',
              eventId: 'ev-l-sus',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('trial-difference')),
          findsOneWidget);
      expect(find.text('Out of balance by ₹40.00'), findsOneWidget);
      expect(rowWith('trial-ledger-l-sus', 'Dr ₹40.00'), findsOneWidget);
    });

    testWidgets('no ledgers shows the empty state', (WidgetTester t) async {
      db.executeArgs(
        'DELETE FROM ledger WHERE company_id = ?', <Object?>['c-b'],
      );
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('trial-empty')), findsOneWidget);
      expect(find.text('No ledgers yet.'), findsOneWidget);
    });

    testWidgets('closed database shows recoverable error with retry',
        (WidgetTester t) async {
      db.close();
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      expect(find.text('Could not load trial balance'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Could not load trial balance'), findsOneWidget);
    });
  });

  group('ledger account (M14.1)', () {
    testWidgets('opening, entries and closing with drill ids',
        (WidgetTester t) async {
      post('v-1', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 3000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 3000},
      ]);
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('trial-ledger-l-cash')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('ledger-entries-list')),
          findsOneWidget);
      expect(find.text('Opening'), findsOneWidget);
      expect(find.text('v-1 · 2026-04-01'), findsOneWidget);
      expect(find.text('Dr'), findsOneWidget);
      expect(find.text('₹30.00 · bal ₹130.00'), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('ledger-closing')), findsOneWidget);
      expect(find.text('₹130.00'), findsOneWidget);
    });

    testWidgets('ledger with no entries reports its opening',
        (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.text('Trial Balance'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('trial-ledger-l-cash')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('ledger-empty')),
          findsOneWidget);
      expect(find.text('No entries. Opening ₹100.00'), findsOneWidget);
    });

    testWidgets('unknown ledger reports missing, never a crash',
        (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        home: LedgerAccountScreen(
          companyId: companyId,
          books: books,
          ledgerId: EntityId('l-nope'),
        ),
      ));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey<String>('ledger-missing')), findsOneWidget);
      expect(find.text('Ledger not found.'), findsOneWidget);
    });

    testWidgets('closed database shows recoverable error with retry',
        (WidgetTester t) async {
      db.close();
      await t.pumpWidget(MaterialApp(
        home: LedgerAccountScreen(
          companyId: companyId,
          books: books,
          ledgerId: EntityId('l-cash'),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text('Could not load ledger account'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Could not load ledger account'), findsOneWidget);
    });
  });
}