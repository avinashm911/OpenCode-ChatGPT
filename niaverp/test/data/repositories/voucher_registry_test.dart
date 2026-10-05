// Prompt-04 tests: voucher-type registry rules (FR-M04-001/002).
// Disposable in-memory databases only. Proves: all 19 canonical base types
// (names + slugs) are accepted, unknown bases are rejected with no residue,
// duplicate series names collide only within their (company, type) scope,
// and series on a missing type fail as foreign-key.
// Traceability: FR-M04-001 (base type must exist); FR-M04-002 (no duplicate
// series configuration in its scope); DECISIONS.md (19 voucher types).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherTypeRepository types;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-v'),
            name: 'Voucher Co',
            deviceId: 'host-test',
            opId: 'op-cv',
            eventId: 'ev-cv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<VoucherType> createType(String id, String base, String name) {
    return types.create(
      id: EntityId(id),
      companyId: CompanyId('c-v'),
      baseType: base,
      name: name,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  Result<VoucherSeries> createSeries(String id, String typeId, String name) {
    return types.createSeries(
      seriesId: EntityId(id),
      companyId: CompanyId('c-v'),
      typeId: EntityId(typeId),
      name: name,
      prefix: 'X/',
      startNo: 1,
      width: 4,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('voucher registry (FR-M04-001/002)', () {
    test('all 19 canonical base types are accepted, slugs distinct', () {
      expect(kCanonicalVoucherTypes, hasLength(19));
      final Set<String> slugs = <String>{
        for (final String n in kCanonicalVoucherTypes) voucherBaseSlug(n),
      };
      expect(slugs, hasLength(19));
      int i = 0;
      for (final String base in kCanonicalVoucherTypes) {
        i += 1;
        expect(createType('t-$i', base, 'Type $i').isOk, isTrue);
      }
      expect(types.listByCompany(CompanyId('c-v')), hasLength(19));
    });

    test('canonical slugs are accepted as base types', () {
      expect(createType('t-s', 'sales-invoice', 'SI').isOk, isTrue);
      expect(
        createType('t-dn', 'delivery-note-delivery-challan', 'DN').isOk,
        isTrue,
      );
    });

    test('unknown base type is rejected with no residue', () {
      final Result<VoucherType> r = createType('t-x', 'made-up-type', 'X');
      expect(r.isErr, isTrue);
      expect((r as Err<VoucherType>).error.code, 'validation');
      expect(types.listByCompany(CompanyId('c-v')), isEmpty);
    });

    test('empty base type is rejected (invalid case)', () {
      final Result<VoucherType> r = createType('t-e', '', 'E');
      expect(r.isErr, isTrue);
      expect((r as Err<VoucherType>).error.code, 'validation');
    });

    test('duplicate series name in one type scope is conflict', () {
      expect(createType('t-1', 'Sales Invoice', 'SI').isOk, isTrue);
      expect(createSeries('s-1', 't-1', 'MAIN').isOk, isTrue);
      final Result<VoucherSeries> dupe = createSeries('s-2', 't-1', 'MAIN');
      expect(dupe.isErr, isTrue);
      expect((dupe as Err<VoucherSeries>).error.code, 'conflict');
      expect(
        types.seriesForType(CompanyId('c-v'), EntityId('t-1')),
        hasLength(1),
      );
    });

    test('same series name under another type is allowed', () {
      expect(createType('t-1', 'Sales Invoice', 'SI').isOk, isTrue);
      expect(createType('t-2', 'Purchase Invoice', 'PI').isOk, isTrue);
      expect(createSeries('s-1', 't-1', 'MAIN').isOk, isTrue);
      expect(createSeries('s-2', 't-2', 'MAIN').isOk, isTrue);
    });

    test('series on a missing type is foreign-key', () {
      expect(createType('t-1', 'Sales Invoice', 'SI').isOk, isTrue);
      final Result<VoucherSeries> r = createSeries('s-9', 't-nope', 'MAIN');
      expect(r.isErr, isTrue);
      expect((r as Err<VoucherSeries>).error.code, 'foreign-key');
    });
  });
}
