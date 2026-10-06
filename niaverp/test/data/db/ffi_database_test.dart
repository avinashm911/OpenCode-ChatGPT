// Production FFI engine tests: transaction safety and handle release (D1-B3/B1).
// Disposable in-memory databases only. Proves: a failing body rolls back and
// the ORIGINAL error propagates (never replaced); when SQLite has already
// ended the transaction (body committed, then threw), the best-effort
// ROLLBACK failure still never masks the original error; close is idempotent
// and every later use is rejected; NiavDatabase.close cascades to the engine.
// Traceability: D1 (B1/B3).

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/core/clock.dart';
import 'package:niaverp/data/db/ffi_database.dart';
import 'package:niaverp/data/db/niav_database.dart';

void main() {
  late Database raw;
  late FfiDatabase engine;

  setUp(() {
    raw = sqlite3.openInMemory();
    raw.execute('CREATE TABLE t (id TEXT PRIMARY KEY, n INTEGER NOT NULL)');
    engine = FfiDatabase.wrap(raw);
  });

  tearDown(() {
    engine.close();
  });

  group('FfiDatabase.runInTransaction (D1-B3)', () {
    test('body failure rolls back and rethrows the original error', () {
      Object? caught;
      try {
        engine.runInTransaction(() {
          engine.executeArgs(
            'INSERT INTO t (id, n) VALUES (?, ?)',
            <Object?>['a', 1],
          );
          throw StateError('original-cause');
        });
      } catch (e) {
        caught = e;
      }
      expect(caught, isStateError);
      expect((caught! as StateError).message, 'original-cause');
      expect(engine.query('SELECT COUNT(*) AS n FROM t').first['n'], 0);
      // The connection is usable afterwards: the transaction ended cleanly.
      engine.executeArgs(
        'INSERT INTO t (id, n) VALUES (?, ?)',
        <Object?>['b', 2],
      );
      expect(engine.query('SELECT COUNT(*) AS n FROM t').first['n'], 1);
    });

    test('an already-ended transaction never masks the original error', () {
      // The body commits and then fails: SQLite already ended the
      // transaction, so the best-effort ROLLBACK raises "no transaction is
      // active". That second failure must not replace the original.
      Object? caught;
      try {
        engine.runInTransaction(() {
          engine.executeArgs(
            'INSERT INTO t (id, n) VALUES (?, ?)',
            <Object?>['a', 1],
          );
          raw.execute('COMMIT');
          throw StateError('original-cause');
        });
      } catch (e) {
        caught = e;
      }
      expect(caught, isStateError);
      expect((caught! as StateError).message, 'original-cause');
      // The body's own commit stands (it happened before the throw).
      expect(engine.query('SELECT COUNT(*) AS n FROM t').first['n'], 1);
    });
  });

  group('FfiDatabase.close (D1-B1)', () {
    test('close is idempotent and rejects further use', () {
      engine.close();
      engine.close();
      expect(() => engine.execute('SELECT 1'), throwsStateError);
      expect(() => engine.query('SELECT 1'), throwsStateError);
      expect(
        () => engine.runInTransaction(() {}),
        throwsStateError,
      );
    });

    test('NiavDatabase.close cascades to the engine handle', () {
      final FfiDatabase inner = FfiDatabase.wrap(sqlite3.openInMemory());
      final NiavDatabase db =
          NiavDatabase(inner, clock: TestClock(1700000000000));
      db.close();
      db.close();
      expect(db.isClosed, isTrue);
      expect(() => inner.execute('SELECT 1'), throwsStateError);
      expect(() => db.execute('SELECT 1'), throwsStateError);
    });
  });
}
