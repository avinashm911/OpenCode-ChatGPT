// Voucher numbering engine — one generator for all series (M04).
// Implements FR-M04-002 over the approved series shape, with every
// unspecified semantic recorded rather than invented:
// - Format: literal prefix + zero-padded sequence (width; overflow never
//   truncated) + literal suffix. Separators live INSIDE the affixes
//   (e.g. prefix 'INV-'): neither schema doc defines a separator column.
// - Scope: (company, series name) — the configured scope DSS-C-002
//   enforces via UNIQUE(company, series, voucher_no), which stays the
//   duplicate backstop under concurrency (single-user V1 calls generate
//   then create; a lost race surfaces as `conflict`, never a duplicate).
// - Mode: only `auto` generates; NULL/manual never do (safe default).
// - Restart: NULL/`never` runs continuous; any other restart value is
//   rejected until the cycle vocabulary is decided (recorded boundary).
// - Sequencing reads well-formed numbers only (matching affixes, all
//   digits); manual/out-of-scope numbers never disturb the sequence, and
//   the floor is always start_no.
// Traceability: FR-M04-002 (duplicate-free scope numbering); DSS-C-002;
// OD-001/O-08 (limited series, owner practice); G0-SCH scope notes.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

/// Render [seq] for [series]: affixes literal, digits zero-padded to width
/// (overflow keeps all digits — never truncated).
String formatVoucherNo(VoucherSeries series, int seq) {
  String digits = '$seq';
  if (series.width > 0) {
    digits = digits.padLeft(series.width, '0');
  }
  return '${series.prefix ?? ''}$digits${series.suffix ?? ''}';
}

/// Parse a stored number back to its sequence, or null when it is not a
/// well-formed number of this series (manual numbers, other scopes).
int? tryParseSequence(VoucherSeries series, String voucherNo) {
  String rest = voucherNo;
  final String pre = series.prefix ?? '';
  final String suf = series.suffix ?? '';
  if (pre.isNotEmpty) {
    if (!rest.startsWith(pre)) return null;
    rest = rest.substring(pre.length);
  }
  if (suf.isNotEmpty) {
    if (!rest.endsWith(suf) || rest.length < suf.length) return null;
    rest = rest.substring(0, rest.length - suf.length);
  }
  if (rest.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(rest)) return null;
  try {
    return int.parse(rest);
  } catch (_) {
    return null;
  }
}

/// Single numbering engine over stored vouchers.
class SeriesNumbering {
  const SeriesNumbering(this._db);

  final MigrationDb _db;

  /// Sequenced numbers already used in scope, ascending. Non-sequenced
  /// numbers are ignored (they never disturb generation).
  List<int> usedSequences(CompanyId companyId, VoucherSeries series) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT voucher_no FROM voucher WHERE company_id = ? AND series = ?',
      <Object?>[companyId.value, series.name],
    );
    final List<int> out = <int>[];
    for (final Map<String, Object?> r in rows) {
      final int? seq = tryParseSequence(series, r['voucher_no'] as String);
      if (seq != null) out.add(seq);
    }
    out.sort();
    return out;
  }

  /// Next document number for [series] in [companyId]'s scope.
  Result<String> nextNumber(CompanyId companyId, VoucherSeries series) {
    if (series.mode != 'auto') {
      return err('validation',
          'series is not automatic (manual or unset mode never generates)');
    }
    if (series.restart != null && series.restart != 'never') {
      return err('validation',
          'unsupported restart cycle: ${series.restart} (continuous only)');
    }
    final List<int> used = usedSequences(companyId, series);
    int next = series.startNo;
    if (used.isNotEmpty && used.last + 1 > next) next = used.last + 1;
    return ok(formatVoucherNo(series, next));
  }

  /// Missing sequences in [start_no..max-used] (gap report input).
  /// Empty scope or nothing above start_no yields no gaps.
  Result<List<int>> seriesGaps(CompanyId companyId, VoucherSeries series) {
    final List<int> used = usedSequences(companyId, series);
    if (used.isEmpty || used.last < series.startNo) return ok(<int>[]);
    final Set<int> seen = used.toSet();
    final List<int> gaps = <int>[];
    for (int n = series.startNo; n < used.last; n++) {
      if (!seen.contains(n)) gaps.add(n);
    }
    return ok(gaps);
  }
}
