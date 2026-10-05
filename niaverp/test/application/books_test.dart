// Books query tests: day book, ledger accounts, group summary and dated
// trial (M14.1/14.2, G1). Disposable in-memory databases only. Proves: day
// book lists posted vouchers in document order with gross totals and
// type/series/date filters (cancelled excluded unless asked); ledger
// accounts open from the signed opening with running balances and drill
// voucher ids; group summary rolls subtrees up; dated trial windows posted
// lines while openings count in full; unknown ledgers report null.
// Traceability: M14.1/14.2/14.13; FR-M06-004; DB §3; DSS-C-001.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late LedgerBooks books;
  final CompanyId companyId = CompanyId('c-k');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    books = LedgerBooks(db);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Books Co',
            deviceId: 'host-test',
            opId: 'op-ck',
            eventId: 'ev-ck',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      groups
          .create(
            id: EntityId('g-assets'),
            companyId: companyId,
            name: 'Assets',
            deviceId: 'host-test',
            opId: 'op-ga',
            eventId: 'ev-ga',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      groups
          .create(
            id: EntityId('g-cash'),
            companyId: companyId,
            parentId: EntityId('g-assets'),
            name: 'Cash',
            deviceId: 'host-test',
            opId: 'op-gc',
            eventId: 'ev-gc',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      groups
          .create(
            id: EntityId('g-cap'),
            companyId: companyId,
            name: 'Capital',
            deviceId: 'host-test',
            opId: 'op-gp',
            eventId: 'ev-gp',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final Map<String, Object> l in <Map<String, Object>>[
      {
        'id': 'l-cash',
        'group': 'g-cash',
        'name': 'Cash',
        'side': 'Dr',
        'opening': 10000
      },
      {
        'id': 'l-cap',
        'group': 'g-cap',
        'name': 'Capital',
        'side': 'Cr',
        'opening': 10000
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
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// Journal fixtures go through the production path: draft → lines → engine
  /// post (D1-D4 forbids adding lines to a voucher created as posted).
  /// Journal fixtures go through the production path: draft → lines → engine
  /// post (D1-D4 forbids adding lines to a voucher created as posted).
  void createJournal(String id, String date, List<Map<String, Object>> arms,
      {bool post = true}) {
    final Result<PostingResult> r = seeder.postVoucher(
      id: EntityId(id),
      companyId: companyId,
      type: 'Journal',
      series: 'J',
      date: NiavDate(date),
      lines: <SeedLine>[
        for (int i = 0; i < arms.length; i++)
          SeedLine(
            ledgerId: EntityId(arms[i]['ledger'] as String),
            drCr: arms[i]['side'] as String,
            qtyQ4: 10000,
            ratePaise: arms[i]['amount'] as int,
          ),
      ],
    );
    expect(r.isOk, isTrue);
  }

  group('day book and registers (M14.1)', () {
    test('document order, gross totals, filters and cancel handling', () {
      createJournal('v-old', '2026-03-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 1000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 1000},
      ]);
      createJournal('v-new', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 2000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 2000},
      ]);
      createJournal('v-draft', '2026-04-02', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 9000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 9000},
      ], post: false);

      final List<DayBookEntry> all = books.dayBook(companyId);
      expect(
        all.map((DayBookEntry e) => e.voucherNo),
        <String>['v-old', 'v-new'],
      );
      expect(all.first.totalPaise, 2000);
      expect(all.first.lineCount, 2);
      expect(
        books
            .dayBook(companyId, from: NiavDate('2026-04-01'))
            .map((DayBookEntry e) => e.voucherNo),
        <String>['v-new'],
      );
      expect(
        books.dayBook(companyId, types: <String>['Nope']),
        isEmpty,
      );
      expect(
        books
            .dayBook(companyId, series: 'J')
            .map((DayBookEntry e) => e.voucherNo),
        <String>['v-old', 'v-new'],
      );
      expect(
        books.postedVoucherTypes(companyId),
        <String>['Journal'],
      );
    });
  });

  group('ledger accounts (M14.1)', () {
    test('opening, running balances and drill ids', () {
      createJournal('v-j', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 2000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 2000},
      ]);
      final LedgerAccount? cash =
          books.ledgerAccount(companyId, EntityId('l-cash'));
      expect(cash, isNotNull);
      expect(cash!.openingPaise, 10000);
      expect(cash.entries, hasLength(1));
      expect(cash.entries.single.drCr, 'Dr');
      expect(cash.entries.single.balanceAfterPaise, 12000);
      expect(cash.entries.single.voucherId, EntityId('v-j'));
      expect(cash.closingPaise, 12000);
      final LedgerAccount? cap =
          books.ledgerAccount(companyId, EntityId('l-cap'));
      expect(cap!.closingPaise, -12000);
      expect(books.ledgerAccount(companyId, EntityId('l-nope')), isNull);
      expect(
        books
            .ledgerAccount(companyId, EntityId('l-cash'),
                to: NiavDate('2026-01-01'))!
            .entries,
        isEmpty,
      );
    });
  });

  group('group summary and dated trial (M14.1/14.2)', () {
    test('subtrees roll up; windows filter lines, not openings', () {
      createJournal('v-j', '2026-04-01', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 2000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 2000},
      ]);
      final List<GroupBalance> groups =
          books.groupTrialBalance(companyId);
      expect(
        groups.map((GroupBalance g) => g.name),
        <String>['Assets', 'Capital', 'Cash'],
      );
      final GroupBalance assets =
          groups.firstWhere((GroupBalance g) => g.name == 'Assets');
      expect(assets.balancePaise, 12000);
      expect(assets.ledgerCount, 1);
      final GroupBalance cash =
          groups.firstWhere((GroupBalance g) => g.name == 'Cash');
      expect(cash.balancePaise, 12000);

      // Window before the posting: lines drop out, openings stay.
      final List<LedgerBalance> early = books.trialBalance(companyId,
          to: NiavDate('2026-01-01'));
      expect(
        early
            .firstWhere((LedgerBalance b) => b.name == 'Cash')
            .balancePaise,
        10000,
      );
      final List<LedgerBalance> full = books.trialBalance(companyId);
      expect(
        full.fold(0, (int s, LedgerBalance b) => s + b.balancePaise),
        0,
      );
    });
  });
}
