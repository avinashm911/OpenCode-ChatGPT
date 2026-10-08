// NiAvERP trial service — B1 (M20.1/M20.2/M20.6 behaviour, M22.4 secure time).
// Trial start/record per company (trial_anchor row + app-private file copy),
// calendar-month trial end (PROPOSED arithmetic — owner approval pending),
// clock-guard observation with rollback audit, the single write gate, and the
// backend-facade entitlement queries. Licence keys and editions are B5.
// Rollback never blocks billing (SEC §3.5); expiry never deletes data (D-04).
// Traceability: SEC §3.3/§3.4/§3.5; D-04/O-05/D-FG-014; D-11/D-13/A-R2;
// G0-SCH-006; D-FG-012 (reissue limit counted in B5).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/security/entitlements.dart' as ent;

import 'trial_store.dart';

/// Trial length in calendar months (approved: 3-month trial, D-11).
/// The *arithmetic* (calendar months, UTC, day clamped) is a B1 proposal:
/// no source defines it. See DECISIONS.md P-TRIAL-END.
const int kTrialMonths = 3;

/// Trial end = start + [kTrialMonths] calendar months (UTC).
/// The day is clamped to the end of the target month (e.g. Aug 31 + 3 months
/// = Nov 30; Nov 30 + 3 months = Feb 28/29). Pure integer/calendar math.
int trialEndsAtMs(int startMs) {
  final DateTime s =
      DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
  int year = s.year;
  int month = s.month + kTrialMonths;
  year += (month - 1) ~/ 12;
  month = ((month - 1) % 12) + 1;
  final int dim = _daysInMonth(year, month);
  final int day = s.day > dim ? dim : s.day;
  return DateTime.utc(year, month, day).millisecondsSinceEpoch;
}

int _daysInMonth(int year, int month) {
  switch (month) {
    case 2:
      final bool leap =
          year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
      return leap ? 29 : 28;
    case 4:
    case 6:
    case 9:
    case 11:
      return 30;
    default:
      return 31;
  }
}

/// One trial_anchor row.
class TrialAnchor {
  const TrialAnchor({
    required this.anchorId,
    required this.companyId,
    required this.installedAtMs,
    required this.trialEndsAtMs,
    required this.lastSeenMs,
  });

  final String anchorId;
  final String companyId;
  final int installedAtMs;
  final int trialEndsAtMs;
  final int? lastSeenMs;
}

/// Full evaluation of one company at one instant.
class TrialEvaluation {
  const TrialEvaluation({
    required this.state,
    required this.effectiveStartMs,
    required this.effectiveEndsAtMs,
    required this.trustedNowMs,
    required this.denylisted,
  });

  final ent.EntitlementState state;
  final int effectiveStartMs;
  final int effectiveEndsAtMs;
  final int trustedNowMs;
  final bool denylisted;
}

/// Whole days left with full function (ceil). Zero when expired/denied.
int trialDaysLeft(ent.EntitlementState state, int effectiveEndsAtMs, int nowMs) {
  switch (state) {
    case ent.EntitlementState.trialActive:
      final int rest = effectiveEndsAtMs - nowMs;
      if (rest <= 0) return 0;
      return (rest + ent.kDayMs - 1) ~/ ent.kDayMs;
    case ent.EntitlementState.graceActive:
      final int rest = effectiveEndsAtMs + ent.kGraceDays * ent.kDayMs - nowMs;
      if (rest <= 0) return 0;
      return (rest + ent.kDayMs - 1) ~/ ent.kDayMs;
    case ent.EntitlementState.expired:
    case ent.EntitlementState.denied:
      return 0;
  }
}

/// Trial/clock/entitlement service (B1). Constructed once per backend;
/// stateless except the per-company clock observations (A3).
class TrialService {
  TrialService({
    required this.db,
    required this.clock,
    this.files,
    this.deviceId,
  });

  final MigrationDb db;
  final Clock clock;
  final TrialFileStore? files;

  /// Platform device identity. Null only in test scaffolding: the denylist
  /// check is then skipped (documented gap; production always supplies it).
  final String? deviceId;

  /// Latest clock observation per company (kept on the facade per A3).
  final Map<String, ent.ClockObservation> observations = <String, ent.ClockObservation>{};

  /// Latest guard diagnostic per company (null when the last guard was clean).
  /// Queryable without throwing: failures never become untyped crashes.
  final Map<String, String> lastGuardError = <String, String>{};

  /// True when the app-private install copy is present and valid.
  /// False covers missing store, missing file and corrupt file alike;
  /// enforcement then rests on the database anchors alone (R1 residual).
  bool get fileCopyUsable {
    final TrialFileStore? store = files;
    if (store == null) return false;
    try {
      return store.readInstallMs() != null;
    } on TrialStoreCorruptException {
      return false;
    }
  }

  int? _fileInstallMs() {
    final TrialFileStore? store = files;
    if (store == null) return null;
    try {
      return store.readInstallMs();
    } on TrialStoreCorruptException {
      return null;
    }
  }

  TrialAnchor? readAnchor(String companyId) {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT anchor_id, company_id, installed_at, trial_ends_at, '
      'last_seen_at FROM trial_anchor WHERE company_id = ?',
      <Object?>[companyId],
    );
    if (rows.isEmpty) return null;
    final Map<String, Object?> r = rows.first;
    return TrialAnchor(
      anchorId: r['anchor_id'] as String,
      companyId: r['company_id'] as String,
      installedAtMs: r['installed_at'] as int,
      trialEndsAtMs: r['trial_ends_at'] as int,
      lastSeenMs: r['last_seen_at'] as int?,
    );
  }

  /// Ensure the install file and the company's anchor row exist.
  /// Effective start is the EARLIEST copy found (file vs anchors vs now).
  TrialAnchor ensureCompanyAnchor(String companyId, int nowMs) {
    final TrialAnchor? existing = readAnchor(companyId);
    if (existing != null) return existing;
    final int? fileMs = _fileInstallMs();
    int? earliest;
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT MIN(installed_at) AS m FROM trial_anchor',
      <Object?>[],
    );
    if (rows.isNotEmpty) earliest = rows.first['m'] as int?;
    int start = nowMs;
    if (fileMs != null && fileMs < start) start = fileMs;
    if (earliest != null && earliest < start) start = earliest;
    db.executeArgs(
      'INSERT INTO trial_anchor '
      '(anchor_id, company_id, installed_at, trial_ends_at, status, '
      'created_at) VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        'anchor-$companyId',
        companyId,
        start,
        trialEndsAtMs(start),
        'trial',
        nowMs,
      ],
    );
    return readAnchor(companyId)!;
  }

  /// Evaluate one company at [nowMs]. Read-only: never creates rows.
  /// A company with no anchor and no file copy is a fresh install (trial).
  TrialEvaluation evaluate(String companyId, int nowMs) {
    final TrialAnchor? anchor = readAnchor(companyId);
    final int? fileMs = _fileInstallMs();
    if (anchor == null && fileMs == null) {
      return TrialEvaluation(
        state: ent.EntitlementState.trialActive,
        effectiveStartMs: nowMs,
        effectiveEndsAtMs: trialEndsAtMs(nowMs),
        trustedNowMs: nowMs,
        denylisted: false,
      );
    }
    int start = nowMs;
    if (anchor != null && anchor.installedAtMs < start) {
      start = anchor.installedAtMs;
    }
    if (fileMs != null && fileMs < start) start = fileMs;
    int ends = trialEndsAtMs(start);
    if (anchor != null) {
      final int recomputed = trialEndsAtMs(start);
      ends = anchor.trialEndsAtMs < recomputed
          ? anchor.trialEndsAtMs
          : recomputed;
    }
    final int trusted = anchor?.lastSeenMs == null || nowMs >= anchor!.lastSeenMs!
        ? nowMs
        : anchor.lastSeenMs!;
    final bool denied = _isDenied();
    return TrialEvaluation(
      state: ent.evaluateEntitlement(
          nowMs: trusted, trialEndsAtMs: ends, denylisted: denied),
      effectiveStartMs: start,
      effectiveEndsAtMs: ends,
      trustedNowMs: trusted,
      denylisted: denied,
    );
  }

  bool _isDenied() {
    final String? id = deviceId;
    if (id == null) return false;
    return isDenied(installKeyHash(id));
  }

  /// Hash-only denylist lookup (OD-DB-004). Row presence denies, in every
  /// clock state. No key format is invented here: the preimage is the
  /// device identity until B5 defines the licence-key format.
  bool isDenied(String keyHash) {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT 1 FROM denylist_entry WHERE key_hash = ?',
      <Object?>[keyHash],
    );
    return rows.isNotEmpty;
  }

  /// Observe the device clock for one company and guard the facade (A3).
  /// Keeps the observation on the facade, writes a security-event audit row
  /// on rollback, and never blocks the caller (rollback never blocks billing,
  /// SEC §3.5). Returns a typed diagnostic on audit failure instead of
  /// throwing; observation bookkeeping always happens first.
  Result<ent.ClockObservation> observeAndGuard({
    required String companyId,
    required int deviceNowMs,
    required String actor,
    required String eventId,
    required OperationLog ops,
    required AuditLog audit,
  }) {
    final ent.ClockObservation obs = ent.observeDeviceClock(
      db,
      companyId: companyId,
      deviceNowMs: deviceNowMs,
    );
    observations[companyId] = obs;
    lastGuardError.remove(companyId);
    if (!obs.rolledBack) return ok(obs);
    final Result<AuditEvent> ev = audit.append(
      eventId: eventId,
      companyId: companyId,
      entity: 'clock_observation',
      entityId: companyId,
      newRow: <String, Object?>{
        'reason': 'clock-rollback',
        'device_now_ms': deviceNowMs,
        'trusted_now_ms': obs.trustedNowMs,
      },
      actor: actor,
    );
    if (ev.isErr) {
      final AppError e = (ev as Err<AuditEvent>).error;
      lastGuardError[companyId] = '${e.code}: ${e.message}';
      return err<ent.ClockObservation>(e.code, e.message);
    }
    return ok(obs);
  }

  /// True when the latest observation for [companyId] reported a rollback.
  bool clockWarning(String companyId) =>
      observations[companyId]?.rolledBack ?? false;
}

/// Install-key hash for the denylist (sha256 hex of the device identity).
/// B1 decision (documented): B5 replaces the preimage with the licence-key
/// format once keys exist. Hash-only storage satisfies OD-DB-004 either way.
String installKeyHash(String deviceId) =>
    sha256.convert(utf8.encode(deviceId)).toString();

/// The single write choke point (A5): every material write funnels through
/// [recordLineage], which consults the gate on [RepositoryContext].
/// Trial/grace write; expired and denied refuse with a typed error; export
/// and backup stay allowed when not denied (they never pass through here).
/// The permission hook for B4 rides the same gate: [WritePermission] allows
/// everything until B4 supplies the rights model.
class TrialWriteGate extends EntitlementGate {
  const TrialWriteGate(this.trial);

  final TrialService trial;

  @override
  bool canWrite(String companyId) =>
      ent.canWrite(trial.evaluate(companyId, trial.clock.nowMs()).state);
}

/// Permission hook for B4 (M19 rights model). Allows everything until B4
/// supplies the rights model; the choke point already calls through it.
abstract class WritePermission {
  const WritePermission();

  bool isAllowed(String companyId, String actor);
}

/// B1 default: no rights model yet, everything allowed (B4 replaces this).
class AllowAllPermission extends WritePermission {
  const AllowAllPermission();

  @override
  bool isAllowed(String companyId, String actor) => true;
}
