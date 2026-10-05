// NiAvERP G0 bill-wise settlement — Phase 2.
// Remaining-balance arithmetic, over-allocation rejection, reversal and
// duplicate-application detection over bill_allocation rows.
// Only allocations with status 'active' consume a balance; reversal marks the
// row 'reversed' (compensating history is preserved, never deleted —
// DSS-C-003). Status lifecycle beyond active/reversed is later-phase policy.
// Traceability: G0-SCH-003 (G1); FR-M06; DSS-C-003/004.

/// Read view of one bill_allocation row.
class AllocationView {
  AllocationView({
    required this.allocationId,
    required this.sourceLineId,
    required this.settlementLineId,
    required this.amountPaise,
    required this.status,
    required this.operationId,
  });
  final String allocationId;
  final String sourceLineId;
  final String settlementLineId;
  final int amountPaise;
  final String status;
  final String operationId;

  bool get isActive => status == 'active';
}

/// Outstanding on a source line: source amount minus active allocations.
/// Throws when the result would be negative (impossible balance = corrupt or
/// double-applied history — never silently clamped).
int remainingBalance(int sourceAmountPaise, List<AllocationView> allocations) {
  final int allocated = allocations
      .where((AllocationView a) => a.isActive)
      .fold(0, (int s, AllocationView a) => s + a.amountPaise);
  final int remaining = sourceAmountPaise - allocated;
  if (remaining < 0) {
    throw StateError('Impossible balance: allocated $allocated exceeds '
        'source $sourceAmountPaise');
  }
  return remaining;
}

/// Guard a new allocation. Returns error strings; empty means appliable.
/// Rejects: unknown/duplicate allocation identity, self-settlement,
/// non-positive or over-remaining amounts, replayed operation lineage.
List<String> checkApplicable({
  required String allocationId,
  required String sourceLineId,
  required String settlementLineId,
  required int amountPaise,
  required String operationId,
  required int sourceAmountPaise,
  required List<AllocationView> existing,
}) {
  final List<String> errors = <String>[];
  if (existing.any((AllocationView a) => a.allocationId == allocationId)) {
    errors.add('duplicate allocation_id: $allocationId');
  }
  if (existing.any((AllocationView a) =>
      a.isActive &&
      a.sourceLineId == sourceLineId &&
      a.settlementLineId == settlementLineId &&
      a.operationId == operationId)) {
    errors.add('duplicate application: same source/settlement/operation already active');
  }
  if (sourceLineId == settlementLineId) {
    errors.add('settlement line must differ from source line');
  }
  if (amountPaise <= 0) errors.add('allocated_amount_paise must be positive');
  int remaining;
  try {
    remaining = remainingBalance(sourceAmountPaise, existing);
  } on StateError catch (e) {
    errors.add(e.message);
    return errors;
  }
  if (amountPaise > remaining) {
    errors.add('over-allocation: $amountPaise exceeds remaining $remaining');
  }
  return errors;
}

/// Guard a reversal: the target must exist, be active, and the actor must
/// cite a reason (reason text itself is stored by the caller in audit).
List<String> checkReversible(AllocationView? target) {
  if (target == null) return <String>['unknown allocation_id'];
  if (!target.isActive) {
    return <String>['allocation ${target.allocationId} is not active'];
  }
  return <String>[];
}
