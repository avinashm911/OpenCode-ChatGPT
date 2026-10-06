// NiAvERP G0 entitlements — Phase 3, clock integrity in D2.
// Trial/grace/expiry evaluation over trial_anchor rows plus denylist check.
// Approved numbers only: 3-month trial encoded in trial_ends_at at issuance
// (no month arithmetic here); 10-day full-function grace, then read-only +
// export + backup with data never deleted (D-04/O-05/D-FG-014); denylist hit
// denies. Clocks are injected (deterministic tests).
// D2-E3: device time is never trusted raw — SEC §3.5 trusted_now =
// max(device_now, last_seen_max), where the high-water mark persists in
// trial_anchor.last_seen_at (m017). Rollback keeps trusted time (billing is
// never blocked for a wrong clock); warning surfacing and security-event
// logging belong to the caller — no UI changes in D2.
// Traceability: D-04/O-05/D-FG-014; D-11/D-13/A-R2; D-FG-012; G0-SCH-006;
// SEC §3.5; D2 (E3).

import 'package:niaverp/data/migrations/migration_runner.dart';

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

/// Outcome of observing the device clock against the persisted mark.
class ClockObservation {
  const ClockObservation({
    required this.trustedNowMs,
    required this.rolledBack,
    required this.lastSeenMs,
  });

  /// SEC §3.5 trusted_now: max(device time, high-water mark).
  final int trustedNowMs;

  /// True when the device clock moved behind the persisted mark.
  final bool rolledBack;

  /// The persisted mark after this observation (never moves backwards).
  final int lastSeenMs;
}

/// Observe the device clock for one company (D2-E3, SEC §3.5). Reads
/// trial_anchor.last_seen_at, persists the mark when it advances, and reports
/// rollback without blocking the caller. Evaluation itself takes
/// [ClockObservation.trustedNowMs] as its now.
ClockObservation observeDeviceClock(
  MigrationDb db, {
  required String companyId,
  required int deviceNowMs,
}) {
  int? lastSeen;
  try {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT last_seen_at FROM trial_anchor WHERE company_id = ?',
      <Object?>[companyId],
    );
    if (rows.isNotEmpty) {
      lastSeen = rows.first['last_seen_at'] as int?;
    }
  } catch (_) {
    lastSeen = null; // Pre-m017 schema: no mark yet.
  }
  final int trusted =
      lastSeen == null || deviceNowMs >= lastSeen ? deviceNowMs : lastSeen;
  final bool rolledBack = lastSeen != null && deviceNowMs < lastSeen;
  if (lastSeen == null || trusted > lastSeen) {
    try {
      db.executeArgs(
        'UPDATE trial_anchor SET last_seen_at = ?, '
        'record_version = record_version + 1 WHERE company_id = ?',
        <Object?>[trusted, companyId],
      );
    } catch (_) {
      // Pre-m017 schema: nothing persisted; evaluation still uses trusted.
    }
  }
  return ClockObservation(
    trustedNowMs: trusted,
    rolledBack: rolledBack,
    lastSeenMs: trusted,
  );
}
