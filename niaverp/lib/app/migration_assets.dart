// Production migration-SQL loading — production DB boundary.
// Maps the registry chain to bundled asset text WITHOUT reading package
// source files (unreadable on-device). The caller supplies the text loader
// (production passes rootBundle.loadString; tests pass a fake), so this
// unit stays engine-neutral and Flutter-free per the layering rule (D-M7).
// The asset bundle is declared in pubspec.yaml and points at the audited
// `lib/data/migrations/*.sql` files themselves: single source of truth,
// no duplication. Traceability: DSS-C-007; P-SQLIB (engine still pending).

import 'package:niaverp/data/migrations/migration_registry.dart';

/// Asset path of one migration's SQL (mirrors the pubspec asset list).
String migrationAssetPath(Migration m) => 'lib/data/migrations/${m.fileName}';

/// Load `{version: sqlText}` for [chain] via [loadString]. Throws [StateError]
/// when any migration text is missing — bootstrap must never run partial.
Future<Map<int, String>> loadMigrationSqlAssets({
  required Future<String> Function(String assetPath) loadString,
  required List<Migration> chain,
}) async {
  final Map<int, String> out = <int, String>{};
  for (final Migration m in chain) {
    final String text = await loadString(migrationAssetPath(m));
    if (text.trim().isEmpty) {
      throw StateError('Missing SQL for migration v${m.version}');
    }
    out[m.version] = text;
  }
  return out;
}
