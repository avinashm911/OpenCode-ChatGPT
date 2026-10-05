// Host golden tests: PDF layout — Phase 6.
// Layout widths, currency, tax and page-break results for A4/A5.
// Host geometry only; not on-device print/share proof.
// Traceability: O-12/O-M07/OD-008; FR-M21-001; G0-VER-006.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/print/pdf_layout.dart';
import 'package:niaverp/data/print/template.dart';

InvoiceTemplate _fixture(int n) => InvoiceTemplate(
      shopName: 'NiAv Store',
      invoiceNo: 'INV-001',
      dateIso: '2026-10-03',
      roundOffPaise: 0,
      lines: List<TemplateLine>.generate(
        n,
        (int i) => TemplateLine(
          name: 'Item ${i + 1}',
          qtyQ4: 10000,
          ratePaise: 1000,
          amountPaise: 1000,
          taxPaise: 180,
        ),
      ),
    );

void main() {
  group('page geometry (golden)', () {
    test('A4 content width 523pt, A5 content width 348pt', () {
      final PdfLayout a4 = pdfLayout(_fixture(2), PdfPage.a4);
      final PdfLayout a5 = pdfLayout(_fixture(2), PdfPage.a5);
      expect(a4.contentWidth, 523.0);
      expect(a5.contentWidth, 348.0);
    });
    test('A5 fits fewer lines per page than A4', () {
      final PdfLayout a4 = pdfLayout(_fixture(2), PdfPage.a4);
      final PdfLayout a5 = pdfLayout(_fixture(2), PdfPage.a5);
      expect(a5.linesPerPage < a4.linesPerPage, isTrue);
      expect(a4.linesPerPage > 0, isTrue);
    });
  });

  group('currency, tax and totals', () {
    test('TOTAL/TAX/SUBTOTAL rows carry rupee strings', () {
      final PdfLayout l = pdfLayout(_fixture(2), PdfPage.a4);
      final String all =
          l.pages.expand((LaidPage p) => p.lines).map((LaidLine x) => x.text).join('\n');
      // 2 lines × (1000 + 180) = subtotal 2000p, tax 360p, total 2360p.
      expect(all.contains('SUBTOTAL'), isTrue);
      expect(all.contains('TAX'), isTrue);
      expect(all.contains('TOTAL'), isTrue);
      expect(all.contains('₹23.60'), isTrue); // total
      expect(all.contains('₹3.60'), isTrue); // tax
    });
  });

  group('page breaks', () {
    test('2 lines fit one page; 80 lines break across pages', () {
      final PdfLayout one = pdfLayout(_fixture(2), PdfPage.a4);
      expect(one.pageCount, 1);
      final PdfLayout many = pdfLayout(_fixture(80), PdfPage.a4);
      expect(many.pageCount > 1, isTrue);
      // Page numbers are sequential from 1.
      for (int i = 0; i < many.pages.length; i++) {
        expect(many.pages[i].number, i + 1);
      }
    });
  });

  group('Indic flagged raster', () {
    test('Devanagari row is flagged raster, Latin is not', () {
      final InvoiceTemplate t = InvoiceTemplate(
        shopName: 'NiAv Store',
        invoiceNo: 'INV-003',
        dateIso: '2026-10-03',
        roundOffPaise: 0,
        lines: <TemplateLine>[
          TemplateLine(
              name: 'कॉपी', qtyQ4: 10000, ratePaise: 3000, amountPaise: 3000, taxPaise: 540),
          TemplateLine(
              name: 'Pen', qtyQ4: 10000, ratePaise: 1000, amountPaise: 1000, taxPaise: 180),
        ],
      );
      final PdfLayout l = pdfLayout(t, PdfPage.a4);
      final List<LaidLine> rows =
          l.pages.expand((LaidPage p) => p.lines).toList();
      final LaidLine indic =
          rows.firstWhere((LaidLine r) => r.text.contains('कॉपी'));
      final LaidLine latin =
          rows.firstWhere((LaidLine r) => r.text.contains('Pen'));
      expect(indic.raster, isTrue);
      expect(latin.raster, isFalse);
    });
  });
}
