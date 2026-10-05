// Phase 01 tests: company/item repositories over real SQLite.
// Disposable in-memory databases only. Proves: create + read round-trip,
// duplicate refusal, FK refusal for foreign companies, company isolation,
// and operation + audit lineage on every write.
// Traceability: DSS-C-001/004; OD-DB-004; DB v0.4 §3.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late CompanyRepository companies;
  late ItemRepository items;
  late OperationLog ops;
  late AuditLog audit;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    companies = CompanyRepository(ctx, ops: ops, audit: audit);
    items = ItemRepository(ctx, ops: ops, audit: audit);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<Company> createCompany(String id, String name) {
    return companies.create(
      id: CompanyId(id),
      name: name,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('company', () {
    test('create then get round-trips', () {
      final Result<Company> r = createCompany('c-1', 'Acme');
      expect(r.isOk, isTrue);
      final Company? got = companies.get(CompanyId('c-1'));
      expect(got, isNotNull);
      expect(got!.name, 'Acme');
    });

    test('duplicate company id is refused as conflict', () {
      expect(createCompany('c-dup', 'First').isOk, isTrue);
      final Result<Company> again = companies.create(
        id: CompanyId('c-dup'),
        name: 'Second',
        deviceId: 'host-test',
        opId: 'op-dup-2',
        eventId: 'ev-dup-2',
        actor: 'tester',
      );
      expect(again.isErr, isTrue);
      expect((again as Err<Company>).error.code, 'conflict');
    });

    test('create appends operation + audit lineage', () {
      expect(createCompany('c-lin', 'Linen').isOk, isTrue);
      expect(ops.forEntity('c-lin', 'company', 'c-lin'), hasLength(1));
      expect(audit.forEntity('c-lin', 'company', 'c-lin'), hasLength(1));
      expect(
        ops.forEntity('c-lin', 'company', 'c-lin').single.action,
        'create',
      );
    });

    test('missing company reads as null, not an error', () {
      expect(companies.get(CompanyId('c-absent')), isNull);
    });
  });

  group('item', () {
    test('create under a company then get round-trips', () {
      expect(createCompany('c-i', 'Items Co').isOk, isTrue);
      final Result<Item> r = items.create(
        id: EntityId('i-1'),
        companyId: CompanyId('c-i'),
        name: 'Bolt',
        deviceId: 'host-test',
        opId: 'op-i-1',
        eventId: 'ev-i-1',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      final Item? got = items.get(CompanyId('c-i'), EntityId('i-1'));
      expect(got, isNotNull);
      expect(got!.name, 'Bolt');
      expect(got.unit, 'pcs');
    });

    test('item under a missing company is refused as foreign-key', () {
      final Result<Item> r = items.create(
        id: EntityId('i-orphan'),
        companyId: CompanyId('c-ghost'),
        name: 'Ghost',
        deviceId: 'host-test',
        opId: 'op-ghost',
        eventId: 'ev-ghost',
        actor: 'tester',
      );
      expect(r.isErr, isTrue);
      expect((r as Err<Item>).error.code, 'foreign-key');
      // Nothing persisted: no operation lineage for a failed write.
      expect(ops.forEntity('c-ghost', 'item', 'i-orphan'), isEmpty);
    });

    test('reads are company-isolated', () {
      expect(createCompany('c-a', 'A').isOk, isTrue);
      expect(createCompany('c-b', 'B').isOk, isTrue);
      expect(
        items
            .create(
              id: EntityId('i-x'),
              companyId: CompanyId('c-a'),
              name: 'X',
              deviceId: 'host-test',
              opId: 'op-ix',
              eventId: 'ev-ix',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(items.get(CompanyId('c-b'), EntityId('i-x')), isNull);
      expect(items.listByCompany(CompanyId('c-b')), isEmpty);
      expect(items.listByCompany(CompanyId('c-a')), hasLength(1));
    });
  });
}
