// DSS transaction-slice tests: document lineage storage (FR-M09-002).
// Disposable in-memory databases only. Proves: header- and line-level links
// persist with lineage, both directions list back, cross-company/missing
// vouchers are rejected with no residue, and empty statuses are rejected.
// Conversion eligibility math stays downstream (document-flow slice).
// Traceability: FR-M09-002 (lineage storage); DSS §3; DSS-C-001.

import 'package:flutter_test/flutter_test.dart';

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

import '../../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late DocumentLinkRepository links;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    links = DocumentLinkRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-d', 'c-other']) {
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

  void addLine(String vid, String lid, String company) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: CompanyId(company),
      lineNo: 1,
      qtyQ4: 10000,
      ratePaise: 500,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<DocumentLink> link(
    String id,
    String company,
    String source,
    String target, {
    String? sourceLine,
    String? targetLine,
    String status = 'active',
  }) {
    return links.create(
      id: EntityId(id),
      companyId: CompanyId(company),
      sourceVoucherId: EntityId(source),
      sourceLineId: sourceLine == null ? null : EntityId(sourceLine),
      targetVoucherId: EntityId(target),
      targetLineId: targetLine == null ? null : EntityId(targetLine),
      qtyQ4: 10000,
      status: status,
      deviceId: 'host-test',
      opId: 'op-$id',
      eventId: 'ev-$id',
      actor: 'tester',
    );
  }

  group('document links (FR-M09-002 storage)', () {
    test('header-level link persists and lists both ways with lineage', () {
      createVoucher('v-q', 'c-d', 'Sales Quotation / Proforma Invoice');
      createVoucher('v-o', 'c-d', 'Sales Order');
      final Result<DocumentLink> r = link('l-1', 'c-d', 'v-q', 'v-o');
      expect(r.isOk, isTrue);
      final DocumentLink saved = (r as Ok<DocumentLink>).value;
      expect(saved.sourceLineId, isNull);
      expect(saved.qtyQ4, 10000);
      expect(
        links.linksFrom(CompanyId('c-d'), EntityId('v-q')).map((DocumentLink l) => l.id.value),
        <String>['l-1'],
      );
      expect(
        links.linksTo(CompanyId('c-d'), EntityId('v-o')).map((DocumentLink l) => l.id.value),
        <String>['l-1'],
      );
      expect(links.linksFrom(CompanyId('c-d'), EntityId('v-o')), isEmpty);
      expect(ops.forEntity('c-d', 'document_link', 'l-1'), isNotEmpty);
      expect(audit.forEntity('c-d', 'document_link', 'l-1'), isNotEmpty);
    });

    test('line-level link stores line refs and quantity', () {
      createVoucher('v-q', 'c-d', 'Sales Quotation / Proforma Invoice');
      addLine('v-q', 'v-q-l1', 'c-d');
      createVoucher('v-o', 'c-d', 'Sales Order');
      addLine('v-o', 'v-o-l1', 'c-d');
      final Result<DocumentLink> r = link('l-1', 'c-d', 'v-q', 'v-o',
          sourceLine: 'v-q-l1', targetLine: 'v-o-l1');
      expect(r.isOk, isTrue);
      final DocumentLink saved = (r as Ok<DocumentLink>).value;
      expect(saved.sourceLineId?.value, 'v-q-l1');
      expect(saved.targetLineId?.value, 'v-o-l1');
    });

    test('cross-company and missing vouchers rejected with no residue', () {
      createVoucher('v-q', 'c-d', 'Sales Quotation / Proforma Invoice');
      createVoucher('v-f', 'c-other', 'Sales Order');
      final Result<DocumentLink> cross = link('l-x', 'c-d', 'v-q', 'v-f');
      expect(cross.isErr, isTrue);
      expect((cross as Err<DocumentLink>).error.code, 'foreign-key');
      final Result<DocumentLink> missing = link('l-y', 'c-d', 'v-q', 'v-nope');
      expect(missing.isErr, isTrue);
      expect((missing as Err<DocumentLink>).error.code, 'foreign-key');
      expect(links.linksFrom(CompanyId('c-d'), EntityId('v-q')), isEmpty);
    });

    test('non-active creation is rejected (closed lifecycle)', () {
      createVoucher('v-q', 'c-d', 'Sales Quotation / Proforma Invoice');
      createVoucher('v-o', 'c-d', 'Sales Order');
      final Result<DocumentLink> r =
          link('l-1', 'c-d', 'v-q', 'v-o', status: 'linked');
      expect(r.isErr, isTrue);
      expect((r as Err<DocumentLink>).error.code, 'validation');
      expect(links.linksFrom(CompanyId('c-d'), EntityId('v-q')), isEmpty);
    });

    test('empty status rejected (invalid case)', () {
      createVoucher('v-q', 'c-d', 'Sales Quotation / Proforma Invoice');
      createVoucher('v-o', 'c-d', 'Sales Order');
      final Result<DocumentLink> r =
          link('l-1', 'c-d', 'v-q', 'v-o', status: '');
      expect(r.isErr, isTrue);
      expect((r as Err<DocumentLink>).error.code, 'validation');
    });
  });
}
