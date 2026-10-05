// NiAvERP G0 entitlements — Phase 3.
// Trial/grace/expiry evaluation over trial_anchor rows plus denylist check.
// Approved numbers only: 3-month trial encoded in trial_ends_at at issuance
// (no month arithmetic here); 10-day full-function grace, then read-only +
// export + backup with data never deleted (D-04/O-05/D-FG-014); denylist hit
// denies. Clocks are injected (deterministic tests).
// Traceability: D-04/O-05/D-FG-014; D-11/D-13/A-R2; D-FG-012; G0-SCH-006.

/// Full-function grace length in days (approved: 10-day grace).
const int kGraceDays = 10;
const int kDayMs = 24 * 60 * 60 * 1000;

/// Entitlement outcome for one company at one instant.
enum EntitlementState {
  /// Within trial: full function.
  trialActive,

  /// Within 10 days after trial end: full function + daily reminder.
  graceActive,

  /// Past grace: read-only + export + backup (data never deleted).
  expired,

  /// Denylisted key: denied regardless of trial clock.
  denied,
}

/// Evaluate entitlement. [denylisted] is the denylist_entry hit for the
/// install key (hash-only lookup, OD-DB-004). Deny wins over the clock.
EntitlementState evaluateEntitlement({
  required int nowMs,
  required int trialEndsAtMs,
  required bool denylisted,
}) {
  if (denylisted) return EntitlementState.denied;
  if (nowMs <= trialEndsAtMs) return EntitlementState.trialActive;
  if (nowMs <= trialEndsAtMs + kGraceDays * kDayMs) {
    return EntitlementState.graceActive;
  }
  return EntitlementState.expired;
}

/// Writes allowed only with full function (trial or grace).
bool canWrite(EntitlementState state) =>
    state == EntitlementState.trialActive ||
    state == EntitlementState.graceActive;

/// Daily trial-expiry reminder is due only during grace.
bool needsExpiryReminder(EntitlementState state) =>
    state == EntitlementState.graceActive;

/// Export + backup stay available in every non-denied state (data is never
/// deleted and must remain recoverable/exportable — D-04).
bool canExportBackup(EntitlementState state) =>
    state != EntitlementState.denied;
