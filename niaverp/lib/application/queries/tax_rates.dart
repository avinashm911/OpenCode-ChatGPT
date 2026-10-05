// Effective-dated HSN rate lookup — prompt 07 (FR-M16-001 structure side).
// Resolves the G0-SCH-004 tax_rate_hsn table for one HSN on one date: the
// covering row with the latest effective_from wins, null when nothing
// covers the date. ISO-text comparison is date-safe (validators.dart).
// The table ships EMPTY by design — statutory values wait for G3
// verification (DSS-O03 / P-EINV-SCH) — so this resolves mechanics only,
// never values. Registration-type vocabularies and voucher tax capture stay
// downstream (FR-M16-001/002 validation is VERIFY).
// Traceability: FR-M16-001; G0-SCH-004; OD-DB-003.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

/// GST rate in basis points for [hsnCode] on [dateIso] (YYYY-MM-DD), or null
/// when no effective row covers the date in this company.
int? hsnRateBps(
  MigrationDb db,
  CompanyId companyId,
  String hsnCode,
  String dateIso,
) {
  final List<Map<String, Object?>> rows = db.queryArgs(
    'SELECT rate_bps FROM tax_rate_hsn '
    'WHERE company_id = ? AND hsn_code = ? '
    'AND effective_from <= ? AND (effective_to IS NULL OR ? <= effective_to) '
    'ORDER BY effective_from DESC LIMIT 1',
    <Object?>[companyId.value, hsnCode, dateIso, dateIso],
  );
  if (rows.isEmpty) return null;
  return rows.first['rate_bps'] as int;
}
