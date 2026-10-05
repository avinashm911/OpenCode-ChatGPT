// NiAvERP G0 validators — Phase 1.
// Pure-Dart, dependency-free validation for the seven G0 deltas.
// Structural rules that SQLite can check live in the migration CHECKs;
// lifecycle/policy rules that the documents assign to app logic live here so
// they stay reviewable without a schema change.
// Money INTEGER paise; quantity INTEGER x10^4; round-half-up (D-M4).

/// Scale factor for quantities (×10⁴) and paise halves for rounding.
const int kQtyScale = 10000;

/// Gross line amount: round-half-up(|qty| × rate / 10⁴), sign of qty kept
/// (negative qty = returns/credit lines). D-M4.
int lineAmount(int qtyQ4, int ratePaise) {
  final int sign = qtyQ4 < 0 ? -1 : 1;
  final int mag = qtyQ4.abs() * ratePaise;
  return sign * ((mag + kQtyScale ~/ 2) ~/ kQtyScale);
}

/// Discount for a gross line amount (G0-SCH-007 explicit rule, PROPOSED for
/// Phase 2 fixture confirmation): an explicit positive amount wins over the
/// rate; otherwise rate basis points apply with round-half-up.
int discountFor(int grossPaise, int discountAmountPaise, int discountRateBps) {
  if (grossPaise <= 0) return 0;
  if (discountAmountPaise > 0) return discountAmountPaise;
  if (discountRateBps <= 0) return 0;
  return ((grossPaise * discountRateBps) + 5000) ~/ 10000;
}

/// Net line amount floored at zero (a discount never pays out).
int lineNet(int grossPaise, int discountAmountPaise, int discountRateBps) {
  final int net = grossPaise - discountFor(grossPaise, discountAmountPaise, discountRateBps);
  return net < 0 ? 0 : net;
}

/// Validate discount inputs. Returns error strings; empty means valid.
List<String> validateDiscountInputs(int amountPaise, int rateBps) {
  final List<String> errors = <String>[];
  if (amountPaise < 0) errors.add('discount_amount_paise must be >= 0');
  if (rateBps < 0 || rateBps > 10000) {
    errors.add('discount_rate_bps must be within 0..10000');
  }
  return errors;
}

/// Validate a period lock row (G0-SCH-002). Date comparison is ISO-text
/// safe (YYYY-MM-DD). The unlock triple must be all-set or all-null.
List<String> validatePeriodLock({
  required String dateFrom,
  required String dateTo,
  String? unlockActor,
  String? unlockReason,
  int? unlockedAt,
}) {
  final List<String> errors = <String>[];
  if (dateTo.compareTo(dateFrom) < 0) {
    errors.add('date_to must be >= date_from');
  }
  final int setCount = (unlockActor == null ? 0 : 1) +
      (unlockReason == null ? 0 : 1) +
      (unlockedAt == null ? 0 : 1);
  if (setCount != 0 && setCount != 3) {
    errors.add('unlock_actor/unlock_reason/unlocked_at must be all set or all null');
  }
  return errors;
}

/// Validate a bill allocation row (G0-SCH-003 structural guards; settlement
/// arithmetic and over-allocation rejection are Phase 2 fixture logic).
List<String> validateAllocation({
  required String sourceLineId,
  required String settlementLineId,
  required int amountPaise,
}) {
  final List<String> errors = <String>[];
  if (sourceLineId == settlementLineId) {
    errors.add('settlement line must differ from source line');
  }
  if (amountPaise < 0) errors.add('allocated_amount_paise must be >= 0');
  return errors;
}

/// Validate an effective-dated tax row (G0-SCH-004).
List<String> validateTaxRange(String effectiveFrom, String? effectiveTo) {
  if (effectiveTo != null && effectiveTo.compareTo(effectiveFrom) < 0) {
    return <String>['effective_to must be null or >= effective_from'];
  }
  return <String>[];
}
