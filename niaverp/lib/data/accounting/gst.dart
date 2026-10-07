// NiAvERP G0 GST rounding — Phase 2.
// Implements the APPROVED arithmetic (D-M4: integer paise, round-half-up;
// invoice round-off as a separate ledger line to the nearest rupee).
// The official rule-source attachment stays owner-evidence (G0-VER-002);
// these fixtures are PROPOSED golden fixtures built strictly from D-M4 and
// do not close G0-VER-002.
// Maximum two-decimal output holds by construction: every amount is integer
// paise. Traceability: D-M4/OD-DB-001; G0-SCH-004/007; FR-M16 (fields pending).

/// GST on a taxable base: round-half-up(base × rateBps / 10⁴), integer paise.
int gstTotal(int taxablePaise, int rateBps) {
  if (taxablePaise <= 0 || rateBps <= 0) return 0;
  return ((taxablePaise * rateBps) + 5000) ~/ 10000;
}

/// Invoice round-off ledger line (D-M4): nearest-rupee (half-up) minus total.
/// Positive = added to the bill, negative = deducted.
int invoiceRoundOff(int totalPaise) {
  final int rounded = ((totalPaise + 50) ~/ 100) * 100;
  return rounded - totalPaise;
}

/// Largest taxable base whose half-rate scaling cannot overflow 64-bit.
/// (CA reply Q3: CGST/SGST are computed separately from the half rate.)
const int _kMaxTaxablePaise = 9223372036854775807 ~/ 20000;

/// CGST and SGST computed SEPARATELY from the half rate (CA reply 2026-10-07,
/// Q3 — approved rule, replaces the PROPOSED total-split convention): each is
/// round-half-up(taxable × rateBps / 20000). The halves are always equal, so
/// no odd-paise remainder exists and none is assigned. Never compute a total
/// first and halve it (that path is rejected: it can differ by a paisa).
/// Throws [ArgumentError] on negative inputs or unrepresentable totals.
({int cgst, int sgst}) cgstSgstSeparate(int taxablePaise, int rateBps) {
  if (taxablePaise <= 0 || rateBps <= 0) return (cgst: 0, sgst: 0);
  if (taxablePaise > _kMaxTaxablePaise) {
    throw ArgumentError('taxable base overflows half-rate scaling');
  }
  final int half = ((taxablePaise * rateBps) + 10000) ~/ 20000;
  return (cgst: half, sgst: half);
}

/// Render integer paise as a decimal rupee string (always ≤ 2 decimals).
String formatRupees(int paise) {
  final String sign = paise < 0 ? '-' : '';
  final int mag = paise.abs();
  final String p = mag.remainder(100).toString().padLeft(2, '0');
  return '$sign${mag ~/ 100}.$p';
}

/// True when [s] carries at most two decimal places.
bool hasMaxTwoDecimals(String s) {
  final int dot = s.indexOf('.');
  if (dot < 0) return true;
  return s.length - dot - 1 <= 2;
}
