// Prompt-10 tests: layout-profile storage (FR-M23-001 / M23 P1).
// Disposable in-memory databases only. Proves: versioned saves persist per
// (company, key), latest resolves to the newest version, duplicate versions
// collide, invalid inputs are rejected with no residue, and state stays
// company-scoped with operation + audit lineage.
// Traceability: FR-M23-001 (preferences stored locally; UI behavior only);
// G0-SCH-004; DSS-C-001; OD-DB-004.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/layout_profile_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late LayoutProfileRepository profiles;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    profiles = LayoutProfileRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-u', 'c-other']) {
      expect(
        companies
            .create(
              id: CompanyId(c),
              name: 'Co $c',
              deviceId: 'host-test',
              opId: 'op-$c',
              eventId: 'ev-$c',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<LayoutProfile> saveProfile(
    String id,
    String company,
    String key,
    int version,
    String json,
  ) {
    return profiles.save(
      id: EntityId(id),
      companyId: CompanyId(company),
      profileKey: key,
      version: version,
      layoutJson: json,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('layout profiles (FR-M23-001)', () {
    test('versions persist; latest resolves newest with lineage', () {
      expect(saveProfile('p-1', 'c-u', 'home-tiles', 1, '{"a":1}').isOk, isTrue);
      expect(saveProfile('p-2', 'c-u', 'home-tiles', 2, '{"a":2}').isOk, isTrue);
      final LayoutProfile? top =
          profiles.latest(CompanyId('c-u'), 'home-tiles');
      expect(top?.version, 2);
      expect(top?.layoutJson, '{"a":2}');
      expect(
        profiles.versions(CompanyId('c-u'), 'home-tiles').map((LayoutProfile p) => p.version),
        <int>[1, 2],
      );
      expect(ops.forEntity('c-u', 'layout_profile', 'p-2'), isNotEmpty);
      expect(audit.forEntity('c-u', 'layout_profile', 'p-2'), isNotEmpty);
    });

    test('duplicate version in one scope is conflict with no residue', () {
      expect(saveProfile('p-1', 'c-u', 'home-tiles', 1, '{"a":1}').isOk, isTrue);
      final Result<LayoutProfile> dupe =
          saveProfile('p-9', 'c-u', 'home-tiles', 1, '{"a":9}');
      expect(dupe.isErr, isTrue);
      expect((dupe as Err<LayoutProfile>).error.code, 'conflict');
      expect(
        profiles.versions(CompanyId('c-u'), 'home-tiles'),
        hasLength(1),
      );
    });

    test('invalid inputs are rejected (invalid cases)', () {
      for (final Result<LayoutProfile> r in <Result<LayoutProfile>>[
        saveProfile('p-x', 'c-u', '', 1, '{}'),
        saveProfile('p-y', 'c-u', 'k', 1, ''),
        saveProfile('p-z', 'c-u', 'k', 0, '{}'),
        saveProfile('p-w', 'c-u', 'k', -2, '{}'),
      ]) {
        expect(r.isErr, isTrue);
        expect((r as Err<LayoutProfile>).error.code, 'validation');
      }
      expect(profiles.latest(CompanyId('c-u'), 'k'), isNull);
    });

    test('profiles stay within their company', () {
      expect(saveProfile('p-1', 'c-u', 'home-tiles', 1, '{}').isOk, isTrue);
      expect(profiles.latest(CompanyId('c-other'), 'home-tiles'), isNull);
      expect(saveProfile('p-2', 'c-other', 'home-tiles', 1, '{}').isOk, isTrue);
      expect(profiles.latest(CompanyId('c-other'), 'home-tiles')?.version, 1);
    });
  });
}
