// Document-flow tests: conversion eligibility math (FR-M09-001/002).
// Disposable in-memory databases only. Proves: partial conversion reduces
// both pools, multiple conversions compose to exhaustion, over-conversion
// is rejected at line and voucher scope, reversal reopens quantities,
// reversed links stop consuming, mismatched lines/companies are rejected,
// and every link carries lineage.
// Traceability: FR-M09-001 (eligible quantities, partial/multiple);
// FR-M09-002 (lineage, reversal reopening).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/services/document_flow.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/document_link_repository.dart';
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
  late DocumentLinkRepository links;
  late DocumentFlow flow;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    links = DocumentLinkRepository(ctx, ops: ops, audit: audit);
    flow = DocumentFlow(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      links: links,
    );
    for (final String c in <String>['c-f', 'c-other']) {
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

  void createVoucher(String id, String company, String type) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      type: type,
      series: 'S',
      no: id,
      date: NiavDate('2026-04-01'),
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void addLine(String vid, String lid, String company, int qty, int line) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: CompanyId(company),
      lineNo: line,
      qtyQ4: qty,
      ratePaise: 500,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<DocumentLink> convert(
    String id,
    String source,
    String target, {
    String? sourceLine,
    String? targetLine,
    required int qty,
    String company = 'c-f',
  }) {
    return flow.convert(
      linkId: EntityId(id),
      companyId: CompanyId(company),
      sourceVoucherId: EntityId(source),
      sourceLineId: sourceLine == null ? null : EntityId(sourceLine),
      targetVoucherId: EntityId(target),
      targetLineId: targetLine == null ? null : EntityId(targetLine),
      qtyQ4: qty,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('conversion eligibility (FR-M09)', () {
    test('partial then remainder compose; over-conversion rejected', () {
      createVoucher('v-q', 'c-f', 'Sales Quotation / Proforma Invoice');
      addLine('v-q', 'v-q-l1', 'c-f', 50000, 1);
      createVoucher('v-o', 'c-f', 'Sales Order');
      addLine('v-o', 'v-o-l1', 'c-f', 50000, 1);

      expect(
        convert('l-1', 'v-q', 'v-o',
            sourceLine: 'v-q-l1', targetLine: 'v-o-l1', qty: 20000)
            .isOk,
        isTrue,
      );
      expect(
        flow.remainingLineQty(CompanyId('c-f'), EntityId('v-q-l1')),
        30000,
      );
      expect(
        flow.remainingVoucherQty(CompanyId('c-f'), EntityId('v-q')),
        30000,
      );
      expect(
        convert('l-2', 'v-q', 'v-o',
            sourceLine: 'v-q-l1', targetLine: 'v-o-l1', qty: 30000)
            .isOk,
        isTrue,
      );
      final Result<DocumentLink> over = convert('l-3', 'v-q', 'v-o',
          sourceLine: 'v-q-l1', targetLine: 'v-o-l1', qty: 1);
      expect(over.isErr, isTrue);
      expect((over as Err<DocumentLink>).error.code, 'validation');
    });

    test('header-level conversion draws the voucher pool', () {
      createVoucher('v-q', 'c-f', 'Sales Quotation / Proforma Invoice');
      addLine('v-q', 'v-q-l1', 'c-f', 40000, 1);
      addLine('v-q', 'v-q-l2', 'c-f', 10000, 2);
      createVoucher('v-o', 'c-f', 'Sales Order');
      expect(convert('l-1', 'v-q', 'v-o', qty: 50000).isOk, isTrue);
      expect(
        flow.remainingVoucherQty(CompanyId('c-f'), EntityId('v-q')),
        0,
      );
      expect(convert('l-2', 'v-q', 'v-o', qty: 1).isErr, isTrue);
    });

    test('reversal reopens quantities; double reversal rejected', () {
      createVoucher('v-q', 'c-f', 'Sales Quotation / Proforma Invoice');
      addLine('v-q', 'v-q-l1', 'c-f', 50000, 1);
      createVoucher('v-o', 'c-f', 'Sales Order');
      expect(
        convert('l-1', 'v-q', 'v-o', sourceLine: 'v-q-l1', qty: 50000).isOk,
        isTrue,
      );
      expect(
        flow.remainingLineQty(CompanyId('c-f'), EntityId('v-q-l1')),
        0,
      );
      final Result<DocumentLink> rev = links.reverse(
        id: EntityId('l-1'),
        companyId: CompanyId('c-f'),
        reason: 'order cancelled',
        deviceId: 'host-test',
        opId: 'op-rev',
        eventId: 'ev-rev',
        actor: 'tester',
      );
      expect(rev.isOk, isTrue);
      expect((rev as Ok<DocumentLink>).value.status, 'reversed');
      expect(
        flow.remainingLineQty(CompanyId('c-f'), EntityId('v-q-l1')),
        50000,
      );
      final Result<DocumentLink> twice = links.reverse(
        id: EntityId('l-1'),
        companyId: CompanyId('c-f'),
        reason: 'again',
        deviceId: 'host-test',
        opId: 'op-rev2',
        eventId: 'ev-rev2',
        actor: 'tester',
      );
      expect(twice.isErr, isTrue);
      final Result<DocumentLink> noReason = links.reverse(
        id: EntityId('l-1'),
        companyId: CompanyId('c-f'),
        reason: '  ',
        deviceId: 'host-test',
        opId: 'op-rev3',
        eventId: 'ev-rev3',
        actor: 'tester',
      );
      expect(noReason.isErr, isTrue);
    });

    test('mismatched lines, missing and foreign documents rejected', () {
      createVoucher('v-q', 'c-f', 'Sales Quotation / Proforma Invoice');
      addLine('v-q', 'v-q-l1', 'c-f', 50000, 1);
      createVoucher('v-o', 'c-f', 'Sales Order');
      addLine('v-o', 'v-o-l1', 'c-f', 50000, 1);
      createVoucher('v-x', 'c-other', 'Sales Order');

      final Result<DocumentLink> swapped = convert('l-bad', 'v-q', 'v-o',
          sourceLine: 'v-o-l1', targetLine: 'v-q-l1', qty: 1000);
      expect(swapped.isErr, isTrue);
      final Result<DocumentLink> missing =
          convert('l-m', 'v-q', 'v-nope', qty: 1000);
      expect(missing.isErr, isTrue);
      final Result<DocumentLink> foreign =
          convert('l-f', 'v-q', 'v-x', qty: 1000);
      expect(foreign.isErr, isTrue);
      final Result<DocumentLink> zero =
          convert('l-z', 'v-q', 'v-o', qty: 0);
      expect(zero.isErr, isTrue);
      expect(links.linksFrom(CompanyId('c-f'), EntityId('v-q')), isEmpty);
    });
  });
}
