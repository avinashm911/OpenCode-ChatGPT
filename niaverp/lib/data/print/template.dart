// NiAvERP G0 print template model — Phase 6.
// Single shared template used by BOTH the ESC/POS thermal renderer and the
// PDF layout calculator. No renderer may invent fields; both consume this
// model verbatim (pack: "using the same template model").
// Money INTEGER paise; quantity INTEGER ×10⁴; line amount round-half-up
// (D-M4). Currency rendered as `Rs.` on thermal (ESC/POS code pages have no
// ₹ glyph guarantee) and as `₹` in PDF layout source strings.
// Traceability: O-12/O-M07/OD-008; FR-M21-001; D-M4.

/// One printed invoice line (projection of a voucher line + tax).
class TemplateLine {
  TemplateLine({
    required this.name,
    required this.qtyQ4,
    required this.ratePaise,
    required this.amountPaise,
    required this.taxPaise,
  });

  final String name;
  final int qtyQ4;
  final int ratePaise;
  final int amountPaise;
  final int taxPaise;
}

/// One printed invoice/report (minimal G0 invoice shape).
class InvoiceTemplate {
  InvoiceTemplate({
    required this.shopName,
    required this.invoiceNo,
    required this.dateIso,
    required this.lines,
    required this.roundOffPaise,
  });

  final String shopName;
  final String invoiceNo;
  final String dateIso;
  final List<TemplateLine> lines;
  final int roundOffPaise;

  int get subtotalPaise =>
      lines.fold(0, (int s, TemplateLine l) => s + l.amountPaise);
  int get taxTotalPaise =>
      lines.fold(0, (int s, TemplateLine l) => s + l.taxPaise);
  int get totalPaise => subtotalPaise + taxTotalPaise + roundOffPaise;
}

/// Render integer paise as `Rs.1234.56` (thermal-safe ASCII).
String formatRs(int paise) {
  final String sign = paise < 0 ? '-' : '';
  final int mag = paise.abs();
  final String p = (mag % 100).toString().padLeft(2, '0');
  return 'Rs.$sign${mag ~/ 100}.$p';
}

/// Render integer paise as `₹1234.56` (PDF source string; rasterised at print).
String formatRupeeSign(int paise) {
  final String sign = paise < 0 ? '-' : '';
  final int mag = paise.abs();
  final String p = (mag % 100).toString().padLeft(2, '0');
  return '₹$sign${mag ~/ 100}.$p';
}

/// True when [s] contains Devanagari (Indic) code points.
/// Indic text is rendered as a raster image on both paths (approved baseline:
// O-12 resolution: "Indic text rendered as raster image").
bool containsIndic(String s) {
  for (final int cp in s.runes) {
    if (cp >= 0x0900 && cp <= 0x097F) return true;
  }
  return false;
}

/// Validate a template. Returns error strings; empty means printable.
List<String> validateTemplate(InvoiceTemplate t) {
  final List<String> errors = <String>[];
  if (t.shopName.isEmpty) errors.add('shopName must not be empty');
  if (t.invoiceNo.isEmpty) errors.add('invoiceNo must not be empty');
  if (t.dateIso.isEmpty) errors.add('dateIso must not be empty');
  if (t.lines.isEmpty) errors.add('at least one line is required');
  for (int i = 0; i < t.lines.length; i++) {
    final TemplateLine l = t.lines[i];
    if (l.name.isEmpty) errors.add('line $i: name must not be empty');
    if (l.qtyQ4 <= 0) errors.add('line $i: qtyQ4 must be positive');
    if (l.ratePaise < 0) errors.add('line $i: ratePaise must be >= 0');
    if (l.amountPaise < 0) errors.add('line $i: amountPaise must be >= 0');
    if (l.taxPaise < 0) errors.add('line $i: taxPaise must be >= 0');
  }
  return errors;
}
