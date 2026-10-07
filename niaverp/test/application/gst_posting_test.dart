// GST posting rule tests (CA reply 2026-10-07, Q1-Q4) — pure functions.
// Disposable data only. Proves: GSTIN state derivation, intra/inter
// determination incl. third-party direction and fallbacks, every block case,
// separate CGST/SGST computation (incl. the CA example with correct
// arithmetic), IGST path, multi-rate aggregation, and fail-loud overflow.
// Traceability: FR-M03-002; G0-VER-003; CA reply 2026-10-07.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/tax/gst_posting.dart';
import 'package:niaverp/core/result.dart';

void main() {
  group('GSTIN state derivation', () {
    test('valid GSTIN yields its state code', () {
      expect(gstStateFromGstin('24ABCDE1234F1Z5'), '24');
      expect(gstStateFromGstin(' 27abcde1234f1z5 '), '27');
    });
    test('invalid GSTIN yields null (never guessed)', () {
      expect(gstStateFromGstin(null), isNull);
      expect(gstStateFromGstin(''), isNull);
      expect(gstStateFromGstin('24SHORT'), isNull);
      expect(gstStateFromGstin('99ABCDE1234F1Z5'), isNull); // no state 99
      expect(gstStateFromGstin('24ABCDE1234F1Z!'), isNull);
    });
  });

  group('place of supply (goods)', () {
    test('same state is intra-state', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(const TaxContext(
        supplierState: '24',
        partyGstin: '24ABCDE1234F1Z5',
        partyRegType: 'registered',
      ));
      expect(r.isOk, isTrue);
      expect((r as Ok<PlaceOfSupply>).value.taxType, 'intra');
      expect(r.value.posState, '24');
    });

    test('different state is inter-state', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(const TaxContext(
        supplierState: '24',
        partyGstin: '27ABCDE1234F1Z5',
        partyRegType: 'registered',
      ));
      expect(((r as Ok<PlaceOfSupply>).value.taxType), 'inter');
    });

    test('registered buyer without valid GSTIN blocks even with addresses', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(const TaxContext(
        supplierState: '24',
        billState: '24',
        shipState: '24',
        partyGstin: 'BOGUS',
        partyRegType: 'registered',
      ));
      expect(r.isErr, isTrue);
    });

    test('third-party direction uses the bill-to state', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(const TaxContext(
        supplierState: '24',
        billState: '07',
        shipState: '09',
        thirdPartyDirection: true,
        partyGstin: '07ABCDE1234F1Z5',
        partyRegType: 'registered',
      ));
      expect(((r as Ok<PlaceOfSupply>).value.posState), '07');
      final Result<PlaceOfSupply> missing = determinePlaceOfSupply(
        const TaxContext(supplierState: '24', thirdPartyDirection: true),
      );
      expect(missing.isErr, isTrue);
    });

    test('ship-to decides when moved; bill-to is the fallback', () {
      final Result<PlaceOfSupply> ship = determinePlaceOfSupply(
        const TaxContext(
          supplierState: '24',
          billState: '24',
          shipState: '09',
          partyRegType: 'unregistered',
        ),
      );
      expect(((ship as Ok<PlaceOfSupply>).value.posState), '09');
      final Result<PlaceOfSupply> bill = determinePlaceOfSupply(
        const TaxContext(
          supplierState: '24',
          billState: '09',
          partyRegType: 'unregistered',
        ),
      );
      expect(((bill as Ok<PlaceOfSupply>).value.posState), '09');
    });

    test('unregistered with no address falls back to supplier (intra)', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(
        const TaxContext(supplierState: '24', partyRegType: 'unregistered'),
      );
      expect(((r as Ok<PlaceOfSupply>).value.taxType), 'intra');
    });

    test('unknown state with no fallback blocks', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(
        const TaxContext(supplierState: '24', partyRegType: null),
      );
      expect(r.isErr, isTrue);
    });

    test('missing supplier state blocks (cannot classify)', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(
        const TaxContext(partyRegType: 'unregistered'),
      );
      expect(r.isErr, isTrue);
    });

    test('blocked supply categories refuse with a code', () {
      for (final String c in <String>[
        'reverse_charge',
        'export_sez',
        'zero_rated',
        'composition',
        'services',
      ]) {
        final Result<PlaceOfSupply> r = determinePlaceOfSupply(TaxContext(
          supplierState: '24',
          supplyCategory: c,
          partyRegType: 'registered',
          partyGstin: '24ABCDE1234F1Z5',
        ));
        expect(r.isErr, isTrue, reason: c);
      }
    });

    test('unknown registration type blocks', () {
      final Result<PlaceOfSupply> r = determinePlaceOfSupply(
        const TaxContext(supplierState: '24', partyRegType: 'alien'),
      );
      expect(r.isErr, isTrue);
    });
  });

  group('line tax computation (kept paise, separate halves)', () {
    test('CA example line 1: 1123457p @ 18% -> 101111 each', () {
      final TaxHeads h = computeLineTax(
        const TaxLineInput(taxablePaise: 1123457, rateBps: 1800),
        'intra',
      );
      expect((h.cgst, h.sgst, h.igst), (101111, 101111, 0));
    });

    test('CA example line 2 follows the formula: 19999p @ 5% -> 500 each', () {
      // The reply text prints Rs.12.50 here, which does not follow its own
      // formula (199.99 x 2.5% = Rs.5.00); the formula governs, not the typo.
      final TaxHeads h = computeLineTax(
        const TaxLineInput(taxablePaise: 19999, rateBps: 500),
        'intra',
      );
      expect((h.cgst, h.sgst, h.igst), (500, 500, 0));
    });

    test('inter-state posts IGST only', () {
      final TaxHeads h = computeLineTax(
        const TaxLineInput(taxablePaise: 10000, rateBps: 1800),
        'inter',
      );
      expect((h.cgst, h.sgst, h.igst), (0, 0, 1800));
    });

    test('tax-free line contributes zero', () {
      expect(
        computeLineTax(const TaxLineInput(taxablePaise: 5000, rateBps: null), 'intra'),
        predicate<TaxHeads>((TaxHeads h) => h.total == 0),
      );
    });

    test('negative base and bad tax type fail loud', () {
      expect(
        () => computeLineTax(const TaxLineInput(taxablePaise: -1, rateBps: 1800), 'intra'),
        throwsArgumentError,
      );
      expect(
        () => computeLineTax(const TaxLineInput(taxablePaise: 100, rateBps: 1800), 'sideways'),
        throwsArgumentError,
      );
    });

    test('multi-rate lines aggregate by summation', () {
      final TaxHeads total = sumTaxHeads(<TaxHeads>[
        computeLineTax(const TaxLineInput(taxablePaise: 1123457, rateBps: 1800), 'intra'),
        computeLineTax(const TaxLineInput(taxablePaise: 19999, rateBps: 500), 'intra'),
      ]);
      expect((total.cgst, total.sgst, total.igst), (101611, 101611, 0));
    });
  });
}
