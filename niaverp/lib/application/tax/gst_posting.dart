// GST tax posting rules — CA reply 2026-10-07 (Q1-Q4), pure functions.
// Implements exactly what the reply approves; everything else blocks.
// Goods only: services are outside the automatic rule until separately
// specified. UT supplies (UTGST) are outside v1 scope with the UTGST ledgers
// (CA Q4): same-code pairs post CGST+SGST — flagged as a v1 boundary, never
// a silent guess (see DECISIONS.md P-GST-POST).
// Money: integer paise, quantities ×10⁴ (D-M4). No floating point anywhere.
// NOTE on authority: CGST Act Section 170 covers return/payment-level
// rounding only — it is NOT cited for invoice-line math anywhere here.
// Traceability: FR-M03-002; G0-VER-003; CA reply 2026-10-07.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/accounting/gst.dart';

/// Tax heads for one computed line or invoice (paise, never negative).
class TaxHeads {
  const TaxHeads({required this.cgst, required this.sgst, required this.igst});
  final int cgst;
  final int sgst;
  final int igst;

  int get total => cgst + sgst + igst;
}

/// Place-of-supply determination: intra-state (CGST+SGST) or inter-state.
class PlaceOfSupply {
  const PlaceOfSupply({required this.posState, required this.taxType});
  final String posState;

  /// 'intra' | 'inter'.
  final String taxType;
}

/// Tax ledger account names (CA Q4: accounting conventions, no UTGST/Cess).
class TaxLedgers {
  const TaxLedgers._();
  static const String outputCgst = 'Output CGST';
  static const String outputSgst = 'Output SGST';
  static const String outputIgst = 'Output IGST';
  static const String inputCgst = 'Input CGST';
  static const String inputSgst = 'Input SGST';
  static const String inputIgst = 'Input IGST';
}

/// Supply categories that refuse automatic tax posting (CA Q2/Q4).
const Set<String> kBlockedSupplyCategories = <String>{
  'reverse_charge',
  'export_sez',
  'zero_rated',
  'composition',
  'services',
};

/// Buyer registration types the rules distinguish.
const Set<String> kKnownRegistrationTypes = <String>{
  'registered',
  'unregistered',
  'composition',
};

/// Derive the 2-digit state code from a GSTIN, or null when invalid.
/// GSTIN shape: 15 uppercase alphanumerics, first two digits 01..38.
String? gstStateFromGstin(String? gstin) {
  if (gstin == null) return null;
  final String g = gstin.trim().toUpperCase();
  if (!RegExp(r'^[0-9A-Z]{15}$').hasMatch(g)) return null;
  final int? code = int.tryParse(g.substring(0, 2));
  if (code == null || code < 1 || code > 38) return null;
  return g.substring(0, 2);
}

/// True for a recorded 2-digit state code (01..38).
bool isValidStateCode(String? code) {
  if (code == null || code.length != 2) return false;
  final int? n = int.tryParse(code);
  return n != null && n >= 1 && n <= 38;
}

/// Inputs for one place-of-supply determination (all as-entered text).
class TaxContext {
  const TaxContext({
    this.supplierState,
    this.billState,
    this.shipState,
    this.thirdPartyDirection = false,
    this.supplyCategory,
    this.partyGstin,
    this.partyRegType,
  });

  /// Supplier (company) location; required to classify intra vs inter.
  /// Null (legacy company without a state) refuses taxable posting.
  final String? supplierState;
  final String? billState;
  final String? shipState;
  final bool thirdPartyDirection;
  final String? supplyCategory;
  final String? partyGstin;
  final String? partyRegType;
}

/// Determine the place of supply and tax type, or refuse with a code.
/// Order follows the CA reply: blocked categories first, then the
/// s.10(1)(b) third-party rule, then registered-GSTIN, then recorded
/// addresses, then the unregistered fallback. Never guesses.
Result<PlaceOfSupply> determinePlaceOfSupply(TaxContext ctx) {
  final String rawCategory = (ctx.supplyCategory ?? '').trim();
  final String category = rawCategory.isEmpty ? 'regular' : rawCategory;
  if (kBlockedSupplyCategories.contains(category)) {
    return err('blocked', 'supply category blocks automatic tax posting: $category');
  }
  if (!isValidStateCode(ctx.supplierState)) {
    return err('validation', 'supplier state is missing or invalid: posting refused');
  }
  final String supplier = ctx.supplierState!;
  final String? gstinState = gstStateFromGstin(ctx.partyGstin);
  final String? reg = ctx.partyRegType?.trim().isEmpty ?? true
      ? null
      : ctx.partyRegType!.trim();
  if (reg != null && !kKnownRegistrationTypes.contains(reg)) {
    return err('validation', 'unknown buyer registration type: posting refused');
  }
  if (reg == 'registered' && gstinState == null) {
    return err('validation',
        'registered buyer needs a valid GSTIN: posting refused, never guessed');
  }
  String? pos;
  if (ctx.thirdPartyDirection) {
    // s.10(1)(b): delivered on a third party's direction — the bill-to
    // party's principal place of business decides.
    if (!isValidStateCode(ctx.billState)) {
      return err('validation',
          'third-party delivery needs a valid bill-to state: posting refused');
    }
    pos = ctx.billState;
  } else if (reg == 'registered') {
    pos = gstinState;
  } else {
    pos = isValidStateCode(ctx.shipState)
        ? ctx.shipState
        : (isValidStateCode(ctx.billState) ? ctx.billState : gstinState);
  }
  pos ??= (reg == 'unregistered' ? supplier : null);
  if (pos == null) {
    return err('validation', 'place of supply cannot be determined: posting refused');
  }
  return ok(PlaceOfSupply(
    posState: pos,
    taxType: pos == supplier ? 'intra' : 'inter',
  ));
}

/// One taxable line: net taxable paise (after discount) + rate, or a
/// tax-free line (rateBps null — always allowed, contributes zero).
class TaxLineInput {
  const TaxLineInput({required this.taxablePaise, required this.rateBps});
  final int taxablePaise;
  final int? rateBps;
}

/// Compute one line's tax heads for a determined tax type.
/// Throws [ArgumentError] on negative inputs or unrepresentable totals.
TaxHeads computeLineTax(TaxLineInput line, String taxType) {
  if (taxType != 'intra' && taxType != 'inter') {
    throw ArgumentError('taxType must be intra or inter');
  }
  if (line.taxablePaise < 0) {
    throw ArgumentError('taxable base must be >= 0');
  }
  final int? rate = line.rateBps;
  if (rate == null) return const TaxHeads(cgst: 0, sgst: 0, igst: 0);
  if (rate < 0 || rate > 10000) {
    throw ArgumentError('rate_bps must be 0..10000');
  }
  if (taxType == 'intra') {
    final ({int cgst, int sgst}) halves = cgstSgstSeparate(line.taxablePaise, rate);
    return TaxHeads(cgst: halves.cgst, sgst: halves.sgst, igst: 0);
  }
  return TaxHeads(cgst: 0, sgst: 0, igst: gstTotal(line.taxablePaise, rate));
}

/// Aggregate heads over lines (multi-rate invoices group by rate upstream;
/// the sums here are order-independent).
TaxHeads sumTaxHeads(Iterable<TaxHeads> heads) {
  int cgst = 0, sgst = 0, igst = 0;
  for (final TaxHeads h in heads) {
    cgst += h.cgst;
    sgst += h.sgst;
    igst += h.igst;
  }
  return TaxHeads(cgst: cgst, sgst: sgst, igst: igst);
}
