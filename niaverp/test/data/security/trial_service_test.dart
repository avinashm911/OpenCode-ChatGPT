// B1 trial service tests: month arithmetic, anchor lifecycle (file + DB,
// earliest-wins, R1 residual), denylist, facade queries, clock guard and the
// entitlements.json parity. Through CompositionRoot.backend (production
// wiring); the encrypted-file choke proof lives in write_gate_test.dart.
// Traceability: SEC §3.3/§3.4/§3.5; D-04; D-11; G0-SCH-006; M20.1/M20.2/M20.6.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/security/entitlements.dart';
import 'package:niaverp/data/security/trial_service.dart';
import 'package:niaverp/data/security/trial_store.dart';

import '../../helpers/test_database.dart';

int utcMs(int y, int m, int d) =>
    DateTime.utc(y, m, d).millisecondsSinceEpoch;

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niav_trial_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  BackendBundle openBackend(
    NiavDatabase db, {
    int? nowMs,
    TrialFileStore? files,
    String? deviceId,
  }) {
    return CompositionRoot.backend(
      engine: db,
      sqlByVersion: loadMigrationSql(),
      clock: TestClock(nowMs ?? utcMs(2026, 4, 1)),
      deviceId: deviceId ?? 'test-device-1',
      trialFiles: files,
    );
  }

  NiavDatabase freshDb() {
    final NiavDatabase db = openTestDatabase();
    addTearDown(db.close);
    return db;
  }

  CompanyId seedCompany(BackendBundle backend, String id) {
    final Result<Company> r = backend.companies.create(
      id: CompanyId(id),
      name: 'Trial Co',
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
    return CompanyId(id);
  }

  group('trial month arithmetic (PROPOSED P-TRIAL-END)', () {
    test('plain month shift keeps the day', () {
      expect(trialEndsAtMs(utcMs(2026, 1, 15)), utcMs(2026, 4, 15));
    });
    test('day clamps to a short target month', () {
      expect(trialEndsAtMs(utcMs(2026, 8, 31)), utcMs(2026, 11, 30));
    });
    test('february clamps in a non-leap year', () {
      expect(trialEndsAtMs(utcMs(2026, 11, 30)), utcMs(2027, 2, 28));
    });
    test('february keeps the leap day', () {
      expect(trialEndsAtMs(utcMs(2023, 11, 30)), utcMs(2024, 2, 29));
    });
    test('december carries the year', () {
      expect(trialEndsAtMs(utcMs(2026, 12, 15)), utcMs(2027, 3, 15));
    });
  });

  group('anchor lifecycle (M20.1)', () {
    test('fresh company create writes one anchor; restart keeps it', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final BackendBundle first = openBackend(db, nowMs: now);
      seedCompany(first, 'c-a');
      final TrialAnchor created = first.trial.readAnchor('c-a')!;
      expect(created.installedAtMs, now);
      expect(created.trialEndsAtMs, trialEndsAtMs(now));
      // Restart over the same database: same row, no duplicate.
      final BackendBundle second = openBackend(db, nowMs: now);
      final TrialAnchor kept = second.trial.ensureCompanyAnchor('c-a', now);
      expect(kept.anchorId, created.anchorId);
      expect(kept.installedAtMs, now);
      final List<Map<String, Object?>> rows = db.queryArgs(
        'SELECT COUNT(*) AS n FROM trial_anchor WHERE company_id = ?',
        <Object?>['c-a'],
      );
      expect(rows.single['n'], 1);
    });

    test('new company inherits the earliest install copy (file wins)', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final int older = utcMs(2026, 2, 10);
      File('${tmp.path}${Platform.pathSeparator}trial_install.ms')
          .writeAsStringSync('$older');
      final BackendBundle backend = openBackend(
        db,
        nowMs: now,
        files: TrialFileStore(tmp.path),
      );
      expect(backend.trial.fileCopyUsable, isTrue);
      seedCompany(backend, 'c-new');
      final TrialAnchor anchor = backend.trial.readAnchor('c-new')!;
      expect(anchor.installedAtMs, older);
      final TrialEvaluation e = backend.trial.evaluate('c-new', now);
      expect(e.effectiveStartMs, older);
      expect(e.state, EntitlementState.trialActive);
    });

    test('R1 residual: deleting the file alone never resets the trial', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final TrialFileStore store = TrialFileStore(tmp.path);
      store.ensureInstallMs(now);
      final BackendBundle backend = openBackend(
        db,
        nowMs: now,
        files: store,
      );
      seedCompany(backend, 'c-r1');
      final int startBefore =
          backend.trial.evaluate('c-r1', now).effectiveStartMs;
      File(store.filePath).deleteSync();
      expect(backend.trial.fileCopyUsable, isFalse);
      expect(
        backend.trial.evaluate('c-r1', now).effectiveStartMs,
        startBefore,
      );
    });

    test('R1 residual (named): deleting every copy starts a new trial', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final TrialFileStore store = TrialFileStore(tmp.path);
      store.ensureInstallMs(now);
      final BackendBundle backend = openBackend(
        db,
        nowMs: now,
        files: store,
      );
      seedCompany(backend, 'c-r1');
      File(store.filePath).deleteSync();
      db.executeArgs(
        'DELETE FROM trial_anchor WHERE company_id = ?',
        <Object?>['c-r1'],
      );
      final int later = utcMs(2026, 9, 1);
      final TrialEvaluation e = backend.trial.evaluate('c-r1', later);
      expect(e.state, EntitlementState.trialActive);
      expect(e.effectiveStartMs, later);
    });

    test('corrupt file degrades to anchor-only enforcement, never throws', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      File('${tmp.path}${Platform.pathSeparator}trial_install.ms')
          .writeAsStringSync('not-a-number');
      final BackendBundle backend = openBackend(
        db,
        nowMs: now,
        files: TrialFileStore(tmp.path),
      );
      expect(backend.trial.fileCopyUsable, isFalse);
      seedCompany(backend, 'c-c');
      expect(
        backend.trial.evaluate('c-c', now).state,
        EntitlementState.trialActive,
      );
    });
  });

  group('denylist (A6)', () {
    test('hash-only hit denies inside the trial window', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final BackendBundle backend = openBackend(db, nowMs: now);
      seedCompany(backend, 'c-d');
      expect(
        backend.entitlementState('c-d'),
        EntitlementState.trialActive,
      );
      db.executeArgs(
        'INSERT INTO denylist_entry '
        '(entry_id, key_hash, reason, status, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'd-1',
          installKeyHash('test-device-1'),
          'stolen',
          'listed',
          now,
        ],
      );
      final TrialEvaluation e = backend.trial.evaluate('c-d', now);
      expect(e.denylisted, isTrue);
      expect(e.state, EntitlementState.denied);
      expect(backend.daysLeft('c-d'), 0);
      expect(backend.exportBackupAllowed('c-d'), isFalse);
    });
  });

  group('facade queries (A4)', () {
    test('trial/grace/expired surface state, days, reminder and export', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final BackendBundle backend = openBackend(db, nowMs: now);
      seedCompany(backend, 'c-q');
      expect(backend.entitlementState('c-q'), EntitlementState.trialActive);
      expect(backend.daysLeft('c-q'), greaterThan(80));
      expect(backend.reminderDue('c-q'), isFalse);
      expect(backend.clockWarning('c-q'), isFalse);
      expect(backend.exportBackupAllowed('c-q'), isTrue);
      // Grace: installed Dec 31, ended Mar 31 (yesterday), inside the window.
      // installed_at/ends kept consistent (ends == start + 3 months).
      db.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[utcMs(2025, 12, 31), now - kDayMs, 'c-q'],
      );
      expect(backend.entitlementState('c-q'), EntitlementState.graceActive);
      expect(backend.daysLeft('c-q'), 9);
      expect(backend.reminderDue('c-q'), isTrue);
      expect(backend.exportBackupAllowed('c-q'), isTrue);
      // Expired: installed Dec 21, ended Mar 21, past grace.
      db.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[utcMs(2025, 12, 21), now - 11 * kDayMs, 'c-q'],
      );
      expect(backend.entitlementState('c-q'), EntitlementState.expired);
      expect(backend.daysLeft('c-q'), 0);
      expect(backend.reminderDue('c-q'), isFalse);
      expect(backend.exportBackupAllowed('c-q'), isTrue);
    });
  });

  group('clock guard (A3, M22.4)', () {
    test('rollback warns, keeps trusted time, allows writes, audits', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final BackendBundle backend = openBackend(db, nowMs: now);
      seedCompany(backend, 'c-k');
      final Result<ClockObservation> first = backend.guardCompanyOpen(
        companyId: 'c-k',
        deviceNowMs: now,
        actor: 'tester',
        eventId: 'ev-g1',
      );
      expect(first.isOk, isTrue);
      expect((first as Ok<ClockObservation>).value.rolledBack, isFalse);
      final Result<ClockObservation> back = backend.guardCompanyOpen(
        companyId: 'c-k',
        deviceNowMs: now - kDayMs,
        actor: 'tester',
        eventId: 'ev-g2',
      );
      expect(back.isOk, isTrue);
      final ClockObservation obs = (back as Ok<ClockObservation>).value;
      expect(obs.rolledBack, isTrue);
      expect(obs.trustedNowMs, now);
      expect(backend.clockWarning('c-k'), isTrue);
      // Billing is never blocked by a wrong clock.
      final Result<Company> w = backend.companies.create(
        id: CompanyId('c-k2'),
        name: 'Second Co',
        deviceId: 'host-test',
        opId: 'op-k2',
        eventId: 'ev-k2',
        actor: 'tester',
      );
      expect(w.isOk, isTrue);
      // The rollback left a security-event audit row.
      final List<AuditEvent> events = backend.audit.forEntity(
        'c-k',
        'clock_observation',
        'c-k',
      );
      expect(events, isNotEmpty);
    });

    test('company switch re-observes the clock (mark advances)', () {
      final NiavDatabase db = freshDb();
      final int now = utcMs(2026, 4, 1);
      final BackendBundle backend = openBackend(db, nowMs: now);
      seedCompany(backend, 'c-s');
      expect(
        backend.guardCompanyOpen(
          companyId: 'c-s',
          deviceNowMs: now,
          actor: 'tester',
          eventId: 'ev-s1',
        ).isOk,
        isTrue,
      );
      expect(backend.trial.readAnchor('c-s')!.lastSeenMs, now);
      // Switch/open again with a later device clock: no rollback, mark moves.
      final Result<ClockObservation> again = backend.guardCompanyOpen(
        companyId: 'c-s',
        deviceNowMs: now + 2 * kDayMs,
        actor: 'tester',
        eventId: 'ev-s2',
      );
      expect(again.isOk, isTrue);
      expect((again as Ok<ClockObservation>).value.rolledBack, isFalse);
      expect(backend.trial.readAnchor('c-s')!.lastSeenMs, now + 2 * kDayMs);
      expect(backend.clockWarning('c-s'), isFalse);
    });
  });

  group('entitlements.json parity (single source)', () {
    test('approved cells match the code constants', () {
      final Map<String, Object?> matrix = jsonDecode(
        File('entitlements.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final Map<String, Object?> trial =
          matrix['trial'] as Map<String, Object?>;
      final Map<String, Object?> grace =
          matrix['grace'] as Map<String, Object?>;
      final Map<String, Object?> editions =
          matrix['editions'] as Map<String, Object?>;
      expect(trial['months'], kTrialMonths);
      expect(grace['days'], kGraceDays);
      expect(matrix['denyWins'], isTrue);
      expect(matrix['dataNeverDeleted'], isTrue);
      expect(editions['status'], contains('BLOCKED'));
    });
  });
}
