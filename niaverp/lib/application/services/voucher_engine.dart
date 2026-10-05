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
// ledger postings (no ledger masters), stock movements (voucher lines carry
// no godown column), tax/charge/round-off persistence (no approved columns;
// math itself lives in validators.dart), party linkage (no voucher party
// column), number generation (FR-M04-002 scope TBD), approval gates (P2).
// Traceability: M04/M05/M06/M07/M08; D-M4; DSS-C-001/004; OD-DB-004;
// D-M5(5) period lock; FR-M04-001/002.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
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
/// warnings, and structurally pending effects (explicit, never silent).
class PostingResult {
  const PostingResult({
    required this.totals,
    required this.movementIds,
    required this.warnings,
    required this.pendingEffects,
  });

  final PostedTotals totals;
  final List<String> movementIds;
  final List<String> warnings;
  final List<String> pendingEffects;
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
/// (stock journal adjustments), absent = no stock movement. Directions come
/// from the FR downstream rows (M05 "stock out/in", M07 delivery "stock
/// out", returns "stock in/out"); transfers need two legs from one line and
/// stay pending (recorded per post, never silently skipped).
const Map<String, int> _stockDirections = <String, int>{
  'Sales Invoice': -1,
  'Delivery Note / Delivery Challan': -1,
  'Purchase Return / Debit Note with items': -1,
  'Purchase Invoice': 1,
  'Sales Return / Credit Note with items': 1,
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

  /// Effects the pipeline deliberately does NOT produce (explicit per post,
  /// never silent). GST needs verified schemas (G0-VER-003); ledger-template
  /// auto-posting needs posting templates; transfer legs need the two-leg
  /// slice; FIFO draws need method selection (weighted-average applied).
  List<String> _pendingEffects(String? canonical) {
    final List<String> out = <String>[];
    if (canonical == 'Stock Transfer') {
      out.add('transfer stock legs pending two-leg slice');
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
  /// correctly produce no movement. Throws [TxFailure] on any rule breach.
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
    for (final VoucherLine line in p.lines) {
      if (line.itemId == null || line.godownId == null) continue;
      if (direction == null) continue;
      if (line.qtyQ4 == 0) {
        throw TxFailure(const AppError(
            'validation', 'stock lines need nonzero quantity'));
      }
      final int dir = direction == 0
          ? (line.qtyQ4 > 0 ? 1 : -1)
          : direction;
      if (dir > 0) {
        writes.add(_inboundWrite(companyId, line));
      } else {
        final _OutboundCost cost =
            _outboundUnitCost(companyId, line, policy, warnings);
        writes.add(_StockWrite(
          movementId: 'mv-${line.id.value}',
          layerId: null,
          companyId: companyId,
          itemId: line.itemId!,
          godownId: line.godownId!,
          lineId: line.id,
          deltaQ4: -line.qtyQ4,
          unitCostPaise: cost.unitCostPaise,
          costSource: cost.source,
        ));
      }
      movementIds.add('mv-${line.id.value}');
    }
    return _StockPlan(
        writes: writes, movementIds: movementIds, warnings: warnings);
  }

  _StockWrite _inboundWrite(CompanyId companyId, VoucherLine line) {
    final int unitCost =
        ((line.amountPaise * 10000) + line.qtyQ4 ~/ 2) ~/ line.qtyQ4;
    return _StockWrite(
      movementId: 'mv-${line.id.value}',
      layerId: 'cl-${line.id.value}',
      companyId: companyId,
      itemId: line.itemId!,
      godownId: line.godownId!,
      lineId: line.id,
      deltaQ4: line.qtyQ4,
      unitCostPaise: unitCost,
      costSource: 'layer',
      layerQtyQ4: line.qtyQ4,
      layerValuePaise: line.amountPaise,
      lastKnownCostPaise: unitCost,
    );
  }

  /// Weighted-average unit cost over book layers (D-M5 default method),
  /// falling back to last-known cost and then zero — each step recorded.
  /// Policy is enforced against the live balance before anything writes.
  _OutboundCost _outboundUnitCost(
    CompanyId companyId,
    VoucherLine line,
    StockPolicy policy,
    List<String> warnings,
  ) {
    final List<Map<String, Object?>> totals = _db.queryArgs(
      'SELECT SUM(qty_q4) AS q, SUM(value_paise) AS v FROM stock_cost_layer '
      'WHERE company_id = ? AND item_id = ? AND godown_id = ?',
      <Object?>[companyId.value, line.itemId!.value, line.godownId!.value],
    );
    final int bookQty = (totals.first['q'] as int?) ?? 0;
    final int bookValue = (totals.first['v'] as int?) ?? 0;
    final List<Map<String, Object?>> balances = _db.queryArgs(
      'SELECT SUM(qty_delta_q4) AS q FROM stock_movement '
      'WHERE company_id = ? AND item_id = ? AND godown_id = ?',
      <Object?>[companyId.value, line.itemId!.value, line.godownId!.value],
    );
    final int onHand = (balances.first['q'] as int?) ?? 0;
    final StockCheck check = checkStockMove(
        policy: policy, onHandQ4: onHand, moveQ4: -line.qtyQ4);
    if (!check.approved) {
      throw TxFailure(AppError('validation',
          'negative stock blocked by policy for item ${line.itemId!.value}'));
    }
    if (check.warning) {
      warnings.add('negative stock warning for item ${line.itemId!.value}');
    }
    if (bookQty > 0) {
      // Weighted-average UNIT cost over book layers (D-M5 default method):
      // round-half-up(bookValue × 10⁴ / bookQty). FIFO draws need
      // per-layer remaining tracking — recorded pending (method selection).
      return _OutboundCost(
        unitCostPaise: ((bookValue * 10000) + bookQty ~/ 2) ~/ bookQty,
        source: 'average',
      );
    }
    final List<Map<String, Object?>> known = _db.queryArgs(
      'SELECT last_known_cost_paise AS c FROM item_cost_state '
      'WHERE item_id = ?',
      <Object?>[line.itemId!.value],
    );
    if (known.isNotEmpty) {
      return _OutboundCost(
        unitCostPaise: (known.first['c'] as int),
        source: 'fallback',
      );
    }
    warnings.add('no cost history for item ${line.itemId!.value}'
        '; valued at zero');
    return const _OutboundCost(unitCostPaise: 0, source: 'zero');
  }

  void _writeStockMovement(
      CompanyId companyId, _StockWrite w, String deviceId) {
    final int now = ctx.clock.nowMs();
    if (w.layerId != null) {
      _db.executeArgs(
        'INSERT INTO stock_cost_layer (layer_id, company_id, item_id, '
        'godown_id, voucher_line_id, qty_q4, value_paise, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          w.layerId,
          companyId.value,
          w.itemId.value,
          w.godownId.value,
          w.lineId.value,
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
  }

  void _lineage({
    required String entity,
    required String entityId,
    required CompanyId companyId,
    required String deviceId,
    required String opId,
    required String eventId,
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
      action: 'create',
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

/// One planned stock write (movement, plus layer + cost-state on inbound).
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
  const _OutboundCost({required this.unitCostPaise, required this.source});

  final int unitCostPaise;
  final String source;
}
