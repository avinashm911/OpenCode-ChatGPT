// Invoice ledger-posting tests (D3-A1/A3/A6, C2): engine posts balanced
// ledger arms in the same transaction as stock. Disposable in-memory
// databases only. Proves per type: arm ledger/drCr/amount shapes follow the
// documented templates (MPL section 8); round-off persists up/down/exact per
// F-GST-006 (absent when zero); missing role ledgers refuse naming the role;
// cancel mirrors every ledger line in the same transaction; cancelled
// invoices leave ledger, outstanding and stock reports in agreement; trial
// balances to zero over a mixed set; two companies isolate postings; an
// injected mid-post failure rolls arms back with everything else.
// Traceability: MPL section 8; D-M4; F-GST-006; D3 (A1/A3/A6, C2/D).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/gst.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
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

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late LedgerBooks books;
  late VoucherSeeder seeder;
  final CompanyId companyId = CompanyId('c-i');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    books = LedgerBooks(db);
    seeder = VoucherSeeder(ctx,
        ops: ops, audit: audit, vouchers: vouchers, types: types);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Invoice Co',
            deviceId: 'host-test',
            opId: 'op-ci',
            eventId: 'ev-ci',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-i'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pi',
            eventId: 'ev-pi',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-i'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ii',
            eventId: 'ev-ii',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-i'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gi',
            eventId: 'ev-gi',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    seeder
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-i')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  /// One invoice line on [vid]: item i-i, godown g-i, party p-i.
  void addItemLine(String vid, String lid, int qtyQ4, int ratePaise,
      {int lineNo = 1}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: lineNo,
      itemId: EntityId('i-i'),
      godownId: EntityId('g-i'),
      partyId: EntityId('p-i'),
      qtyQ4: qtyQ4,
      ratePaise: ratePaise,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void createInvoice(String vid, String type) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(vid),
      companyId: companyId,
      type: type,
      series: 'S',
      no: vid,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$vid',
      eventId: 'ev-$vid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> post(String vid,
      {StockPolicy policy = StockPolicy.block}) {
    return engine.postWithStock(
      id: EntityId(vid),
      companyId: companyId,
      policy: policy,
      deviceId: 'host-test',
      opId: 'op-post-$vid',
      eventId: 'ev-post-$vid',
      actor: 'tester',
    );
  }

  /// Ledger arms of one voucher: ledger name → (drCr, amount).
  Map<String, (String, int)> armsOf(String vid) {
    final VoucherWithLines? got = vouchers.get(companyId, EntityId(vid));
    expect(got, isNotNull);
    final Map<String, (String, int)> out = <String, (String, int)>{};
    for (final VoucherLine l in got!.lines) {
      if (l.drCr == null || l.ledgerId == null) continue;
      final List<Map<String, Object?>> ledgers = db.queryArgs(
        'SELECT name FROM ledger WHERE ledger_id = ?',
        <Object?>[l.ledgerId!.value],
      );
      out[ledgers.single['name'] as String] =
          (l.drCr!, l.amountPaise);
    }
    return out;
  }

  int armCount(String vid) {
    final VoucherWithLines? got = vouchers.get(companyId, EntityId(vid));
    int n = 0;
    for (final VoucherLine l in got!.lines) {
      if (l.drCr != null) n += 1;
    }
    return n;
  }

  List<OutstandingBill> outstandingBills(CompanyId c) => OutstandingReport(db)
      .bills(c, asOf: NiavDate('2026-04-01'));

  group('invoice ledger arms (D3-A1/A3)', () {
    test('sales invoice posts Dr Party / Cr Sales / round-off up', () {
      createInvoice('v-s', 'Sales Invoice');
      addItemLine('v-s', 'v-s-l1', 20000, 50039); // net 100078, ro +22.
      // Empty book: allow prices the issue at zero cost (stock assertions
      // are not this test's subject; arms are).
      expect(post('v-s', policy: StockPolicy.allow).isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-s');
      expect(arms['Party Ledger'], ('Dr', 100100));
      expect(arms['Sales'], ('Cr', 100078));
      expect(arms['Round Off'], ('Cr', 22));
      expect(armCount('v-s'), 3);
    });

    test('round-off down and exact persist correctly', () {
      createInvoice('v-d', 'Sales Invoice');
      addItemLine('v-d', 'v-d-l1', 20000, 50022); // net 100044, ro -44.
      expect(post('v-d', policy: StockPolicy.allow).isOk, isTrue);
      final Map<String, (String, int)> down = armsOf('v-d');
      expect(down['Round Off'], ('Dr', 44));
      expect(down['Party Ledger'], ('Dr', 100000));

      createInvoice('v-e', 'Sales Invoice');
      addItemLine('v-e', 'v-e-l1', 20000, 50000); // net 100000, ro 0.
      expect(post('v-e', policy: StockPolicy.allow).isOk, isTrue);
      expect(armCount('v-e'), 2);
      expect(armsOf('v-e').containsKey('Round Off'), isFalse);
    });

    test('purchase invoice posts the mirror arms', () {
      createInvoice('v-p', 'Purchase Invoice');
      addItemLine('v-p', 'v-p-l1', 20000, 50039); // net 100078, ro +22.
      // postDraft takes the same transactional path (D3-D2 coverage).
      final Result<PostedTotals> posted = engine.postDraft(
        id: EntityId('v-p'),
        companyId: companyId,
        deviceId: 'host-test',
        opId: 'op-post-v-p',
        eventId: 'ev-post-v-p',
        actor: 'tester',
      );
      expect(posted.isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-p');
      expect(arms['Purchases'], ('Dr', 100078));
      expect(arms['Party Ledger'], ('Cr', 100100));
      expect(arms['Round Off'], ('Dr', 22));
    });

    test('returns mirror without tax arms', () {
      createInvoice('v-sr', 'Sales Return / Credit Note with items');
      addItemLine('v-sr', 'v-sr-l1', 10000, 5000); // net 5000, ro 0.
      expect(post('v-sr').isOk, isTrue);
      final Map<String, (String, int)> sr = armsOf('v-sr');
      expect(sr['Sales Return'], ('Dr', 5000));
      expect(sr['Party Ledger'], ('Cr', 5000));

      createInvoice('v-pr', 'Purchase Return / Debit Note with items');
      addItemLine('v-pr', 'v-pr-l1', 10000, 5000);
      expect(post('v-pr').isOk, isTrue);
      final Map<String, (String, int)> pr = armsOf('v-pr');
      expect(pr['Party Ledger'], ('Dr', 5000));
      expect(pr['Purchase Return'], ('Cr', 5000));
    });

    test('missing role ledgers refuse naming the role', () {
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      final PartyRepository bareParties =
          PartyRepository(ctx, ops: ops, audit: audit);
      final AccountGroupRepository bareGroups =
          AccountGroupRepository(ctx, ops: ops, audit: audit);
      final LedgerRepository bareLedgers =
          LedgerRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-bare'),
              name: 'Bare Co',
              deviceId: 'host-test',
              opId: 'op-cbare',
              eventId: 'ev-cbare',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        bareParties
            .create(
              id: EntityId('p-bare'),
              companyId: CompanyId('c-bare'),
              name: 'Buyer',
              role: 'customer',
              deviceId: 'host-test',
              opId: 'op-pbare',
              eventId: 'ev-pbare',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<Voucher> created = vouchers.create(
        id: EntityId('v-bare'),
        companyId: CompanyId('c-bare'),
        type: 'Sales Invoice',
        series: 'S',
        no: 'v-bare',
        date: NiavDate('2026-04-01'),
        deviceId: 'host-test',
        opId: 'op-v-bare',
        eventId: 'ev-v-bare',
        actor: 'tester',
      );
      expect(created.isOk, isTrue);
      expect(
        vouchers
            .addLine(
              lineId: EntityId('v-bare-l1'),
              voucherId: EntityId('v-bare'),
              companyId: CompanyId('c-bare'),
              lineNo: 1,
              partyId: EntityId('p-bare'),
              qtyQ4: 10000,
              ratePaise: 5000,
              deviceId: 'host-test',
              opId: 'op-v-bare-l1',
              eventId: 'ev-v-bare-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      Result<PostingResult> attempt() => engine.postWithStock(
            id: EntityId('v-bare'),
            companyId: CompanyId('c-bare'),
            policy: StockPolicy.block,
            deviceId: 'host-test',
            opId: 'op-post-v-bare',
            eventId: 'ev-post-v-bare',
            actor: 'tester',
          );
      // No party ledger linked: the party role is named.
      final Result<PostingResult> noPartyLedger = attempt();
      expect(noPartyLedger.isErr, isTrue);
      final AppError noPartyError =
          (noPartyLedger as Err<PostingResult>).error;
      expect(noPartyError.code, 'validation');
      expect(noPartyError.message, contains('party ledger'));
      // Party linked, but no Sales role ledger: the role is named.
      expect(
        bareGroups
            .create(
              id: EntityId('g-bare'),
              companyId: CompanyId('c-bare'),
              name: 'Misc',
              deviceId: 'host-test',
              opId: 'op-gbare',
              eventId: 'ev-gbare',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        bareLedgers
            .create(
              id: EntityId('l-other'),
              companyId: CompanyId('c-bare'),
              groupId: EntityId('g-bare'),
              name: 'Other',
              deviceId: 'host-test',
              opId: 'op-lother',
              eventId: 'ev-lother',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Party? before =
          bareParties.get(CompanyId('c-bare'), EntityId('p-bare'));
      expect(
        bareParties
            .update(
              id: EntityId('p-bare'),
              companyId: CompanyId('c-bare'),
              name: before!.name,
              role: before.role,
              ledgerId: 'l-other',
              deviceId: 'host-test',
              opId: 'op-pbare-link',
              eventId: 'ev-pbare-link',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<PostingResult> noSales = attempt();
      expect(noSales.isErr, isTrue);
      final AppError noSalesError = (noSales as Err<PostingResult>).error;
      expect(noSalesError.code, 'validation');
      expect(noSalesError.message, contains('Sales'));
    });

    test('arms roll back with the post on injected failure', () {
      createInvoice('v-z', 'Sales Invoice');
      addItemLine('v-z', 'v-z-l1', 20000, 5000);
      // Collide with the deterministic party-arm id: the arm INSERT fails,
      // so stock, allocations and arms must all roll back together.
      db.executeArgs(
        'INSERT INTO voucher_line (voucher_line_id, voucher_id, company_id, '
        'line_no, qty_q4, rate_paise, amount_paise, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'la-v-z-party',
          'v-z',
          'c-i',
          9,
          10000,
          100,
          100,
          1700000000000
        ],
      );
      final Result<PostingResult> failed = post('v-z');
      expect(failed.isErr, isTrue);
      expect(vouchers.get(companyId, EntityId('v-z'))?.voucher.status,
          'draft');
      expect(
        db.queryArgs(
          'SELECT SUM(qty_delta_q4) AS q FROM stock_movement '
          'WHERE company_id = ? AND voucher_line_id = ?',
          <Object?>['c-i', 'v-z-l1'],
        ).first['q'],
        isNull,
      );
    });
  });

  group('cancel reverses ledger arms; reports agree (D3-A6/C2)', () {
    test('cancelled purchase leaves ledger, outstanding and stock agreed',
        () {
      createInvoice('v-p', 'Purchase Invoice');
      addItemLine('v-p', 'v-p-l1', 20000, 5000); // net 10000, ro 0.
      expect(post('v-p').isOk, isTrue);
      expect(armCount('v-p'), 2);
      final Result<Voucher> cancelled = engine.cancelPosted(
        id: EntityId('v-p'),
        companyId: companyId,
        reason: 'wrong supplier',
        deviceId: 'host-test',
        opId: 'op-cancel-v-p',
        eventId: 'ev-cancel-v-p',
        actor: 'tester',
      );
      expect(cancelled.isOk, isTrue);
      // Every ledger-marked line gained a mirror with the opposite marker:
      // 2 posting arms + 2 compensating mirrors; originals untouched.
      expect(armCount('v-p'), 4);
      final List<Map<String, Object?>> mirrors = db.queryArgs(
        'SELECT dr_cr FROM voucher_line WHERE voucher_line_id LIKE ?',
        <Object?>['lr-%'],
      );
      expect(mirrors, hasLength(2));
      // Ledger books: the cancelled document drops out (posted-only reads).
      expect(books.ledgerBalance(companyId, EntityId('l-purchases')), 0);
      expect(
          books.trialBalance(companyId).fold(
              0, (int s, LedgerBalance b) => s + b.balancePaise),
          0);
      // Outstanding: the cancelled bill is gone.
      expect(
          outstandingBills(companyId),
          isEmpty,
      );
      // Stock: the purchase is fully reversed.
      expect(
        db.queryArgs(
          'SELECT SUM(qty_delta_q4) AS q FROM stock_movement '
          'WHERE company_id = ? AND item_id = ?',
          <Object?>['c-i', 'i-i'],
        ).first['q'],
        0,
      );
    });

    test('trial balances to zero over a mixed set', () {
      createInvoice('v-s', 'Sales Invoice');
      addItemLine('v-s', 'v-s-l1', 10000, 5000); // net 5000.
      expect(post('v-s', policy: StockPolicy.allow).isOk, isTrue);
      final Result<PostingResult> journal = seeder.postVoucher(
        id: EntityId('v-j'),
        companyId: companyId,
        type: 'Journal',
        series: 'J',
        date: NiavDate('2026-04-01'),
        lines: <SeedLine>[
          SeedLine(
              ledgerId: EntityId('l-purchases'),
              drCr: 'Dr',
              qtyQ4: 10000,
              ratePaise: 700),
          SeedLine(
              ledgerId: EntityId('l-party'),
              drCr: 'Cr',
              qtyQ4: 10000,
              ratePaise: 700),
        ],
      );
      expect(journal.isOk, isTrue);
      expect(
          books.trialBalance(companyId).fold(
              0, (int s, LedgerBalance b) => s + b.balancePaise),
          0);
    });

    test('two companies isolate ledger postings', () {
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-o'),
              name: 'Other Co',
              deviceId: 'host-test',
              opId: 'op-co',
              eventId: 'ev-co',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      seeder
        ..ensurePostingLedgers(CompanyId('c-o'), idSuffix: '-o')
        ..linkPartyLedgers(CompanyId('c-o'), const <EntityId>[],
            idSuffix: '-o');
      createInvoice('v-s', 'Sales Invoice');
      addItemLine('v-s', 'v-s-l1', 10000, 5000);
      expect(post('v-s', policy: StockPolicy.allow).isOk, isTrue);
      // c-o has no activity: its Sales ledger reads null, c-i is untouched
      // by anything outside its company.
      final List<Map<String, Object?>> other = db.queryArgs(
        'SELECT ledger_id FROM ledger WHERE company_id = ? AND name = ?',
        <Object?>['c-o', 'Sales'],
      );
      expect(
          books.ledgerBalance(
              CompanyId('c-o'), EntityId(other.single['ledger_id'] as String)),
          0);
      // c-i's own Sales ledger carries only its company's credit.
      expect(books.ledgerBalance(companyId, EntityId('l-sales')), -5000);
    });
  });

  group('GST calculation subset (D3-A2)', () {
    test('line GST with CGST/SGST split, odd remainder to CGST', () {
      final ({int gst, int cgst, int sgst}) even =
          lineGstPaise(netPaise: 10000, rateBps: 1800);
      expect(even.gst, 1800);
      expect(even.cgst, 900);
      expect(even.sgst, 900);
      final ({int gst, int cgst, int sgst}) odd =
          lineGstPaise(netPaise: 10006, rateBps: 1800);
      expect(odd.gst, 1801);
      expect(odd.cgst, 901);
      expect(odd.sgst, 900);
    });

    test('zero rate or zero base yields zero tax, never negative', () {
      expect(lineGstPaise(netPaise: 10000, rateBps: 0).gst, 0);
      expect(lineGstPaise(netPaise: 0, rateBps: 1800).gst, 0);
    });
  });
}
