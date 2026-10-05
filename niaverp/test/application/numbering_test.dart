// Numbering engine tests: one generator for all series (FR-M04-002).
// Disposable in-memory databases only. Proves: affix/width formatting with
// untruncated overflow, sequence parsing (manual numbers ignored),
// start_no floor, auto-only generation, restart-vocabulary refusal, gap
// detection, company isolation, and the UNIQUE backstop on races.
// Traceability: FR-M04-002 (duplicate-free scope numbering); DSS-C-002;
// OD-001/O-08 (limited series).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/services/numbering.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late SeriesNumbering numbering;
  final CompanyId companyId = CompanyId('c-n');

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    numbering = SeriesNumbering(db);
    for (final String c in <String>['c-n', 'c-other']) {
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
      types
          .create(
            id: EntityId('t-si'),
            companyId: companyId,
            baseType: 'Sales Invoice',
            name: 'Sales Invoice',
            deviceId: 'host-test',
            opId: 'op-t',
            eventId: 'ev-t',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  VoucherSeries autoSeries({
    String id = 's-auto',
    String name = 'INV',
    String? prefix = 'INV-',
    String? suffix,
    int startNo = 1,
    int width = 4,
    String? restart,
    String? mode = 'auto',
  }) {
    final Result<VoucherSeries> r = types.createSeries(
      seriesId: EntityId(id),
      companyId: companyId,
      typeId: EntityId('t-si'),
      name: name,
      prefix: prefix,
      suffix: suffix,
      startNo: startNo,
      width: width,
      restart: restart,
      mode: mode,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
    return (r as Ok<VoucherSeries>).value;
  }

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

  group('numbering engine (FR-M04-002)', () {
    test('formats affixes, pads width, never truncates overflow', () {
      final VoucherSeries s = autoSeries();
      expect(formatVoucherNo(s, 7), 'INV-0007');
      expect(formatVoucherNo(s, 12345), 'INV-12345');
      final VoucherSeries bare = autoSeries(
          id: 's-bare', name: 'BARE', prefix: null, width: 0);
      expect(formatVoucherNo(bare, 42), '42');
    });

    test('parses own numbers; foreign and malformed yield null', () {
      final VoucherSeries s = autoSeries();
      expect(tryParseSequence(s, 'INV-0007'), 7);
      expect(tryParseSequence(s, 'INV-12345'), 12345);
      expect(tryParseSequence(s, 'X-0007'), isNull);
      expect(tryParseSequence(s, 'INV-'), isNull);
      expect(tryParseSequence(s, 'INV-12A'), isNull);
      expect(tryParseSequence(s, 'INV-0007 '), isNull);
    });

    test('generates from start_no, continues past max, honors floor', () {
      final VoucherSeries s = autoSeries();
      expect((numbering.nextNumber(companyId, s) as Ok<String>).value,
          'INV-0001');
      createVoucher('v-1', 'c-n', 'INV', 'INV-0003');
      createVoucher('v-2', 'c-n', 'INV', 'MANUAL-9');
      createVoucher('v-3', 'c-n', 'INV', 'INV-0001');
      expect((numbering.nextNumber(companyId, s) as Ok<String>).value,
          'INV-0004');

      final VoucherSeries high = autoSeries(
          id: 's-high', name: 'HI', prefix: 'HI-', startNo: 100);
      createVoucher('v-4', 'c-n', 'HI', 'HI-0005');
      expect((numbering.nextNumber(companyId, high) as Ok<String>).value,
          'HI-0100');
    });

    test('manual/unset mode and unknown restarts never generate', () {
      final VoucherSeries manual =
          autoSeries(id: 's-man', name: 'MAN', mode: 'manual');
      final Result<String> m = numbering.nextNumber(companyId, manual);
      expect(m.isErr, isTrue);
      final VoucherSeries unset =
          autoSeries(id: 's-unset', name: 'UN', mode: null);
      expect(numbering.nextNumber(companyId, unset).isErr, isTrue);
      final VoucherSeries yearly = autoSeries(
          id: 's-year', name: 'YR', restart: 'yearly');
      final Result<String> y = numbering.nextNumber(companyId, yearly);
      expect(y.isErr, isTrue);
      expect((y as Err<String>).error.message, contains('yearly'));
      final VoucherSeries never = autoSeries(
          id: 's-never', name: 'NV', restart: 'never');
      expect(numbering.nextNumber(companyId, never).isOk, isTrue);
    });

    test('bad mode values rejected at series creation', () {
      final Result<VoucherSeries> r = types.createSeries(
        seriesId: EntityId('s-bogus'),
        companyId: companyId,
        typeId: EntityId('t-si'),
        name: 'BOGUS',
        deviceId: 'host-test',
        opId: 'op-bogus',
        eventId: 'ev-bogus',
        actor: 'tester',
      );
      expect(r.isOk, isTrue);
      // mode travels through createSeries only; bogus mode rejected there:
      final Result<VoucherSeries> bad = types.createSeries(
        seriesId: EntityId('s-bogus2'),
        companyId: companyId,
        typeId: EntityId('t-si'),
        name: 'BOGUS2',
        mode: 'sometimes',
        deviceId: 'host-test',
        opId: 'op-bogus2',
        eventId: 'ev-bogus2',
        actor: 'tester',
      );
      expect(bad.isErr, isTrue);
      expect((bad as Err<VoucherSeries>).error.code, 'validation');
    });

    test('gaps report missing sequences in scope', () {
      final VoucherSeries s = autoSeries();
      expect(
          (numbering.seriesGaps(companyId, s) as Ok<List<int>>).value, isEmpty);
      createVoucher('v-1', 'c-n', 'INV', 'INV-0001');
      createVoucher('v-2', 'c-n', 'INV', 'INV-0002');
      createVoucher('v-3', 'c-n', 'INV', 'INV-0004');
      expect((numbering.seriesGaps(companyId, s) as Ok<List<int>>).value,
          <int>[3]);
    });

    test('scopes isolate companies; UNIQUE stays the race backstop', () {
      final VoucherSeries s = autoSeries();
      createVoucher('v-1', 'c-n', 'INV', 'INV-0001');
      createVoucher('v-9', 'c-other', 'INV', 'INV-0009');
      expect((numbering.nextNumber(companyId, s) as Ok<String>).value,
          'INV-0002');
      // Two creates with the same generated number: the second collides.
      createVoucher('v-a', 'c-n', 'INV', 'INV-0002');
      final Result<Voucher> dupe = vouchers.create(
        id: EntityId('v-b'),
        companyId: companyId,
        type: 'sales-invoice',
        series: 'INV',
        no: 'INV-0002',
        date: NiavDate('2026-04-01'),
        deviceId: 'host-test',
        opId: 'op-v-b',
        eventId: 'ev-v-b',
        actor: 'tester',
      );
      expect(dupe.isErr, isTrue);
      expect((dupe as Err<Voucher>).error.code, 'conflict');
    });
  });
}
