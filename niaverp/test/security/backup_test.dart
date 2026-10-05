// Tests: backup manifest integrity + restore refusal + reinstall key plan.
// Payloads are fixed byte vectors in temp files (disposable, deterministic).
// Traceability: DB §8; DSS §6/C-007; RSP 5; FR-M22-001; D-06.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/security/backup.dart';

void main() {
  group('manifest integrity (DB §8)', () {
    test('clean backup verifies; tampered payload is detected', () async {
      final Directory tmp =
          await Directory.systemTemp.createTemp('niav_backup_');
      addTearDown(() => tmp.delete(recursive: true));
      final List<int> payload = <int>[1, 2, 3, 4, 5, 6, 7, 8];
      final File f = File('${tmp.path}/company.db')..writeAsBytesSync(payload);

      final BackupManifest m = createManifest(
        companyId: 'c1',
        createdAtMs: 1000,
        schemaVersion: 8,
        payload: f.readAsBytesSync(),
        files: <String>['company.db'],
      );
      expect(
          checkRestorable(
              manifest: m,
              actualPayload: f.readAsBytesSync(),
              appSchemaVersion: 8),
          isEmpty);

      final List<int> tampered = List<int>.of(payload)..[0] = 9;
      expect(
          checkRestorable(
              manifest: m, actualPayload: tampered, appSchemaVersion: 8),
          isNotEmpty);
    });

    test('manifest hash is a stable 64-hex SHA-256', () {
      final BackupManifest m = createManifest(
        companyId: 'c1',
        createdAtMs: 1000,
        schemaVersion: 8,
        payload: const <int>[0],
        files: const <String>['company.db'],
      );
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(m.payloadSha256Hex), isTrue);
      expect(
          createManifest(
            companyId: 'c1',
            createdAtMs: 1000,
            schemaVersion: 8,
            payload: const <int>[0],
            files: const <String>['company.db'],
          ).payloadSha256Hex,
          m.payloadSha256Hex);
    });
  });

  group('downgrade refusal (DSS-C-007 / RSP 5)', () {
    test('newer-schema backup onto older app is refused', () {
      final BackupManifest m = createManifest(
        companyId: 'c1',
        createdAtMs: 1000,
        schemaVersion: 9,
        payload: const <int>[1, 2, 3],
        files: const <String>['company.db'],
      );
      final List<String> errors = checkRestorable(
          manifest: m,
          actualPayload: const <int>[1, 2, 3],
          appSchemaVersion: 8);
      expect(errors, isNotEmpty);
      expect(errors.join(' ').contains('downgrade'), isTrue);
    });

    test('same-or-older schema is not refused on version grounds', () {
      final BackupManifest m = createManifest(
        companyId: 'c1',
        createdAtMs: 1000,
        schemaVersion: 7,
        payload: const <int>[1, 2, 3],
        files: const <String>['company.db'],
      );
      expect(
          checkRestorable(
              manifest: m,
              actualPayload: const <int>[1, 2, 3],
              appSchemaVersion: 8),
          isEmpty);
    });
  });

  group('reinstall key plan (D-06: uninstall wipes Keystore keys)', () {
    test('wiped keystore forces re-provision; intact does not', () {
      expect(requiresKeyReprovision(keystoreWiped: true), isTrue);
      expect(requiresKeyReprovision(keystoreWiped: false), isFalse);
    });
  });
}
