// Phase 01 tests: database bootstrap over real SQLite.
// Disposable in-memory databases only. Proves: clean install reaches the
// latest schema, re-bootstrap is a no-op, a newer-schema database is refused
// (no in-place downgrade), and FK/CHECK constraints are enforced.
// Traceability: DSS §6; DB §8; DSS-C-007; RSP 5 / G0-CON-003; G0-SCH-001…007.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  group('bootstrap', () {
    test('clean install reaches the latest schema version', () {
      expect(db.schemaVersion, kLatestVersion);
    });

    test('re-bootstrap is a safe no-op', () {
      db.bootstrap();
      db.bootstrap();
      expect(db.schemaVersion, kLatestVersion);
    });

    test('staged upgrade v1 → latest preserves rows', () {
      final NiavDatabase staged = openTestDatabase(upTo: 1);
      addTearDown(() => rawEngineOf(staged).close());
      staged.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-staged', 'Staged Co', 1],
      );
      staged.sqlByVersion = loadMigrationSql();
      staged.bootstrap();
      expect(staged.schemaVersion, kLatestVersion);
      final List<Map<String, Object?>> rows = staged.queryArgs(
        'SELECT name FROM company WHERE company_id = ?',
        <Object?>['c-staged'],
      );
      expect(rows.single['name'], 'Staged Co');
    });

    test('newer-schema database is refused (no in-place downgrade)', () {
      final NiavDatabase newer = openTestDatabase();
      addTearDown(() => rawEngineOf(newer).close());
      newer.execute(
        'INSERT INTO schema_migrations (version, applied_at, description) '
        'VALUES (${kLatestVersion + 1}, 1, \'future\')',
      );
      expect(() => newer.bootstrap(), throwsStateError);
    });

    test('foreign keys are enforced on the connection', () {
      expect(
        () => db.executeArgs(
          'INSERT INTO item (item_id, company_id, name, unit, created_at) '
          'VALUES (?, ?, ?, ?, ?)',
          <Object?>['i-orphan', 'no-such-company', 'Orphan', 'pcs', 1],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('CHECK constraints are enforced (line_no > 0)', () {
      db.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-check', 'Check Co', 1],
      );
      db.executeArgs(
        'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
        'voucher_no, voucher_date, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'v-check',
          'c-check',
          'sales-invoice',
          'A',
          '1',
          '2026-04-01',
          'draft',
          1,
        ],
      );
      expect(
        () => db.executeArgs(
          'INSERT INTO voucher_line (voucher_line_id, voucher_id, '
          'company_id, line_no, qty_q4, rate_paise, amount_paise, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>['l-bad', 'v-check', 'c-check', 0, 10000, 100, 100, 1],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Result contract', () {
    test('ok/err shapes hold for db-adjacent code', () {
      const Result<int> r = Ok<int>(1);
      expect(r.isOk, isTrue);
    });
  });
}
