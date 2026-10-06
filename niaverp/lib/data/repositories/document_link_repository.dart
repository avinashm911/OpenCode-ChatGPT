// NiAvERP document-link repository — DSS transaction slice (FR-M09).
// Storage for the m010 `document_link` lineage table (DSS §3 exact shape:
// link/company/source+target voucher+line refs, qty, status). Line refs are
// nullable (header-level links); voucher refs are FK-enforced. Status stays
// free TEXT: the conversion/eligibility math and reversal-reopen rules that
// interpret it belong to the document-flow slice, never invented here.
// Every write carries operation + audit lineage.
// Traceability: FR-M09-002 (lineage storage); DSS §3; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One lineage link row.
class DocumentLink {
  const DocumentLink({
    required this.id,
    required this.companyId,
    required this.sourceVoucherId,
    this.sourceLineId,
    required this.targetVoucherId,
    this.targetLineId,
    required this.qtyQ4,
    required this.status,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId sourceVoucherId;
  final EntityId? sourceLineId;
  final EntityId targetVoucherId;
  final EntityId? targetLineId;
  final int qtyQ4;
  final String status;
  final int createdAt;

  static DocumentLink fromRow(Map<String, Object?> r) => DocumentLink(
        id: EntityId(r['link_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        sourceVoucherId: EntityId(r['source_voucher_id'] as String),
        sourceLineId: r['source_line_id'] == null
            ? null
            : EntityId(r['source_line_id'] as String),
        targetVoucherId: EntityId(r['target_voucher_id'] as String),
        targetLineId: r['target_line_id'] == null
            ? null
            : EntityId(r['target_line_id'] as String),
        qtyQ4: r['qty_q4'] as int,
        status: r['status'] as String,
        createdAt: r['created_at'] as int,
      );
}

class DocumentLinkRepository {
  DocumentLinkRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'link_id, company_id, source_voucher_id, source_line_id, '
      'target_voucher_id, target_line_id, qty_q4, status, created_at';

  /// Record one lineage link. Both vouchers must live in the writing
  /// company (FKs alone cannot enforce company scope — DSS-C-001). Links
  /// are born `active` (consuming eligibility); only [reverse] moves them
  /// to `reversed`. No other status is admitted — the lifecycle stays
  /// closed so eligibility math cannot silently drift.
  Result<DocumentLink> create({
    required EntityId id,
    required CompanyId companyId,
    required EntityId sourceVoucherId,
    EntityId? sourceLineId,
    required EntityId targetVoucherId,
    EntityId? targetLineId,
    required int qtyQ4,
    required String status,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (status.isEmpty || deviceId.isEmpty) {
      return err('validation', 'link status and device id must not be empty');
    }
    if (status != 'active') {
      return err('validation', 'new links are created active');
    }
    if (!_inCompany(companyId, sourceVoucherId) ||
        !_inCompany(companyId, targetVoucherId)) {
      return err('foreign-key', 'linked vouchers must exist in this company');
    }
    DocumentLink? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO document_link (link_id, company_id, '
          'source_voucher_id, source_line_id, target_voucher_id, '
          'target_line_id, qty_q4, status, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            sourceVoucherId.value,
            sourceLineId?.value,
            targetVoucherId.value,
            targetLineId?.value,
            qtyQ4,
            status,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'link_id': id.value,
          'company_id': companyId.value,
          'source_voucher_id': sourceVoucherId.value,
          'target_voucher_id': targetVoucherId.value,
          'qty_q4': qtyQ4,
          'status': status,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'document_link',
          entityId: id.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
          eventId: eventId,
          newRow: row,
          actor: actor,
        );
        if (lineage.isErr) {
          txFailure = (lineage as Err<void>).error;
          throw const RepositoryAbort();
        }
        done = DocumentLink(
          id: id,
          companyId: companyId,
          sourceVoucherId: sourceVoucherId,
          sourceLineId: sourceLineId,
          targetVoucherId: targetVoucherId,
          targetLineId: targetLineId,
          qtyQ4: qtyQ4,
          status: status,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'document-link-create');
      return err(be.code, be.message);
    }
  }

  bool _inCompany(CompanyId companyId, EntityId voucherId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT voucher_id FROM voucher WHERE company_id = ? AND voucher_id = ?',
      <Object?>[companyId.value, voucherId.value],
    );
    return rows.isNotEmpty;
  }

  /// Links out of one source voucher, oldest first (lineage order).
  List<DocumentLink> linksFrom(CompanyId companyId, EntityId sourceVoucherId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM document_link '
      'WHERE company_id = ? AND source_voucher_id = ? ORDER BY created_at',
      <Object?>[companyId.value, sourceVoucherId.value],
    );
    return <DocumentLink>[
      for (final Map<String, Object?> r in rows) DocumentLink.fromRow(r),
    ];
  }

  /// Links into one target voucher, oldest first.
  List<DocumentLink> linksTo(CompanyId companyId, EntityId targetVoucherId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM document_link '
      'WHERE company_id = ? AND target_voucher_id = ? ORDER BY created_at',
      <Object?>[companyId.value, targetVoucherId.value],
    );
    return <DocumentLink>[
      for (final Map<String, Object?> r in rows) DocumentLink.fromRow(r),
    ];
  }

  /// Reverse one active link, reopening its quantity for re-conversion
  /// (FR-M09-002: reversals must reopen eligible quantities). The link row
  /// is never deleted or rewritten — only its status moves to `reversed`
  /// with a mandatory reason and full lineage. Mirrors the settlement
  /// active/reversed lifecycle (G0-SCH-003 precedent).
  Result<DocumentLink> reverse({
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
    final List<Map<String, Object?>> current = _db.queryArgs(
      'SELECT $_cols FROM document_link WHERE company_id = ? AND link_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (current.isEmpty) {
      return err('validation', 'link does not exist in this company');
    }
    if ((current.first['status'] as String) != 'active') {
      return err('validation', 'only active links can be reversed');
    }
    DocumentLink? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        _db.executeArgs(
          "UPDATE document_link SET status = 'reversed', "
          'record_version = record_version + 1 '
          'WHERE company_id = ? AND link_id = ?',
          <Object?>[companyId.value, id.value],
        );
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'document_link',
          entityId: id.value,
          action: 'reverse',
          payloadHash: auditPayloadHash(<String, Object?>{
            'link_id': id.value,
            'status': 'reversed',
            'reason': reason.trim(),
          }),
          eventId: eventId,
          oldRow: <String, Object?>{
            'link_id': id.value,
            'status': current.first['status'],
          },
          newRow: <String, Object?>{
            'status': 'reversed',
            'reason': reason.trim(),
          },
          actor: actor,
        );
        if (lineage.isErr) {
          txFailure = (lineage as Err<void>).error;
          throw const RepositoryAbort();
        }
        final List<Map<String, Object?>> reloaded = _db.queryArgs(
          'SELECT $_cols FROM document_link WHERE company_id = ? AND link_id = ?',
          <Object?>[companyId.value, id.value],
        );
        done = DocumentLink.fromRow(reloaded.first);
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'document-link-reverse');
      return err(be.code, be.message);
    }
  }
}
