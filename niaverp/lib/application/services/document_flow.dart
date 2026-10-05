// Document conversion flow — eligibility math over lineage (FR-M09).
// Answers "how much may still convert" without inventing workflow states:
// a source's remaining quantity is its stored quantity minus quantities
// already consumed by ACTIVE links; `reversed` links release their qty
// back (FR-M09-002). Pools are computed at both scopes so partial and
// multiple conversions compose safely: a line-level link must fit its
// line pool AND its voucher pool; a header-level link must fit the voucher
// pool (voucher pool = Σ line qty − ALL active links out of the voucher).
// Link quantities must be positive; non-positive source pools reject any
// conversion (returns, with negative qty, are therefore not convertible).
// Source/target document states (open/converted/closed) stay downstream:
// this service neither reads nor writes voucher status.
// Traceability: FR-M09-001 (eligible quantities, partial/multiple);
// FR-M09-002 (lineage, reversal reopening); D-M4 (integer qty).

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/document_link_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

/// Conversion flow over lineage storage.
class DocumentFlow {
  DocumentFlow(
    this.ctx, {
    required this.ops,
    required this.audit,
    required this.vouchers,
    required this.links,
  });

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;
  final VoucherRepository vouchers;
  final DocumentLinkRepository links;

  MigrationDb get _db => ctx.db;

  /// Quantity already consumed by active links out of one source line.
  int convertedLineQty(
    CompanyId companyId,
    EntityId sourceLineId,
  ) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      "SELECT SUM(qty_q4) AS q FROM document_link WHERE company_id = ? "
      "AND source_line_id = ? AND status = 'active'",
      <Object?>[companyId.value, sourceLineId.value],
    );
    return (rows.first['q'] as int?) ?? 0;
  }

  /// Quantity already consumed by active links out of one source voucher
  /// (header-level links plus every line-level link beneath it).
  int convertedVoucherQty(CompanyId companyId, EntityId sourceVoucherId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      "SELECT SUM(qty_q4) AS q FROM document_link WHERE company_id = ? "
      "AND source_voucher_id = ? AND status = 'active'",
      <Object?>[companyId.value, sourceVoucherId.value],
    );
    return (rows.first['q'] as int?) ?? 0;
  }

  /// Remaining convertible quantity of one source line.
  /// Returns null when the line is absent in this company.
  int? remainingLineQty(CompanyId companyId, EntityId sourceLineId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT qty_q4, voucher_id FROM voucher_line '
      'WHERE company_id = ? AND voucher_line_id = ?',
      <Object?>[companyId.value, sourceLineId.value],
    );
    if (rows.isEmpty) return null;
    return (rows.first['qty_q4'] as int) -
        convertedLineQty(companyId, sourceLineId);
  }

  /// Remaining convertible quantity of one source voucher (Σ line qty minus
  /// all active conversions beneath it). Null when absent in this company.
  int? remainingVoucherQty(CompanyId companyId, EntityId sourceVoucherId) {
    final List<Map<String, Object?>> hasVoucher = _db.queryArgs(
      'SELECT voucher_id FROM voucher WHERE company_id = ? AND voucher_id = ?',
      <Object?>[companyId.value, sourceVoucherId.value],
    );
    if (hasVoucher.isEmpty) return null;
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT SUM(qty_q4) AS q FROM voucher_line '
      'WHERE company_id = ? AND voucher_id = ?',
      <Object?>[companyId.value, sourceVoucherId.value],
    );
    final int total = (rows.first['q'] as int?) ?? 0;
    return total - convertedVoucherQty(companyId, sourceVoucherId);
  }

  /// Convert [qtyQ4] from source to target, recording an active link.
  /// Line refs are optional (header-level conversion); when a source line
  /// is named it must belong to the source voucher, and likewise for the
  /// target. The quantity must fit every pool it draws from.
  Result<DocumentLink> convert({
    required EntityId linkId,
    required CompanyId companyId,
    required EntityId sourceVoucherId,
    EntityId? sourceLineId,
    required EntityId targetVoucherId,
    EntityId? targetLineId,
    required int qtyQ4,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (qtyQ4 <= 0 || deviceId.isEmpty) {
      return err('validation', 'conversion quantity must be > 0');
    }
    if (vouchers.get(companyId, sourceVoucherId) == null ||
        vouchers.get(companyId, targetVoucherId) == null) {
      return err('validation', 'source and target must exist in this company');
    }
    if (sourceLineId != null &&
        !_lineBelongsTo(companyId, sourceLineId, sourceVoucherId)) {
      return err('validation', 'source line must belong to the source voucher');
    }
    if (targetLineId != null &&
        !_lineBelongsTo(companyId, targetLineId, targetVoucherId)) {
      return err('validation', 'target line must belong to the target voucher');
    }
    final int? voucherPool = remainingVoucherQty(companyId, sourceVoucherId);
    if (voucherPool == null || qtyQ4 > voucherPool) {
      return err('validation', 'conversion exceeds remaining source quantity');
    }
    if (sourceLineId != null) {
      final int? linePool = remainingLineQty(companyId, sourceLineId);
      if (linePool == null || qtyQ4 > linePool) {
        return err(
            'validation', 'conversion exceeds remaining source-line quantity');
      }
    }
    return links.create(
      id: linkId,
      companyId: companyId,
      sourceVoucherId: sourceVoucherId,
      sourceLineId: sourceLineId,
      targetVoucherId: targetVoucherId,
      targetLineId: targetLineId,
      qtyQ4: qtyQ4,
      status: 'active',
      deviceId: deviceId,
      opId: opId,
      eventId: eventId,
      actor: actor,
    );
  }

  bool _lineBelongsTo(
    CompanyId companyId,
    EntityId lineId,
    EntityId voucherId,
  ) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT voucher_id FROM voucher_line '
      'WHERE company_id = ? AND voucher_line_id = ?',
      <Object?>[companyId.value, lineId.value],
    );
    if (rows.isEmpty) return false;
    return (rows.first['voucher_id'] as String) == voucherId.value;
  }
}
