// NiAvERP production startup sequence — D1 (A3).
// One ordered path from a cold process to a live [CompanyScope]:
//
//   load migration SQL assets → obtain the Keystore-wrapped key →
//   open the encrypted database → build the backend bundle → map to scope
//
// Every failure becomes one of a small, non-technical, DISTINCT states:
//   starting · keyUnavailable(code) · databaseUnavailable(code) ·
//   schemaTooNew · deviceIdFailure(code) · ready
// There is no plaintext path and no unencrypted fallback anywhere in this
// file: when the key or the database cannot be opened the app stops at the
// matching state and never constructs a backend over an unencrypted engine.
// Codes are stable strings ([StartupCode]); no key bytes, paths, driver text
// or SQL ever reach the UI. On-device Keystore and cipher behaviour stays
// G0-VER-005 / G0-VER-001 evidence — host runs with an injected fake channel
// are not device evidence.
// Traceability: D1 (A3/A4); D-06; P-SQLIB; G0-CON-003 (no downgrade);
// DSS-C-007; strategy Slice 0/1.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/migration_assets.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/uuid_v7.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/cipher_opener.dart';
import 'package:niaverp/data/db/key_provider.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';
import 'package:niaverp/data/security/trial_store.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

/// Stable failure codes surfaced to the startup UI. Deliberately coarse: the
/// UI shows a state, never a diagnostic dump.
class StartupCode {
  const StartupCode._();

  /// The platform key channel is absent, unreachable or reported a failure.
  static const String keyUnavailable = 'key-unavailable';

  /// The key exists but the device has locked it (fresh auth required).
  static const String keyLocked = 'key-locked';

  /// No key at all and re-provisioning did not happen (wiped install).
  static const String keyMissing = 'key-missing';

  /// The wrapped blob exists but cannot be unwrapped (tamper/version skew).
  static const String keyCorrupt = 'key-corrupt';

  /// Database data exists but no wrapped key does: minting is refused so
  /// existing data is never orphaned (MainActivity existingDataLocked).
  static const String existingDataLocked = 'existing-data-locked';
  /// The encrypted database could not be opened (cipher build, wrong key,
  /// unreadable file, permissions).
  static const String databaseUnavailable = 'database-unavailable';

  /// The stored schema is newer than this build: restore-only, never an
  /// in-place downgrade (G0-CON-003).
  static const String schemaTooNew = 'schema-too-new';

  /// Migration SQL assets missing or unreadable from the bundle.
  static const String migrationAssetsMissing = 'migration-assets-missing';

  /// The device identity file is missing, corrupt or unwritable, so no
  /// operation lineage can be stamped. Shown on its own failure screen.
  static const String deviceIdUnavailable = 'device-id-unavailable';
}

/// Terminal or transient startup states.
enum StartupStage {
  /// Work in progress (assets, key, open, migrations).
  starting,

  /// Backend live; [StartupOutcome.scope] carries the tab surface.
  ready,

  /// The wrapped key is unusable (code distinguishes the reason).
  keyFailure,

  /// The database could not be opened or migrated.
  databaseFailure,

  /// Stored schema is newer than this build (restore required).
  schemaRefused,

  /// The device identity could not be established (missing, corrupt or
  /// unwritable device_id file). No backend is built without lineage.
  deviceIdFailure,
}

/// Outcome of one startup run. Exactly one of [scope]/[code] is meaningful.
class StartupOutcome {
  const StartupOutcome._({
    required this.stage,
    this.scope,
    this.code,
    this.backend,
    this.databaseFileName,
  });

  /// Work in progress.
  const StartupOutcome.starting()
      : this._(stage: StartupStage.starting, databaseFileName: null);

  /// Backend ready for the shell.
  const StartupOutcome.ready(
    CompanyScope scope, {
    BackendBundle? backend,
    String? databaseFileName,
  }) : this._(
          stage: StartupStage.ready,
          scope: scope,
          backend: backend,
          databaseFileName: databaseFileName,
        );

  /// Key unusable: no database is opened and no scope exists.
  const StartupOutcome.keyFailure(String code)
      : this._(stage: StartupStage.keyFailure, code: code);

  /// Database unusable: nothing was loaded and no scope exists.
  const StartupOutcome.databaseFailure(String code)
      : this._(stage: StartupStage.databaseFailure, code: code);

  /// Stored schema newer than this build.
  const StartupOutcome.schemaRefused()
      : this._(stage: StartupStage.schemaRefused, code: StartupCode.schemaTooNew);

  /// Device identity unusable: no scope is built and no lineage is stamped.
  const StartupOutcome.deviceIdFailure(String code)
      : this._(stage: StartupStage.deviceIdFailure, code: code);

  final StartupStage stage;

  /// Live tab surface; non-null only for [StartupStage.ready].
  final CompanyScope? scope;

  /// Failure code for the failure stages; null when starting or ready.
  final String? code;

  /// The wired backend, kept so the caller can close the database on exit.
  final BackendBundle? backend;

  /// Database file name (not the full path) for diagnostics-free display.
  final String? databaseFileName;
}

/// Production dependencies of [runStartup]. Injected so the same sequence runs
/// in tests over an in-memory/temp engine and a fake channel — the wiring is
/// identical, only the platform edges are replaced.
class StartupEnvironment {
  const StartupEnvironment({
    required this.channel,
    required this.loadString,
    required this.clock,
    required this.dbPath,
    required this.deviceId,
    required this.actor,
    required this.dbFileName,
    this.chain = kMigrations,
  });

  /// Platform channel: `getDatabaseKey` (key), `getFilesDirectory` (sandbox
  /// path) and `getDeviceId` (operation identity). Tests inject a fake handler;
  /// no fake is bundled into production.
  final MethodChannel channel;

  /// Asset text loader (`rootBundle.loadString` in production).
  final Future<String> Function(String assetPath) loadString;

  /// App clock (injected so ids/timestamps are testable).
  final Clock clock;

  /// Absolute database file path inside the app sandbox.
  final String dbPath;

  /// Platform device identity for operation lineage (S1 supplies the real one).
  final String deviceId;

  /// Actor recorded in operation/audit lineage.
  final String actor;

  /// Display name of the database file (never the full path).
  final String dbFileName;

  /// Migration chain to load and apply.
  final List<Migration> chain;
}

/// Run the full startup sequence. Never throws: every failure becomes a
/// typed [StartupOutcome] state. Order is fixed and each step is allowed to
/// stop the run — assets first (nothing can open without SQL), then the key
/// (nothing may open without it), then the database, then the graph.
Future<StartupOutcome> runStartup(StartupEnvironment env) async {
  // 1. Migration SQL from the bundle. A missing asset is a packaging fault and
  // stops here — never "open with whatever SQL we happen to have".
  final Map<int, String> sql;
  try {
    sql = await loadMigrationSqlAssets(
      loadString: env.loadString,
      chain: env.chain,
    );
  } catch (_) {
    return const StartupOutcome.databaseFailure(
        StartupCode.migrationAssetsMissing);
  }

  // 2. Key from the platform vault (Android Keystore via the channel). Only an
  // `available` reply with 32 bytes may continue; every other state stops.
  final ChannelKeyProvider provider = ChannelKeyProvider(channel: env.channel);
  final ChannelKeyResult keyResult = await provider.obtainKey();
  final Uint8List? keyBytes = keyResult.bytes;
  if (keyBytes == null) {
    // Distinct screen per platform failure code (the reference line shows
    // the code; headlines differ — see StartupStatusScreen).
    switch (keyResult.failure) {
      case KeyFailure.authFailed:
        return const StartupOutcome.keyFailure(StartupCode.keyLocked);
      case KeyFailure.wipedByUninstall:
        return const StartupOutcome.keyFailure(StartupCode.keyMissing);
      case KeyFailure.corruptWrapper:
        return const StartupOutcome.keyFailure(StartupCode.keyCorrupt);
      case KeyFailure.existingDataLocked:
        return const StartupOutcome.keyFailure(
            StartupCode.existingDataLocked);
      case KeyFailure.keystoreUnavailable:
      case null:
        break;
    }
    switch (provider.state.name) {
      case 'locked':
        return const StartupOutcome.keyFailure(StartupCode.keyLocked);
      case 'missing':
        return const StartupOutcome.keyFailure(StartupCode.keyMissing);
      case 'failed':
      default:
        return const StartupOutcome.keyFailure(StartupCode.keyUnavailable);
    }
  }

  // 3. Encrypted open + bootstrap through the single opener. The key lives in
  // this closure for the open only; nothing else can read it.
  final CipherDatabaseOpener opener = CipherDatabaseOpener.fromKeyBytes(
    dbPath: env.dbPath,
    keyBytes: () => keyBytes,
    sqlByVersion: sql,
    clock: env.clock,
  );
  final NiavDatabase database;
  try {
    database = opener.openCompanyDatabase();
  } on StateError catch (e) {
    // Newer-schema refusal keeps its own meaning (G0-CON-003: restore, never
    // downgrade). The message is a fixed string built from the version numbers.
    if (e.message.contains('is newer than app v')) {
      return const StartupOutcome.schemaRefused();
    }
    return const StartupOutcome.databaseFailure(
        StartupCode.databaseUnavailable);
  } on CipherOpenException catch (e) {
    if (e.code == 'cipher-build-unavailable') {
      return const StartupOutcome.databaseFailure(
          StartupCode.databaseUnavailable);
    }
    return const StartupOutcome.databaseFailure(
        StartupCode.databaseUnavailable);
  } catch (_) {
    return const StartupOutcome.databaseFailure(
        StartupCode.databaseUnavailable);
  }

  // 4. Backend graph over the live encrypted database. CompositionRoot.backend
  // closes the database itself if bootstrap fails, so a failure here leaves no
  // dangling handle.
  final BackendBundle backend;
  // B1 (A1/A2): the app-private install copy lives beside the database file
  // (same sandbox directory). A corrupt/unwritable copy degrades to
  // database-anchor-only enforcement (R1 residual) instead of failing startup:
  // the anchors remain authoritative and the gap stays queryable via
  // `trial.fileCopyUsable`. No silent trial reset is possible while any
  // anchor row survives.
  TrialFileStore? trialFiles;
  try {
    final String filesDir = Directory(env.dbPath).parent.path;
    trialFiles = TrialFileStore(filesDir);
    trialFiles.ensureInstallMs(env.clock.nowMs());
  } on TrialStoreCorruptException {
    trialFiles = null;
  } on TrialStoreWriteException {
    trialFiles = null;
  }
  try {
    backend = CompositionRoot.backend(
      engine: database,
      sqlByVersion: sql,
      clock: env.clock,
      deviceId: env.deviceId,
      trialFiles: trialFiles,
    );
  } catch (_) {
    database.close();
    return const StartupOutcome.databaseFailure(
        StartupCode.databaseUnavailable);
  }

  // 4b. Trial/clock guard (B1, A3): per-company anchors plus one clock
  // observation each. Rollback writes a security-event audit row but never
  // blocks startup or billing (SEC §3.5). A failed guard diagnostic is
  // recorded on the facade (`trial.lastGuardError`) and startup continues:
  // every later write is still gated by the choke point.
  final int startupNowMs = env.clock.nowMs();
  final List<Map<String, Object?>> companyRows = database.queryArgs(
    'SELECT company_id FROM company',
    <Object?>[],
  );
  final UuidV7 idGen = UuidV7();
  for (final Map<String, Object?> row in companyRows) {
    final String companyId = row['company_id'] as String;
    backend.trial.ensureCompanyAnchor(companyId, startupNowMs);
    backend.guardCompanyOpen(
      companyId: companyId,
      deviceNowMs: startupNowMs,
      actor: env.actor,
      eventId: 'co-${idGen.next()}',
    );
  }

  // 5. Tab surface for the five destinations.
  final CompanyScope scope = scopeOfBackend(
    backend,
    write: UuidV7WriteContext(deviceId: env.deviceId, actor: env.actor),
    today: todayFromClock(env.clock),
  );
  return StartupOutcome.ready(scope,
      backend: backend, databaseFileName: env.dbFileName);
}

/// Today's date (UTC, ISO) for report defaults, read from the injected clock.
NiavDate todayFromClock(Clock clock) {
  final DateTime now = DateTime.fromMillisecondsSinceEpoch(
    clock.nowMs(),
    isUtc: true,
  );
  final String iso =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return NiavDate(iso);
}