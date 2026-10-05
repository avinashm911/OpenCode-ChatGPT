// NiAvERP bill-allocation writer — posting slice (FR-M06, G1).
// Writes the m004 `bill_allocation` rows that the settlement engine
// (settlement.dart) guards: every allocation is validated against open
// balances before commit (no over-allocation, no self-settlement, no
// replayed operation), and reversals preserve history. The operation row
// is appended FIRST: bill_allocation.operation_id is an FK to it.
// Traceability: FR-M06-001/002 (bill-wise settlement); G0-SCH-003;
// DSS-C-003/004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/settlement.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

class BillAllocationRepository {
  BillAllocationRepository(this.ctx,
      {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  /// Active allocations out of one source line, oldest first.
  List<AllocationView> activeForSource(
    CompanyId companyId,
    EntityId sourceLineId,
  ) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT allocation_id, source_voucher_line_id, '
      'settlement_voucher_line_id, allocated_amount_paise, status, '
      'operation_id FROM bill_allocation WHERE company_id = ? '
      "AND source_voucher_line_id = ? AND status = 'active' "
      'ORDER BY created_at',
      <Object?>[companyId.value, sourceLineId.value],
    );
    return <AllocationView>[
      for (final Map<String, Object?> r in rows)
        AllocationView(
          allocationId: r['allocation_id'] as String,
          sourceLineId: r['source_voucher_line_id'] as String,
          settlementLineId: r['settlement_voucher_line_id'] as String,
          amountPaise: r['allocated_amount_paise'] as int,
          status: r['status'] as String,
          operationId: r['operation_id'] as String,
        ),
    ];
  }

  int? _lineAmount(CompanyId companyId, EntityId lineId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT amount_paise FROM voucher_line '
      'WHERE company_id = ? AND voucher_line_id = ?',
      <Object?>[companyId.value, lineId.value],
    );
    if (rows.isEmpty) return null;
    return rows.first['amount_paise'] as int;
  }

  /// Allocate [amountPaise] of one source line to one settlement line.
  /// Both lines must exist in the company; the amount must fit the open
  /// balance (guarded by settlement.checkApplicable, never clamped).
  Result<void> allocate({
    required EntityId id,
    required CompanyId companyId,
    required EntityId sourceLineId,
    required EntityId settlementLineId,
    required int amountPaise,
    required NiavDate date,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    try {
      _db.runInTransaction(() {
        allocateTx(
          id: id,
          companyId: companyId,
          sourceLineId: sourceLineId,
          settlementLineId: settlementLineId,
          amountPaise: amountPaise,
          date: date,
          deviceId: deviceId,
          opId: opId,
          eventId: eventId,
          actor: actor,
        );
      });
      return ok(null);
    } on TxFailure catch (f) {
      return err(f.error.code, f.error.message);
    } catch (e) {
      final AppError be = dbError(e, 'bill-allocation-create');
      return err(be.code, be.message);
    }
  }

  /// Allocation assuming the caller already holds the transaction (used by
  /// the posting pipeline so allocations commit with everything else).
  /// Throws [TxFailure]; the adapter rolls back.
  void allocateTx({
    required EntityId id,
    required CompanyId companyId,
    required EntityId sourceLineId,
    required EntityId settlementLineId,
    required int amountPaise,
    required NiavDate date,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (deviceId.isEmpty) {
      throw TxFailure(
          const AppError('validation', 'device id must not be empty'));
    }
    final int? sourceAmount = _lineAmount(companyId, sourceLineId);
    final int? settlementAmount = _lineAmount(companyId, settlementLineId);
    if (sourceAmount == null || settlementAmount == null) {
      throw TxFailure(const AppError(
          'validation', 'allocation lines must exist in this company'));
    }
    final List<String> guardErrors = checkApplicable(
      allocationId: id.value,
      sourceLineId: sourceLineId.value,
      settlementLineId: settlementLineId.value,
      amountPaise: amountPaise,
      operationId: opId,
      sourceAmountPaise: sourceAmount,
      existing: activeForSource(companyId, sourceLineId),
    );
    if (guardErrors.isNotEmpty) {
      throw TxFailure(AppError('validation', guardErrors.first));
    }
    final int now = ctx.clock.nowMs();
    final Result<OperationRecord> op = ops.append(
      opId: opId,
      companyId: companyId.value,
      deviceId: deviceId,
      entity: 'bill_allocation',
      entityId: id.value,
      action: 'create',
      payloadHash: auditPayloadHash(<String, Object?>{
        'allocation_id': id.value,
        'source': sourceLineId.value,
        'settlement': settlementLineId.value,
        'amount': amountPaise,
      }),
    );
    if (op.isErr) throw TxFailure((op as Err<OperationRecord>).error);
    try {
      _db.executeArgs(
        'INSERT INTO bill_allocation (allocation_id, company_id, '
        'source_voucher_line_id, settlement_voucher_line_id, '
        'allocated_amount_paise, allocation_date, status, operation_id, '
        'created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          id.value,
          companyId.value,
          sourceLineId.value,
          settlementLineId.value,
          amountPaise,
          date.iso,
          'active',
          opId,
          now,
        ],
      );
    } catch (e) {
      throw TxFailure(dbError(e, 'bill-allocation-create'));
    }
    final Result<AuditEvent> ev = audit.append(
      eventId: eventId,
      companyId: companyId.value,
      entity: 'bill_allocation',
      entityId: id.value,
      newRow: <String, Object?>{
        'source': sourceLineId.value,
        'settlement': settlementLineId.value,
        'amount': amountPaise,
      },
      actor: actor,
    );
    if (ev.isErr) throw TxFailure((ev as Err<AuditEvent>).error);
  }

  /// Reverse one active allocation, releasing its amount back to open
  /// (compensating history — the row is never deleted).
  Result<void> reverse({
    required EntityId id,
    required CompanyId companyId,
    required String reason,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (reason.trim().isEmpty || deviceId.isEmpty) {
      return err('validation', 'reversal reason and device id are required');
    }
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT allocation_id, source_voucher_line_id, '
      'settlement_voucher_line_id, allocated_amount_paise, status, '
      'operation_id FROM bill_allocation WHERE company_id = ? AND allocation_id = ?',
      <Object?>[companyId.value, id.value],
    );
    AllocationView? target;
    if (rows.isNotEmpty) {
      final Map<String, Object?> r = rows.first;
      target = AllocationView(
        allocationId: r['allocation_id'] as String,
        sourceLineId: r['source_voucher_line_id'] as String,
        settlementLineId: r['settlement_voucher_line_id'] as String,
        amountPaise: r['allocated_amount_paise'] as int,
        status: r['status'] as String,
        operationId: r['operation_id'] as String,
      );
    }
    final List<String> guardErrors = checkReversible(target);
    if (guardErrors.isNotEmpty) {
      return err('validation', guardErrors.first);
    }
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        _db.executeArgs(
          "UPDATE bill_allocation SET status = 'reversed' "
          'WHERE company_id = ? AND allocation_id = ?',
          <Object?>[companyId.value, id.value],
        );
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'bill_allocation',
          entityId: id.value,
          action: 'reverse',
          payloadHash: auditPayloadHash(<String, Object?>{
            'allocation_id': id.value,
            'status': 'reversed',
            'reason': reason.trim(),
          }),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'bill_allocation',
          entityId: id.value,
          newRow: <String, Object?>{
            'status': 'reversed',
            'reason': reason.trim(),
          },
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
      });
      return ok(null);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'bill-allocation-reverse');
      return err(be.code, be.message);
    }
  }
}
