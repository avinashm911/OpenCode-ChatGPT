// Phase 02 tests: master search over real SQLite (M12.3 subset).
// Disposable in-memory databases only. Proves: substring matching on stored
// fields + stored aliases (either script as typed), prefix-first ordering,
// empty-query silence, company isolation, and literal wildcard handling.
// What is NOT here (explicit boundaries): fuzzy matching (P2 M12.4),
// transliteration (excluded G0-DEF-003), latency targets (TBC M12.8).
// Traceability: REG M12.3; G0-DEF-003; DSS-C-001.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/alias_repository.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late MasterSearch search;
  late PartyRepository parties;
  late ItemRepository items;
  late AliasRepository aliases;

  void seed() {
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    parties = PartyRepository(ctx, ops: ops, audit: audit);
    items = ItemRepository(ctx, ops: ops, audit: audit);
    aliases = AliasRepository(ctx, ops: ops, audit: audit);
    search = MasterSearch(db);
    for (final String c in <String>['c-s', 'c-other']) {
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
    expect(
      parties
          .create(
            id: EntityId('p-sharma'),
            companyId: CompanyId('c-s'),
            name: 'Sharma Traders',
            role: 'customer',
            gstin: '24ABCDE1234F1Z5',
            mobile: '9898000000',
            deviceId: 'host-test',
            opId: 'op-ps',
            eventId: 'ev-ps',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-patel'),
            companyId: CompanyId('c-s'),
            name: 'Patel Brothers',
            role: 'supplier',
            deviceId: 'host-test',
            opId: 'op-pp',
            eventId: 'ev-pp',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      aliases
          .add(
            id: EntityId('al-sh'),
            companyId: CompanyId('c-s'),
            entity: 'party',
            entityId: EntityId('p-sharma'),
            alias: 'शर्मा',
            deviceId: 'host-test',
            opId: 'op-al',
            eventId: 'ev-al',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-bolt'),
            companyId: CompanyId('c-s'),
            name: 'Hex Bolt M8',
            deviceId: 'host-test',
            opId: 'op-ib',
            eventId: 'ev-ib',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .updateMaster(
            companyId: CompanyId('c-s'),
            id: EntityId('i-bolt'),
            code: 'HB-M8',
            barcode: '8901234567890',
            deviceId: 'host-test',
            opId: 'op-ibm',
            eventId: 'ev-ibm',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  }

  setUp(() {
    db = openTestDatabase();
    seed();
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  group('party search', () {
    test('matches name substring', () {
      final List<Party> hits = search.searchParties(CompanyId('c-s'), 'shar');
      expect(hits.map((Party p) => p.id.value), <String>['p-sharma']);
    });

    test('matches GSTIN and mobile', () {
      expect(
        search.searchParties(CompanyId('c-s'), 'ABCDE').single.id.value,
        'p-sharma',
      );
      expect(
        search.searchParties(CompanyId('c-s'), '9898').single.id.value,
        'p-sharma',
      );
    });

    test('matches stored native-script alias as typed', () {
      final List<Party> hits = search.searchParties(CompanyId('c-s'), 'शर्म');
      expect(hits.map((Party p) => p.id.value), <String>['p-sharma']);
    });

    test('prefix matches rank before inner matches', () {
      final List<Party> hits = search.searchParties(CompanyId('c-s'), 'Pat');
      expect(hits.first.id.value, 'p-patel');
    });

    test('empty query matches nothing', () {
      expect(search.searchParties(CompanyId('c-s'), '   '), isEmpty);
    });

    test('other companies are invisible', () {
      expect(search.searchParties(CompanyId('c-other'), 'shar'), isEmpty);
    });

    test('wildcards match literally, not as patterns', () {
      expect(search.searchParties(CompanyId('c-s'), '%'), isEmpty);
      expect(search.searchParties(CompanyId('c-s'), '_'), isEmpty);
    });
  });

  group('item search', () {
    test('matches name, code and barcode', () {
      expect(
        search.searchItems(CompanyId('c-s'), 'bolt').single.id.value,
        'i-bolt',
      );
      expect(
        search.searchItems(CompanyId('c-s'), 'HB-M8').single.id.value,
        'i-bolt',
      );
      expect(
        search.searchItems(CompanyId('c-s'), '8901234').single.id.value,
        'i-bolt',
      );
    });

    test('matches stored alias', () {
      expect(
        aliases
            .add(
              id: EntityId('al-nut'),
              companyId: CompanyId('c-s'),
              entity: 'item',
              entityId: EntityId('i-bolt'),
              alias: 'नट-बोल्ट',
              deviceId: 'host-test',
              opId: 'op-aln',
              eventId: 'ev-aln',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        search.searchItems(CompanyId('c-s'), 'नट').single.id.value,
        'i-bolt',
      );
    });

    test('empty query and foreign company match nothing', () {
      expect(search.searchItems(CompanyId('c-s'), ''), isEmpty);
      expect(search.searchItems(CompanyId('c-other'), 'bolt'), isEmpty);
    });
  });
}
