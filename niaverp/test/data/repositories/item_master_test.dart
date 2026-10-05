// Phase 02 tests: item master columns (M03.8) + rename over real SQLite.
// Disposable in-memory databases only. Proves: updateMaster persists the
// documented nullable set with lineage, rename rewrites base text, FK links
// to missing group/unit/tax rows fail, and GST range validation precedes
// the database. Traceability: REG M03.8; DSS §3; OD-DB-004.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/unit_group_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late ItemRepository items;
  late UnitRepository units;
  late ItemGroupRepository groups;
  late OperationLog ops;
  late AuditLog audit;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    items = ItemRepository(ctx, ops: ops, audit: audit);
    units = UnitRepository(ctx, ops: ops, audit: audit);
    groups = ItemGroupRepository(ctx, ops: ops, audit: audit);
    expect(
      companies
          .create(
            id: CompanyId('c-im'),
            name: 'Item Master Co',
            deviceId: 'host-test',
            opId: 'op-cim',
            eventId: 'ev-cim',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-m'),
            companyId: CompanyId('c-im'),
            name: 'Washer',
            deviceId: 'host-test',
            opId: 'op-im',
            eventId: 'ev-im',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  group('updateMaster', () {
    test('persists code/barcode/HSN/GST with update lineage', () {
      final Result<Item> r = items.updateMaster(
        companyId: CompanyId('c-im'),
        id: EntityId('i-m'),
        code: 'WS-6',
        barcode: '8900000000011',
        hsnCode: '7318',
        gstRateBps: 1800,
        deviceId: 'host-test',
        opId: 'op-imm',
        eventId: 'ev-imm',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      final Item? got = items.get(CompanyId('c-im'), EntityId('i-m'));
      expect(got!.code, 'WS-6');
      expect(got.hsnCode, '7318');
      expect(got.gstRateBps, 1800);
      expect(audit.forEntity('c-im', 'item', 'i-m'), hasLength(2));
    });

    test('GST bps outside 0..10000 is rejected pre-database', () {
      final Result<Item> r = items.updateMaster(
        companyId: CompanyId('c-im'),
        id: EntityId('i-m'),
        gstRateBps: 10001,
        deviceId: 'host-test',
        opId: 'op-imb',
        eventId: 'ev-imb',
        actor: 'tester',
      );
      expect((r as Err<Item>).error.code, 'validation');
    });

    test('link to a missing group is foreign-key', () {
      final Result<Item> r = items.updateMaster(
        companyId: CompanyId('c-im'),
        id: EntityId('i-m'),
        groupId: EntityId('g-ghost'),
        deviceId: 'host-test',
        opId: 'op-img',
        eventId: 'ev-img',
        actor: 'tester',
      );
      expect((r as Err<Item>).error.code, 'foreign-key');
    });

    test('links to live group/unit/tax rows persist', () {
      expect(
        units
            .create(
              id: EntityId('u-nos'),
              companyId: CompanyId('c-im'),
              name: 'Nos',
              deviceId: 'host-test',
              opId: 'op-u',
              eventId: 'ev-u',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        groups
            .create(
              id: EntityId('g-hw'),
              companyId: CompanyId('c-im'),
              name: 'Hardware',
              deviceId: 'host-test',
              opId: 'op-g',
              eventId: 'ev-g',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      db.executeArgs(
        'INSERT INTO tax_rate_hsn (rate_id, company_id, hsn_code, rate_bps, '
        'effective_from) VALUES (?, ?, ?, ?, ?)',
        <Object?>['tx-1', 'c-im', '7318', 1800, '2026-04-01'],
      );
      final Result<Item> r = items.updateMaster(
        companyId: CompanyId('c-im'),
        id: EntityId('i-m'),
        taxRateId: 'tx-1',
        groupId: EntityId('g-hw'),
        unitId: EntityId('u-nos'),
        deviceId: 'host-test',
        opId: 'op-iml',
        eventId: 'ev-iml',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      final Item? got = items.get(CompanyId('c-im'), EntityId('i-m'));
      expect(got!.taxRateId, 'tx-1');
      expect(got.groupId?.value, 'g-hw');
      expect(got.unitId?.value, 'u-nos');
    });
  });

  group('rename', () {
    test('rewrites name/unit text with lineage', () {
      final Result<Item> r = items.rename(
        companyId: CompanyId('c-im'),
        id: EntityId('i-m'),
        name: 'Spring Washer',
        unit: 'pcs',
        deviceId: 'host-test',
        opId: 'op-ir',
        eventId: 'ev-ir',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      expect(
        items.get(CompanyId('c-im'), EntityId('i-m'))!.name,
        'Spring Washer',
      );
    });

    test('missing item is not-found', () {
      final Result<Item> r = items.rename(
        companyId: CompanyId('c-im'),
        id: EntityId('i-ghost'),
        name: 'Ghost',
        unit: 'pcs',
        deviceId: 'host-test',
        opId: 'op-ig',
        eventId: 'ev-ig',
        actor: 'tester',
      );
      expect((r as Err<Item>).error.code, 'not-found');
    });
  });
}
