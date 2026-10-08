// NiAvERP audit log — implementation Phase 01, hash chain in D2.
// Append-only audit events: field-level old/new deltas as JSON, hash chain
// over the canonical record (OD-DB-004). The writer stores the delta JSON
// plus per-row chain columns (prev_hash/row_hash, added by m017; NULL on
// pre-chain rows): row_hash covers the canonical event including prev_hash,
// so any rewrite breaks verification. Chain verification lives here
// (verifyAuditChain); the admin/audit viewer screen lands with prompt 11.
// Traceability: OD-DB-004; DB-004 (append-oriented, protected); DSS-C-003
// (no destructive delete); D-M4 (epoch-ms); D2 (A3/D2).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'operation_log.dart';
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
  /// D2-A3: the row joins the company's hash chain — prev_hash is the latest
  /// row_hash of the company (NULL at genesis), row_hash covers the canonical
  /// event including prev_hash. Both live in m017 columns (NULL on legacy).
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
      final String? prev = _latestHash(companyId);
      final String rowHash = auditPayloadHash(<String, Object?>{
        'event_id': eventId,
        'company_id': companyId,
        'entity': entity,
        'entity_id': entityId,
        'old_data': oldJson,
        'new_data': newJson,
        'actor': actor,
        'created_at': now,
        'prev_hash': prev,
      });
      _db.executeArgs(
        'INSERT INTO audit_event '
        '(event_id, company_id, entity, entity_id, old_data, new_data, '
        'actor, created_at, prev_hash, row_hash) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          eventId,
          companyId,
          entity,
          entityId,
          oldJson,
          newJson,
          actor,
          now,
          prev,
          rowHash,
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

  /// Events for one entity, oldest first. Deterministic: ties on created_at
  /// (same-ms writes share a clock value) break by insertion order (D2-C1).
  List<AuditEvent> forEntity(String companyId, String entity, String entityId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT event_id, company_id, entity, entity_id, old_data, new_data, '
      'actor, created_at FROM audit_event '
      'WHERE company_id = ? AND entity = ? AND entity_id = ? '
      'ORDER BY created_at, rowid',
      <Object?>[companyId, entity, entityId],
    );
    return <AuditEvent>[
      for (final Map<String, Object?> r in rows) AuditEvent.fromRow(r),
    ];
  }

  /// Latest chain hash of one company (NULL at genesis / all-legacy history).
  String? _latestHash(String companyId) {
    try {
      final List<Map<String, Object?>> rows = _db.queryArgs(
        'SELECT row_hash FROM audit_event WHERE company_id = ? '
        'AND row_hash IS NOT NULL ORDER BY rowid DESC LIMIT 1',
        <Object?>[companyId],
      );
      if (rows.isEmpty) return null;
      return rows.first['row_hash'] as String?;
    } catch (_) {
      return null; // Pre-chain schema (before m017): genesis.
    }
  }
}

/// Verify one company's audit hash chain (D2-A3, OD-DB-004). Returns error
/// strings; empty means the chain is intact. Legacy (NULL-hash) rows must
/// form a strict prefix; every chained row's stored hash must recompute, and
/// its prev_hash must link the previous chained row (NULL only at genesis).
List<String> verifyAuditChain(MigrationDb db, String companyId) {
  final List<String> errors = <String>[];
  List<Map<String, Object?>> rows;
  try {
    rows = db.queryArgs(
      'SELECT event_id, company_id, entity, entity_id, old_data, new_data, '
      'actor, created_at, prev_hash, row_hash FROM audit_event '
      'WHERE company_id = ? ORDER BY rowid',
      <Object?>[companyId],
    );
  } catch (_) {
    return <String>['audit chain columns unavailable (pre-m017 schema)'];
  }
  String? lastHash;
  bool chained = false;
  for (final Map<String, Object?> r in rows) {
    final String eventId = r['event_id'] as String;
    final Object? stored = r['row_hash'];
    if (stored == null) {
      if (chained) {
        errors.add('unchained legacy row after chain start: $eventId');
      }
      continue;
    }
    chained = true;
    final Object? prev = r['prev_hash'];
    if (prev == null) {
      if (lastHash != null) {
        errors.add('genesis link after chain start: $eventId');
      }
    } else if (prev != lastHash) {
      errors.add('broken prev link: $eventId');
    }
    final String recomputed = auditPayloadHash(<String, Object?>{
      'event_id': eventId,
      'company_id': r['company_id'],
      'entity': r['entity'],
      'entity_id': r['entity_id'],
      'old_data': r['old_data'],
      'new_data': r['new_data'],
      'actor': r['actor'],
      'created_at': r['created_at'],
      'prev_hash': prev,
    });
    if (recomputed != stored) {
      errors.add('hash mismatch (tampered row): $eventId');
    }
    lastHash = stored as String;
  }
  return errors;
}

/// Shared operation + audit lineage for one write (D2-D2). Performs the
/// operation append and the audit append with the caller's exact ids, action
/// and payload; returns the first error, if any. Callers keep their own
/// transaction/error mapping — this only removes the duplicated pair.
Result<void> recordLineage({
  required OperationLog ops,
  required AuditLog audit,
  required String opId,
  required String companyId,
  required String deviceId,
  required String entity,
  required String entityId,
  required String action,
  required String payloadHash,
  required String eventId,
  Map<String, Object?>? oldRow,
  Map<String, Object?>? newRow,
  required String actor,
}) {
  // B1 single write choke point (A5): every material write funnels through
  // here. Expired/denied companies refuse with a typed error; the caller's
  // transaction aborts, so a refused write leaves no residue. Reads, audit
  // appends, clock observations and trial-anchor bootstrapping never pass
  // through here and stay available in every state.
  final EntitlementGate? gate = ops.ctx.gate;
  if (gate != null && !gate.canWrite(companyId)) {
    return err<void>(
      'entitlement',
      'trial expired or denied: material writes are refused '
      '(read-only + export + backup remain)',
    );
  }
  final Result<OperationRecord> op = ops.append(
    opId: opId,
    companyId: companyId,
    deviceId: deviceId,
    entity: entity,
    entityId: entityId,
    action: action,
    payloadHash: payloadHash,
  );
  if (op.isErr) {
    final AppError e = (op as Err<OperationRecord>).error;
    return err<void>(e.code, e.message);
  }
  final Result<AuditEvent> ev = audit.append(
    eventId: eventId,
    companyId: companyId,
    entity: entity,
    entityId: entityId,
    oldRow: oldRow,
    newRow: newRow,
    actor: actor,
  );
  if (ev.isErr) {
    final AppError e = (ev as Err<AuditEvent>).error;
    return err<void>(e.code, e.message);
  }
  return ok(null);
}
