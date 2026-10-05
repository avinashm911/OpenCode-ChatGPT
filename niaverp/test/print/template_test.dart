// Host tests: shared print template model — Phase 6.
// Validates the single model both renderers consume.
// Traceability: FR-M21-001; D-M4.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/print/template.dart';

void main() {
  group('money formatting (paise integers)', () {
    test('Rs. thermal form and rupee-sign PDF form', () {
      expect(formatRs(15400), 'Rs.154.00');
      expect(formatRs(-45), 'Rs.-0.45');
      expect(formatRupeeSign(15400), '₹154.00');
    });
  });

  group('totals arithmetic', () {
    test('total = subtotal + tax + roundOff', () {
      final InvoiceTemplate t = InvoiceTemplate(
        shopName: 'S',
        invoiceNo: 'INV-1',
        dateIso: '2026-10-03',
        roundOffPaise: -40,
        lines: <TemplateLine>[
          TemplateLine(
              name: 'A', qtyQ4: 10000, ratePaise: 10000, amountPaise: 10000, taxPaise: 1800),
        ],
      );
      expect(t.subtotalPaise, 10000);
      expect(t.taxTotalPaise, 1800);
      expect(t.totalPaise, 11760);
    });
  });

  group('validation', () {
    test('empty shop/invoice/lines rejected; bad qty rejected', () {
      final InvoiceTemplate bad = InvoiceTemplate(
        shopName: '',
        invoiceNo: '',
        dateIso: '',
        roundOffPaise: 0,
        lines: <TemplateLine>[],
      );
      expect(validateTemplate(bad).isNotEmpty, isTrue);
      final InvoiceTemplate badQty = InvoiceTemplate(
        shopName: 'S',
        invoiceNo: 'INV-1',
        dateIso: '2026-10-03',
        roundOffPaise: 0,
        lines: <TemplateLine>[
          TemplateLine(
              name: 'A', qtyQ4: 0, ratePaise: 100, amountPaise: 0, taxPaise: 0),
        ],
      );
      expect(
          validateTemplate(badQty).any((String e) => e.contains('qtyQ4')),
          isTrue);
    });
  });
}
