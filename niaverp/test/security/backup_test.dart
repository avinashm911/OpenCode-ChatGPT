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

  group('manifest authentication (D2-E1/E2, injected key)', () {
    List<int> key() => List<int>.generate(32, (int i) => i + 1);

    BackupManifest keyed() => createManifest(
          companyId: 'c1',
          createdAtMs: 1000,
          schemaVersion: 8,
          payload: const <int>[1, 2, 3],
          files: const <String>['company.db'],
          fileHashes: const <String, String>{'company.db': 'abc123'},
          macKey: key(),
        );

    test('keyed manifest verifies; unkeyed legacy keeps the hash-only path',
        () {
      final BackupManifest m = keyed();
      expect(m.macHex, isNotNull);
      expect(verifyManifestMac(manifest: m, macKey: key()), isTrue);
      expect(
          checkRestorable(
              manifest: m,
              actualPayload: const <int>[1, 2, 3],
              appSchemaVersion: 8,
              macKey: key()),
          isEmpty);
      // Legacy manifest without a MAC still verifies by payload hash.
      final BackupManifest legacy = createManifest(
        companyId: 'c1',
        createdAtMs: 1000,
        schemaVersion: 8,
        payload: const <int>[1, 2, 3],
        files: const <String>['company.db'],
      );
      expect(legacy.macHex, isNull);
      expect(
          checkRestorable(
              manifest: legacy,
              actualPayload: const <int>[1, 2, 3],
              appSchemaVersion: 8),
          isEmpty);
    });

    test('tamper with payload, files, company or version breaks the MAC',
        () {
      final BackupManifest m = keyed();
      final BackupManifest tamperedPayload = BackupManifest(
        companyId: m.companyId,
        createdAtMs: m.createdAtMs,
        schemaVersion: m.schemaVersion,
        payloadSha256Hex: sha256Hex(const <int>[9, 9, 9]),
        files: m.files,
        fileHashes: m.fileHashes,
        macHex: m.macHex,
      );
      expect(verifyManifestMac(manifest: tamperedPayload, macKey: key()),
          isFalse);
      // Replay across companies / versions / file sets fails.
      for (final BackupManifest replayed in <BackupManifest>[
        BackupManifest(
            companyId: 'c2',
            createdAtMs: m.createdAtMs,
            schemaVersion: m.schemaVersion,
            payloadSha256Hex: m.payloadSha256Hex,
            files: m.files,
            fileHashes: m.fileHashes,
            macHex: m.macHex),
        BackupManifest(
            companyId: m.companyId,
            createdAtMs: m.createdAtMs,
            schemaVersion: 9,
            payloadSha256Hex: m.payloadSha256Hex,
            files: m.files,
            fileHashes: m.fileHashes,
            macHex: m.macHex),
        BackupManifest(
            companyId: m.companyId,
            createdAtMs: m.createdAtMs,
            schemaVersion: m.schemaVersion,
            payloadSha256Hex: m.payloadSha256Hex,
            files: const <String>['company.db', 'extra.db'],
            fileHashes: const <String, String>{
              'company.db': 'abc123',
              'extra.db': 'def456'
            },
            macHex: m.macHex),
      ]) {
        expect(verifyManifestMac(manifest: replayed, macKey: key()), isFalse);
        expect(
            checkRestorable(
                manifest: replayed,
                actualPayload: const <int>[1, 2, 3],
                appSchemaVersion: 9,
                liveCompanyId: replayed.companyId,
                macKey: key()),
            isNotEmpty);
      }
    });

    test('wrong key fails verification', () {
      final BackupManifest m = keyed();
      final List<int> wrong = List<int>.generate(32, (int i) => 99 - i);
      expect(verifyManifestMac(manifest: m, macKey: wrong), isFalse);
      expect(
          checkRestorable(
              manifest: m,
              actualPayload: const <int>[1, 2, 3],
              appSchemaVersion: 8,
              macKey: wrong),
          isNotEmpty);
    });
  });

  group('reinstall key plan (D-06: uninstall wipes Keystore keys)', () {
    test('wiped keystore forces re-provision; intact does not', () {
      expect(requiresKeyReprovision(keystoreWiped: true), isTrue);
      expect(requiresKeyReprovision(keystoreWiped: false), isFalse);
    });
  });
}
