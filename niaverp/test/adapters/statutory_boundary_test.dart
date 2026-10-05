// Statutory G0 boundary attestation — Phase 4.
// Proves the G0 boundary WITHOUT inventing columns: the migrated schema
// carries NO IRN/acknowledgement/e-way fields (owner field list pending),
// the APK has NO statutory API surface, and NO credentials live in code.
// Full file workflow belongs to R3/G3; direct portal APIs are excluded.
// Traceability: O-10/O-FG-002/O-FG-003 (G3); FR-M16-003 (R1a GST JSON);
// G0-VER-003 (evidence still required); pack rule 11.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

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

/// Statutory identifiers that must NOT exist until the owner-approved R1a
/// field list lands. (tax_rate_hsn is APPROVED G0-SCH-004 and unaffected.)
const List<String> kBannedSchemaIds = <String>[
  'irn',
  'ack_no',
  'ackno',
  'eway',
  'e_way',
  'einvoice',
  'e_invoice',
  'gstr',
  'signed_qr',
];

/// Network/portal markers that must NOT appear in lib/ Dart sources.
const List<String> kBannedCodeIds = <String>[
  'einvoice',
  'ewaybill',
  'gst.gov.in',
  'nic.in',
  'package:http',
  'package:dio',
];

/// Credential-literal markers that must NOT appear in lib/ Dart sources.
const List<String> kBannedCredentialIds = <String>[
  'api_key',
  'apikey',
  'client_secret',
  'passwd',
];

void main() {
  group('G0 boundary: no invented statutory columns', () {
    test('migrated schema has no IRN/ack/e-way/GSTR identifiers', () {
      final Database raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      migrate(
          _Db(raw),
          <int, String>{
            for (final Migration m in kMigrations)
              m.version: File('lib/data/migrations/${m.fileName}')
                  .readAsStringSync(),
          });
      final List<String> tableNames = <String>[
        for (final Row r in raw.select(
            "SELECT name FROM sqlite_master WHERE type='table'"))
          (r['name'] as String).toLowerCase(),
      ];
      expect(tableNames, isNotEmpty);
      for (final String t in tableNames) {
        for (final String banned in kBannedSchemaIds) {
          expect(t.contains(banned), isFalse, reason: 'table $t');
        }
        for (final Row c
            in raw.select('PRAGMA table_info(${r'"'}$t${r'"'})')) {
          final String col = (c['name'] as String).toLowerCase();
          for (final String banned in kBannedSchemaIds) {
            expect(col.contains(banned), isFalse, reason: '$t.$col');
          }
        }
      }
    });
  });

  group('G0 boundary: no statutory API surface', () {
    test('no network client dependencies in pubspec', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String banned in <String>['http:', 'dio:', 'retrofit:', 'chopper:']) {
        final bool hit = pubspec
            .split('\n')
            .any((String l) => l.trim().startsWith(banned));
        expect(hit, isFalse, reason: banned);
      }
    });

    test('lib/ sources reference no portal endpoints', () {
      final Directory lib = Directory('lib');
      final List<File> dartFiles = lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final File f in dartFiles) {
        final String src = f.readAsStringSync().toLowerCase();
        for (final String banned in kBannedCodeIds) {
          expect(src.contains(banned), isFalse, reason: '${f.path}: $banned');
        }
      }
    });
  });

  group('G0 boundary: no credentials in code', () {
    test('lib/ sources carry no credential literals', () {
      final Directory lib = Directory('lib');
      for (final FileSystemEntity e
          in lib.listSync(recursive: true).whereType<File>().where(
              (File f) => f.path.endsWith('.dart'))) {
        final String src = (e as File).readAsStringSync().toLowerCase();
        for (final String banned in kBannedCredentialIds) {
          expect(src.contains(banned), isFalse, reason: '${e.path}: $banned');
        }
      }
    });
  });
}
