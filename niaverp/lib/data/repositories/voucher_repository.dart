// NiAvERP voucher repository — implementation Phase 01.
// CRUD over the m001 `voucher` + `voucher_line` tables (plus the m008
// discount columns). Line amounts reuse the approved D-M4 arithmetic
// (`lineAmount`, `discountFor` in validators.dart); the type/status TEXT
// columns accept any non-empty value — voucher-type lifecycle and status
// transitions are later-slice policy (prompts 03/03A), never invented here.
// Every write is company-scoped, single-transaction, with operation + audit
// lineage. Traceability: D-M4; DSS-C-001/004; OD-DB-004; G0-SCH-007.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/migrations/validators.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One voucher header row. [narration]/[actor]/[device] are the DSS §3
/// header fields (actor = DSS "user", house term per audit_event); fy and
/// registry-FK conversion wait on the financial_year table and numbering
/// design. [no] uniqueness per (company, series) is DB-enforced (DSS-C-002).
class Voucher {
  const Voucher({
    required this.id,
    required this.companyId,
    required this.type,
    required this.series,
    required this.no,
    required this.date,
    required this.status,
    required this.createdAt,
    this.narration,
    this.actor,
    this.device,
    this.fyId,
  });

  final EntityId id;
  final CompanyId companyId;

  /// Voucher type text (e.g. 'sales-invoice'). Free text: the 19-type
  /// registry and its gates land with the voucher engine (prompt 03A).
  final String type;
  final String series;
  final String no;
  final NiavDate date;

  /// Status text (schema default 'draft'). Transitions are later policy.
  final String status;
  final int createdAt;
  final String? narration;
  final String? actor;
  final String? device;
  final EntityId? fyId;

  static Voucher fromRow(Map<String, Object?> r) => Voucher(
        id: EntityId(r['voucher_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        type: r['voucher_type'] as String,
        series: r['series'] as String,
        no: r['voucher_no'] as String,
        date: NiavDate(r['voucher_date'] as String),
        status: r['status'] as String,
        createdAt: r['created_at'] as int,
        narration: r['narration'] as String?,
        actor: r['actor'] as String?,
        device: r['device'] as String?,
        fyId: r['fy_id'] == null ? null : EntityId(r['fy_id'] as String),
      );
}

/// One voucher line row (amounts derived by D-M4 arithmetic at write time).
class VoucherLine {
  const VoucherLine({
    required this.id,
    required this.voucherId,
    required this.companyId,
    required this.lineNo,
    required this.itemId,
    this.ledgerId,
    this.partyId,
    this.godownId,
    this.batchId,
    required this.qtyQ4,
    required this.ratePaise,
    required this.amountPaise,
    required this.discountAmountPaise,
    required this.discountRateBps,
    required this.createdAt,
    this.drCr,
  });

  final EntityId id;
  final EntityId voucherId;
  final CompanyId companyId;
  final int lineNo;
  final EntityId? itemId;
  /// DSS §3 line refs: [ledgerId]/[batchId] are plain text until ledger
  /// masters / batch P2 land; [partyId]/[godownId] are FK-enforced.
  /// [drCr] is the DSS "Dr/Cr" field: item-quantity lines carry signed qty
  /// and must NOT carry Dr/Cr; ledger-amount lines use it once ledger
  /// masters exist. Tax waits on G3 verification (OD-DB-003).
  final EntityId? ledgerId;
  final EntityId? partyId;
  final EntityId? godownId;
  final EntityId? batchId;
  final String? drCr;
  final int qtyQ4;
  final int ratePaise;
  final int amountPaise;
  final int discountAmountPaise;
  final int discountRateBps;
  final int createdAt;

  static VoucherLine fromRow(Map<String, Object?> r) => VoucherLine(
        id: EntityId(r['voucher_line_id'] as String),
        voucherId: EntityId(r['voucher_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        lineNo: r['line_no'] as int,
        itemId: r['item_id'] == null
            ? null
            : EntityId(r['item_id'] as String),
        ledgerId: r['ledger_id'] == null
            ? null
            : EntityId(r['ledger_id'] as String),
        partyId: r['party_id'] == null
            ? null
            : EntityId(r['party_id'] as String),
        godownId: r['godown_id'] == null
            ? null
            : EntityId(r['godown_id'] as String),
        batchId: r['batch_id'] == null
            ? null
            : EntityId(r['batch_id'] as String),
        drCr: r['dr_cr'] as String?,
        qtyQ4: r['qty_q4'] as int,
        ratePaise: r['rate_paise'] as int,
        amountPaise: r['amount_paise'] as int,
        discountAmountPaise: (r['discount_amount_paise'] as int?) ?? 0,
        discountRateBps: (r['discount_rate_bps'] as int?) ?? 0,
        createdAt: r['created_at'] as int,
      );
}

/// Header with its lines in line-number order.
class VoucherWithLines {
  const VoucherWithLines(this.voucher, this.lines);

  final Voucher voucher;
  final List<VoucherLine> lines;
}

class VoucherRepository {
  VoucherRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _headerCols =
      'voucher_id, company_id, voucher_type, series, voucher_no, '
      'voucher_date, status, created_at, narration, actor, device, fy_id';
  static const String _lineCols =
      'voucher_line_id, voucher_id, company_id, line_no, item_id, qty_q4, '
      'rate_paise, amount_paise, discount_amount_paise, discount_rate_bps, '
      'ledger_id, party_id, godown_id, batch_id, dr_cr, created_at';

  /// Create a draft voucher header with operation + audit lineage.
  /// [narration]/[headerActor]/[headerDevice] are the DSS §3 header fields
  /// (distinct from the lineage [actor]/[deviceId] that record who wrote).
  Result<Voucher> create({
    required EntityId id,
    required CompanyId companyId,
    required String type,
    required String series,
    required String no,
    required NiavDate date,
    String status = 'draft',
    String? narration,
    String? headerActor,
    String? headerDevice,
    EntityId? fyId,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (type.isEmpty ||
        series.isEmpty ||
        no.isEmpty ||
        status.isEmpty ||
        deviceId.isEmpty) {
      return err(
        'validation',
        'voucher type/series/no/status and device id must not be empty',
      );
    }
    Voucher? created;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO voucher (voucher_id, company_id, voucher_type, '
          'series, voucher_no, voucher_date, status, created_at, narration, '
          'actor, device, fy_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            type,
            series,
            no,
            date.iso,
            status,
            now,
            narration,
            headerActor,
            headerDevice,
            fyId?.value,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'voucher_id': id.value,
          'company_id': companyId.value,
          'voucher_type': type,
          'series': series,
          'voucher_no': no,
          'voucher_date': date.iso,
          'status': status,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'voucher',
          entityId: id.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'voucher',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        created = Voucher(
          id: id,
          companyId: companyId,
          type: type,
          series: series,
          no: no,
          date: date,
          status: status,
          createdAt: now,
          narration: narration,
          actor: headerActor,
          device: headerDevice,
          fyId: fyId,
        );
      });
      return ok(created!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-create');
      return err(be.code, be.message);
    }
  }

  /// Append one line. The gross amount is derived by D-M4 arithmetic
  /// (`lineAmount`); discount inputs are validated and stored as given
  /// (owner-decided amount-wins/tax-on-net per P-DISC-PREC; net math lives
  /// in `lineNet`, not in storage).
  Result<VoucherLine> addLine({
    required EntityId lineId,
    required EntityId voucherId,
    required CompanyId companyId,
    required int lineNo,
    EntityId? itemId,
    EntityId? ledgerId,
    EntityId? partyId,
    EntityId? godownId,
    EntityId? batchId,
    String? drCr,
    required int qtyQ4,
    required int ratePaise,
    int discountAmountPaise = 0,
    int discountRateBps = 0,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (lineNo <= 0 || ratePaise < 0 || deviceId.isEmpty) {
      return err(
        'validation',
        'line_no must be > 0, rate must be >= 0, device id not empty',
      );
    }
    // Dr/Cr sign convention (owner-directed): item-quantity lines carry
    // signed qty (lineAmount) and must not carry Dr/Cr; anything else must
    // be exactly Dr or Cr (DB CHECK is the backstop).
    if (itemId != null && drCr != null) {
      return err('validation', 'item lines carry signed quantity, not Dr/Cr');
    }
    if (drCr != null && drCr != 'Dr' && drCr != 'Cr') {
      return err('validation', 'dr_cr must be Dr or Cr');
    }
    final List<String> discountErrors =
        validateDiscountInputs(discountAmountPaise, discountRateBps);
    if (discountErrors.isNotEmpty) {
      return err('validation', discountErrors.first);
    }
    VoucherLine? created;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        final int amount = lineAmount(qtyQ4, ratePaise);
        _db.executeArgs(
          'INSERT INTO voucher_line (voucher_line_id, voucher_id, '
          'company_id, line_no, item_id, qty_q4, rate_paise, amount_paise, '
          'discount_amount_paise, discount_rate_bps, ledger_id, party_id, '
          'godown_id, batch_id, dr_cr, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            lineId.value,
            voucherId.value,
            companyId.value,
            lineNo,
            itemId?.value,
            qtyQ4,
            ratePaise,
            amount,
            discountAmountPaise,
            discountRateBps,
            ledgerId?.value,
            partyId?.value,
            godownId?.value,
            batchId?.value,
            drCr,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'voucher_line_id': lineId.value,
          'voucher_id': voucherId.value,
          'company_id': companyId.value,
          'line_no': lineNo,
          'qty_q4': qtyQ4,
          'rate_paise': ratePaise,
          'amount_paise': amount,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'voucher_line',
          entityId: lineId.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'voucher_line',
          entityId: lineId.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        created = VoucherLine(
          id: lineId,
          voucherId: voucherId,
          companyId: companyId,
          lineNo: lineNo,
          itemId: itemId,
          ledgerId: ledgerId,
          partyId: partyId,
          godownId: godownId,
          batchId: batchId,
          drCr: drCr,
          qtyQ4: qtyQ4,
          ratePaise: ratePaise,
          amountPaise: amount,
          discountAmountPaise: discountAmountPaise,
          discountRateBps: discountRateBps,
          createdAt: now,
        );
      });
      return ok(created!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-line-add');
      return err(be.code, be.message);
    }
  }

  /// Header with lines, or null when absent in this company.
  VoucherWithLines? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> headers = _db.queryArgs(
      'SELECT $_headerCols FROM voucher WHERE company_id = ? AND voucher_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (headers.isEmpty) return null;
    final List<Map<String, Object?>> lines = _db.queryArgs(
      'SELECT $_lineCols FROM voucher_line '
      'WHERE company_id = ? AND voucher_id = ? ORDER BY line_no',
      <Object?>[companyId.value, id.value],
    );
    return VoucherWithLines(
      Voucher.fromRow(headers.first),
      <VoucherLine>[for (final Map<String, Object?> r in lines) VoucherLine.fromRow(r)],
    );
  }

  /// All voucher headers of one company, newest first.
  List<Voucher> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_headerCols FROM voucher WHERE company_id = ? '
      'ORDER BY voucher_date DESC, created_at DESC',
      <Object?>[companyId.value],
    );
    return <Voucher>[for (final Map<String, Object?> r in rows) Voucher.fromRow(r)];
  }

  /// Held-bill queue (FR-M11-003): vouchers with status `held` are incomplete
  /// working documents. They persist header/line rows only — no write in this
  /// engine creates accounting or stock effects, so held data cannot affect
  /// them until an owning slice posts it. Oldest-held first (counter order).
  List<Voucher> heldBills(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      "SELECT $_headerCols FROM voucher WHERE company_id = ? AND status = 'held' "
      'ORDER BY created_at',
      <Object?>[companyId.value],
    );
    return <Voucher>[for (final Map<String, Object?> r in rows) Voucher.fromRow(r)];
  }

  /// Explicitly move a held bill to its next counter state (FR-M11-003:
  /// Held → Resumed/Cancelled/Posted) with operation + audit lineage in one
  /// transaction. Only held bills may move, and only to those three states;
  /// posted history stays immutable per the technical baseline, and every
  /// other lifecycle (approvals, posting rules) belongs to its owning slice
  /// and is rejected here, never invented.
  Result<Voucher> updateHeldStatus({
    required EntityId id,
    required CompanyId companyId,
    required String status,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (status != 'resumed' && status != 'cancelled' && status != 'posted') {
      return err('validation', 'held bills move only to resumed/cancelled/posted');
    }
    if (deviceId.isEmpty) {
      return err('validation', 'device id must not be empty');
    }
    final List<Map<String, Object?>> current = _db.queryArgs(
      'SELECT status FROM voucher WHERE company_id = ? AND voucher_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (current.isEmpty) {
      return err('validation', 'voucher does not exist in this company');
    }
    if ((current.first['status'] as String) != 'held') {
      return err('validation', 'only held bills can change status here');
    }
    Voucher? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        _db.executeArgs(
          'UPDATE voucher SET status = ? WHERE company_id = ? AND voucher_id = ?',
          <Object?>[status, companyId.value, id.value],
        );
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'voucher',
          entityId: id.value,
          action: 'status-change',
          payloadHash: auditPayloadHash(<String, Object?>{
            'voucher_id': id.value,
            'status': status,
          }),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'voucher',
          entityId: id.value,
          newRow: <String, Object?>{'status': status},
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        final VoucherWithLines? reloaded = get(companyId, id);
        done = reloaded?.voucher;
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-status-change');
      return err(be.code, be.message);
    }
  }
}
