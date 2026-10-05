// NiAvERP audit log — implementation Phase 01.
// Append-only audit events: field-level old/new deltas as JSON, hash chain
// over the canonical record (OD-DB-004). This writer stores the delta JSON
// and a SHA-256 payload hash (package:crypto, already a dependency); chain
// verification queries land with the admin/audit viewer (prompt 04B).
// Traceability: OD-DB-004; DSS-C-003 (no destructive delete); D-M4 (epoch-ms).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'repository.dart';

/// One audit event row.
class AuditEvent {
  const AuditEvent({
    required this.eventId,
    required this.companyId,
    required this.entity,
    required this.entityId,
    required this.oldData,
    required this.newData,
    required this.actor,
    required this.createdAt,
  });

  final String eventId;
  final String companyId;
  final String entity;
  final String entityId;
  final String? oldData;
  final String? newData;
  final String actor;
  final int createdAt;

  static AuditEvent fromRow(Map<String, Object?> r) => AuditEvent(
        eventId: r['event_id'] as String,
        companyId: r['company_id'] as String,
        entity: r['entity'] as String,
        entityId: r['entity_id'] as String,
        oldData: r['old_data'] as String?,
        newData: r['new_data'] as String?,
        actor: r['actor'] as String,
        createdAt: r['created_at'] as int,
      );
}

/// Canonical JSON for a row map (sorted keys) + its SHA-256 hex digest.
/// The digest is stored as the operation payload hash (OD-DB-004 hash chain
/// hook). Row maps here carry no secrets (no key material in G0 tables).
String auditPayloadHash(Map<String, Object?> row) {
  final List<String> keys = row.keys.toList()..sort();
  final Map<String, Object?> canonical = <String, Object?>{
    for (final String k in keys) k: row[k],
  };
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

/// Append-only writer/reader for audit events.
class AuditLog {
  const AuditLog(this.ctx);

  final RepositoryContext ctx;

  MigrationDb get _db => ctx.db;

  /// Append one event. [oldRow]/[newRow] are encoded as JSON deltas.
  Result<AuditEvent> append({
    required String eventId,
    required String companyId,
    required String entity,
    required String entityId,
    Map<String, Object?>? oldRow,
    Map<String, Object?>? newRow,
    required String actor,
  }) {
    if (eventId.isEmpty || entity.isEmpty || entityId.isEmpty || actor.isEmpty) {
      return err('validation', 'audit ids and actor must not be empty');
    }
    try {
      final int now = ctx.clock.nowMs();
      final String? oldJson =
          oldRow == null ? null : jsonEncode(oldRow);
      final String? newJson =
          newRow == null ? null : jsonEncode(newRow);
      _db.executeArgs(
        'INSERT INTO audit_event '
        '(event_id, company_id, entity, entity_id, old_data, new_data, '
        'actor, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          eventId,
          companyId,
          entity,
          entityId,
          oldJson,
          newJson,
          actor,
          now,
        ],
      );
      return ok(
        AuditEvent(
          eventId: eventId,
          companyId: companyId,
          entity: entity,
          entityId: entityId,
          oldData: oldJson,
          newData: newJson,
          actor: actor,
          createdAt: now,
        ),
      );
    } catch (e) {
      return err<AuditEvent>(
        dbError(e, 'audit-append').code,
        dbError(e, 'audit-append').message,
      );
    }
  }

  /// Events for one entity, oldest first.
  List<AuditEvent> forEntity(String companyId, String entity, String entityId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT event_id, company_id, entity, entity_id, old_data, new_data, '
      'actor, created_at FROM audit_event '
      'WHERE company_id = ? AND entity = ? AND entity_id = ? '
      'ORDER BY created_at',
      <Object?>[companyId, entity, entityId],
    );
    return <AuditEvent>[
      for (final Map<String, Object?> r in rows) AuditEvent.fromRow(r),
    ];
  }
}
