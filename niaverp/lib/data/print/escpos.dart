// NiAvERP G0 ESC/POS thermal renderer — Phase 6.
// Bluetooth ESC/POS thermal output for 58 mm and 80 mm paper, driven by the
// shared InvoiceTemplate (template.dart). Pure-Dart byte builder; the
// Bluetooth transport itself is device-side (PENDING-INPUT until a frozen
// printer matrix exists under OD-FD-006).
// Host golden tests assert exact bytes, widths, currency, tax and Indic
// handling. Host tests prove ONLY host byte generation — stated plainly in
// evidence; they do not prove behavior on a physical printer.
// Traceability: O-12/O-M07/OD-008; FR-M21-001; G0-VER-006 (G5).

import 'template.dart';

/// Printable columns per paper width (approved thermal profiles).
const int kCols58 = 32;
const int kCols80 = 48;

/// Supported column profiles. Anything else must fail visibly before
/// rendering (FR-M21-001) — output is never silently squeezed onto an
/// unsupported width. The physical matrix itself stays G5 evidence
/// (G0-VER-006); this guard only enforces the two approved host profiles.
const List<int> kSupportedCols = <int>[kCols58, kCols80];

/// Null when [cols] is a supported profile, else a visible-failure message
/// naming the requested width and the supported set.
String? checkPrinterCols(int cols) => kSupportedCols.contains(cols)
    ? null
    : 'unsupported printer width: $cols columns (supported: 32, 48)';

/// ESC/POS control bytes.
const int kEsc = 0x1B;
const int kGs = 0x1D;
const int kLf = 0x0A;

/// Initialise printer: ESC @.
List<int> escInit() => <int>[kEsc, 0x40];

/// Select alignment: ESC a n (0 left, 1 centre).
List<int> escAlign({required bool centre}) =>
    <int>[kEsc, 0x61, centre ? 0x01 : 0x00];

/// Full cut: GS V 0.
List<int> escCut() => <int>[kGs, 0x56, 0x00];

/// Raster-image placeholder header for one Indic line (GS v 0).
/// Real bitmap bytes come from the platform rasteriser on-device; this host
/// marker is deterministic so golden tests can assert "Indic went raster".
List<int> rasterMarker(String text, int cols) {
  int h = 0;
  for (final int c in text.codeUnits) {
    h = ((h * 31) + c) & 0xFFFF;
  }
  return <int>[kGs, 0x76, 0x30, 0x00, cols & 0xFF, h & 0xFF, (h >> 8) & 0xFF];
}

List<int> _ascii(String s) {
  final List<int> out = <int>[];
  for (final int c in s.codeUnits) {
    out.add(c < 128 ? c : 0x3F); // non-ASCII → '?'; Indic never reaches here
  }
  return out;
}

String _pad2(String left, String right, int cols) {
  if (left.length + right.length + 1 > cols) {
    final int keep = cols - right.length - 1;
    final String l = keep > 0 ? left.substring(0, keep) : '';
    return '$l $right';
  }
  return left + ' ' * (cols - left.length - right.length) + right;
}

String _centre(String s, int cols) {
  if (s.length >= cols) return s.substring(0, cols);
  final int pad = (cols - s.length) ~/ 2;
  return ' ' * pad + s;
}

/// Render [t] for [cols] columns (use kCols58 / kCols80).
/// Indic line names are emitted as raster markers, never as raw text bytes.
List<int> escposRender(InvoiceTemplate t, int cols) {
  final List<int> out = <int>[];
  out.addAll(escInit());
  out.addAll(escAlign(centre: true));
  out.addAll(_ascii(_centre(t.shopName, cols)));
  out.add(kLf);
  out.addAll(escAlign(centre: false));
  out.addAll(_ascii(_pad2('Bill ${t.invoiceNo}', t.dateIso, cols)));
  out.add(kLf);
  out.addAll(_ascii('-' * cols));
  out.add(kLf);
  for (final TemplateLine l in t.lines) {
    if (containsIndic(l.name)) {
      out.addAll(rasterMarker(l.name, cols));
      out.add(kLf);
    } else {
      final String name =
          l.name.length > cols ? l.name.substring(0, cols) : l.name;
      out.addAll(_ascii(_pad2(name, formatRs(l.amountPaise), cols)));
      out.add(kLf);
    }
    // Quantity × rate detail line (proves qty/rate survive to paper).
    final String detail =
        '  ${(l.qtyQ4 / 10000).toString()} x ${formatRs(l.ratePaise)}'
        ' +tax ${formatRs(l.taxPaise)}';
    final String d = detail.length > cols ? detail.substring(0, cols) : detail;
    out.addAll(_ascii(d));
    out.add(kLf);
  }
  out.addAll(_ascii('-' * cols));
  out.add(kLf);
  out.addAll(_ascii(_pad2('SUBTOTAL', formatRs(t.subtotalPaise), cols)));
  out.add(kLf);
  out.addAll(_ascii(_pad2('TAX', formatRs(t.taxTotalPaise), cols)));
  out.add(kLf);
  out.addAll(_ascii(_pad2('ROUND OFF', formatRs(t.roundOffPaise), cols)));
  out.add(kLf);
  out.addAll(_ascii(_pad2('TOTAL', formatRs(t.totalPaise), cols)));
  out.add(kLf);
  out.addAll(escCut());
  return out;
}
