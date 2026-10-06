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

/// CGST/SGST split of an intra-state GST total (fixture convention
/// F-GST-SPLIT, PROPOSED): equal halves floored, the odd-paise remainder to
/// CGST. Stated here because 1 paise cannot be halved; owner to confirm.
({int cgst, int sgst}) splitCgstSgst(int totalPaise) {
  final int half = totalPaise ~/ 2;
  return (cgst: half + (totalPaise % 2), sgst: half);
}

/// Per-line GST for posting displays (D3-A2 documented subset): the rate is
/// the item's documented GST rate; the math is D-M4 (gstTotal) with the
/// P-DISC-PREC odd-to-CGST split. This is intra-state CGST/SGST ONLY — the
/// CGST+SGST-vs-IGST determination (place of supply) is NOT defined by the
/// documents (G0-VER-003), so no IGST arm is produced anywhere from this.
/// Callers must treat the result as a calculation aid behind that boundary.
({int gst, int cgst, int sgst}) lineGstPaise({
  required int netPaise,
  required int rateBps,
}) {
  final int gst = gstTotal(netPaise, rateBps);
  final ({int cgst, int sgst}) split = splitCgstSgst(gst);
  return (gst: gst, cgst: split.cgst, sgst: split.sgst);
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
