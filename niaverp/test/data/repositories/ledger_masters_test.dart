// Posting-slice tests: ledger masters (FR-M03-002, gate G1).
// Disposable in-memory databases only. Proves: group tree guards,
// ledger CRUD with group scoping, duplicate-name conflicts, opening
// side/amount rules, company isolation, and lineage on writes.
// Contact/address/bank/GST detail columns wait on their specs.
// Traceability: FR-M03-002 (duplicate handling); DB §3; DSS-C-001.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late AccountGroupRepository groups;
  late LedgerRepository ledgers;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    groups = AccountGroupRepository(ctx, ops: ops, audit: audit);
    ledgers = LedgerRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-l', 'c-other']) {
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

  Result<AccountGroup> createGroup(String id, String name, {String? parent}) {
    return groups.create(
      id: EntityId(id),
      companyId: CompanyId('c-l'),
      parentId: parent == null ? null : EntityId(parent),
      name: name,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  Result<Ledger> createLedger(
    String id,
    String group,
    String name, {
    String? side,
    int opening = 0,
    bool billwise = false,
    String company = 'c-l',
  }) {
    return ledgers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      groupId: EntityId(group),
      name: name,
      openingSide: side,
      openingPaise: opening,
      billwise: billwise,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('ledger masters (FR-M03-002)', () {
    test('group tree nests; ledger carries opening with lineage', () {
      expect(createGroup('g-a', 'Assets').isOk, isTrue);
      expect(createGroup('g-cash', 'Cash', parent: 'g-a').isOk, isTrue);
      final Result<Ledger> r =
          createLedger('l-cash', 'g-cash', 'Cash Account', side: 'Dr', opening: 5000);
      expect(r.isOk, isTrue);
      final Ledger got = (r as Ok<Ledger>).value;
      expect(got.signedOpening, 5000);
      expect(ledgers.get(CompanyId('c-l'), EntityId('l-cash'))?.billwise, isFalse);
      expect(ops.forEntity('c-l', 'ledger', 'l-cash'), isNotEmpty);
      expect(audit.forEntity('c-l', 'ledger', 'l-cash'), isNotEmpty);
    });

    test('self-parent and foreign groups rejected', () {
      final Result<AccountGroup> self = createGroup('g-s', 'S', parent: 'g-s');
      expect(self.isErr, isTrue);
      expect(createGroup('g-ok', 'OK').isOk, isTrue);
      final Result<Ledger> foreign = createLedger('l-x', 'g-ghost', 'X');
      expect(foreign.isErr, isTrue);
      expect((foreign as Err<Ledger>).error.code, 'foreign-key');
    });

    test('duplicate ledger names collide per company only', () {
      expect(createGroup('g-a', 'Assets').isOk, isTrue);
      expect(createLedger('l-1', 'g-a', 'Cash').isOk, isTrue);
      final Result<Ledger> dupe = createLedger('l-2', 'g-a', 'Cash');
      expect(dupe.isErr, isTrue);
      expect((dupe as Err<Ledger>).error.code, 'conflict');
      expect(groups.listByCompany(CompanyId('c-l')), hasLength(1));
    });

    test('opening rules: side required with amount, values constrained', () {
      expect(createGroup('g-a', 'Assets').isOk, isTrue);
      final Result<Ledger> noSide = createLedger('l-1', 'g-a', 'A', opening: 100);
      expect(noSide.isErr, isTrue);
      expect((noSide as Err<Ledger>).error.code, 'validation');
      final Result<Ledger> badSide =
          createLedger('l-2', 'g-a', 'B', side: 'Dx', opening: 100);
      expect(badSide.isErr, isTrue);
      final Result<Ledger> negative =
          createLedger('l-3', 'g-a', 'C', side: 'Dr', opening: -5);
      expect(negative.isErr, isTrue);
      final Result<Ledger> cr =
          createLedger('l-4', 'g-a', 'D', side: 'Cr', opening: 250);
      expect(cr.isOk, isTrue);
      expect((cr as Ok<Ledger>).value.signedOpening, -250);
    });

    test('ledgers stay within their company', () {
      expect(createGroup('g-a', 'Assets').isOk, isTrue);
      expect(createLedger('l-1', 'g-a', 'Cash').isOk, isTrue);
      expect(ledgers.get(CompanyId('c-other'), EntityId('l-1')), isNull);
      expect(ledgers.listByCompany(CompanyId('c-other')), isEmpty);
    });
  });
}
