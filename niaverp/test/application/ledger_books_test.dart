// Posting-slice tests: derived ledger balances (M14 books foundation).
// Disposable in-memory databases only. Proves: opening sides sign
// balances, posted Dr/Cr lines move them, drafts never count, trial
// balance lists every ledger, and unknown ledgers report null.
// Full voucher→ledger auto-posting templates stay downstream — only
// explicitly ledger-referenced lines participate (nothing inferred).
// Traceability: FR-M06-004; DB §3 (ledger); DSS projection model.

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
  late LedgerRepository ledgers;
  late VoucherRepository vouchers;
  late LedgerBooks books;
  final CompanyId companyId = CompanyId('c-b');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    ledgers = LedgerRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
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
    expect(
      groups
          .create(
            id: EntityId('g-b'),
            companyId: companyId,
            name: 'Books',
            deviceId: 'host-test',
            opId: 'op-gb',
            eventId: 'ev-gb',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    int n = 0;
    for (final Map<String, Object> l in <Map<String, Object>>[
      {'id': 'l-cash', 'name': 'Cash', 'side': 'Dr', 'opening': 5000},
      {'id': 'l-cap', 'name': 'Capital', 'side': 'Cr', 'opening': 5000},
    ]) {
      n += 1;
      expect(
        ledgers
            .create(
              id: EntityId(l['id'] as String),
              companyId: companyId,
              groupId: EntityId('g-b'),
              name: l['name'] as String,
              openingSide: l['side'] as String,
              openingPaise: l['opening'] as int,
              deviceId: 'host-test',
              opId: 'op-l$n',
              eventId: 'ev-l$n',
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

  void createJournal(String id, List<Map<String, Object>> arms) {
    final Result<Voucher> h = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: 'Journal',
      series: 'J',
      no: id,
      date: NiavDate('2026-04-01'),
      status: 'posted',
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(h.isOk, isTrue);
    int lineNo = 0;
    for (final Map<String, Object> arm in arms) {
      lineNo += 1;
      final Result<VoucherLine> l = vouchers.addLine(
        lineId: EntityId('$id-l$lineNo'),
        voucherId: EntityId(id),
        companyId: companyId,
        lineNo: lineNo,
        ledgerId: EntityId(arm['ledger'] as String),
        drCr: arm['side'] as String,
        qtyQ4: 10000,
        ratePaise: arm['amount'] as int,
        deviceId: 'host-test',
        opId: 'op-$id-l$lineNo',
        eventId: 'ev-$id-l$lineNo',
        actor: 'tester',
      );
      expect(l.isOk, isTrue);
    }
  }

  group('ledger books (M14 foundation)', () {
    test('openings sign balances; posted lines move them', () {
      expect(books.ledgerBalance(companyId, EntityId('l-cash')), 5000);
      expect(books.ledgerBalance(companyId, EntityId('l-cap')), -5000);
      createJournal('v-j', <Map<String, Object>>[
        {'ledger': 'l-cash', 'side': 'Dr', 'amount': 2000},
        {'ledger': 'l-cap', 'side': 'Cr', 'amount': 2000},
      ]);
      expect(books.ledgerBalance(companyId, EntityId('l-cash')), 7000);
      expect(books.ledgerBalance(companyId, EntityId('l-cap')), -7000);
      expect(books.ledgerBalance(companyId, EntityId('l-nope')), isNull);
    });

    test('drafts never count; trial lists every ledger', () {
      final Result<Voucher> h = vouchers.create(
        id: EntityId('v-d'),
        companyId: companyId,
        type: 'Journal',
        series: 'J',
        no: 'v-d',
        date: NiavDate('2026-04-01'),
        deviceId: 'host-test',
        opId: 'op-v-d',
        eventId: 'ev-v-d',
        actor: 'tester',
      );
      expect(h.isOk, isTrue);
      final Result<VoucherLine> l = vouchers.addLine(
        lineId: EntityId('v-d-l1'),
        voucherId: EntityId('v-d'),
        companyId: companyId,
        lineNo: 1,
        ledgerId: EntityId('l-cash'),
        drCr: 'Dr',
        qtyQ4: 10000,
        ratePaise: 9000,
        deviceId: 'host-test',
        opId: 'op-v-d-l1',
        eventId: 'ev-v-d-l1',
        actor: 'tester',
      );
      expect(l.isOk, isTrue);
      expect(books.ledgerBalance(companyId, EntityId('l-cash')), 5000);
      final List<LedgerBalance> trial = books.trialBalance(companyId);
      expect(trial.map((LedgerBalance b) => b.name), <String>['Capital', 'Cash']);
      expect(
        trial.fold(0, (int s, LedgerBalance b) => s + b.balancePaise),
        0,
      );
    });
  });
}
