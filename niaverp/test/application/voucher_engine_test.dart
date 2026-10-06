// Shared voucher engine tests: one posting path, nineteen configurations.
// Disposable in-memory databases only. Proves: draft→posted with D-M4
// totals and lineage, unknown/unregistered types rejected, line rules per
// profile, period-lock enforcement, terminal-state immutability, reasoned
// compensating cancellation, and company isolation.
// Traceability: M04–M08; D-M4; D-M5(5); FR-M04-001; OD-DB-004.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
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
  late PartyRepository partyRepo;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    partyRepo = PartyRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    for (final String c in <String>['c-e', 'c-other']) {
      expect(
        companies
            .create(
              id: CompanyId(c),
              name: 'Co $c',
              deviceId: 'host-test',
              opId: 'op-$c',
              eventId: 'ev-$c',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      partyRepo
          .create(
            id: EntityId('p-e'),
            companyId: CompanyId('c-e'),
            name: 'Engine Party',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-pe',
            eventId: 'ev-pe',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(CompanyId('c-e'))
      ..linkPartyLedgers(
          CompanyId('c-e'), <EntityId>[EntityId('p-e')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void registerType(String id, String base, String name) {
    final Result<VoucherType> r = types.create(
      id: EntityId(id),
      companyId: CompanyId('c-e'),
      baseType: base,
      name: name,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void createDraft(
    String id,
    String company,
    String type, {
    String status = 'draft',
    String date = '2026-04-01',
  }) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      type: type,
      series: 'S',
      no: id,
      date: NiavDate(date),
      status: status,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void addLine(String vid, String lid, String company,
      {int qty = 20000,
      int rate = 999,
      int discAmt = 0,
      int discBps = 0,
      String? party,
      int line = 1}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: CompanyId(company),
      lineNo: line,
      qtyQ4: qty,
      ratePaise: rate,
      discountAmountPaise: discAmt,
      discountRateBps: discBps,
      partyId: party == null ? null : EntityId(party),
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostedTotals> post(String id, [String company = 'c-e']) {
    return engine.postDraft(
      id: EntityId(id),
      companyId: CompanyId(company),
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
  }

  void lockPeriod(String from, String to) {
    db.executeArgs(
      'INSERT INTO period_lock (lock_id, company_id, scope, date_from, '
      'date_to, status, locked_by, locked_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'lock-1',
        'c-e',
        'all',
        from,
        to,
        'locked',
        'admin',
        1700000000000,
      ],
    );
  }

  group('posting engine', () {
    test('posts a draft invoice with D-M4 totals and lineage', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-1', 'c-e', 'Sales Invoice');
      // 2.0 × Rs 9.99 → 1998 gross; explicit 98 discount → 1900 net.
      addLine('v-1', 'v-1-l1', 'c-e', discAmt: 98, party: 'p-e');
      final int opsBefore = ops.forEntity('c-e', 'voucher', 'v-1').length;
      final Result<PostedTotals> r = post('v-1');
      expect(r.isOk, isTrue);
      final PostedTotals t = (r as Ok<PostedTotals>).value;
      expect(t.lineCount, 1);
      expect(t.grossPaise, 1998);
      expect(t.netPaise, 1900);
      expect(vouchers.get(CompanyId('c-e'), EntityId('v-1'))?.voucher.status,
          'posted');
      expect(ops.forEntity('c-e', 'voucher', 'v-1').length, opsBefore + 1);
      expect(audit.forEntity('c-e', 'voucher', 'v-1'), isNotEmpty);
    });

    test('canonical slugs post without registration; custom needs it', () {
      createDraft('v-s', 'c-e', 'sales-invoice');
      addLine('v-s', 'v-s-l1', 'c-e', party: 'p-e');
      expect(post('v-s').isOk, isTrue);

      createDraft('v-c', 'c-e', 'My Retail Bill');
      addLine('v-c', 'v-c-l1', 'c-e', party: 'p-e');
      final Result<PostedTotals> unknown = post('v-c');
      expect(unknown.isErr, isTrue);
      expect((unknown as Err<PostedTotals>).error.code, 'validation');

      registerType('t-c', 'Sales Invoice', 'My Retail Bill');
      // Fresh voucher: the earlier attempt left v-c untouched (still draft).
      expect(post('v-c').isOk, isTrue);
    });

    test('line rules follow the type profile', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-empty', 'c-e', 'Sales Invoice');
      final Result<PostedTotals> noLines = post('v-empty');
      expect(noLines.isErr, isTrue);
      expect((noLines as Err<PostedTotals>).error.code, 'validation');

      // Payment captures header amounts, not item lines: posts lineless.
      createDraft('v-pay', 'c-e', 'Payment');
      expect(post('v-pay').isOk, isTrue);
    });

    test('locked-period dates are rejected; outside dates post', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      lockPeriod('2026-04-01', '2026-04-30');
      createDraft('v-locked', 'c-e', 'Sales Invoice', date: '2026-04-15');
      addLine('v-locked', 'v-locked-l1', 'c-e', party: 'p-e');
      final Result<PostedTotals> r = post('v-locked');
      expect(r.isErr, isTrue);
      expect((r as Err<PostedTotals>).error.code, 'validation');
      expect(vouchers
          .get(CompanyId('c-e'), EntityId('v-locked'))?.voucher.status, 'draft');

      createDraft('v-open', 'c-e', 'Sales Invoice', date: '2026-05-02');
      addLine('v-open', 'v-open-l1', 'c-e', party: 'p-e');
      expect(post('v-open').isOk, isTrue);
    });

    test('only draft/resumed post; posted is terminal here', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-h', 'c-e', 'Sales Invoice', status: 'held');
      addLine('v-h', 'v-h-l1', 'c-e');
      expect(post('v-h').isErr, isTrue);

      // A resumed voucher reaches posting through the held-bill queue
      // (D1-D2: held → resumed via updateHeldStatus, then the engine posts;
      // lines are added while held since D1-D4 keeps resumed non-editable).
      createDraft('v-r', 'c-e', 'Sales Invoice', status: 'held');
      addLine('v-r', 'v-r-l1', 'c-e', party: 'p-e');
      final Result<Voucher> resumed = vouchers.updateHeldStatus(
        id: EntityId('v-r'),
        companyId: CompanyId('c-e'),
        status: 'resumed',
        deviceId: 'host-test',
        opId: 'op-resume-v-r',
        eventId: 'ev-resume-v-r',
        actor: 'tester',
      );
      expect(resumed.isOk, isTrue);
      expect(post('v-r').isOk, isTrue);
      final Result<PostedTotals> again = post('v-r');
      expect(again.isErr, isTrue);
      expect((again as Err<PostedTotals>).error.code, 'validation');
    });

    test('journal with no ledger lines still posts (D1-D9)', () {
      // D1-D9: must-balance types (Journal, Contra, Debit/Credit Note without
      // items) with zero ledger lines are NOT rejected. The documents allow
      // empty: M06 accounting vouchers capture header amounts rather than
      // item rows (no payment-line columns exist in the approved schema), so
      // the profile sets requiresLines=false exactly for them and
      // checkJournalBalance only constrains lines that carry Dr/Cr markers.
      // DECISIONS.md names no non-empty rule for these types.
      registerType('t-j', 'Journal', 'Journal');
      createDraft('v-empty', 'c-e', 'Journal');
      expect(post('v-empty').isOk, isTrue);
      expect(vouchers.get(CompanyId('c-e'), EntityId('v-empty'))?.voucher.status,
          'posted');
    });

    test('compensating cancellation needs a reason; terminal stays shut', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-1', 'c-e', 'Sales Invoice');
      addLine('v-1', 'v-1-l1', 'c-e', party: 'p-e');
      expect(post('v-1').isOk, isTrue);

      Result<Voucher> move(String tag, String reason) {
        return engine.cancelPosted(
          id: EntityId('v-1'),
          companyId: CompanyId('c-e'),
          reason: reason,
          deviceId: 'host-test',
          opId: 'op-$tag',
          eventId: 'ev-$tag',
          actor: 'tester',
        );
      }

      final Result<Voucher> noReason = move('noreason', '   ');
      expect(noReason.isErr, isTrue);
      final Result<Voucher> done = move('ok', 'returned goods');
      expect(done.isOk, isTrue);
      expect((done as Ok<Voucher>).value.status, 'cancelled');
      // Cancelled is terminal: neither repost nor recancel passes.
      expect(post('v-1').isErr, isTrue);
      expect(move('twice', 'again').isErr, isTrue);
      // Drafts cannot be cancelled through the correction path.
      createDraft('v-d', 'c-e', 'Sales Invoice');
      final Result<Voucher> bad = engine.cancelPosted(
        id: EntityId('v-d'),
        companyId: CompanyId('c-e'),
        reason: 'oops',
        deviceId: 'host-test',
        opId: 'op-bad',
        eventId: 'ev-bad',
        actor: 'tester',
      );
      expect(bad.isErr, isTrue);
    });

    test('party-requiring types need a party on at least one line', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-np', 'c-e', 'Sales Invoice');
      addLine('v-np', 'v-np-l1', 'c-e');
      final Result<PostedTotals> bare = post('v-np');
      expect(bare.isErr, isTrue);
      expect((bare as Err<PostedTotals>).error.code, 'validation');
      // A second line carrying the party satisfies the rule.
      addLine('v-np', 'v-np-l2', 'c-e', party: 'p-e', line: 2);
      final Result<PostedTotals> fed = post('v-np');
      expect(fed.isOk, isTrue);
      expect((fed as Ok<PostedTotals>).value.lineCount, 2);
    });

    test('foreign-company vouchers are invisible to the engine', () {
      registerType('t-si', 'Sales Invoice', 'Sales Invoice');
      createDraft('v-x', 'c-other', 'Sales Invoice');
      final Result<PostedTotals> r = post('v-x', 'c-e');
      expect(r.isErr, isTrue);
      expect((r as Err<PostedTotals>).error.code, 'validation');
    });
  });
}
