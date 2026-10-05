// Prompt-03 tests: voucher-number search (FR-M12-001).
// Disposable in-memory databases only. Proves: lookup by partial number and
// by series over stored text, prefix-first ordering, wildcard literality,
// company isolation, and empty/unknown queries matching nothing.
// Traceability: FR-M12-001 (voucher number); DSS-C-001 (scope).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late MasterSearch search;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
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
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createVoucher(String id, String company, String series, String no) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      type: 'sales-invoice',
      series: series,
      no: no,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  group('voucher-number search (FR-M12-001)', () {
    test('finds vouchers by partial number, prefix first', () {
      createVoucher('v-1', 'c-s', 'SI', 'XINV-001');
      createVoucher('v-2', 'c-s', 'SI', 'INV-002');
      final List<Voucher> hits = search.searchVouchers(CompanyId('c-s'), 'INV');
      expect(hits.map((Voucher v) => v.no), <String>['INV-002', 'XINV-001']);
    });

    test('finds vouchers by series', () {
      createVoucher('v-1', 'c-s', 'SI', 'INV-001');
      createVoucher('v-2', 'c-s', 'PI', 'INV-001');
      final List<Voucher> hits = search.searchVouchers(CompanyId('c-s'), 'PI');
      expect(hits.map((Voucher v) => v.series), <String>['PI']);
    });

    test('empty and unknown queries match nothing', () {
      createVoucher('v-1', 'c-s', 'SI', 'INV-001');
      expect(search.searchVouchers(CompanyId('c-s'), '   '), isEmpty);
      expect(search.searchVouchers(CompanyId('c-s'), 'ZZZ-999'), isEmpty);
    });

    test('results stay within the requesting company', () {
      createVoucher('v-1', 'c-other', 'SI', 'INV-001');
      expect(search.searchVouchers(CompanyId('c-s'), 'INV'), isEmpty);
      expect(
        search.searchVouchers(CompanyId('c-other'), 'INV').map((Voucher v) => v.no),
        <String>['INV-001'],
      );
    });

    test('LIKE wildcards in the query match literally', () {
      createVoucher('v-1', 'c-s', 'SI', '100%OK');
      createVoucher('v-2', 'c-s', 'SI', '100XOK');
      final List<Voucher> hits =
          search.searchVouchers(CompanyId('c-s'), '100%OK');
      expect(hits.map((Voucher v) => v.no), <String>['100%OK']);
    });
  });
}
