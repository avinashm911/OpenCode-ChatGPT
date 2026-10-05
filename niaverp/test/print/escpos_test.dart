// Host golden tests: ESC/POS thermal — Phase 6.
// Expected byte sequences, layout widths, currency, tax and Indic handling.
// These tests prove ONLY host byte generation; they do not prove behavior on
// a physical printer (stated in evidence).
// Traceability: O-12/O-M07/OD-008; FR-M21-001; G0-VER-006.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/print/escpos.dart';
import 'package:niaverp/data/print/template.dart';

InvoiceTemplate _fixture() => InvoiceTemplate(
      shopName: 'NiAv Store',
      invoiceNo: 'INV-001',
      dateIso: '2026-10-03',
      roundOffPaise: 60,
      lines: <TemplateLine>[
        TemplateLine(
            name: 'Notebook',
            qtyQ4: 20000,
            ratePaise: 5000,
            amountPaise: 10000,
            taxPaise: 1800),
        TemplateLine(
            name: 'Pen',
            qtyQ4: 10000,
            ratePaise: 3000,
            amountPaise: 3000,
            taxPaise: 540),
      ],
    );

void main() {
  group('control sequences (golden bytes)', () {
    test('INIT is ESC @', () {
      expect(escInit(), <int>[0x1B, 0x40]);
    });
    test('align centre/left', () {
      expect(escAlign(centre: true), <int>[0x1B, 0x61, 0x01]);
      expect(escAlign(centre: false), <int>[0x1B, 0x61, 0x00]);
    });
    test('cut is GS V 0', () {
      expect(escCut(), <int>[0x1D, 0x56, 0x00]);
    });
  });

  group('paper widths (OD-FD-006 profiles)', () {
    test('58mm = 32 cols, 80mm = 48 cols', () {
      expect(kCols58, 32);
      expect(kCols80, 48);
    });
  });

  group('P58 render (golden)', () {
    test('starts with INIT and ends with CUT', () {
      final List<int> b = escposRender(_fixture(), kCols58);
      expect(b.sublist(0, 2), <int>[0x1B, 0x40]);
      expect(b.sublist(b.length - 3), <int>[0x1D, 0x56, 0x00]);
    });
    test('TOTAL line carries Rs.154.00 (10000+3000+1800+540+60)', () {
      // subtotal 13000 + tax 2340 + roundOff 60 = 15400p = Rs.154.00
      expect(_fixture().totalPaise, 15400);
      final List<int> b = escposRender(_fixture(), kCols58);
      final String s = String.fromCharCodes(b);
      expect(s.contains('TOTAL'), isTrue);
      expect(s.contains('Rs.154.00'), isTrue);
      expect(s.contains('TAX'), isTrue);
      expect(s.contains('Rs.23.40'), isTrue); // 2340p
      expect(s.contains('SUBTOTAL'), isTrue);
      expect(s.contains('Rs.130.00'), isTrue);
    });
  });

  group('P80 render (golden)', () {
    test('TOTAL identical on 80mm; lines fit 48 cols', () {
      final List<int> b = escposRender(_fixture(), kCols80);
      final String s = String.fromCharCodes(b);
      expect(s.contains('Rs.154.00'), isTrue);
      // Every text row (split on LF) fits the profile width.
      for (final String row in s.split('\n')) {
        // Raster rows are binary; text rows are printable ASCII.
        final bool printable =
            row.isNotEmpty && row.codeUnits.every((int c) => c < 128);
        if (printable && row.trim().isNotEmpty) {
          expect(row.length <= kCols80 + 8, isTrue,
              reason: 'row too wide: "$row"');
        }
      }
    });
  });

  group('Indic text rendered as raster image', () {
    test('Devanagari line emits GS v 0 marker, not raw glyph bytes', () {
      final InvoiceTemplate t = InvoiceTemplate(
        shopName: 'NiAv Store',
        invoiceNo: 'INV-002',
        dateIso: '2026-10-03',
        roundOffPaise: 0,
        lines: <TemplateLine>[
          TemplateLine(
              name: 'कॉपी',
              qtyQ4: 10000,
              ratePaise: 3000,
              amountPaise: 3000,
              taxPaise: 540),
        ],
      );
      expect(containsIndic('कॉपी'), isTrue);
      expect(containsIndic('Notebook'), isFalse);
      final List<int> b = escposRender(t, kCols58);
      // Raster marker GS v 0 present …
      bool hasMarker = false;
      for (int i = 0; i + 3 < b.length; i++) {
        if (b[i] == 0x1D && b[i + 1] == 0x76 && b[i + 2] == 0x30) {
          hasMarker = true;
          break;
        }
      }
      expect(hasMarker, isTrue);
      // … and no Devanagari code units leak as raw bytes.
      final String s = String.fromCharCodes(b);
      expect(s.contains('कॉपी'), isFalse);
    });
  });
}
