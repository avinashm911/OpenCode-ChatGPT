// Clock rollback guard tests (D2-E3, SEC section 3.5).
// Disposable databases only. Proves: the first observation initializes the
// high-water mark without flagging rollback; forward progress advances it;
// a device clock behind the mark reports rollback while trusted time stays at
// the mark; entitlement evaluated on trusted time (trial, grace, expiry with
// data never deleted); a missing anchor row degrades to device time.
// Traceability: SEC section 3.5 (trusted_now); D-04/O-05/D-FG-014; D2 (E3).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/security/entitlements.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  final CompanyId companyId = CompanyId('c-e');

  int mark() {
    return db.queryArgs(
      'SELECT last_seen_at AS m FROM trial_anchor WHERE company_id = ?',
      <Object?>['c-e'],
    ).single['m'] as int;
  }

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: companyId,
            name: 'Entitlement Co',
            deviceId: 'host-test',
            opId: 'op-ce',
            eventId: 'ev-ce',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    db.executeArgs(
      'INSERT INTO trial_anchor (anchor_id, company_id, installed_at, '
      'trial_ends_at, status, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>['a-e', 'c-e', 1700000000000, 1700000000000 + 90 * kDayMs,
          'trial', 1700000000000],
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  group('clock high-water mark (D2-E3)', () {
    test('first observation initializes the mark without rollback', () {
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-e',
        deviceNowMs: 1700000001000,
      );
      expect(seen.rolledBack, isFalse);
      expect(seen.trustedNowMs, 1700000001000);
      expect(seen.lastSeenMs, 1700000001000);
      expect(mark(), 1700000001000);
    });

    test('forward progress advances the mark', () {
      observeDeviceClock(db, companyId: 'c-e', deviceNowMs: 1700000001000);
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-e',
        deviceNowMs: 1700000002000,
      );
      expect(seen.rolledBack, isFalse);
      expect(seen.trustedNowMs, 1700000002000);
      expect(mark(), 1700000002000);
    });

    test('a clock behind the mark reports rollback and keeps trusted time',
        () {
      observeDeviceClock(db, companyId: 'c-e', deviceNowMs: 1700000002000);
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-e',
        deviceNowMs: 1700000001000,
      );
      expect(seen.rolledBack, isTrue);
      expect(seen.trustedNowMs, 1700000002000);
      expect(seen.lastSeenMs, 1700000002000);
      expect(mark(), 1700000002000);
    });

    test('rollback cannot regain trial; expiry never deletes data', () {
      // Mark sits past trial + grace; the device claims to be back inside
      // the trial window. Trusted time stays at the mark: expired.
      observeDeviceClock(
          db, companyId: 'c-e', deviceNowMs: 1700000000000 + 101 * kDayMs);
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-e',
        deviceNowMs: 1700000000000 + 10 * kDayMs,
      );
      expect(seen.rolledBack, isTrue);
      final EntitlementState state = evaluateEntitlement(
        nowMs: seen.trustedNowMs,
        trialEndsAtMs: 1700000000000 + 90 * kDayMs,
        denylisted: false,
      );
      expect(state, EntitlementState.expired);
      expect(canWrite(state), isFalse);
      // Data is never deleted: export and backup stay available.
      expect(canExportBackup(state), isTrue);
    });

    test('trusted time inside grace keeps full function', () {
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-e',
        deviceNowMs: 1700000000000 + 95 * kDayMs,
      );
      expect(seen.rolledBack, isFalse);
      final EntitlementState state = evaluateEntitlement(
        nowMs: seen.trustedNowMs,
        trialEndsAtMs: 1700000000000 + 90 * kDayMs,
        denylisted: false,
      );
      expect(state, EntitlementState.graceActive);
      expect(canWrite(state), isTrue);
    });

    test('missing anchor row degrades to device time', () {
      final ClockObservation seen = observeDeviceClock(
        db,
        companyId: 'c-nope',
        deviceNowMs: 1700000001000,
      );
      expect(seen.rolledBack, isFalse);
      expect(seen.trustedNowMs, 1700000001000);
    });
  });
}
