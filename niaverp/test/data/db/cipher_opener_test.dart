// Production DB boundary tests: encrypted file opener (P-SQLIB).
// Disposable temp-file databases only. Proves: key hex shape, open +
// migration bootstrap to latest, on-disk ciphertext (no SQLite header, no
// plaintext), close→reopen persistence under the same key, and refusal
// under a wrong key. The cipher build itself is proven by every open (no
// sqlite3mc functions means a plaintext build — refused, never carried).
// Android 8 proof stays device work (P-DEVICE-8).
// Traceability: P-SQLIB / G0-VER-001; D-06 (256-bit, no plaintext fallback).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/db/cipher_opener.dart';
import 'package:niaverp/data/db/ffi_database.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';

import '../../helpers/test_database.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niav_cipher_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  DbKey keyOf(int fill) =>
      DbKey(Uint8List.fromList(List<int>.filled(32, fill)));

  CipherDatabaseOpener opener(String name, DbKey key) =>
      CipherDatabaseOpener(
        dbPath: '${tmp.path}/$name.db',
        dbKey: key,
        sqlByVersion: loadMigrationSql(),
      );

  group('encrypted opener (P-SQLIB)', () {
    test('key hex is 64 lowercase hex chars', () {
      expect(CipherDatabaseOpener.keyHex(keyOf(0)), '0' * 64);
      expect(CipherDatabaseOpener.keyHex(keyOf(255)), 'ff' * 32);
    });

    test('opens encrypted and bootstraps to latest schema', () {
      final NiavDatabase db = opener('c1', keyOf(7)).openCompanyDatabase();
      try {
        expect(db.schemaVersion, kLatestVersion);
      } finally {
        (db.engine as FfiDatabase).close();
      }
    });

    test('close then reopen with the same key preserves rows', () {
      final NiavDatabase first = opener('c1', keyOf(7)).openCompanyDatabase();
      first.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-persist', 'Persist Co', 1700000000000],
      );
      (first.engine as FfiDatabase).close();
      // Load-bearing proof: the file carries ciphertext, not a database.
      final String rawText =
          String.fromCharCodes(File('${tmp.path}/c1.db').readAsBytesSync());
      expect(rawText.startsWith('SQLite format 3'), isFalse);
      expect(rawText.contains('Persist Co'), isFalse);
      final NiavDatabase second = opener('c1', keyOf(7)).openCompanyDatabase();
      try {
        final List<Map<String, Object?>> rows = second.queryArgs(
          'SELECT name FROM company WHERE company_id = ?',
          <Object?>['c-persist'],
        );
        expect(rows.single['name'], 'Persist Co');
      } finally {
        (second.engine as FfiDatabase).close();
      }
    });

    test('wrong key refuses to open (no plaintext, no partial state)', () {
      final NiavDatabase first = opener('c1', keyOf(7)).openCompanyDatabase();
      (first.engine as FfiDatabase).close();
      // The native layer raises its own error (not StateError); what matters
      // is that the open fails and the handle is disposed, never plaintext.
      expect(
        () => opener('c1', keyOf(9)).openCompanyDatabase(),
        throwsException,
      );
    });
  });
}
