// Voucher open balances — prompt 06 (FR-M14-001 validation side, G1).
// Open amount of one voucher = Σ voucher_line amounts − Σ active
// bill_allocation amounts on its lines (same rule as
// settlement.remainingBalance, applied at voucher scope). A negative result
// throws: allocated history can never exceed posted lines (corrupt or
// double-applied rows are never silently clamped). Due-date tracking and the
// receipt/payment picker UI stay downstream — the approved schema carries no
// due-date column (FR-M14-001 interaction → prompt 11).
// Traceability: FR-M14-001 (allocation cannot exceed open balance); G0-SCH-003.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

/// Open (unsettled) amount, in paise, of one voucher in its company.
/// Vouchers without lines, or unknown ids, report zero.
int voucherOpenBalance(
  MigrationDb db,
  CompanyId companyId,
  EntityId voucherId,
) {
  final List<Map<String, Object?>> lines = db.queryArgs(
    'SELECT voucher_line_id, amount_paise FROM voucher_line '
    'WHERE company_id = ? AND voucher_id = ?',
    <Object?>[companyId.value, voucherId.value],
  );
  if (lines.isEmpty) return 0;
  int total = 0;
  final List<Object?> lineIds = <Object?>[];
  for (final Map<String, Object?> line in lines) {
    total += line['amount_paise'] as int;
    lineIds.add(line['voucher_line_id'] as String);
  }
  final String placeholders =
      List<String>.filled(lineIds.length, '?').join(', ');
  final List<Map<String, Object?>> allocs = db.queryArgs(
    'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
    "WHERE company_id = ? AND status = 'active' "
    'AND source_voucher_line_id IN ($placeholders)',
    <Object?>[companyId.value, ...lineIds],
  );
  final int allocated = (allocs.first['a'] as int?) ?? 0;
  final int remaining = total - allocated;
  if (remaining < 0) {
    throw StateError('Impossible balance: allocated $allocated exceeds '
        'voucher total $total');
  }
  return remaining;
}
