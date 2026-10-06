// Entry-field parsing for voucher forms (D3-B1, application layer).
// Pure functions shared by the billing and inventory forms: user-typed
// quantities (units → ×10⁴), money (rupees → paise) and percents (→ basis
// points). Invalid input yields -1 (empty money/percent yields 0); widgets
// keep their own messages and states. Moved out of voucher_form_screen.dart
// so parsing is tested once and reused, never reimplemented per screen.
// Traceability: D-M4 (paise/Q4/bps); D3 (B1/B2).

/// Parse a quantity in units to ×10⁴, or -1 when invalid (D3-B1).
int parseQuantityQ4(String raw) {
  final double? units = double.tryParse(raw.trim());
  if (units == null || units <= 0) return -1;
  return (units * 10000).round();
}

/// Parse rupees to integer paise (empty counts as zero), or -1 when invalid.
int parsePaise(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final double? rupees = double.tryParse(t);
  if (rupees == null || rupees < 0) return -1;
  return (rupees * 100).round();
}

/// Parse percent to integer basis points (empty counts as zero), or -1 when
/// invalid (negative or above 100%).
int parsePercentBps(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final double? pct = double.tryParse(t);
  if (pct == null || pct < 0 || pct > 100) return -1;
  return (pct * 100).round();
}
