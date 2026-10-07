// Fixture tests: GST rounding — Phase 2.
// Fixture IDs F-GST-001…008. All expectations hand-computed below and frozen;
// the implementation must satisfy them, never the reverse.
// Arithmetic basis: D-M4 (integer paise, round-half-up). Official rule-source
// attachment stays owner-evidence (G0-VER-002 — NOT closed here).
// Traceability: D-M4/OD-DB-001; G0-SCH-004/007; FR-M16.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/accounting/gst.dart';

void main() {
  group('F-GST-001 standard slab rate (18% on Rs100)', () {
    test('tax is exactly 1800p', () {
      // 10000 × 1800 / 10⁴ = 1800.0 → 1800.
      expect(gstTotal(10000, 1800), 1800);
    });
  });

  group('F-GST-002 fractional slab rate (5% on Rs9.99)', () {
    test('49.95p rounds half-up to 50p', () {
      // 999 × 500 / 10⁴ = 49.95 → 50.
      expect(gstTotal(999, 500), 50);
    });
  });

  group('F-GST-003 exact-half boundary rounds up', () {
    test('4.5p becomes 5p', () {
      // 25 × 1800 / 10⁴ = 4.5 → 5.
      expect(gstTotal(25, 1800), 5);
    });
  });

  group('F-GST-004 sub-paise fraction rounds down', () {
    test('0.15p becomes 0p', () {
      // 3 × 500 / 10⁴ = 0.15 → 0.
      expect(gstTotal(3, 500), 0);
    });
  });

  group('F-GST-005 line-level versus invoice-level rounding', () {
    test('line-level is authoritative (D-M4): 5 + 5, not 9', () {
      final int l1 = gstTotal(25, 1800); // 4.5 → 5
      final int l2 = gstTotal(25, 1800); // 4.5 → 5
      final int invoiceLevel = gstTotal(50, 1800); // 9.0 → 9
      expect(l1, 5);
      expect(l2, 5);
      expect(invoiceLevel, 9);
      // Approved rule prices each line; the 1p gap is WHY line-level wins.
      expect(l1 + l2, 10);
      expect(l1 + l2 != invoiceLevel, isTrue);
    });
  });

  group('F-GST-006 invoice round-off ledger line (nearest rupee)', () {
    test('Rs1000.45 rounds down with a -45p line', () {
      expect(invoiceRoundOff(100045), -45);
    });
    test('Rs1000.78 rounds up with a +22p line', () {
      expect(invoiceRoundOff(100078), 22);
    });
    test('exact half-rupee rounds up (+50p)', () {
      expect(invoiceRoundOff(100050), 50);
    });
  });

  group('F-GST-007 maximum two-decimal output', () {
    test('paise formatting never exceeds two decimals', () {
      expect(formatRupees(1), '0.01');
      expect(formatRupees(100045), '1000.45');
      expect(formatRupees(-45), '-0.45');
      for (final String s in <String>['0.01', '1000.45', '-0.45', '7']) {
        expect(hasMaxTwoDecimals(s), isTrue, reason: s);
      }
      expect(hasMaxTwoDecimals('1.005'), isFalse);
    });
  });

  group('F-GST-008 CGST/SGST computed separately (CA reply 2026-10-07 Q3)', () {
    test('equal halves from the half rate; never split a total', () {
      // 10000 × 1800 half-rate: (10000×1800+10000)/20000 = 900 each.
      final ({int cgst, int sgst}) even = cgstSgstSeparate(10000, 1800);
      expect((even.cgst, even.sgst), (900, 900));
      // 10006 × 1800: separate halves are 901/901 (sum 1802), while a
      // total-first computation gives 1801 — the 1p gap is WHY the CA
      // rejects splitting a total. Halves are always equal here.
      final ({int cgst, int sgst}) oddBase = cgstSgstSeparate(10006, 1800);
      expect((oddBase.cgst, oddBase.sgst), (901, 901));
      // CA worked example line 1: 1123457p @ 18% → 101111 each.
      final ({int cgst, int sgst}) worked = cgstSgstSeparate(1123457, 1800);
      expect((worked.cgst, worked.sgst), (101111, 101111));
      expect(cgstSgstSeparate(10000, 0), (cgst: 0, sgst: 0));
      expect(cgstSgstSeparate(0, 1800), (cgst: 0, sgst: 0));
    });
  });
}
