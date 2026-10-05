// Period-lock administration — controls slice (D-M5, G1).
// Writer over the m003 `period_lock` table (reads live in the voucher
// engine): create a dated lock and authorised unlock with reason + audit.
// An active lock (unlocked_at NULL) blocks posting on covered dates; the
// engine is the enforcer, this repository the administrator. Unlock
// requires a named actor and a non-empty reason, both stored with an audit
// event (D-M5: unlock needs reason + audit). Permission/rights checks wait
// on the users/roles slice (M19) — the actor identity is recorded, never
// invented as an authorization.
// Traceability: DB/DSS G0-SCH-002; D-M5; FR-COM-002; DSS-C-003.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One period-lock row.
class PeriodLock {
  const PeriodLock({
    required this.id,
    required this.companyId,
    required this.scope,
    required this.dateFrom,
    required this.dateTo,
    required this.status,
    required this.lockedBy,
    required this.lockedAt,
    this.unlockActor,
    this.unlockReason,
    this.unlockedAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String scope;
  final String dateFrom;
  final String dateTo;
  final String status;
  final String lockedBy;
  final int lockedAt;
  final String? unlockActor;
  final String? unlockReason;
  final int? unlockedAt;

  bool get isActive => unlockedAt == null;

  static PeriodLock fromRow(Map<String, Object?> r) => PeriodLock(
        id: EntityId(r['lock_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        scope: r['scope'] as String,
        dateFrom: r['date_from'] as String,
        dateTo: r['date_to'] as String,
        status: r['status'] as String,
        lockedBy: r['locked_by'] as String,
        lockedAt: r['locked_at'] as int,
        unlockActor: r['unlock_actor'] as String?,
        unlockReason: r['unlock_reason'] as String?,
        unlockedAt: r['unlocked_at'] as int?,
      );
}

class PeriodLockRepository {
  PeriodLockRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'lock_id, company_id, scope, date_from, date_to, status, locked_by, '
      'locked_at, unlock_actor, unlock_reason, unlocked_at';

  Result<PeriodLock> create({
    required EntityId id,
    required CompanyId companyId,
    required String scope,
    required String dateFrom,
    required String dateTo,
    required String lockedBy,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (scope.isEmpty || lockedBy.isEmpty || deviceId.isEmpty) {
      return err('validation',
          'scope, locking actor and device id must not be empty');
    }
    if (dateTo.compareTo(dateFrom) < 0) {
      return err('validation', 'lock range end must not precede its start');
    }
    PeriodLock? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO period_lock (lock_id, company_id, scope, date_from, '
          'date_to, status, locked_by, locked_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            scope,
            dateFrom,
            dateTo,
            'locked',
            lockedBy,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'lock_id': id.value,
          'company_id': companyId.value,
          'scope': scope,
          'date_from': dateFrom,
          'date_to': dateTo,
          'status': 'locked',
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'period_lock',
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
          entity: 'period_lock',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = PeriodLock(
          id: id,
          companyId: companyId,
          scope: scope,
          dateFrom: dateFrom,
          dateTo: dateTo,
          status: 'locked',
          lockedBy: lockedBy,
          lockedAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'period-lock-create');
      return err(be.code, be.message);
    }
  }

  /// Authorised unlock: the lock must exist, belong to the company and be
  /// active; [reason] is mandatory and stored with the audit event. The
  /// lock row is updated (compensating lifecycle, never deleted).
  Result<PeriodLock> unlock({
    required EntityId id,
    required CompanyId companyId,
    required String reason,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (reason.trim().isEmpty || deviceId.isEmpty) {
      return err(
          'validation', 'unlock reason and device id are required');
    }
    final PeriodLock? current = get(companyId, id);
    if (current == null) {
      return err('validation', 'lock does not exist in this company');
    }
    if (!current.isActive) {
      return err('validation', 'lock is already unlocked');
    }
    PeriodLock? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          "UPDATE period_lock SET status = 'unlocked', unlock_actor = ?, "
          'unlock_reason = ?, unlocked_at = ? '
          'WHERE company_id = ? AND lock_id = ?',
          <Object?>[
            actor,
            reason.trim(),
            now,
            companyId.value,
            id.value,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'lock_id': id.value,
          'status': 'unlocked',
          'reason': reason.trim(),
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'period_lock',
          entityId: id.value,
          action: 'unlock',
          payloadHash: auditPayloadHash(row),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'period_lock',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = get(companyId, id);
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'period-lock-unlock');
      return err(be.code, be.message);
    }
  }

  PeriodLock? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM period_lock WHERE company_id = ? AND lock_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return PeriodLock.fromRow(rows.first);
  }

  List<PeriodLock> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM period_lock WHERE company_id = ? '
      'ORDER BY date_from, lock_id',
      <Object?>[companyId.value],
    );
    return <PeriodLock>[
      for (final Map<String, Object?> r in rows) PeriodLock.fromRow(r),
    ];
  }
}
