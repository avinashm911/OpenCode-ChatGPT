// Settlement posting tests: reconciliation at post (FR-M06-001/002).
// Disposable in-memory databases only. Proves: a receipt posts with
// allocations inside its own line total and reports the advance remainder;
// over-allocation against the settlement line aborts the whole post
// (draft stays draft, no rows); pre-existing allocations count toward the
// cap; full allocation leaves no remainder; unknown settlement lines are
// rejected.
// Traceability: FR-M06-001 (cannot exceed permitted); FR-M06-002
// (reconcile to receipt, advances); G0-SCH-003.

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

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late BillAllocationRepository allocRepo;
  final CompanyId companyId = CompanyId('c-s');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    allocRepo = BillAllocationRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: allocRepo,
    );
    expect(
      companies
          .create(
            id: companyId,
            name: 'Settle Co',
            deviceId: 'host-test',
            opId: 'op-cs',
            eventId: 'ev-cs',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    for (final String t in <String>[
      'Sales Invoice',
      'Receipt',
      'Payment',
    ]) {
      expect(
        types
            .create(
              id: EntityId('t-$t'),
              companyId: companyId,
              baseType: t,
              name: t,
              deviceId: 'host-test',
              opId: 'op-t-$t',
              eventId: 'ev-t-$t',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      parties
          .create(
            id: EntityId('p-s'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-ps',
            eventId: 'ev-ps',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    VoucherSeeder(ctx, ops: ops, audit: audit)
      ..ensurePostingLedgers(companyId)
      ..linkPartyLedgers(companyId, <EntityId>[EntityId('p-s')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createVoucher(String id, String type) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: companyId,
      type: type,
      series: 'S',
      no: id,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  // Amount line: qty 1.0 × rate = amount paise. Receipt/invoice lines carry
  // the party (Receipt requires it); payment lines need none.
  void addAmountLine(String vid, String lid, int amount, {bool party = true}) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: 1,
      partyId: party ? EntityId('p-s') : null,
      qtyQ4: 10000,
      ratePaise: amount,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> postWith(
      String id, List<AllocationSpec> allocs) {
    return engine.postWithStock(
      id: EntityId(id),
      companyId: companyId,
      policy: StockPolicy.allow,
      allocations: allocs,
      deviceId: 'host-test',
      opId: 'op-post-$id',
      eventId: 'ev-post-$id',
      actor: 'tester',
    );
  }

  group('settlement reconciliation at post (FR-M06-001/002)', () {
    test('partial receipt settles part and reports the advance', () {
      createVoucher('v-inv', 'Sales Invoice');
      addAmountLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-rcpt', 'Receipt');
      addAmountLine('v-rcpt', 'v-rcpt-l1', 5000);
      final Result<PostingResult> r = postWith('v-rcpt', <AllocationSpec>[
        AllocationSpec(
          sourceLineId: EntityId('v-inv-l1'),
          settlementLineId: EntityId('v-rcpt-l1'),
          amountPaise: 2000,
        ),
      ]);
      expect(r.isOk, isTrue);
      final PostingResult pr = (r as Ok<PostingResult>).value;
      expect(pr.unallocated, hasLength(1));
      expect(pr.unallocated.single.settlementLineId, EntityId('v-rcpt-l1'));
      expect(pr.unallocated.single.permittedPaise, 5000);
      expect(pr.unallocated.single.allocatedPaise, 2000);
      expect(pr.unallocated.single.remainderPaise, 3000);
      expect(
        voucherOpenBalance(db, companyId, EntityId('v-inv')),
        3000,
      );
      expect(
        vouchers.get(companyId, EntityId('v-rcpt'))?.voucher.status,
        'posted',
      );
    });

    test('over-allocation against the settlement line aborts all', () {
      createVoucher('v-inv', 'Sales Invoice');
      addAmountLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-rcpt', 'Receipt');
      addAmountLine('v-rcpt', 'v-rcpt-l1', 5000);
      final Result<PostingResult> r = postWith('v-rcpt', <AllocationSpec>[
        AllocationSpec(
          sourceLineId: EntityId('v-inv-l1'),
          settlementLineId: EntityId('v-rcpt-l1'),
          amountPaise: 6000,
        ),
      ]);
      expect(r.isErr, isTrue);
      expect((r as Err<PostingResult>).error.code, 'validation');
      expect(vouchers.get(companyId, EntityId('v-rcpt'))?.voucher.status,
          'draft');
      expect(
        voucherOpenBalance(db, companyId, EntityId('v-inv')),
        5000,
      );
      expect(
        allocRepo.activeForSource(companyId, EntityId('v-inv-l1')),
        isEmpty,
      );
    });

    test('posted history counts toward the settlement cap', () {
      createVoucher('v-inv1', 'Sales Invoice');
      addAmountLine('v-inv1', 'v-inv1-l1', 5000);
      createVoucher('v-rcpt', 'Receipt');
      addAmountLine('v-rcpt', 'v-rcpt-l1', 5000);
      expect(
        postWith('v-rcpt', <AllocationSpec>[
          AllocationSpec(
            sourceLineId: EntityId('v-inv1-l1'),
            settlementLineId: EntityId('v-rcpt-l1'),
            amountPaise: 2000,
          ),
        ]).isOk,
        isTrue,
      );
      // The receipt line already settled 2000: 4000 more does not fit.
      createVoucher('v-inv2', 'Sales Invoice');
      addAmountLine('v-inv2', 'v-inv2-l1', 5000);
      final Result<PostingResult> over = postWith('v-inv2', <AllocationSpec>[
        AllocationSpec(
          sourceLineId: EntityId('v-inv2-l1'),
          settlementLineId: EntityId('v-rcpt-l1'),
          amountPaise: 4000,
        ),
      ]);
      expect(over.isErr, isTrue);
      expect(vouchers.get(companyId, EntityId('v-inv2'))?.voucher.status,
          'draft');
      // The fitting remainder commits and leaves no advance.
      final Result<PostingResult> fits = postWith('v-inv2', <AllocationSpec>[
        AllocationSpec(
          sourceLineId: EntityId('v-inv2-l1'),
          settlementLineId: EntityId('v-rcpt-l1'),
          amountPaise: 3000,
        ),
      ]);
      expect(fits.isOk, isTrue);
      expect((fits as Ok<PostingResult>).value.unallocated, isEmpty);
      expect(
        voucherOpenBalance(db, companyId, EntityId('v-inv2')),
        2000,
      );
    });

    test('unknown settlement lines rejected', () {
      createVoucher('v-inv', 'Sales Invoice');
      addAmountLine('v-inv', 'v-inv-l1', 5000);
      createVoucher('v-rcpt', 'Receipt');
      addAmountLine('v-rcpt', 'v-rcpt-l1', 5000);
      final Result<PostingResult> r = postWith('v-rcpt', <AllocationSpec>[
        AllocationSpec(
          sourceLineId: EntityId('v-inv-l1'),
          settlementLineId: EntityId('l-nope'),
          amountPaise: 1000,
        ),
      ]);
      expect(r.isErr, isTrue);
    });
  });
}
