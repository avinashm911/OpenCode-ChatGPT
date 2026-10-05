// Prompt-09 tests: restore company-match guard (FR-M22-001).
// Pure unit tests (no database, no device): a restore must never silently
// overwrite live data of another company. Encryption, FileProvider routing
// and on-device restore remain downstream (P-SQLIB, G0-VER-008).
// Traceability: FR-M22-001 (restore must not silently overwrite live data);
// DSS-C-001 (company isolation).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/security/backup.dart';

void main() {
  group('restore company guard (FR-M22-001)', () {
    BackupManifest manifestFor(String company) => createManifest(
          companyId: company,
          createdAtMs: 1000,
          schemaVersion: 9,
          payload: const <int>[1, 2, 3],
          files: const <String>['company.db'],
        );

    test('foreign-company backup onto live data is refused', () {
      final List<String> errors = checkRestorable(
        manifest: manifestFor('c-a'),
        actualPayload: const <int>[1, 2, 3],
        appSchemaVersion: 9,
        liveCompanyId: 'c-b',
      );
      expect(errors, isNotEmpty);
      expect(errors.join(' ').contains('c-a'), isTrue);
      expect(errors.join(' ').contains('c-b'), isTrue);
    });

    test('matching company restores clean', () {
      expect(
        checkRestorable(
          manifest: manifestFor('c-a'),
          actualPayload: const <int>[1, 2, 3],
          appSchemaVersion: 9,
          liveCompanyId: 'c-a',
        ),
        isEmpty,
      );
    });

    test('omitted live company preserves prior behavior (invalid case)', () {
      // No live context (fresh install): hash + version rules still apply.
      expect(
        checkRestorable(
          manifest: manifestFor('c-a'),
          actualPayload: const <int>[1, 2, 3],
          appSchemaVersion: 9,
        ),
        isEmpty,
      );
      expect(
        checkRestorable(
          manifest: manifestFor('c-a'),
          actualPayload: const <int>[9, 9, 9],
          appSchemaVersion: 9,
          liveCompanyId: 'c-a',
        ),
        isNotEmpty,
      );
    });
  });
}
