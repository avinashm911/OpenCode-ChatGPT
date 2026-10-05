// NiAvERP operation log — implementation Phase 01.
// Append-only operation envelope per SYNC §3 (+ base_version SYNC §3 /
// G0-SCH-005, defaulting to 1 = genesis). Replay-safe by op_id and by
// UNIQUE (company_id, device_id, seq) (DSS-C-004).
// Traceability: SYNC §3; DSS-C-004; G0-SCH-005; OD-DB-006 (conflict shape).

import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'repository.dart';

/// One operation envelope row.
class OperationRecord {
  const OperationRecord({
    required this.opId,
    required this.companyId,
    required this.deviceId,
    required this.seq,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.baseVersion,
    required this.createdAt,
  });

  final String opId;
  final String companyId;
  final String deviceId;
  final int seq;
  final String entity;
  final String entityId;
  final String action;
  final int baseVersion;
  final int createdAt;

  static OperationRecord fromRow(Map<String, Object?> r) => OperationRecord(
        opId: r['op_id'] as String,
        companyId: r['company_id'] as String,
        deviceId: r['device_id'] as String,
        seq: r['seq'] as int,
        entity: r['entity'] as String,
        entityId: r['entity_id'] as String,
        action: r['action'] as String,
        baseVersion: (r['base_version'] as int?) ?? 1,
        createdAt: r['created_at'] as int,
      );
}

/// Append-only writer/reader for the operation envelope.
class OperationLog {
  const OperationLog(this.ctx);

  final RepositoryContext ctx;

  MigrationDb get _db => ctx.db;

  /// Append one operation. Callers must already hold a transaction when the
  /// operation belongs to a larger write (repositories do this for them).
  Result<OperationRecord> append({
    required String opId,
    required String companyId,
    required String deviceId,
    required String entity,
    required String entityId,
    required String action,
    int? baseVersion,
    String? payloadHash,
  }) {
    if (opId.isEmpty || entity.isEmpty || entityId.isEmpty || action.isEmpty) {
      return err('validation', 'op/entity/action ids must not be empty');
    }
    try {
      final int seq = nextOperationSeq(_db, companyId, deviceId);
      final int now = ctx.clock.nowMs();
      _db.executeArgs(
        'INSERT INTO operation '
        '(op_id, company_id, device_id, seq, entity, entity_id, action, '
        'base_version, payload_hash, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          opId,
          companyId,
          deviceId,
          seq,
          entity,
          entityId,
          action,
          baseVersion ?? 1,
          payloadHash,
          now,
        ],
      );
      return ok(
        OperationRecord(
          opId: opId,
          companyId: companyId,
          deviceId: deviceId,
          seq: seq,
          entity: entity,
          entityId: entityId,
          action: action,
          baseVersion: baseVersion ?? 1,
          createdAt: now,
        ),
      );
    } catch (e) {
      return err<OperationRecord>(
        dbError(e, 'operation-append').code,
        dbError(e, 'operation-append').message,
      );
    }
  }

  /// Operations for one entity, oldest first (replay order).
  List<OperationRecord> forEntity(String companyId, String entity, String entityId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT op_id, company_id, device_id, seq, entity, entity_id, action, '
      'base_version, created_at FROM operation '
      'WHERE company_id = ? AND entity = ? AND entity_id = ? ORDER BY seq',
      <Object?>[companyId, entity, entityId],
    );
    return <OperationRecord>[
      for (final Map<String, Object?> r in rows) OperationRecord.fromRow(r),
    ];
  }
}
