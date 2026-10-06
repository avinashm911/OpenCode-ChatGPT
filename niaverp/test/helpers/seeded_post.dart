// Shared seeding helper for posted vouchers (D1 / D4).
//
// Since D1-D4 a line may only be added while its voucher is a draft or held
// working document, so a report/query fixture cannot "create it as posted and
// then add lines". This helper performs the real production sequence instead:
// create draft → add lines → post through the single [VoucherEngine]
// (validation, Dr=Cr, period lock, stock effects and lineage all apply). Tests
// that only need stored history therefore exercise the same path the app does.
// Traceability: D1 (D4, D3).

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

/// One line of a seeded voucher.
class SeedLine {
  const SeedLine({
    this.itemId,
    this.ledgerId,
    this.partyId,
    this.godownId,
    this.drCr,
    required this.qtyQ4,
    required this.ratePaise,
  });

  final EntityId? itemId;
  final EntityId? ledgerId;
  final EntityId? partyId;
  final EntityId? godownId;
  final String? drCr;
  final int qtyQ4;
  final int ratePaise;
}

/// Creates and posts vouchers through the real engine over one context.
class VoucherSeeder {
  VoucherSeeder(
    this.ctx, {
    required this.ops,
    required this.audit,
    VoucherRepository? vouchers,
    VoucherTypeRepository? types,
  })  : vouchers = vouchers ?? VoucherRepository(ctx, ops: ops, audit: audit),
        types = types ?? VoucherTypeRepository(ctx, ops: ops, audit: audit) {
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: this.vouchers,
      types: this.types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
  }

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;
  final VoucherRepository vouchers;
  final VoucherTypeRepository types;
  late final VoucherEngine engine;

  /// Ensure the documented D3-A1 posting role ledgers exist (MPL section 8
  /// arm names). [idSuffix] scopes the helper's own ids when several
  /// companies share one database (ids are global TEXT PRIMARY KEYs); master
  /// NAMES stay exact because the engine resolves roles by name. Throws on
  /// any failure (loud setUp helper, never silent).
  void ensurePostingLedgers(CompanyId companyId, {String idSuffix = ''}) {
    final AccountGroupRepository groups =
        AccountGroupRepository(ctx, ops: ops, audit: audit);
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    final Result<AccountGroup> group = groups.create(
      id: EntityId('g-post$idSuffix'),
      companyId: companyId,
      name: 'Posting',
      deviceId: 'host-test',
      opId: 'op-gpost-${companyId.value}$idSuffix',
      eventId: 'ev-gpost-${companyId.value}$idSuffix',
      actor: 'tester',
    );
    if (group.isErr) {
      throw StateError('posting fixture: group not created');
    }
    const Map<String, String> roles = <String, String>{
      'Sales': 'l-sales',
      'Purchases': 'l-purchases',
      'Sales Return': 'l-sales-return',
      'Purchase Return': 'l-purchase-return',
      'Round Off': 'l-round-off',
    };
    roles.forEach((String name, String id) {
      final Result<Ledger> created = ledgers.create(
        id: EntityId('$id$idSuffix'),
        companyId: companyId,
        groupId: EntityId('g-post$idSuffix'),
        name: name,
        deviceId: 'host-test',
        opId: 'op-$id-${companyId.value}$idSuffix',
        eventId: 'ev-$id-${companyId.value}$idSuffix',
        actor: 'tester',
      );
      if (created.isErr) {
        throw StateError('posting fixture: ledger $name not created');
      }
    });
  }

  /// Link [partyIds] to a party-control ledger for D3-A1 invoice arms.
  /// Throws on any failure (loud setUp helper, never silent).
  void linkPartyLedgers(CompanyId companyId, List<EntityId> partyIds,
      {String idSuffix = ''}) {
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    final Result<Ledger> control = ledgers.create(
      id: EntityId('l-party$idSuffix'),
      companyId: companyId,
      groupId: EntityId('g-post$idSuffix'),
      name: 'Party Ledger',
      deviceId: 'host-test',
      opId: 'op-l-party-${companyId.value}$idSuffix',
      eventId: 'ev-l-party-${companyId.value}$idSuffix',
      actor: 'tester',
    );
    if (control.isErr) {
      throw StateError('posting fixture: party ledger not created');
    }
    for (final EntityId partyId in partyIds) {
      final Party? before = parties.get(companyId, partyId);
      if (before == null) {
        throw StateError('posting fixture: party ${partyId.value} missing');
      }
      final Result<Party> linked = parties.update(
        id: partyId,
        companyId: companyId,
        name: before.name,
        role: before.role,
        ledgerId: 'l-party$idSuffix',
        gstin: before.gstin,
        state: before.state,
        mobile: before.mobile,
        address: before.address,
        terms: before.terms,
        deviceId: 'host-test',
        opId: 'op-link-${partyId.value}',
        eventId: 'ev-link-${partyId.value}',
        actor: 'tester',
      );
      if (linked.isErr) {
        throw StateError('posting fixture: party ${partyId.value} not linked');
      }
    }
  }

  /// Create a draft [type] voucher with [lines], then post it. Returns the
  /// engine result so callers can assert on warnings/pending effects.
  Result<PostingResult> postVoucher({
    required EntityId id,
    required CompanyId companyId,
    required String type,
    required String series,
    required NiavDate date,
    required List<SeedLine> lines,
    String? no,
    StockPolicy policy = StockPolicy.block,
  }) {
    final Result<Voucher> created = vouchers.create(
      id: id,
      companyId: companyId,
      type: type,
      series: series,
      no: no ?? id.value,
      date: date,
      deviceId: 'host-test',
      opId: 'op-create-${id.value}',
      eventId: 'ev-create-${id.value}',
      actor: 'tester',
    );
    if (created.isErr) {
      final AppError e = (created as Err<Voucher>).error;
      return err<PostingResult>(e.code, e.message);
    }
    int lineNo = 0;
    for (final SeedLine line in lines) {
      lineNo += 1;
      final Result<VoucherLine> added = vouchers.addLine(
        lineId: EntityId('${id.value}-l$lineNo'),
        voucherId: id,
        companyId: companyId,
        lineNo: lineNo,
        itemId: line.itemId,
        ledgerId: line.ledgerId,
        partyId: line.partyId,
        godownId: line.godownId,
        drCr: line.drCr,
        qtyQ4: line.qtyQ4,
        ratePaise: line.ratePaise,
        deviceId: 'host-test',
        opId: 'op-${id.value}-l$lineNo',
        eventId: 'ev-${id.value}-l$lineNo',
        actor: 'tester',
      );
      if (added.isErr) {
        final AppError e = (added as Err<VoucherLine>).error;
        return err<PostingResult>(e.code, e.message);
      }
    }
    return engine.postWithStock(
      id: id,
      companyId: companyId,
      policy: policy,
      deviceId: 'host-test',
      opId: 'op-post-${id.value}',
      eventId: 'ev-post-${id.value}',
      actor: 'tester',
    );
  }
}