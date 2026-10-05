// Phase 02 tests: M03 master repositories over real SQLite.
// Disposable in-memory databases only. Proves: party CRUD + role vocabulary
// + addresses, unit/group/type/series/godown CRUD + documented uniques,
// alias storage, and lineage on writes.
// Traceability: REG M03.3/7/9/10/16; DSS §3; DB §3; DSS-C-001/004; OD-DB-004.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/alias_repository.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/unit_group_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late PartyRepository parties;
  late UnitRepository units;
  late ItemGroupRepository groups;
  late VoucherTypeRepository types;
  late GodownRepository godowns;
  late AliasRepository aliases;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    parties = PartyRepository(ctx, ops: ops, audit: audit);
    units = UnitRepository(ctx, ops: ops, audit: audit);
    groups = ItemGroupRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    godowns = GodownRepository(ctx, ops: ops, audit: audit);
    aliases = AliasRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-m'),
            name: 'Masters Co',
            deviceId: 'host-test',
            opId: 'op-cm',
            eventId: 'ev-cm',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Result<Party> createParty(String id, String name, String role) {
    return parties.create(
      id: EntityId(id),
      companyId: CompanyId('c-m'),
      name: name,
      role: role,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('party', () {
    test('create + get round-trips with all documented fields', () {
      final Result<Party> r = parties.create(
        id: EntityId('p-1'),
        companyId: CompanyId('c-m'),
        name: 'Sharma Traders',
        role: 'customer',
        gstin: '24ABCDE1234F1Z5',
        state: 'Gujarat',
        mobile: '9898000000',
        address: 'Shop 1, Market Road',
        terms: 'Net 30',
        deviceId: 'host-test',
        opId: 'op-p-1',
        eventId: 'ev-p-1',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      final Party? got = parties.get(CompanyId('c-m'), EntityId('p-1'));
      expect(got, isNotNull);
      expect(got!.gstin, '24ABCDE1234F1Z5');
      expect(got.mobile, '9898000000');
      expect(ops.forEntity('c-m', 'party', 'p-1'), hasLength(1));
      expect(audit.forEntity('c-m', 'party', 'p-1'), hasLength(1));
    });

    test('role outside customer/supplier is rejected', () {
      final Result<Party> r = createParty('p-bad', 'X', 'both');
      expect(r.isErr, isTrue);
      expect((r as Err<Party>).error.code, 'validation');
    });

    test('update rewrites fields with old/new lineage', () {
      expect(createParty('p-u', 'Old Name', 'supplier').isOk, isTrue);
      final Result<Party> r = parties.update(
        id: EntityId('p-u'),
        companyId: CompanyId('c-m'),
        name: 'New Name',
        role: 'supplier',
        deviceId: 'host-test',
        opId: 'op-pu2',
        eventId: 'ev-pu2',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      expect(parties.get(CompanyId('c-m'), EntityId('p-u'))!.name, 'New Name');
      final List<AuditEvent> evs = audit.forEntity('c-m', 'party', 'p-u');
      expect(evs, hasLength(2));
      expect(evs.last.newData, contains('New Name'));
    });

    test('missing party update is not-found', () {
      final Result<Party> r = parties.update(
        id: EntityId('p-ghost'),
        companyId: CompanyId('c-m'),
        name: 'Ghost',
        role: 'customer',
        deviceId: 'host-test',
        opId: 'op-g',
        eventId: 'ev-g',
        actor: 'tester',
      );
      expect((r as Err<Party>).error.code, 'not-found');
    });

    test('additional addresses accumulate in order', () {
      expect(createParty('p-a', 'Addr Co', 'customer').isOk, isTrue);
      for (final String addr in <String>['Godown 1', 'Shop 2']) {
        expect(
          parties
              .addAddress(
                addressId: EntityId('a-$addr'),
                companyId: CompanyId('c-m'),
                partyId: EntityId('p-a'),
                address: addr,
                deviceId: 'host-test',
                opId: 'op-a-$addr',
                eventId: 'ev-a-$addr',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
      }
      final List<PartyAddress> list =
          parties.addressesFor(CompanyId('c-m'), EntityId('p-a'));
      expect(list.map((PartyAddress a) => a.address), <String>[
        'Godown 1',
        'Shop 2',
      ]);
    });

    test('address on a missing party is foreign-key', () {
      final Result<PartyAddress> r = parties.addAddress(
        addressId: EntityId('a-x'),
        companyId: CompanyId('c-m'),
        partyId: EntityId('p-ghost'),
        address: 'Nowhere',
        deviceId: 'host-test',
        opId: 'op-ax',
        eventId: 'ev-ax',
        actor: 'tester',
      );
      expect((r as Err<PartyAddress>).error.code, 'foreign-key');
    });
  });

  group('unit + group', () {
    test('unit with base-unit factor stores the documented shape', () {
      expect(
        units
            .create(
              id: EntityId('u-nos'),
              companyId: CompanyId('c-m'),
              name: 'Nos',
              deviceId: 'host-test',
              opId: 'op-unos',
              eventId: 'ev-unos',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<Unit> box = units.create(
        id: EntityId('u-box'),
        companyId: CompanyId('c-m'),
        name: 'Box',
        baseUnitId: EntityId('u-nos'),
        factor: 12,
        deviceId: 'host-test',
        opId: 'op-ubox',
        eventId: 'ev-ubox',
        actor: 'tester',
      );
      expect(box.isOk, isTrue);
      expect((box as Ok<Unit>).value.factor, 12);
    });

    test('duplicate unit name in one company is conflict', () {
      Result<Unit> once(String tag) => units.create(
            id: EntityId('u-$tag'),
            companyId: CompanyId('c-m'),
            name: 'Kg',
            deviceId: 'host-test',
            opId: 'op-u-$tag',
            eventId: 'ev-u-$tag',
            actor: 'tester',
          );
      expect(once('1').isOk, isTrue);
      expect((once('2') as Err<Unit>).error.code, 'conflict');
    });

    test('item groups nest via parent links', () {
      expect(
        groups
            .create(
              id: EntityId('g-root'),
              companyId: CompanyId('c-m'),
              name: 'Hardware',
              deviceId: 'host-test',
              opId: 'op-gr',
              eventId: 'ev-gr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<ItemGroup> child = groups.create(
        id: EntityId('g-child'),
        companyId: CompanyId('c-m'),
        parentId: EntityId('g-root'),
        name: 'Fasteners',
        deviceId: 'host-test',
        opId: 'op-gc',
        eventId: 'ev-gc',
        actor: 'tester',
      );
      expect(child.isOk, isTrue);
      expect((child as Ok<ItemGroup>).value.parentId?.value, 'g-root');
    });
  });

  group('voucher type/series + godown', () {
    test('series attaches to its type; numbering stays engine scope', () {
      expect(
        types
            .create(
              id: EntityId('t-inv'),
              companyId: CompanyId('c-m'),
              baseType: 'sales-invoice',
              name: 'Sales Invoice',
              deviceId: 'host-test',
              opId: 'op-t',
              eventId: 'ev-t',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      final Result<VoucherSeries> s = types.createSeries(
        seriesId: EntityId('s-a'),
        companyId: CompanyId('c-m'),
        typeId: EntityId('t-inv'),
        name: 'INV-A',
        prefix: 'INV-A/',
        startNo: 1,
        width: 4,
        deviceId: 'host-test',
        opId: 'op-s',
        eventId: 'ev-s',
        actor: 'tester',
      );
      expect(s.isOk, isTrue);
      expect(
        types.seriesForType(CompanyId('c-m'), EntityId('t-inv')),
        hasLength(1),
      );
    });

    test('duplicate godown name in one company is conflict (repo-level uq)', () {
      Result<Godown> once(String tag) => godowns.create(
            id: EntityId('g-$tag'),
            companyId: CompanyId('c-m'),
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-g-$tag',
            eventId: 'ev-g-$tag',
            actor: 'tester',
          );
      expect(once('1').isOk, isTrue);
      expect((once('2') as Err<Godown>).error.code, 'conflict');
    });
  });

  group('aliases', () {
    test('alias stores exactly as typed and lists back', () {
      expect(createParty('p-al', 'Sharma', 'customer').isOk, isTrue);
      final Result<SearchAlias> r = aliases.add(
        id: EntityId('al-1'),
        companyId: CompanyId('c-m'),
        entity: 'party',
        entityId: EntityId('p-al'),
        alias: 'शर्मा',
        deviceId: 'host-test',
        opId: 'op-al',
        eventId: 'ev-al',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      expect(
        aliases
            .forEntity(CompanyId('c-m'), 'party', EntityId('p-al'))
            .single
            .alias,
        'शर्मा',
      );
    });

    test('unknown alias entity is rejected', () {
      final Result<SearchAlias> r = aliases.add(
        id: EntityId('al-x'),
        companyId: CompanyId('c-m'),
        entity: 'voucher',
        entityId: EntityId('v-1'),
        alias: 'x',
        deviceId: 'host-test',
        opId: 'op-alx',
        eventId: 'ev-alx',
        actor: 'tester',
      );
      expect((r as Err<SearchAlias>).error.code, 'validation');
    });
  });
}
