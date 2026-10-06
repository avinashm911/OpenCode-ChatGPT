// Backup integrity: rejection when no MAC present but macKey supplied (D2-E2).
import 'package:flutter_test/flutter_test.dart';
import 'package:niaverp/data/security/backup.dart';

void main() {
  test('backup with no MAC is refused when macKey is supplied', () {
    final BackupManifest manifest = createManifest(
      companyId: 'c1',
      createdAtMs: 1000,
      schemaVersion: 8,
      payload: <int>[1, 2, 3],
      files: <String>['a.db'],
    );
    // macHex is null by design (unkeyed legacy shape).
    expect(manifest.macHex, isNull);
    final List<String> errors = checkRestorable(
      manifest: manifest,
      actualPayload: <int>[1, 2, 3],
      appSchemaVersion: 8,
      macKey: <int>[1, 2, 3], // injected key supplied
    );
    expect(errors, contains('manifest MAC missing: backup requires authentication'));
  });
}
