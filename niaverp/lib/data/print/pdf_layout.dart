// NiAvERP G0 PDF layout calculator — Phase 6.
// PDF output through Android print/share for A4 and A5, driven by the shared
// InvoiceTemplate (template.dart). Pure-Dart geometry: the actual PDF bytes
// await the owner-confirmed `pdf`/`printing` package (UNVERIFIED candidate —
// never locked in here), so this file computes what WILL be laid out
// (positions, widths, page breaks) and golden tests assert it. Indic runs are
// flagged raster (same rule as thermal).
// Host tests prove ONLY host geometry — not on-device print/share behavior.
// Traceability: O-12/O-M07/OD-008; FR-M21-001; G0-VER-006 (G5).

import 'template.dart';

/// Page size in PostScript points (72 dpi).
enum PdfPage { a4, a5 }

double pageWidth(PdfPage p) => p == PdfPage.a4 ? 595.0 : 420.0;
double pageHeight(PdfPage p) => p == PdfPage.a4 ? 842.0 : 595.0;

const double kMargin = 36.0;
const double kHeaderH = 60.0;
const double kFooterH = 40.0;
const double kLineH = 14.0;

/// One laid-out line: source text + vertical position + raster flag.
class LaidLine {
  LaidLine({required this.text, required this.y, required this.raster});
  final String text;
  final double y;
  final bool raster;
}

/// One laid-out page.
class LaidPage {
  LaidPage({required this.number, required this.lines});
  final int number;
  final List<LaidLine> lines;
}

/// Full layout result for a template on one page size.
class PdfLayout {
  PdfLayout({
    required this.page,
    required this.contentWidth,
    required this.linesPerPage,
    required this.pages,
  });
  final PdfPage page;
  final double contentWidth;
  final int linesPerPage;
  final List<LaidPage> pages;

  int get pageCount => pages.length;
}

/// Lay out [t] on [page]. Geometry is deterministic; no clock/IO involved.
PdfLayout pdfLayout(InvoiceTemplate t, PdfPage page) {
  final double w = pageWidth(page);
  final double h = pageHeight(page);
  final double contentWidth = w - 2 * kMargin;
  final double bodyH = h - kMargin * 2 - kHeaderH - kFooterH;
  final int linesPerPage = bodyH ~/ kLineH;

  final List<String> rows = <String>[];
  rows.add('${t.shopName}  Bill ${t.invoiceNo}  ${t.dateIso}');
  for (final TemplateLine l in t.lines) {
    rows.add(
        '${l.name}  ${(l.qtyQ4 / 10000).toString()} x ${formatRupeeSign(l.ratePaise)}'
        ' = ${formatRupeeSign(l.amountPaise)} +tax ${formatRupeeSign(l.taxPaise)}');
  }
  rows.add('SUBTOTAL ${formatRupeeSign(t.subtotalPaise)}');
  rows.add('TAX ${formatRupeeSign(t.taxTotalPaise)}');
  rows.add('ROUND OFF ${formatRupeeSign(t.roundOffPaise)}');
  rows.add('TOTAL ${formatRupeeSign(t.totalPaise)}');

  final List<LaidPage> pages = <LaidPage>[];
  int n = 0;
  int idx = 0;
  while (idx < rows.length) {
    n += 1;
    final List<LaidLine> pl = <LaidLine>[];
    for (int i = 0; i < linesPerPage && idx < rows.length; i++, idx++) {
      final String row = rows[idx];
      pl.add(LaidLine(
        text: row,
        y: kMargin + kHeaderH + pl.length * kLineH,
        raster: containsIndic(row),
      ));
    }
    pages.add(LaidPage(number: n, lines: pl));
  }
  return PdfLayout(
    page: page,
    contentWidth: contentWidth,
    linesPerPage: linesPerPage,
    pages: pages,
  );
}
