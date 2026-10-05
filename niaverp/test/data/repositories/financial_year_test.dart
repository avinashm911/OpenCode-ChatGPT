// DSS slice tests: financial years (DB §3, gate G1).
// Disposable in-memory databases only. Proves: FY create/list/get with
// lineage, date-order validation, duplicate (company, start) conflict,
// company isolation, and invalid inputs rejected with no residue.
// FY status vocabulary and enforcement stay downstream (open question).
// Traceability: DB §3 (financial_year); DSS-C-001; OD-DB-004.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/financial_year_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late FinancialYearRepository fys;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    fys = FinancialYearRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-fy', 'c-other']) {
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

  Result<FinancialYear> createFy(
    String id,
    String company,
    String from,
    String to, {
    String status = 'open',
  }) {
    return fys.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      startDate: NiavDate(from),
      endDate: NiavDate(to),
      status: status,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('financial years (DB §3)', () {
    test('create, list and get persist with lineage', () {
      expect(createFy('fy-1', 'c-fy', '2026-04-01', '2027-03-31').isOk, isTrue);
      expect(createFy('fy-2', 'c-fy', '2027-04-01', '2028-03-31').isOk, isTrue);
      final List<FinancialYear> all = fys.listByCompany(CompanyId('c-fy'));
      expect(all.map((FinancialYear f) => f.id.value), <String>['fy-1', 'fy-2']);
      expect(fys.get(CompanyId('c-fy'), EntityId('fy-1'))?.status, 'open');
      expect(ops.forEntity('c-fy', 'financial_year', 'fy-1'), isNotEmpty);
      expect(audit.forEntity('c-fy', 'financial_year', 'fy-1'), isNotEmpty);
    });

    test('inverted dates and empty status rejected with no residue', () {
      final Result<FinancialYear> bad =
          createFy('fy-x', 'c-fy', '2027-04-01', '2026-03-31');
      expect(bad.isErr, isTrue);
      expect((bad as Err<FinancialYear>).error.code, 'validation');
      final Result<FinancialYear> empty =
          createFy('fy-y', 'c-fy', '2026-04-01', '2027-03-31', status: '');
      expect(empty.isErr, isTrue);
      expect(fys.listByCompany(CompanyId('c-fy')), isEmpty);
    });

    test('duplicate start in one company is conflict; other company free', () {
      expect(createFy('fy-1', 'c-fy', '2026-04-01', '2027-03-31').isOk, isTrue);
      final Result<FinancialYear> dupe =
          createFy('fy-9', 'c-fy', '2026-04-01', '2027-03-31');
      expect(dupe.isErr, isTrue);
      expect((dupe as Err<FinancialYear>).error.code, 'conflict');
      expect(
          createFy('fy-1o', 'c-other', '2026-04-01', '2027-03-31').isOk, isTrue);
      expect(fys.get(CompanyId('c-fy'), EntityId('fy-1o')), isNull);
    });
  });
}
