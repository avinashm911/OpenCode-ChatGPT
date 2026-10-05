// Prompt-03 tests: item-group hierarchy guards (FR-M03-001).
// Disposable in-memory databases only. Proves: nested chains persist with
// parent links, self-parent/cross-company/missing parents are rejected with
// no residue, and corrupt deep chains fail safe instead of hanging.
// Traceability: FR-M03-001 (no circular hierarchy); DSS-C-001 (scope).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/unit_group_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late ItemGroupRepository groups;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    groups = ItemGroupRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-g'),
            name: 'Group Co',
            deviceId: 'host-test',
            opId: 'op-cg',
            eventId: 'ev-cg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<ItemGroup> createGroup(String id, String name, {String? parent}) {
    return groups.create(
      id: EntityId(id),
      companyId: CompanyId('c-g'),
      parentId: parent == null ? null : EntityId(parent),
      name: name,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('item-group hierarchy (FR-M03-001)', () {
    test('nested chain persists with parent links', () {
      expect(createGroup('g-a', 'A').isOk, isTrue);
      expect(createGroup('g-b', 'B', parent: 'g-a').isOk, isTrue);
      expect(createGroup('g-c', 'C', parent: 'g-b').isOk, isTrue);
      expect(
        groups.get(CompanyId('c-g'), EntityId('g-c'))?.parentId?.value,
        'g-b',
      );
      expect(groups.listByCompany(CompanyId('c-g')), hasLength(3));
    });

    test('self-parent is rejected with no residue', () {
      final Result<ItemGroup> r = createGroup('g-self', 'Self', parent: 'g-self');
      expect(r.isErr, isTrue);
      expect((r as Err<ItemGroup>).error.code, 'validation');
      expect(groups.get(CompanyId('c-g'), EntityId('g-self')), isNull);
      expect(groups.listByCompany(CompanyId('c-g')), isEmpty);
    });

    test('missing parent is rejected as foreign-key with no residue', () {
      final Result<ItemGroup> r = createGroup('g-orph', 'Orphan', parent: 'g-nope');
      expect(r.isErr, isTrue);
      expect((r as Err<ItemGroup>).error.code, 'foreign-key');
      expect(groups.get(CompanyId('c-g'), EntityId('g-orph')), isNull);
    });

    test('cross-company parent is rejected as foreign-key', () {
      final CompanyRepository companies =
          CompanyRepository(ctx, ops: ops, audit: audit);
      expect(
        companies
            .create(
              id: CompanyId('c-other'),
              name: 'Other Co',
              deviceId: 'host-test',
              opId: 'op-co',
              eventId: 'ev-co',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final ItemGroupRepository otherGroups =
          ItemGroupRepository(ctx, ops: ops, audit: audit);
      expect(
        otherGroups
            .create(
              id: EntityId('g-foreign'),
              companyId: CompanyId('c-other'),
              name: 'Foreign',
              deviceId: 'host-test',
              opId: 'op-gf',
              eventId: 'ev-gf',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<ItemGroup> r = createGroup('g-x', 'X', parent: 'g-foreign');
      expect(r.isErr, isTrue);
      expect((r as Err<ItemGroup>).error.code, 'foreign-key');
      expect(groups.get(CompanyId('c-g'), EntityId('g-x')), isNull);
    });

    test('excessively deep chain fails safe instead of hanging', () {
      String parent = 'g-d0';
      expect(createGroup(parent, 'D0').isOk, isTrue);
      for (int i = 1; i <= 65; i++) {
        final String id = 'g-d$i';
        expect(createGroup(id, 'D$i', parent: parent).isOk, isTrue);
        parent = id;
      }
      final Result<ItemGroup> tooDeep = createGroup('g-d66', 'D66', parent: parent);
      expect(tooDeep.isErr, isTrue);
      expect((tooDeep as Err<ItemGroup>).error.code, 'validation');
    });

    test('empty name is rejected (invalid case)', () {
      final Result<ItemGroup> r = createGroup('g-bad', '');
      expect(r.isErr, isTrue);
      expect((r as Err<ItemGroup>).error.code, 'validation');
    });
  });
}
