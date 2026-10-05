// Tests: trial/grace/expiry + denylist, incl. DB-backed storage tie-in.
// Fixed clocks (no wall-clock reads). Boundaries asserted to the millisecond.
// Traceability: D-04/O-05/D-FG-014; D-11/D-13/A-R2; G0-SCH-006.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/data/security/entitlements.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

class _Db implements MigrationDb {
  _Db(this.db);
  final Database db;
  @override
  void execute(String sql) => db.execute(sql);
  @override
  void executeArgs(String sql, List<Object?> args) =>
      db.execute(sql, args);
  @override
  List<Map<String, Object?>> query(String sql) =>
      queryArgs(sql, <Object?>[]);
  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    final ResultSet rs = db.select(sql, args);
    return <Map<String, Object?>>[
      for (final Row row in rs)
        <String, Object?>{for (final String c in rs.columnNames) c: row[c]},
    ];
  }

  @override
  void runInTransaction(void Function() body) {
    db.execute('BEGIN');
    try {
      body();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

// Trial ends at fixed T; grace = 10 days.
const int kT = 1754000000000;

void main() {
  group('trial clock boundaries', () {
    test('active through the exact end instant', () {
      expect(
          evaluateEntitlement(nowMs: kT, trialEndsAtMs: kT, denylisted: false),
          EntitlementState.trialActive);
    });

    test('grace starts 1ms after end and spans the full 10th day', () {
      expect(
          evaluateEntitlement(
              nowMs: kT + 1, trialEndsAtMs: kT, denylisted: false),
          EntitlementState.graceActive);
      expect(
          evaluateEntitlement(
              nowMs: kT + 10 * kDayMs, trialEndsAtMs: kT, denylisted: false),
          EntitlementState.graceActive);
    });

    test('expired 1ms after grace ends', () {
      expect(
          evaluateEntitlement(
              nowMs: kT + 10 * kDayMs + 1,
              trialEndsAtMs: kT,
              denylisted: false),
          EntitlementState.expired);
    });

    test('denylist denies in every clock state', () {
      for (final int now in <int>[kT - 1, kT, kT + 5 * kDayMs, kT + 30 * kDayMs]) {
        expect(
            evaluateEntitlement(
                nowMs: now, trialEndsAtMs: kT, denylisted: true),
            EntitlementState.denied);
      }
    });
  });

  group('capability matrix (D-04: read-only + export + backup after grace)', () {
    test('writes need full function; export/backup survive expiry', () {
      expect(canWrite(EntitlementState.trialActive), isTrue);
      expect(canWrite(EntitlementState.graceActive), isTrue);
      expect(canWrite(EntitlementState.expired), isFalse);
      expect(canWrite(EntitlementState.denied), isFalse);
      expect(needsExpiryReminder(EntitlementState.graceActive), isTrue);
      expect(needsExpiryReminder(EntitlementState.trialActive), isFalse);
      expect(canExportBackup(EntitlementState.expired), isTrue);
      expect(canExportBackup(EntitlementState.denied), isFalse);
    });
  });

  group('storage tie-in: trial_anchor + denylist_entry rows drive evaluation', () {
    test('anchor window and key-hash hit read from the migrated DB', () {
      final Database raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      migrate(
          _Db(raw),
          <int, String>{
            for (final Migration m in kMigrations)
              m.version: File('lib/data/migrations/${m.fileName}')
                  .readAsStringSync(),
          });
      raw.execute(
          "INSERT INTO company (company_id, name, created_at) VALUES ('c1','Shop',1000)");
      raw.execute(
          "INSERT INTO trial_anchor (anchor_id, company_id, installed_at, trial_ends_at, status, created_at) VALUES ('a1','c1',1000,$kT,'trial',1000)");
      raw.execute(
          "INSERT INTO denylist_entry (entry_id, key_hash, reason, status, created_at) VALUES ('d1','deadbeef','stolen','listed',1000)");

      final int endsAt = raw
          .select("SELECT trial_ends_at FROM trial_anchor WHERE company_id='c1'")
          .first['trial_ends_at'] as int;
      final bool hit = raw
          .select("SELECT 1 FROM denylist_entry WHERE key_hash='deadbeef'")
          .isNotEmpty;
      final bool miss = raw
          .select("SELECT 1 FROM denylist_entry WHERE key_hash='other'")
          .isNotEmpty;
      expect(
          evaluateEntitlement(
              nowMs: kT + 2 * kDayMs, trialEndsAtMs: endsAt, denylisted: hit),
          EntitlementState.denied);
      expect(
          evaluateEntitlement(
              nowMs: kT + 2 * kDayMs, trialEndsAtMs: endsAt, denylisted: miss),
          EntitlementState.graceActive);
    });
  });
}
