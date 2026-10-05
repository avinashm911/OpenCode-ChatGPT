// Production DB boundary tests: asset SQL loading + backend wiring.
// The loader is engine-neutral (fake text source); backend() is exercised
// over the disposable test engine — the encrypted engine plugs into the
// same seam after P-SQLIB closes, with no wiring change.
// Traceability: DSS-C-007; P-SQLIB.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/migration_assets.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/repositories/company_repository.dart';

import '../helpers/test_database.dart';

void main() {
  group('migration assets', () {
    test('paths mirror the registry chain', () {
      expect(migrationAssetPath(kMigrations.first),
          'lib/data/migrations/m001_base.sql');
      expect(migrationAssetPath(kMigrations.last),
          'lib/data/migrations/m015_stock_valuation.sql');
    });

    test('loads every version; empty text throws', () async {
      final Map<int, String> sql = await loadMigrationSqlAssets(
        loadString: (String path) async => '-- $path;',
        chain: kMigrations,
      );
      expect(sql.keys.toSet(), hasLength(kMigrations.length));
      expect(sql[kLatestVersion], contains('m015_stock_valuation.sql'));
      expect(
        () => loadMigrationSqlAssets(
          loadString: (String path) async => '   ',
          chain: kMigrations,
        ),
        throwsStateError,
      );
    });
  });

  group('backend bundle', () {
    test('bootstraps latest schema and wires a working company path', () {
      final NiavDatabase db = openTestDatabase();
      try {
        // NiavDatabase implements MigrationDb, so the bundle builds over it
        // directly; repeat-safe bootstrap makes this a no-op re-run, exactly
        // as production re-entry behaves. Real production passes a fresh
        // encrypted engine with asset-loaded SQL instead.
        final BackendBundle backend = CompositionRoot.backend(
          engine: db,
          sqlByVersion: loadMigrationSql(),
          clock: testClock(),
        );
        expect(backend.database.schemaVersion, kLatestVersion);
        final Result<Company> r = backend.companies.create(
          id: CompanyId('c-prod'),
          name: 'Prod Path Co',
          deviceId: 'host-test',
          opId: 'op-prod',
          eventId: 'ev-prod',
          actor: 'tester',
        );
        expect(r.isOk, isTrue);
        expect(
          backend.companies.get(CompanyId('c-prod'))?.name,
          'Prod Path Co',
        );
        expect(
          backend.search.searchParties(CompanyId('c-prod'), 'Prod'),
          isEmpty,
        );
      } finally {
        rawEngineOf(db).close();
      }
    });
  });
}
