// GST engine posting tests (CA reply 2026-10-07, Q1-Q4).
// Disposable in-memory databases only. Proves through the real engine:
// intra-state sale posts balanced Cr Output CGST/SGST arms; inter-state
// purchase posts Dr Input IGST; separate halves (never split totals);
// multi-rate aggregation; ship-to vs bill-to incl. third-party direction;
// every block case refuses with a naming error and writes nothing; cancel
// mirrors tax arms; returns reverse sides; locked periods refuse; round-off
// runs once on net+tax with Dr = Cr throughout.
// Traceability: FR-M03-002; G0-VER-003; CA reply 2026-10-07.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/bill_allocation_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/period_lock.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

import '../helpers/seeded_post.dart';
import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;
  late OperationLog ops;
  late AuditLog audit;
  late VoucherRepository vouchers;
  late VoucherTypeRepository types;
  late VoucherEngine engine;
  late VoucherSeeder seeder;
  final CompanyId companyId = CompanyId('c-g');

  const Map<String, String> taxLedgers = <String, String>{
    'Output CGST': 'l-o-cgst',
    'Output SGST': 'l-o-sgst',
    'Output IGST': 'l-o-igst',
    'Input CGST': 'l-i-cgst',
    'Input SGST': 'l-i-sgst',
    'Input IGST': 'l-i-igst',
  };

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    ops = OperationLog(ctx);
    audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    vouchers = VoucherRepository(ctx, ops: ops, audit: audit);
    types = VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final PartyRepository parties =
        PartyRepository(ctx, ops: ops, audit: audit);
    final ItemRepository items = ItemRepository(ctx, ops: ops, audit: audit);
    final GodownRepository godowns =
        GodownRepository(ctx, ops: ops, audit: audit);
    engine = VoucherEngine(
      ctx,
      ops: ops,
      audit: audit,
      vouchers: vouchers,
      types: types,
      allocationRepo: BillAllocationRepository(ctx, ops: ops, audit: audit),
    );
    seeder = VoucherSeeder(ctx,
        ops: ops, audit: audit, vouchers: vouchers, types: types);
    expect(
      companies
          .create(
            id: companyId,
            name: 'GST Co',
            stateCode: '24',
            deviceId: 'host-test',
            opId: 'op-cg',
            eventId: 'ev-cg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-g'),
            companyId: companyId,
            name: 'Buyer',
            role: 'customer',
            gstin: '24ABCDE1234F1Z5',
            registrationType: 'registered',
            deviceId: 'host-test',
            opId: 'op-pg',
            eventId: 'ev-pg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      parties
          .create(
            id: EntityId('p-s'),
            companyId: companyId,
            name: 'Supplier',
            role: 'supplier',
            gstin: '27ABCDE1234F1Z5',
            registrationType: 'registered',
            deviceId: 'host-test',
            opId: 'op-ps',
            eventId: 'ev-ps',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      items
          .create(
            id: EntityId('i-g'),
            companyId: companyId,
            name: 'Widget',
            deviceId: 'host-test',
            opId: 'op-ig',
            eventId: 'ev-ig',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      godowns
          .create(
            id: EntityId('g-g'),
            companyId: companyId,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-gg',
            eventId: 'ev-gg',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    seeder.ensurePostingLedgers(companyId);
    final LedgerRepository ledgers =
        LedgerRepository(ctx, ops: ops, audit: audit);
    taxLedgers.forEach((String name, String id) {
      expect(
        ledgers
            .create(
              id: EntityId(id),
              companyId: companyId,
              groupId: EntityId('g-post'),
              name: name,
              deviceId: 'host-test',
              opId: 'op-$id',
              eventId: 'ev-$id',
              actor: 'tester',
            )
            .isOk,
        isTrue,
        reason: name,
      );
    });
    seeder.linkPartyLedgers(
        companyId, <EntityId>[EntityId('p-g'), EntityId('p-s')]);
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void createTaxInvoice(
    String vid,
    String type, {
    String party = 'p-g',
    String? billState,
    String? shipState,
    int? thirdPartyDirection,
    String? supplyCategory,
  }) {
    final Result<Voucher> r = vouchers.create(
      id: EntityId(vid),
      companyId: companyId,
      type: type,
      series: 'S',
      no: vid,
      date: NiavDate('2026-04-01'),
      billState: billState,
      shipState: shipState,
      thirdPartyDirection: thirdPartyDirection,
      supplyCategory: supplyCategory,
      deviceId: 'host-test',
      opId: 'op-$vid',
      eventId: 'ev-$vid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  void addTaxLine(
    String vid,
    String lid,
    int qtyQ4,
    int ratePaise,
    int? rateBps, {
    int lineNo = 1,
    String party = 'p-g',
  }) {
    final Result<VoucherLine> r = vouchers.addLine(
      lineId: EntityId(lid),
      voucherId: EntityId(vid),
      companyId: companyId,
      lineNo: lineNo,
      itemId: EntityId('i-g'),
      godownId: EntityId('g-g'),
      partyId: EntityId(party),
      qtyQ4: qtyQ4,
      ratePaise: ratePaise,
      rateBps: rateBps,
      deviceId: 'host-test',
      opId: 'op-$lid',
      eventId: 'ev-$lid',
      actor: 'tester',
    );
    expect(r.isOk, isTrue);
  }

  Result<PostingResult> post(String vid) {
    return engine.postWithStock(
      id: EntityId(vid),
      companyId: companyId,
      policy: StockPolicy.allow,
      deviceId: 'host-test',
      opId: 'op-post-$vid',
      eventId: 'ev-post-$vid',
      actor: 'tester',
    );
  }

  Map<String, (String, int)> armsOf(String vid) {
    final VoucherWithLines? got = vouchers.get(companyId, EntityId(vid));
    expect(got, isNotNull);
    final Map<String, (String, int)> out = <String, (String, int)>{};
    for (final VoucherLine l in got!.lines) {
      if (l.drCr == null || l.ledgerId == null) continue;
      final List<Map<String, Object?>> ledgers = db.queryArgs(
        'SELECT name FROM ledger WHERE ledger_id = ?',
        <Object?>[l.ledgerId!.value],
      );
      out[ledgers.single['name'] as String] = (l.drCr!, l.amountPaise);
    }
    return out;
  }

  Map<String, int> lineTax(String lid) {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT cgst_paise, sgst_paise, igst_paise FROM voucher_line '
      'WHERE voucher_line_id = ?',
      <Object?>[lid],
    );
    final Map<String, Object?> r = rows.single;
    return <String, int>{
      'cgst': r['cgst_paise'] as int,
      'sgst': r['sgst_paise'] as int,
      'igst': r['igst_paise'] as int,
    };
  }

  Map<String, String?> voucherTax(String vid) {
    final List<Map<String, Object?>> rows = db.queryArgs(
      'SELECT pos_state, tax_type FROM voucher WHERE voucher_id = ?',
      <Object?>[vid],
    );
    return <String, String?>{
      'pos': rows.single['pos_state'] as String?,
      'type': rows.single['tax_type'] as String?,
    };
  }

  group('intra-state sale posts balanced Output CGST/SGST arms', () {
    test('Dr Party / Cr Sales / Cr taxes, Dr = Cr, pos recorded', () {
      createTaxInvoice('v-s', 'Sales Invoice');
      addTaxLine('v-s', 'v-s-l1', 10000, 10000, 1800);
      expect(post('v-s').isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-s');
      expect(arms['Party Ledger'], ('Dr', 11800));
      expect(arms['Sales'], ('Cr', 10000));
      expect(arms['Output CGST'], ('Cr', 900));
      expect(arms['Output SGST'], ('Cr', 900));
      expect(arms.containsKey('Round Off'), isFalse);
      expect(lineTax('v-s-l1'), {'cgst': 900, 'sgst': 900, 'igst': 0});
      expect(voucherTax('v-s'), {'pos': '24', 'type': 'intra'});
    });

    test('odd-paise bases use separate halves, never a split total', () {
      createTaxInvoice('v-o', 'Sales Invoice');
      addTaxLine('v-o', 'v-o-l1', 10000, 10006, 1800);
      expect(post('v-o').isOk, isTrue);
      // 10006p @ 18%: separate halves 901/901 (a total-first split would
      // give 901/900 — rejected by the CA reply).
      expect(lineTax('v-o-l1'), {'cgst': 901, 'sgst': 901, 'igst': 0});
      final Map<String, (String, int)> arms = armsOf('v-o');
      expect(arms['Output CGST'], ('Cr', 901));
      expect(arms['Output SGST'], ('Cr', 901));
    });

    test('round-off runs once on net + tax with Dr = Cr', () {
      createTaxInvoice('v-r', 'Sales Invoice');
      addTaxLine('v-r', 'v-r-l1', 10000, 10001, 1800);
      expect(post('v-r').isOk, isTrue);
      // net 10001 + tax 1800 = 11801 -> ro -1 (Dr Round Off 1).
      final Map<String, (String, int)> arms = armsOf('v-r');
      expect(arms['Party Ledger'], ('Dr', 11800));
      expect(arms['Sales'], ('Cr', 10001));
      expect(arms['Round Off'], ('Dr', 1));
      int dr = 0, cr = 0;
      for (final MapEntry<String, (String, int)> e in arms.entries) {
        if (e.value.$1 == 'Dr') {
          dr += e.value.$2;
        } else {
          cr += e.value.$2;
        }
      }
      expect(dr, cr);
    });
  });

  group('inter-state purchase posts Dr Input IGST', () {
    test('Cr Party / Dr Purchases / Dr IGST, pos recorded', () {
      createTaxInvoice('v-p', 'Purchase Invoice', party: 'p-s');
      addTaxLine('v-p', 'v-p-l1', 10000, 10000, 1800, party: 'p-s');
      expect(post('v-p').isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-p');
      expect(arms['Party Ledger'], ('Cr', 11800));
      expect(arms['Purchases'], ('Dr', 10000));
      expect(arms['Input IGST'], ('Dr', 1800));
      expect(arms.containsKey('Input CGST'), isFalse);
      expect(voucherTax('v-p'), {'pos': '27', 'type': 'inter'});
    });
  });

  group('multi-rate invoices aggregate per line', () {
    test('18% + 5% lines sum independently', () {
      createTaxInvoice('v-m', 'Sales Invoice');
      addTaxLine('v-m', 'v-m-l1', 10000, 10000, 1800, lineNo: 1);
      addTaxLine('v-m', 'v-m-l2', 10000, 999, 500, lineNo: 2);
      expect(post('v-m').isOk, isTrue);
      // 999p @ 5%: (999x500+10000)/20000 = 25 each.
      expect(lineTax('v-m-l2'), {'cgst': 25, 'sgst': 25, 'igst': 0});
      final Map<String, (String, int)> arms = armsOf('v-m');
      expect(arms['Output CGST'], ('Cr', 925));
      expect(arms['Output SGST'], ('Cr', 925));
      expect(arms['Sales'], ('Cr', 10999));
    });
  });

  group('ship-to vs bill-to (CA Q2)', () {
    test('third-party direction uses the bill-to state', () {
      createTaxInvoice('v-t', 'Sales Invoice',
          billState: '07', shipState: '09', thirdPartyDirection: 1);
      addTaxLine('v-t', 'v-t-l1', 10000, 10000, 1800);
      expect(post('v-t').isOk, isTrue);
      expect(voucherTax('v-t'), {'pos': '07', 'type': 'inter'});
      expect(armsOf('v-t')['Output IGST'], ('Cr', 1800));
    });

    test('without direction, the ship-to state decides', () {
      createTaxInvoice('v-d', 'Sales Invoice',
          billState: '24', shipState: '09');
      addTaxLine('v-d', 'v-d-l1', 10000, 10000, 1800);
      expect(post('v-d').isOk, isTrue);
      expect(voucherTax('v-d'), {'pos': '09', 'type': 'inter'});
    });
  });

  group('blocks refuse loudly and write nothing taxable', () {
    test('registered buyer with bad GSTIN blocks', () {
      createTaxInvoice('v-b1', 'Sales Invoice');
      addTaxLine('v-b1', 'v-b1-l1', 10000, 10000, 1800);
      db.executeArgs(
        'UPDATE party SET gstin = ? WHERE party_id = ?',
        <Object?>['BOGUS', 'p-g'],
      );
      final Result<PostingResult> r = post('v-b1');
      expect(r.isErr, isTrue);
      expect(voucherTax('v-b1'), {'pos': null, 'type': null});
    });

    test('reverse charge, export, services block', () {
      for (final String cat in <String>[
        'reverse_charge',
        'export_sez',
        'services',
      ]) {
        createTaxInvoice('v-x-$cat', 'Sales Invoice', supplyCategory: cat);
        addTaxLine('v-x-$cat', 'v-x-$cat-l1', 10000, 10000, 1800);
        expect(post('v-x-$cat').isErr, isTrue, reason: cat);
      }
    });

    test('missing tax ledger names the role and refuses', () {
      db.executeArgs('DELETE FROM ledger WHERE ledger_id = ?',
          <Object?>['l-o-cgst']);
      createTaxInvoice('v-m', 'Sales Invoice');
      addTaxLine('v-m', 'v-m-l1', 10000, 10000, 1800);
      final Result<PostingResult> r = post('v-m');
      expect(r.isErr, isTrue);
      expect((r as Err<PostingResult>).error.message, contains('Output CGST'));
    });

    test('exempt voucher with a rated line blocks; tax-free posts clean', () {
      createTaxInvoice('v-e1', 'Sales Invoice', supplyCategory: 'exempt');
      addTaxLine('v-e1', 'v-e1-l1', 10000, 10000, 1800);
      expect(post('v-e1').isErr, isTrue);
      createTaxInvoice('v-e2', 'Sales Invoice', supplyCategory: 'exempt');
      addTaxLine('v-e2', 'v-e2-l1', 10000, 10000, null);
      expect(post('v-e2').isOk, isTrue);
      expect(armsOf('v-e2').containsKey('Output CGST'), isFalse);
    });
  });

  group('cancel and returns mirror tax', () {
    test('cancel writes mirror arms for every tax line', () {
      createTaxInvoice('v-c', 'Sales Invoice');
      addTaxLine('v-c', 'v-c-l1', 10000, 10000, 1800);
      expect(post('v-c').isOk, isTrue);
      final Result<Voucher> cancelled = engine.cancelPosted(
        id: EntityId('v-c'),
        companyId: companyId,
        reason: 'test cancel',
        deviceId: 'host-test',
        opId: 'op-cancel-v-c',
        eventId: 'ev-cancel-v-c',
        actor: 'tester',
      );
      expect(cancelled.isOk, isTrue);
      // Mirror arms share the ledger with opposite Dr/Cr; count the Dr
      // Output rows directly (the per-ledger map keeps only the last row).
      final List<Map<String, Object?>> mirrors = db.queryArgs(
        'SELECT vl.dr_cr AS d, l.name AS n, vl.amount_paise AS a '
        'FROM voucher_line vl JOIN ledger l ON l.ledger_id = vl.ledger_id '
        'WHERE vl.company_id = ? AND vl.voucher_id = ? AND vl.dr_cr = ? '
        'AND l.name LIKE ? ORDER BY vl.line_no',
        <Object?>[companyId.value, 'v-c', 'Dr', 'Output%'],
      );
      expect(
        mirrors.map((Map<String, Object?> r) => '${r['n']}:${r['a']}').toList(),
        <String>['Output CGST:900', 'Output SGST:900'],
      );
    });

    test('sales return reverses the output sides', () {
      createTaxInvoice('v-r', 'Sales Return / Credit Note with items');
      addTaxLine('v-r', 'v-r-l1', 10000, 10000, 1800);
      expect(post('v-r').isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-r');
      expect(arms['Output CGST'], ('Dr', 900));
      expect(arms['Output SGST'], ('Dr', 900));
    });

    test('purchase return reverses the input sides', () {
      createTaxInvoice('v-pr', 'Purchase Return / Debit Note with items',
          party: 'p-s');
      addTaxLine('v-pr', 'v-pr-l1', 10000, 10000, 1800, party: 'p-s');
      expect(post('v-pr').isOk, isTrue);
      final Map<String, (String, int)> arms = armsOf('v-pr');
      expect(arms['Input IGST'], ('Cr', 1800));
    });
  });

  group('locked periods refuse tax postings too', () {
    test('post into a locked period fails with the lock message', () {
      final PeriodLockRepository locks =
          PeriodLockRepository(ctx, ops: ops, audit: audit);
      expect(
        locks
            .create(
              id: EntityId('lock-g'),
              companyId: companyId,
              scope: 'company',
              dateFrom: '2026-01-01',
              dateTo: '2026-12-31',
              lockedBy: 'owner',
              deviceId: 'host-test',
              opId: 'op-lock-g',
              eventId: 'ev-lock-g',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      createTaxInvoice('v-l', 'Sales Invoice');
      addTaxLine('v-l', 'v-l-l1', 10000, 10000, 1800);
      final Result<PostingResult> r = post('v-l');
      expect(r.isErr, isTrue);
      expect((r as Err<PostingResult>).error.message, contains('locked period'));
    });
  });
}
