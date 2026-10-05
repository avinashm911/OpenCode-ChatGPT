// Shared voucher posting engine — one engine, many configurations.
// Every voucher type flows through the same lifecycle, validation and
// lineage; types differ only by their static profile (required lines),
// resolved from the 19 canonical names (DECISIONS.md) or a registered
// company type derived from a known base (FR-M04-001).
//
// What posting DOES here (all schema-grounded, nothing invented):
// validate type/status/lines/period, compute D-M4 totals, move
// draft|resumed → posted and posted → cancelled (compensating correction
// with mandatory reason), every move with operation + audit lineage.
// Posted rows are otherwise never rewritten (immutability).
//
// What posting does NOT do yet (recorded boundaries, not silent gaps):
// tax/charge/round-off persistence (no approved columns; math itself lives
// in validators.dart), number generation (FR-M04-002 scope TBD), approval
// gates (P2). Ledger refs are validated for existence (m013/m014 masters);
// full voucher→ledger auto-posting templates stay downstream (only
// explicitly ledger-referenced lines participate).
// Traceability: M04/M05/M06/M07/M08; D-M4; DSS-C-001/004; OD-DB-004;
// D-M5(5) period lock; FR-M04-001/002.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/accounting/costing.dart';
import 'package:niaverp/data/accounting/settlement.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/migrations/validators.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

/// Static per-type configuration. Both flags are schema- and FR-grounded,
/// never invented posting behavior:
/// - [requiresLines]: false only for M06 accounting vouchers, whose FR rows
///   capture header amounts rather than item rows (no payment-line columns
///   exist in the approved schema).
/// - [requiresParty]: true exactly where the FR required-data rows name a
///   party/supplier/customer (FR-M05-001/002/003/004, FR-M06-002/005,
///   FR-M07-001, FR-M08-001/002); false for account/location/journal flows
///   whose FR rows name ledgers or locations instead (FR-M06-001/003/004,
///   FR-M07-002/003). Party linkage itself is verified on stored lines
///   (DSS puts party on the line): at least one line must carry it.
class VoucherProfile {
  const VoucherProfile({required this.requiresLines, required this.requiresParty});

  final bool requiresLines;
  final bool requiresParty;
}

/// Profile per canonical voucher name (DECISIONS.md order).
const Map<String, VoucherProfile> kVoucherProfiles = <String, VoucherProfile>{
  'Sales Invoice': VoucherProfile(requiresLines: true, requiresParty: true),
  'Purchase Invoice':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Sales Return / Credit Note with items':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Purchase Return / Debit Note with items':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Payment': VoucherProfile(requiresLines: false, requiresParty: false),
  'Receipt': VoucherProfile(requiresLines: false, requiresParty: true),
  'Contra': VoucherProfile(requiresLines: false, requiresParty: false),
  'Journal': VoucherProfile(requiresLines: false, requiresParty: false),
  'Debit Note without items':
      VoucherProfile(requiresLines: false, requiresParty: true),
  'Credit Note without items':
      VoucherProfile(requiresLines: false, requiresParty: true),
  'Delivery Note / Delivery Challan':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Material Issue to Party':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Material Receive from Party':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Stock Transfer': VoucherProfile(requiresLines: true, requiresParty: false),
  'Stock Journal': VoucherProfile(requiresLines: true, requiresParty: false),
  'Sales Quotation / Proforma Invoice':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Purchase Quotation':
      VoucherProfile(requiresLines: true, requiresParty: true),
  'Sales Order': VoucherProfile(requiresLines: true, requiresParty: true),
  'Purchase Order':
      VoucherProfile(requiresLines: true, requiresParty: true),
};

/// Posted totals computed by D-M4 arithmetic (discount rule: explicit amount
/// wins, else rate basis points — P-DISC-PREC via lineNet).
class PostedTotals {
  const PostedTotals({
    required this.lineCount,
    required this.grossPaise,
    required this.netPaise,
  });

  final int lineCount;
  final int grossPaise;
  final int netPaise;
}

PostedTotals summarizeLines(List<VoucherLine> lines) {
  int gross = 0;
  int net = 0;
  for (final VoucherLine l in lines) {
    gross += l.amountPaise;
    net += lineNet(
        l.amountPaise, l.discountAmountPaise, l.discountRateBps);
  }
  return PostedTotals(
      lineCount: lines.length, grossPaise: gross, netPaise: net);
}

/// One bill-allocation instruction for the posting pipeline. Lines must
/// pre-exist; amounts are validated against open balances at post time.
class AllocationSpec {
  const AllocationSpec({
    required this.sourceLineId,
    required this.settlementLineId,
    required this.amountPaise,
  });

  final EntityId sourceLineId;
  final EntityId settlementLineId;
  final int amountPaise;
}

/// Outcome of a full posting: totals, written movement ids, policy
/// warnings, unallocated (advance) remainders on settlement lines, and
/// structurally pending effects (explicit, never silent).
class PostingResult {
  const PostingResult({
    required this.totals,
    required this.movementIds,
    required this.warnings,
    this.unallocated = const <UnallocatedAmount>[],
    required this.pendingEffects,
  });

  final PostedTotals totals;
  final List<String> movementIds;
  final List<String> warnings;

  /// Settlement lines of this post left with remainder > 0: the advance /
  /// unallocated amount available for later bills (FR-M06-002 advances).
  final List<UnallocatedAmount> unallocated;
  final List<String> pendingEffects;
}

/// Unallocated remainder on one settlement line after a posting: the line
/// permitted [permittedPaise], [allocatedPaise] consumed by this post plus
/// history, and the [remainderPaise] advance available for later bills.
class UnallocatedAmount {
  const UnallocatedAmount({
    required this.settlementLineId,
    required this.permittedPaise,
    required this.allocatedPaise,
    required this.remainderPaise,
  });

  final EntityId settlementLineId;
  final int permittedPaise;
  final int allocatedPaise;
  final int remainderPaise;
}

/// Canonical types that never post: quotations and orders live in
/// open/convert/fulfil/close lifecycles (FR-M08-001/002) — `posted` is not
/// one of their states, so the engine rejects them here.
const Set<String> _nonPostableTypes = <String>{
  'Sales Quotation / Proforma Invoice',
  'Purchase Quotation',
  'Sales Order',
  'Purchase Order',
};

/// Stock direction per canonical type: -1 issue, +1 receipt, 0 sign-of-qty
/// (stock journal adjustments and transfer legs), absent = no stock
/// movement. Directions come from the FR downstream rows (M05 "stock
/// out/in", M07 delivery "stock out", FR-M07-002 transfer from/to locations,
/// FR-M07-003 "qty in/out", returns "stock in/out"). A line's movement sign
/// is type-direction × line-qty-sign, so a flipped-sign line moves the
/// opposite way at its own economics (IN legs layer at line cost, OUT legs
/// consume per the valuation method). Transfer legs are signed-qty at zero
/// rate (negative = OUT source, positive = IN destination; value flows from
/// the book — this also satisfies the G0 amount CHECK, which forbids
/// negative line amounts). Material Issue/Receive stay pending (R1b
/// document-flow slice) via [_pendingEffects], never silently skipped.
const Map<String, int> _stockDirections = <String, int>{
  'Sales Invoice': -1,
  'Delivery Note / Delivery Challan': -1,
  'Purchase Return / Debit Note with items': -1,
  'Purchase Invoice': 1,
  'Sales Return / Credit Note with items': 1,
  'Stock Transfer': 0,
  'Stock Journal': 0,
};

/// The single posting engine for all voucher types.
class VoucherEngine {
  VoucherEngine(
    this.ctx, {
    required this.ops,
    required this.audit,
    required this.vouchers,
    required this.types,
    required this.allocationRepo,
  });

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;
  final VoucherRepository vouchers;
  final VoucherTypeRepository types;
  final BillAllocationRepository allocationRepo;

  MigrationDb get _db => ctx.db;

  /// Resolve [typeText] to a profile: canonical name, canonical slug, or a
  /// company-registered type name whose base is known. Null when unknown.
  VoucherProfile? resolveProfile(CompanyId companyId, String typeText) {
    final String? canonical = resolveCanonicalName(companyId, typeText);
    if (canonical == null) return null;
    return kVoucherProfiles[canonical];
  }

  /// Canonical name behind [typeText] (itself, its slug, or its registered
  /// base). Null when the type is unknown to this company.
  String? resolveCanonicalName(CompanyId companyId, String typeText) {
    for (final String name in kVoucherProfiles.keys) {
      if (typeText == name || typeText == voucherBaseSlug(name)) return name;
    }
    for (final VoucherType t in types.listByCompany(companyId)) {
      if (typeText == t.name) {
        for (final String name in kVoucherProfiles.keys) {
          if (t.baseType == name || t.baseType == voucherBaseSlug(name)) {
            return name;
          }
        }
      }
    }
    return null;
  }

  /// True when [dateIso] (YYYY-MM-DD) falls inside any active (not unlocked)
  /// period lock of the company. Scope vocabulary is pending, so any active
  /// company lock blocks — the safe direction, recorded as a boundary.
  bool isDateLocked(CompanyId companyId, String dateIso) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT 1 FROM period_lock WHERE company_id = ? '
      'AND unlocked_at IS NULL AND date_from <= ? AND ? <= date_to LIMIT 1',
      <Object?>[companyId.value, dateIso, dateIso],
    );
    return rows.isNotEmpty;
  }

  /// Post a draft (or resumed counter bill): validate everything the schema
  /// supports, compute totals, move to `posted` with lineage.
  Result<PostedTotals> postDraft({
    required EntityId id,
    required CompanyId companyId,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (deviceId.isEmpty) {
      return err('validation', 'device id must not be empty');
    }
    final Result<_Postable> checked = _validatePostable(id, companyId);
    if (checked.isErr) {
      final AppError e = (checked as Err<_Postable>).error;
      return err(e.code, e.message);
    }
    final Result<Voucher> moved = _moveStatus(
      id: id,
      companyId: companyId,
      status: 'posted',
      action: 'post',
      deviceId: deviceId,
      opId: opId,
      eventId: eventId,
      actor: actor,
    );
    if (moved.isErr) {
      final AppError e = (moved as Err<Voucher>).error;
      return err(e.code, e.message);
    }
    return ok((checked as Ok<_Postable>).value.totals);
  }

  /// Shared validation path for every posting entry point: existence,
  /// postable status, known type, line/profile rules, journal balance,
  /// period lock. One path, never forked.
  Result<_Postable> _validatePostable(EntityId id, CompanyId companyId) {
    final VoucherWithLines? current = vouchers.get(companyId, id);
    if (current == null) {
      return err('validation', 'voucher does not exist in this company');
    }
    final Voucher v = current.voucher;
    if (v.status != 'draft' && v.status != 'resumed') {
      return err('validation',
          'only draft or resumed vouchers can be posted (held bills resume first)');
    }
    final VoucherProfile? profile = resolveProfile(companyId, v.type);
    if (profile == null) {
      return err('validation', 'unknown voucher type: ${v.type}');
    }
    final String? canonical = resolveCanonicalName(companyId, v.type);
    if (canonical != null && _nonPostableTypes.contains(canonical)) {
      return err('validation',
          '$canonical documents open, convert and close — they are not posted');
    }
    if (profile.requiresLines && current.lines.isEmpty) {
      return err('validation', 'voucher requires at least one line');
    }
    if (profile.requiresParty &&
        current.lines.every((VoucherLine l) => l.partyId == null)) {
      return err('validation',
          'voucher type requires a party reference on at least one line');
    }
    final String? journalError = checkJournalBalance(current.lines);
    if (journalError != null) {
      return err('validation', journalError);
    }
    // Ledger grounding (FR-M03-002 downstream: accounting postings): every
    // line carrying a ledger ref must resolve in this company. Ledger refs
    // are plain TEXT (m010) — the check lives here, on the single posting
    // path, so Payment/Receipt/Contra/Journal cannot post against ghosts.
    for (final VoucherLine l in current.lines) {
      final EntityId? ledgerRef = l.ledgerId;
      if (ledgerRef == null) continue;
      final List<Map<String, Object?>> ledger = _db.queryArgs(
        'SELECT 1 FROM ledger WHERE company_id = ? AND ledger_id = ? LIMIT 1',
        <Object?>[companyId.value, ledgerRef.value],
      );
      if (ledger.isEmpty) {
        return err(
            'validation', 'voucher references an unknown ledger in this company');
      }
    }
    if (isDateLocked(companyId, v.date.iso)) {
      return err('validation', 'voucher date falls in a locked period');
    }
    return ok(_Postable(
        voucher: v,
        lines: current.lines,
        totals: summarizeLines(current.lines)));
  }

  /// Journal-balance rule (FR-M06-004): when any line carries a Dr/Cr
  /// marker, total Dr must equal total Cr (stored gross amounts). Lines
  /// without markers are non-ledger lines (items, charges) and do not
  /// participate. Null when balanced or inapplicable, else the message.
  String? checkJournalBalance(List<VoucherLine> lines) {
    int dr = 0;
    int cr = 0;
    bool any = false;
    for (final VoucherLine l in lines) {
      if (l.drCr == 'Dr') {
        any = true;
        dr += l.amountPaise;
      } else if (l.drCr == 'Cr') {
        any = true;
        cr += l.amountPaise;
      }
    }
    if (!any || dr == cr) return null;
    return 'Dr total must equal Cr total';
  }

  /// Compensating correction for a posted voucher: posted → cancelled with
  /// a mandatory reason. The posted row is never rewritten; the cancellation
  /// is a new audited event (immutability + compensating history).
  Result<Voucher> cancelPosted({
    required EntityId id,
    required CompanyId companyId,
    required String reason,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (reason.trim().isEmpty || deviceId.isEmpty) {
      return err('validation', 'cancellation reason and device id are required');
    }
    final VoucherWithLines? current = vouchers.get(companyId, id);
    if (current == null) {
      return err('validation', 'voucher does not exist in this company');
    }
    if (current.voucher.status != 'posted') {
      return err('validation', 'only posted vouchers can be cancelled here');
    }
    return _moveStatus(
      id: id,
      companyId: companyId,
      status: 'cancelled',
      action: 'correct',
      deviceId: deviceId,
      opId: opId,
      eventId: eventId,
      actor: actor,
      reason: reason.trim(),
    );
  }

  /// Full posting pipeline in ONE database transaction: shared validation,
  /// stock effects, explicit bill allocations, then the draft→posted move
  /// with lineage. Any failure aborts everything — a posted invoice never
  /// leaves accounting without stock, stock without audit, or half-created
  /// allocations. GST persistence and ledger-template auto-posting stay
  /// downstream (recorded per post in [PostingResult.pendingEffects]).
  Result<PostingResult> postWithStock({
    required EntityId id,
    required CompanyId companyId,
    required StockPolicy policy,
    List<AllocationSpec> allocations = const <AllocationSpec>[],
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (deviceId.isEmpty) {
      return err('validation', 'device id must not be empty');
    }
    try {
      PostingResult? done;
      _db.runInTransaction(() {
        final Result<_Postable> checked = _validatePostable(id, companyId);
        if (checked.isErr) {
          final AppError e = (checked as Err<_Postable>).error;
          throw TxFailure(e);
        }
        final _Postable p = (checked as Ok<_Postable>).value;
        final String? canonical =
            resolveCanonicalName(companyId, p.voucher.type);
        final _StockPlan plan =
            _planStockEffects(companyId, p, canonical, policy);
        for (final _StockWrite w in plan.writes) {
          _writeStockMovement(companyId, w, deviceId);
        }
        // Settlement reconciliation (FR-M06-001/002): every settlement line
        // caps what it can settle at its permitted amount (|line total|),
        // counting both posted history and this post's specs. Remainders
        // are reported as advances — never silently absorbed, never
        // over-allocated. Validated before any allocation writes.
        final List<UnallocatedAmount> unallocated =
            _reconcileSettlements(companyId, allocations);
        int n = 0;
        for (final AllocationSpec spec in allocations) {
          n += 1;
          allocationRepo.allocateTx(
            id: EntityId('al-${id.value}-$n'),
            companyId: companyId,
            sourceLineId: spec.sourceLineId,
            settlementLineId: spec.settlementLineId,
            amountPaise: spec.amountPaise,
            date: p.voucher.date,
            deviceId: deviceId,
            opId: 'op-al-${id.value}-$n',
            eventId: 'ev-al-${id.value}-$n',
            actor: actor,
          );
        }
        _moveStatusInTx(
          id: id,
          companyId: companyId,
          status: 'posted',
          action: 'post',
          deviceId: deviceId,
          opId: opId,
          eventId: eventId,
          actor: actor,
        );
        done = PostingResult(
          totals: p.totals,
          movementIds: plan.movementIds,
          warnings: plan.warnings,
          unallocated: unallocated,
          pendingEffects: _pendingEffects(canonical),
        );
      });
      return ok(done!);
    } on TxFailure catch (f) {
      return err(f.error.code, f.error.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-post');
      return err(be.code, be.message);
    }
  }

  /// Settlement-side reconciliation for one posting: group specs by
  /// settlement line, verify each line's permitted amount covers posted
  /// history plus this post (FR-M06-001/002), and report every line left
  /// with remainder as an advance. Throws [TxFailure] on any breach or on
  /// an unknown settlement line; the adapter rolls everything back.
  List<UnallocatedAmount> _reconcileSettlements(
    CompanyId companyId,
    List<AllocationSpec> allocations,
  ) {
    final Map<String, int> wantedByLine = <String, int>{};
    for (final AllocationSpec spec in allocations) {
      wantedByLine[spec.settlementLineId.value] =
          (wantedByLine[spec.settlementLineId.value] ?? 0) +
              spec.amountPaise;
    }
    final List<UnallocatedAmount> out = <UnallocatedAmount>[];
    for (final MapEntry<String, int> e in wantedByLine.entries) {
      final EntityId lineId = EntityId(e.key);
      final List<Map<String, Object?>> lines = _db.queryArgs(
        'SELECT amount_paise FROM voucher_line '
        'WHERE company_id = ? AND voucher_line_id = ?',
        <Object?>[companyId.value, lineId.value],
      );
      if (lines.isEmpty) {
        throw TxFailure(const AppError(
            'validation', 'allocation references an unknown line'));
      }
      final int total = lines.first['amount_paise'] as int;
      final int pre = allocationRepo.allocatedAgainstSettlement(
          companyId, lineId);
      final List<String> errors = checkSettlementCap(
        settlementLineId: lineId.value,
        lineTotalPaise: total,
        preAllocatedPaise: pre,
        newAllocationsPaise: e.value,
      );
      if (errors.isNotEmpty) {
        throw TxFailure(AppError('validation', errors.first));
      }
      final int remainder = total.abs() - (pre + e.value);
      if (remainder > 0) {
        out.add(UnallocatedAmount(
          settlementLineId: lineId,
          permittedPaise: total.abs(),
          allocatedPaise: pre + e.value,
          remainderPaise: remainder,
        ));
      }
    }
    return out;
  }

  /// Effects the pipeline deliberately does NOT produce (explicit per post,
  /// never silent). GST needs verified schemas (G0-VER-003); ledger-template
  /// auto-posting needs posting templates; material issue/receive need the
  /// R1b document-flow slice (their lines post the document but move no
  /// stock in V1).
  List<String> _pendingEffects(String? canonical) {
    final List<String> out = <String>[];
    if (canonical == 'Material Issue to Party' ||
        canonical == 'Material Receive from Party') {
      out.add('material issue/receive stock effects pending R1b slice');
    }
    const Set<String> taxed = <String>{
      'Sales Invoice',
      'Purchase Invoice',
      'Sales Return / Credit Note with items',
      'Purchase Return / Debit Note with items',
      'Delivery Note / Delivery Challan',
    };
    if (canonical != null && taxed.contains(canonical)) {
      out.add('gst persistence pending verified schemas');
    }
    return out;
  }

  /// Plan stock writes for every stock-carrying line (item + godown
  /// present). Other lines are non-stock (services, charges, notes) and
  /// correctly produce no movement. Each leg's direction is
  /// type-direction × qty-sign; IN legs layer at line cost, OUT legs consume
  /// the book per the resolved valuation method. Transfers additionally
  /// require balanced per-item legs across distinct godowns (FR-M07-002
  /// source ≠ destination); their IN legs carry the consumed OUT value so
  /// transfers preserve book value. Throws [TxFailure] on any rule breach.
  _StockPlan _planStockEffects(
    CompanyId companyId,
    _Postable p,
    String? canonical,
    StockPolicy policy,
  ) {
    final int? direction =
        canonical == null ? null : _stockDirections[canonical];
    final List<_StockWrite> writes = <_StockWrite>[];
    final List<String> movementIds = <String>[];
    final List<String> warnings = <String>[];
    final List<VoucherLine> stockLines = <VoucherLine>[
      for (final VoucherLine line in p.lines)
        if (line.itemId != null && line.godownId != null) line,
    ];
    if (direction == null) {
      return _StockPlan(
          writes: writes, movementIds: movementIds, warnings: warnings);
    }
    for (final VoucherLine line in stockLines) {
      if (line.qtyQ4 == 0) {
        throw TxFailure(const AppError(
            'validation', 'stock lines need nonzero quantity'));
      }
    }
    if (canonical == 'Stock Transfer') {
      _checkTransferPairing(stockLines);
      // OUT legs first (value flows out of sources), then IN legs funded by
      // the consumed value so the transfer preserves book value per item.
      final Map<String, int> outValueByItem = <String, int>{};
      for (final VoucherLine line in stockLines) {
        if (line.qtyQ4 >= 0) continue;
        final _OutboundCost cost = _priceOutbound(
            companyId, line, -line.qtyQ4, policy, warnings);
        outValueByItem[line.itemId!.value] =
            (outValueByItem[line.itemId!.value] ?? 0) + cost.totalValuePaise;
        writes.add(_StockWrite(
          movementId: 'mv-${line.id.value}',
          layerId: null,
          companyId: companyId,
          itemId: line.itemId!,
          godownId: line.godownId!,
          lineId: line.id,
          deltaQ4: line.qtyQ4,
          unitCostPaise: cost.unitCostPaise,
          costSource: cost.source,
          consumes: cost.consumes,
        ));
        movementIds.add('mv-${line.id.value}');
      }
      final Map<String, int> inQtyByItem = <String, int>{};
      for (final VoucherLine line in stockLines) {
        if (line.qtyQ4 <= 0) continue;
        inQtyByItem[line.itemId!.value] =
            (inQtyByItem[line.itemId!.value] ?? 0) + line.qtyQ4;
      }
      final Map<String, int> inValueGiven = <String, int>{};
      final List<VoucherLine> inLegs = <VoucherLine>[
        for (final VoucherLine line in stockLines) if (line.qtyQ4 > 0) line,
      ];
      for (int i = 0; i < inLegs.length; i++) {
        final VoucherLine line = inLegs[i];
        final String item = line.itemId!.value;
        final int funded = outValueByItem[item] ?? 0;
        final int share;
        if (i == inLegs.length - 1 ||
            inLegs.sublist(i).every((VoucherLine l) =>
                l.itemId!.value != item ||
                l == line)) {
          // Last leg of its item takes the remainder (rounding sink).
          share = funded - (inValueGiven[item] ?? 0);
        } else {
          share = ((funded * line.qtyQ4) + inQtyByItem[item]! ~/ 2) ~/
              inQtyByItem[item]!;
          inValueGiven[item] = (inValueGiven[item] ?? 0) + share;
        }
        writes.add(_inboundWrite(companyId, line, valuePaise: share));
        movementIds.add('mv-${line.id.value}');
      }
      return _StockPlan(
          writes: writes, movementIds: movementIds, warnings: warnings);
    }
    for (final VoucherLine line in stockLines) {
      final int delta = direction == 0
          ? line.qtyQ4
          : direction * (line.qtyQ4 < 0 ? -1 : 1) * line.qtyQ4.abs();
      if (delta > 0) {
        writes.add(_inboundWrite(companyId, line,
            valuePaise: line.amountPaise.abs()));
      } else {
        final _OutboundCost cost = _priceOutbound(
            companyId, line, -delta, policy, warnings);
        writes.add(_StockWrite(
          movementId: 'mv-${line.id.value}',
          layerId: null,
          companyId: companyId,
          itemId: line.itemId!,
          godownId: line.godownId!,
          lineId: line.id,
          deltaQ4: delta,
          unitCostPaise: cost.unitCostPaise,
          costSource: cost.source,
          consumes: cost.consumes,
        ));
      }
      movementIds.add('mv-${line.id.value}');
    }
    return _StockPlan(
        writes: writes, movementIds: movementIds, warnings: warnings);
  }

  /// Transfer pairing rule (FR-M07-002: source and destination godowns,
  /// items, quantities; source ≠ destination). Legs are signed-qty at zero
  /// rate: negative lines are OUT legs (sources), positive lines are IN legs
  /// (destinations), and the transfer moves book value — line prices would
  /// conflict with that, and negative amounts violate the G0 amount CHECK,
  /// so a nonzero rate is rejected. Per item the signed legs must balance
  /// to zero with at least one leg each way, and every source godown must
  /// differ from every destination godown.
  void _checkTransferPairing(List<VoucherLine> stockLines) {
    final Map<String, List<VoucherLine>> byItem = <String, List<VoucherLine>>{};
    for (final VoucherLine line in stockLines) {
      if (line.ratePaise != 0) {
        throw TxFailure(const AppError('validation',
            'transfer lines carry no price; value flows from the book'));
      }
      byItem.putIfAbsent(line.itemId!.value, () => <VoucherLine>[]).add(line);
    }
    if (byItem.isEmpty) {
      throw TxFailure(const AppError(
          'validation', 'stock transfer needs item lines'));
    }
    for (final MapEntry<String, List<VoucherLine>> e in byItem.entries) {
      int net = 0;
      final Set<String> sources = <String>{};
      final Set<String> destinations = <String>{};
      for (final VoucherLine line in e.value) {
        net += line.qtyQ4;
        if (line.qtyQ4 < 0) {
          sources.add(line.godownId!.value);
        } else {
          destinations.add(line.godownId!.value);
        }
      }
      if (net != 0 || sources.isEmpty || destinations.isEmpty) {
        throw TxFailure(AppError('validation',
            'transfer of item ${e.key} needs balanced in/out legs'));
      }
      if (sources.intersection(destinations).isNotEmpty) {
        throw TxFailure(const AppError(
            'validation', 'transfer source must differ from destination'));
      }
    }
  }

  /// Effective valuation method for a line's book: item override over the
  /// group default, else Weighted Average (D-M5). The method must match the
  /// lock left by posted layer-priced movements of the same book.
  String _resolveMethod(
      CompanyId companyId, EntityId itemId, EntityId godownId) {
    String? itemMethod;
    String? groupMethod;
    final List<Map<String, Object?>> items = _db.queryArgs(
      'SELECT cost_method, group_id FROM item '
      'WHERE company_id = ? AND item_id = ?',
      <Object?>[companyId.value, itemId.value],
    );
    if (items.isNotEmpty) {
      itemMethod = items.first['cost_method'] as String?;
      final Object? groupId = items.first['group_id'];
      if (groupId != null) {
        final List<Map<String, Object?>> groups = _db.queryArgs(
          'SELECT cost_method FROM item_group '
          'WHERE company_id = ? AND group_id = ?',
          <Object?>[companyId.value, groupId],
        );
        if (groups.isNotEmpty) {
          groupMethod = groups.first['cost_method'] as String?;
        }
      }
    }
    String method;
    try {
      method = resolveCostMethod(itemMethod, groupMethod);
    } on ArgumentError {
      throw TxFailure(const AppError(
          'validation', 'stored cost method must be fifo or wa'));
    }
    final List<Map<String, Object?>> priced = _db.queryArgs(
      'SELECT cost_source FROM stock_movement '
      'WHERE company_id = ? AND item_id = ? AND godown_id = ? '
      "AND cost_source IN ('average', 'fifo', 'fifo-fallback') "
      'ORDER BY created_at DESC, movement_id DESC LIMIT 1',
      <Object?>[companyId.value, itemId.value, godownId.value],
    );
    if (priced.isNotEmpty) {
      final String? locked =
          methodOfPricedSource(priced.first['cost_source'] as String);
      if (locked != null && locked != method) {
        throw TxFailure(AppError('validation',
            'valuation method locked to $locked for item ${itemId.value}'));
      }
    }
    return method;
  }

  /// Live layer book for (item, godown), oldest first. COALESCE keeps
  /// raw-seeded pre-v15 layers readable (backfill covers posted ones).
  List<CostLayer> _liveLayers(
      CompanyId companyId, EntityId itemId, EntityId godownId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT layer_id, COALESCE(remaining_qty_q4, qty_q4) AS q, '
      'COALESCE(remaining_value_paise, value_paise) AS v '
      'FROM stock_cost_layer WHERE company_id = ? AND item_id = ? '
      'AND godown_id = ? AND COALESCE(remaining_qty_q4, qty_q4) > 0 '
      'ORDER BY created_at, layer_id',
      <Object?>[companyId.value, itemId.value, godownId.value],
    );
    return <CostLayer>[
      for (final Map<String, Object?> r in rows)
        CostLayer(
          layerId: r['layer_id'] as String,
          qtyQ4: r['q'] as int,
          valuePaise: r['v'] as int,
        ),
    ];
  }

  int? _lastKnownCost(EntityId itemId) {
    final List<Map<String, Object?>> known = _db.queryArgs(
      'SELECT last_known_cost_paise AS c FROM item_cost_state '
      'WHERE item_id = ?',
      <Object?>[itemId.value],
    );
    if (known.isEmpty) return null;
    return known.first['c'] as int;
  }

  _StockWrite _inboundWrite(CompanyId companyId, VoucherLine line,
      {int? valuePaise}) {
    final int value = valuePaise ?? line.amountPaise;
    final int qty = line.qtyQ4.abs();
    final int unitCost = qty == 0 ? 0 : ((value * 10000) + qty ~/ 2) ~/ qty;
    return _StockWrite(
      movementId: 'mv-${line.id.value}',
      layerId: 'cl-${line.id.value}',
      companyId: companyId,
      itemId: line.itemId!,
      godownId: line.godownId!,
      lineId: line.id,
      deltaQ4: qty,
      unitCostPaise: unitCost,
      costSource: 'layer',
      layerQtyQ4: qty,
      layerValuePaise: value,
      lastKnownCostPaise: unitCost,
    );
  }

  /// Price an outbound issue of [qtyOutQ4] (positive) per the book's method.
  /// Policy is enforced against the live balance before anything writes;
  /// every outcome (average/fifo/fallback/zero) is recorded in the movement
  /// source. Layer consumption rides in [consumes]; shortfall value (if any)
  /// is included in [totalValuePaise] but consumes no layer.
  _OutboundCost _priceOutbound(
    CompanyId companyId,
    VoucherLine line,
    int qtyOutQ4,
    StockPolicy policy,
    List<String> warnings,
  ) {
    final EntityId itemId = line.itemId!;
    final EntityId godownId = line.godownId!;
    final String method = _resolveMethod(companyId, itemId, godownId);
    final List<CostLayer> layers = _liveLayers(companyId, itemId, godownId);
    int bookQty = 0;
    int bookValue = 0;
    for (final CostLayer l in layers) {
      bookQty += l.qtyQ4;
      bookValue += l.valuePaise;
    }
    final List<Map<String, Object?>> balances = _db.queryArgs(
      'SELECT SUM(qty_delta_q4) AS q FROM stock_movement '
      'WHERE company_id = ? AND item_id = ? AND godown_id = ?',
      <Object?>[companyId.value, itemId.value, godownId.value],
    );
    final int onHand = (balances.first['q'] as int?) ?? 0;
    final StockCheck check = checkStockMove(
        policy: policy, onHandQ4: onHand, moveQ4: -qtyOutQ4);
    if (!check.approved) {
      throw TxFailure(AppError('validation',
          'negative stock blocked by policy for item ${itemId.value}'));
    }
    if (check.warning) {
      warnings.add('negative stock warning for item ${itemId.value}');
    }
    if (method == kCostMethodFifo && bookQty > 0) {
      final IssuePricing pricing = priceFifoIssue(layers, qtyOutQ4);
      int value = pricing.layersValuePaise;
      String source = 'fifo';
      if (pricing.shortfallQ4 > 0) {
        final int? known = _lastKnownCost(itemId);
        if (known != null) {
          value += fallbackShortfallValue(pricing.shortfallQ4, known);
          source = 'fifo-fallback';
        } else {
          warnings.add('no cost history for item ${itemId.value}'
              '; shortfall valued at zero');
          source = 'fifo-fallback';
        }
      }
      return _OutboundCost(
        unitCostPaise: ((value * 10000) + qtyOutQ4 ~/ 2) ~/ qtyOutQ4,
        totalValuePaise: value,
        source: source,
        consumes: <_LayerConsume>[
          for (final LayerDraw d in pricing.draws)
            _LayerConsume(
                layerId: d.layerId, qtyQ4: d.qtyQ4, valuePaise: d.valuePaise),
        ],
      );
    }
    if (method == kCostMethodWa && bookQty > 0) {
      final int totalValue =
          weightedIssueValue(qtyOutQ4, bookQty, bookValue);
      final Map<String, _LayerConsume> touched = <String, _LayerConsume>{};
      int qtyNeeded = qtyOutQ4 < bookQty ? qtyOutQ4 : bookQty;
      int valueNeeded = totalValue < bookValue ? totalValue : bookValue;
      for (final CostLayer l in layers) {
        if (qtyNeeded <= 0 && valueNeeded <= 0) break;
        int qTake = 0;
        int vTake = 0;
        if (qtyNeeded > 0) {
          qTake = qtyNeeded < l.qtyQ4 ? qtyNeeded : l.qtyQ4;
          qtyNeeded -= qTake;
        }
        if (valueNeeded > 0) {
          vTake = valueNeeded < l.valuePaise ? valueNeeded : l.valuePaise;
          valueNeeded -= vTake;
        }
        if (qTake > 0 || vTake > 0) {
          touched[l.layerId] =
              _LayerConsume(layerId: l.layerId, qtyQ4: qTake, valuePaise: vTake);
        }
      }
      return _OutboundCost(
        unitCostPaise: ((totalValue * 10000) + qtyOutQ4 ~/ 2) ~/ qtyOutQ4,
        totalValuePaise: totalValue,
        source: 'average',
        consumes: touched.values.toList(),
      );
    }
    final int? known = _lastKnownCost(itemId);
    if (known != null) {
      final int value = fallbackShortfallValue(qtyOutQ4, known);
      return _OutboundCost(
        unitCostPaise: ((value * 10000) + qtyOutQ4 ~/ 2) ~/ qtyOutQ4,
        totalValuePaise: value,
        source: 'fallback',
      );
    }
    warnings.add('no cost history for item ${itemId.value}'
        '; valued at zero');
    return _OutboundCost(
        unitCostPaise: 0, totalValuePaise: 0, source: 'zero');
  }

  void _writeStockMovement(
      CompanyId companyId, _StockWrite w, String deviceId) {
    final int now = ctx.clock.nowMs();
    if (w.layerId != null) {
      _db.executeArgs(
        'INSERT INTO stock_cost_layer (layer_id, company_id, item_id, '
        'godown_id, voucher_line_id, qty_q4, value_paise, remaining_qty_q4, '
        'remaining_value_paise, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          w.layerId,
          companyId.value,
          w.itemId.value,
          w.godownId.value,
          w.lineId.value,
          w.layerQtyQ4,
          w.layerValuePaise,
          w.layerQtyQ4,
          w.layerValuePaise,
          now,
        ],
      );
      _lineage(
        entity: 'stock_cost_layer',
        entityId: w.layerId!,
        companyId: companyId,
        deviceId: deviceId,
        opId: 'op-${w.layerId}',
        eventId: 'ev-${w.layerId}',
      );
      _db.executeArgs(
        'INSERT INTO item_cost_state (item_id, last_known_cost_paise, '
        'updated_at) VALUES (?, ?, ?) '
        'ON CONFLICT (item_id) DO UPDATE SET '
        'last_known_cost_paise = excluded.last_known_cost_paise, '
        'updated_at = excluded.updated_at',
        <Object?>[w.itemId.value, w.lastKnownCostPaise, now],
      );
      _lineage(
        entity: 'item_cost_state',
        entityId: w.itemId.value,
        companyId: companyId,
        deviceId: deviceId,
        opId: 'op-cost-${w.movementId}',
        eventId: 'ev-cost-${w.movementId}',
      );
    }
    // Operation first: stock_movement.operation_id is an FK to it.
    final Map<String, Object?> moveRow = <String, Object?>{
      'movement_id': w.movementId,
      'delta_q4': w.deltaQ4,
      'cost_source': w.costSource,
    };
    final Result<OperationRecord> mop = ops.append(
      opId: 'op-${w.movementId}',
      companyId: companyId.value,
      deviceId: deviceId,
      entity: 'stock_movement',
      entityId: w.movementId,
      action: 'create',
      payloadHash: auditPayloadHash(moveRow),
    );
    if (mop.isErr) throw TxFailure((mop as Err<OperationRecord>).error);
    _db.executeArgs(
      'INSERT INTO stock_movement (movement_id, company_id, item_id, '
      'godown_id, qty_delta_q4, cost_paise, cost_source, voucher_line_id, '
      'operation_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        w.movementId,
        companyId.value,
        w.itemId.value,
        w.godownId.value,
        w.deltaQ4,
        w.unitCostPaise,
        w.costSource,
        w.lineId.value,
        'op-${w.movementId}',
        now,
      ],
    );
    final Result<AuditEvent> mev = audit.append(
      eventId: 'ev-${w.movementId}',
      companyId: companyId.value,
      entity: 'stock_movement',
      entityId: w.movementId,
      newRow: moveRow,
      actor: 'posting-engine',
    );
    if (mev.isErr) throw TxFailure((mev as Err<AuditEvent>).error);
    // Layer consumption: decrement remaining balances (the receipt record
    // qty_q4/value_paise is never rewritten — no retro revaluation).
    for (final _LayerConsume c in w.consumes) {
      _db.executeArgs(
        'UPDATE stock_cost_layer SET remaining_qty_q4 = '
        'COALESCE(remaining_qty_q4, qty_q4) - ?, remaining_value_paise = '
        'COALESCE(remaining_value_paise, value_paise) - ? '
        'WHERE layer_id = ?',
        <Object?>[c.qtyQ4, c.valuePaise, c.layerId],
      );
      _lineage(
        entity: 'stock_cost_layer',
        entityId: c.layerId,
        companyId: companyId,
        deviceId: deviceId,
        opId: 'op-consume-${w.movementId}-${c.layerId}',
        eventId: 'ev-consume-${w.movementId}-${c.layerId}',
        action: 'consume',
      );
    }
  }

  void _lineage({
    required String entity,
    required String entityId,
    required CompanyId companyId,
    required String deviceId,
    required String opId,
    required String eventId,
    String action = 'create',
  }) {
    final Map<String, Object?> row = <String, Object?>{
      'entity': entity,
      'entity_id': entityId,
    };
    final Result<OperationRecord> op = ops.append(
      opId: opId,
      companyId: companyId.value,
      deviceId: deviceId,
      entity: entity,
      entityId: entityId,
      action: action,
      payloadHash: auditPayloadHash(row),
    );
    if (op.isErr) throw TxFailure((op as Err<OperationRecord>).error);
    final Result<AuditEvent> ev = audit.append(
      eventId: eventId,
      companyId: companyId.value,
      entity: entity,
      entityId: entityId,
      newRow: row,
      actor: 'posting-engine',
    );
    if (ev.isErr) throw TxFailure((ev as Err<AuditEvent>).error);
  }

  Result<Voucher> _moveStatus({
    required EntityId id,
    required CompanyId companyId,
    required String status,
    required String action,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
    String? reason,
  }) {
    try {
      Voucher? done;
      _db.runInTransaction(() {
        done = _moveStatusInTx(
          id: id,
          companyId: companyId,
          status: status,
          action: action,
          deviceId: deviceId,
          opId: opId,
          eventId: eventId,
          actor: actor,
          reason: reason,
        );
      });
      return ok(done!);
    } on TxFailure catch (f) {
      return err(f.error.code, f.error.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-engine-move');
      return err(be.code, be.message);
    }
  }

  /// Status move assuming the caller already holds the transaction (used by
  /// [postWithStock] so effects and the move commit atomically). Throws
  /// [TxFailure] carrying the mapped error; the adapter rolls back.
  Voucher _moveStatusInTx({
    required EntityId id,
    required CompanyId companyId,
    required String status,
    required String action,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
    String? reason,
  }) {
    _db.executeArgs(
      'UPDATE voucher SET status = ? WHERE company_id = ? AND voucher_id = ?',
      <Object?>[status, companyId.value, id.value],
    );
    final Map<String, Object?> row = <String, Object?>{
      'voucher_id': id.value,
      'status': status,
    };
    if (reason != null) row['reason'] = reason;
    final Result<OperationRecord> op = ops.append(
      opId: opId,
      companyId: companyId.value,
      deviceId: deviceId,
      entity: 'voucher',
      entityId: id.value,
      action: action,
      payloadHash: auditPayloadHash(row),
    );
    if (op.isErr) throw TxFailure((op as Err<OperationRecord>).error);
    final Result<AuditEvent> ev = audit.append(
      eventId: eventId,
      companyId: companyId.value,
      entity: 'voucher',
      entityId: id.value,
      newRow: row,
      actor: actor,
    );
    if (ev.isErr) throw TxFailure((ev as Err<AuditEvent>).error);
    final Voucher? done = vouchers.get(companyId, id)?.voucher;
    if (done == null) {
      throw TxFailure(const AppError('db', 'voucher vanished mid-move'));
    }
    return done;
  }
}

/// Validated postable snapshot (single validation path output).
class _Postable {
  const _Postable(
      {required this.voucher, required this.lines, required this.totals});

  final Voucher voucher;
  final List<VoucherLine> lines;
  final PostedTotals totals;
}

/// One planned stock write (movement, plus layer + cost-state on inbound,
/// plus layer-remaining consumption on outbound).
class _StockWrite {
  const _StockWrite({
    required this.movementId,
    required this.layerId,
    required this.companyId,
    required this.itemId,
    required this.godownId,
    required this.lineId,
    required this.deltaQ4,
    required this.unitCostPaise,
    required this.costSource,
    this.layerQtyQ4,
    this.layerValuePaise,
    this.lastKnownCostPaise,
    this.consumes = const <_LayerConsume>[],
  });

  final String movementId;
  final String? layerId;
  final CompanyId companyId;
  final EntityId itemId;
  final EntityId godownId;
  final EntityId lineId;
  final int deltaQ4;
  final int unitCostPaise;
  final String costSource;
  final int? layerQtyQ4;
  final int? layerValuePaise;
  final int? lastKnownCostPaise;

  /// Layer balances consumed by an outbound leg (empty for inbound).
  final List<_LayerConsume> consumes;
}

class _StockPlan {
  const _StockPlan(
      {required this.writes,
      required this.movementIds,
      required this.warnings});

  final List<_StockWrite> writes;
  final List<String> movementIds;
  final List<String> warnings;
}

class _OutboundCost {
  const _OutboundCost({
    required this.unitCostPaise,
    required this.totalValuePaise,
    required this.source,
    this.consumes = const <_LayerConsume>[],
  });

  /// Movement unit cost (paise per whole unit, round-half-up).
  final int unitCostPaise;

  /// Total issue value including any fallback-priced shortfall.
  final int totalValuePaise;
  final String source;

  /// Per-layer consumption (empty when nothing was drawn from layers).
  final List<_LayerConsume> consumes;
}

/// One layer-balance decrement applied by an outbound leg.
class _LayerConsume {
  const _LayerConsume({
    required this.layerId,
    required this.qtyQ4,
    required this.valuePaise,
  });

  final String layerId;
  final int qtyQ4;
  final int valuePaise;
}
