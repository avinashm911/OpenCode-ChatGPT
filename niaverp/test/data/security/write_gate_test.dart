// B1 write-gate tests: table-driven over EVERY public write command.
// Refused with code 'entitlement' when expired/denied (with no residue),
// allowed in trial/grace; export/backup stay available when expired; the
// choke holds on a real encrypted file across close/reopen (production
// wiring: CipherDatabaseOpener → CompositionRoot.backend).
// Traceability: SEC §3.3/§3.5; D-04; M20.1/M20.2/M20.6; G0-SCH-006.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/db/cipher_opener.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/data/security/entitlements.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';
import 'package:niaverp/data/security/trial_service.dart';
import 'package:niaverp/data/security/trial_store.dart';

import '../../helpers/seeded_post.dart';
import '../../helpers/test_database.dart';

int utcMs(int y, int m, int d) =>
    DateTime.utc(y, m, d).millisecondsSinceEpoch;

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niav_gate_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  const String dev = 'test-device-1';
  const String cid = 'c-g';
  final CompanyId company = CompanyId(cid);

  /// Fresh backend with the full write fixture seeded in trial state.
  /// Returns the bundle; the caller mutates the anchor to reach a state.
  BackendBundle seedGate({required int nowMs}) {
    final NiavDatabase db = openTestDatabase();
    addTearDown(db.close);
    final TestClock clock = TestClock(nowMs);
    final TrialFileStore store = TrialFileStore(tmp.path);
    store.ensureInstallMs(nowMs);
    final BackendBundle b = CompositionRoot.backend(
      engine: db,
      sqlByVersion: loadMigrationSql(),
      clock: clock,
      deviceId: dev,
      trialFiles: store,
    );
    expect(
      b.companies
          .create(
            id: company,
            name: 'Gate Co',
            deviceId: 'host-test',
            opId: 'op-c-g',
            eventId: 'ev-c-g',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Posting role ledgers for the stock fixtures are seeded after the
    // party exists (the seeder links p-1 to the party-control ledger).
    // Ungated helper ctx: seeding happens in trial state either way.
    final RepositoryContext seedCtx = testContext(db);
    // Masters.
    expect(
      b.accountGroups
          .create(
            id: EntityId('g-root'),
            companyId: company,
            name: 'Root',
            deviceId: 'host-test',
            opId: 'op-g-root',
            eventId: 'ev-g-root',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.ledgers
          .create(
            id: EntityId('l-cash'),
            companyId: company,
            groupId: EntityId('g-root'),
            name: 'Cash',
            openingSide: 'Dr',
            openingPaise: 5000,
            deviceId: 'host-test',
            opId: 'op-l-cash',
            eventId: 'ev-l-cash',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.banks
          .create(
            id: EntityId('b-1'),
            companyId: company,
            ledgerId: EntityId('l-cash'),
            accountNo: '50200012345678',
            ifsc: 'HDFC0001234',
            upiId: 'gate@hdfc',
            deviceId: 'host-test',
            opId: 'op-b-1',
            eventId: 'ev-b-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // One bank account per ledger (UNIQUE company+ledger): the table case
    // gets its own ledger.
    expect(
      b.ledgers
          .create(
            id: EntityId('l-bank2'),
            companyId: company,
            groupId: EntityId('g-root'),
            name: 'Bank2 Ledger',
            openingSide: 'Dr',
            openingPaise: 100,
            deviceId: 'host-test',
            opId: 'op-l-bank2',
            eventId: 'ev-l-bank2',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.parties
          .create(
            id: EntityId('p-1'),
            companyId: company,
            name: 'Gate Traders',
            role: 'customer',
            deviceId: 'host-test',
            opId: 'op-p-1',
            eventId: 'ev-p-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    VoucherSeeder(seedCtx, ops: b.ops, audit: b.audit)
      ..ensurePostingLedgers(company)
      ..linkPartyLedgers(company, <EntityId>[EntityId('p-1')]);
    expect(
      b.units
          .create(
            id: EntityId('u-nos'),
            companyId: company,
            name: 'Nos',
            deviceId: 'host-test',
            opId: 'op-u-nos',
            eventId: 'ev-u-nos',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.items
          .create(
            id: EntityId('i-1'),
            companyId: company,
            name: 'Bolt',
            deviceId: 'host-test',
            opId: 'op-i-1',
            eventId: 'ev-i-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Dedicated stock item without GST metadata: the table's updateMaster
    // case arms i-1 with a tax rate, which would route later posts through
    // GST validation. v-ps must stay a plain stock post.
    expect(
      b.items
          .create(
            id: EntityId('i-stock'),
            companyId: company,
            name: 'Stock Bolt',
            deviceId: 'host-test',
            opId: 'op-i-stock',
            eventId: 'ev-i-stock',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.groups
          .create(
            id: EntityId('ig-root'),
            companyId: company,
            name: 'Items Root',
            deviceId: 'host-test',
            opId: 'op-ig-root',
            eventId: 'ev-ig-root',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.groups
          .create(
            id: EntityId('g-child'),
            companyId: company,
            parentId: EntityId('ig-root'),
            name: 'Fasteners',
            deviceId: 'host-test',
            opId: 'op-g-child',
            eventId: 'ev-g-child',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.types
          .create(
            id: EntityId('t-inv'),
            companyId: company,
            baseType: 'sales-invoice',
            name: 'Sales Invoice',
            deviceId: 'host-test',
            opId: 'op-t-inv',
            eventId: 'ev-t-inv',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.types
          .createSeries(
            seriesId: EntityId('s-a'),
            companyId: company,
            typeId: EntityId('t-inv'),
            name: 'INV-A',
            prefix: 'INV-A/',
            startNo: 1,
            width: 4,
            deviceId: 'host-test',
            opId: 'op-s-a',
            eventId: 'ev-s-a',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.godowns
          .create(
            id: EntityId('g-1'),
            companyId: company,
            name: 'Main',
            deviceId: 'host-test',
            opId: 'op-g-1',
            eventId: 'ev-g-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.aliases
          .add(
            id: EntityId('al-1'),
            companyId: company,
            entity: 'party',
            entityId: EntityId('p-1'),
            alias: 'gate-alias',
            deviceId: 'host-test',
            opId: 'op-al-1',
            eventId: 'ev-al-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.fyYears
          .create(
            id: EntityId('fy-1'),
            companyId: company,
            startDate: NiavDate('2026-04-01'),
            endDate: NiavDate('2027-03-31'),
            status: 'open',
            deviceId: 'host-test',
            opId: 'op-fy-1',
            eventId: 'ev-fy-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Locked month outside the posting fixtures (April) so seed posts
    // succeed; the unlock case still exercises a locked lock.
    expect(
      b.periodLocks
          .create(
            id: EntityId('lock-1'),
            companyId: company,
            scope: 'company',
            dateFrom: '2026-06-01',
            dateTo: '2026-06-30',
            lockedBy: 'owner',
            deviceId: 'host-test',
            opId: 'op-lock-1',
            eventId: 'ev-lock-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.layoutProfiles
          .save(
            id: EntityId('p-layout'),
            companyId: company,
            profileKey: 'home-tiles',
            version: 1,
            layoutJson: '{"a":1}',
            deviceId: 'host-test',
            opId: 'op-p-layout',
            eventId: 'ev-p-layout',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Bill pair + allocation (a-1 stays allocated for the reverse case).
    for (final String v in <String>['v-bill', 'v-rec']) {
      expect(
        b.vouchers
            .create(
              id: EntityId(v),
              companyId: company,
              type: v == 'v-bill' ? 'sales-invoice' : 'receipt',
              series: v == 'v-bill' ? 'SI' : 'RC',
              no: v,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-$v',
              eventId: 'ev-$v',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        b.vouchers
            .addLine(
              lineId: EntityId('$v-l1'),
              voucherId: EntityId(v),
              companyId: company,
              lineNo: 1,
              qtyQ4: 10000,
              ratePaise: 5000,
              deviceId: 'host-test',
              opId: 'op-$v-l1',
              eventId: 'ev-$v-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      b.allocations
          .allocate(
            id: EntityId('a-1'),
            companyId: company,
            sourceLineId: EntityId('v-bill-l1'),
            settlementLineId: EntityId('v-rec-l1'),
            amountPaise: 2000,
            date: NiavDate('2026-04-02'),
            deviceId: 'host-test',
            opId: 'op-a-1',
            eventId: 'ev-a-1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Second bill pair for the allocate case.
    for (final String v in <String>['v-bill2', 'v-rec2']) {
      expect(
        b.vouchers
            .create(
              id: EntityId(v),
              companyId: company,
              type: v == 'v-bill2' ? 'sales-invoice' : 'receipt',
              series: v == 'v-bill2' ? 'SI' : 'RC',
              no: v,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-$v',
              eventId: 'ev-$v',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        b.vouchers
            .addLine(
              lineId: EntityId('$v-l1'),
              voucherId: EntityId(v),
              companyId: company,
              lineNo: 1,
              qtyQ4: 10000,
              ratePaise: 5000,
              deviceId: 'host-test',
              opId: 'op-$v-l1',
              eventId: 'ev-$v-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    // Draft reserved for the table's addLine case (in refused states the
    // create itself would be gated, so each dependent write gets a
    // pre-existing parent from the trial-state fixture).
    expect(
      b.vouchers
          .create(
            id: EntityId('v-t2'),
            companyId: company,
            type: 'sales-invoice',
            series: 'SI',
            no: 'v-t2',
            date: NiavDate('2026-04-01'),
            deviceId: 'host-test',
            opId: 'op-v-t2',
            eventId: 'ev-v-t2',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Held bill for the status case.
    expect(
      b.vouchers
          .create(
            id: EntityId('v-held'),
            companyId: company,
            type: 'sales-invoice',
            series: 'QB',
            no: 'v-held',
            date: NiavDate('2026-04-01'),
            status: 'held',
            deviceId: 'host-test',
            opId: 'op-v-held',
            eventId: 'ev-v-held',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Quotation pair + lines for document flow.
    for (final String v in <String>['v-q', 'v-o']) {
      expect(
        b.vouchers
            .create(
              id: EntityId(v),
              companyId: company,
              type: 'sales-order',
              series: 'SO',
              no: v,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-$v',
              eventId: 'ev-$v',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        b.vouchers
            .addLine(
              lineId: EntityId('$v-l1'),
              voucherId: EntityId(v),
              companyId: company,
              lineNo: 1,
              qtyQ4: 50000,
              ratePaise: 1000,
              deviceId: 'host-test',
              opId: 'op-$v-l1',
              eventId: 'ev-$v-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      b.links
          .create(
            id: EntityId('l-a'),
            companyId: company,
            sourceVoucherId: EntityId('v-q'),
            targetVoucherId: EntityId('v-o'),
            qtyQ4: 10000,
            status: 'active',
            deviceId: 'host-test',
            opId: 'op-l-a',
            eventId: 'ev-l-a',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Payment draft for postDraft (proven ledger-line pattern).
    expect(
      b.vouchers
          .create(
            id: EntityId('v-pd'),
            companyId: company,
            type: 'Payment',
            series: 'P',
            no: 'v-pd',
            date: NiavDate('2026-04-01'),
            deviceId: 'host-test',
            opId: 'op-v-pd',
            eventId: 'ev-v-pd',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    expect(
      b.vouchers
          .addLine(
            lineId: EntityId('v-pd-l1'),
            voucherId: EntityId('v-pd'),
            companyId: company,
            lineNo: 1,
            ledgerId: EntityId('l-cash'),
            qtyQ4: 10000,
            ratePaise: 5000,
            deviceId: 'host-test',
            opId: 'op-v-pd-l1',
            eventId: 'ev-v-pd-l1',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    // Purchase drafts for postWithStock / cancelPosted (proven stock lines).
    // Both use the GST-free i-stock item (see above).
    for (final String v in <String>['v-ps', 'v-pc']) {
      expect(
        b.vouchers
            .create(
              id: EntityId(v),
              companyId: company,
              type: 'Purchase Invoice',
              series: 'PI',
              no: v,
              date: NiavDate('2026-04-01'),
              deviceId: 'host-test',
              opId: 'op-$v',
              eventId: 'ev-$v',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        b.vouchers
            .addLine(
              lineId: EntityId('$v-l1'),
              voucherId: EntityId(v),
              companyId: company,
              lineNo: 1,
              itemId: EntityId('i-stock'),
              godownId: EntityId('g-1'),
              partyId: EntityId('p-1'),
              qtyQ4: 100000,
              ratePaise: 1000,
              deviceId: 'host-test',
              opId: 'op-$v-l1',
              eventId: 'ev-$v-l1',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
    expect(
      b.engine
          .postWithStock(
            id: EntityId('v-pc'),
            companyId: company,
            policy: StockPolicy.allow,
            deviceId: 'host-test',
            opId: 'op-post-v-pc',
            eventId: 'ev-post-v-pc',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
    return b;
  }

  /// Every public write command, each returning the refusal code or null.
  /// Reads, audit/operation appends, clock observations and anchor
  /// bootstrapping are intentionally NOT in this table (never gated).
  List<MapEntry<String, String? Function(BackendBundle)>> writeTable() {
    String? code(Result<dynamic> r) =>
        r.isErr ? (r as Err<dynamic>).error.code : null;
    return <MapEntry<String, String? Function(BackendBundle)>>[
      MapEntry('companies.create', (BackendBundle b) => code(b.companies.create(
            id: CompanyId('c-g2'),
            name: 'Second Co',
            deviceId: 'host-test',
            opId: 'op-c-g2',
            eventId: 'ev-c-g2',
            actor: 'tester',
          ))),
      MapEntry('fyYears.create', (BackendBundle b) => code(b.fyYears.create(
            id: EntityId('fy-2'),
            companyId: company,
            startDate: NiavDate('2027-04-01'),
            endDate: NiavDate('2028-03-31'),
            status: 'open',
            deviceId: 'host-test',
            opId: 'op-fy-2',
            eventId: 'ev-fy-2',
            actor: 'tester',
          ))),
      MapEntry('accountGroups.create', (BackendBundle b) => code(b.accountGroups.create(
            id: EntityId('g-t2'),
            companyId: company,
            name: 'T2',
            deviceId: 'host-test',
            opId: 'op-g-t2',
            eventId: 'ev-g-t2',
            actor: 'tester',
          ))),
      MapEntry('ledgers.create', (BackendBundle b) => code(b.ledgers.create(
            id: EntityId('l-t2'),
            companyId: company,
            groupId: EntityId('g-root'),
            name: 'T2 Ledger',
            openingSide: 'Dr',
            openingPaise: 100,
            deviceId: 'host-test',
            opId: 'op-l-t2',
            eventId: 'ev-l-t2',
            actor: 'tester',
          ))),
      MapEntry('banks.create', (BackendBundle b) => code(b.banks.create(
            id: EntityId('b-2'),
            companyId: company,
            ledgerId: EntityId('l-bank2'),
            accountNo: '50200099999999',
            ifsc: 'HDFC0009999',
            upiId: 'gate2@hdfc',
            deviceId: 'host-test',
            opId: 'op-b-2',
            eventId: 'ev-b-2',
            actor: 'tester',
          ))),
      MapEntry('allocations.allocate', (BackendBundle b) => code(b.allocations.allocate(
            id: EntityId('a-2'),
            companyId: company,
            sourceLineId: EntityId('v-bill2-l1'),
            settlementLineId: EntityId('v-rec2-l1'),
            amountPaise: 1000,
            date: NiavDate('2026-04-02'),
            deviceId: 'host-test',
            opId: 'op-a-2',
            eventId: 'ev-a-2',
            actor: 'tester',
          ))),
      MapEntry('allocations.reverse', (BackendBundle b) => code(b.allocations.reverse(
            id: EntityId('a-1'),
            companyId: company,
            reason: 'gate probe',
            deviceId: 'host-test',
            opId: 'op-a-rev',
            eventId: 'ev-a-rev',
            actor: 'tester',
          ))),
      MapEntry('periodLocks.create', (BackendBundle b) => code(b.periodLocks.create(
            id: EntityId('lock-2'),
            companyId: company,
            scope: 'company',
            dateFrom: '2027-01-01',
            dateTo: '2027-12-31',
            lockedBy: 'owner',
            deviceId: 'host-test',
            opId: 'op-lock-2',
            eventId: 'ev-lock-2',
            actor: 'tester',
          ))),
      MapEntry('periodLocks.unlock', (BackendBundle b) => code(b.periodLocks.unlock(
            id: EntityId('lock-1'),
            companyId: company,
            reason: 'gate probe',
            deviceId: 'host-test',
            opId: 'op-un-1',
            eventId: 'ev-un-1',
            actor: 'owner',
          ))),
      MapEntry('parties.create', (BackendBundle b) => code(b.parties.create(
            id: EntityId('p-2'),
            companyId: company,
            name: 'Probe Traders',
            role: 'supplier',
            deviceId: 'host-test',
            opId: 'op-p-2',
            eventId: 'ev-p-2',
            actor: 'tester',
          ))),
      MapEntry('parties.update', (BackendBundle b) => code(b.parties.update(
            id: EntityId('p-1'),
            companyId: company,
            name: 'Gate Traders Renamed',
            role: 'customer',
            // Full-row replace: preserve the seeder's party-ledger link so
            // later posts keep their posting fixture intact.
            ledgerId: 'l-party',
            deviceId: 'host-test',
            opId: 'op-p-u',
            eventId: 'ev-p-u',
            actor: 'tester',
          ))),
      MapEntry('parties.addAddress', (BackendBundle b) => code(b.parties.addAddress(
            addressId: EntityId('a-probe'),
            companyId: company,
            partyId: EntityId('p-1'),
            address: 'Probe Street',
            deviceId: 'host-test',
            opId: 'op-a-probe',
            eventId: 'ev-a-probe',
            actor: 'tester',
          ))),
      MapEntry('items.create', (BackendBundle b) => code(b.items.create(
            id: EntityId('i-2'),
            companyId: company,
            name: 'Nut',
            deviceId: 'host-test',
            opId: 'op-i-2',
            eventId: 'ev-i-2',
            actor: 'tester',
          ))),
      MapEntry('items.rename', (BackendBundle b) => code(b.items.rename(
            companyId: company,
            id: EntityId('i-1'),
            name: 'Bolt Renamed',
            unit: 'pcs',
            deviceId: 'host-test',
            opId: 'op-i-r',
            eventId: 'ev-i-r',
            actor: 'tester',
          ))),
      MapEntry('items.updateMaster', (BackendBundle b) => code(b.items.updateMaster(
            companyId: company,
            id: EntityId('i-1'),
            code: 'B-8',
            barcode: '8900000000088',
            hsnCode: '7318',
            gstRateBps: 1200,
            deviceId: 'host-test',
            opId: 'op-i-m',
            eventId: 'ev-i-m',
            actor: 'tester',
          ))),
      MapEntry('units.create', (BackendBundle b) => code(b.units.create(
            id: EntityId('u-box'),
            companyId: company,
            name: 'Box',
            baseUnitId: EntityId('u-nos'),
            factor: 12,
            deviceId: 'host-test',
            opId: 'op-u-box',
            eventId: 'ev-u-box',
            actor: 'tester',
          ))),
      MapEntry('groups.create', (BackendBundle b) => code(b.groups.create(
            id: EntityId('g-t2'),
            companyId: company,
            parentId: EntityId('ig-root'),
            name: 'T2 Group',
            deviceId: 'host-test',
            opId: 'op-g-t2b',
            eventId: 'ev-g-t2b',
            actor: 'tester',
          ))),
      MapEntry('types.create', (BackendBundle b) => code(b.types.create(
            id: EntityId('t-t2'),
            companyId: company,
            baseType: 'purchase-invoice',
            name: 'Purchase Invoice T2',
            deviceId: 'host-test',
            opId: 'op-t-t2',
            eventId: 'ev-t-t2',
            actor: 'tester',
          ))),
      MapEntry('types.createSeries', (BackendBundle b) => code(b.types.createSeries(
            seriesId: EntityId('s-t2'),
            companyId: company,
            typeId: EntityId('t-inv'),
            name: 'INV-T2',
            prefix: 'INV-T2/',
            startNo: 1,
            width: 4,
            deviceId: 'host-test',
            opId: 'op-s-t2',
            eventId: 'ev-s-t2',
            actor: 'tester',
          ))),
      MapEntry('godowns.create', (BackendBundle b) => code(b.godowns.create(
            id: EntityId('g-t2'),
            companyId: company,
            name: 'Overflow',
            deviceId: 'host-test',
            opId: 'op-gd-t2',
            eventId: 'ev-gd-t2',
            actor: 'tester',
          ))),
      MapEntry('aliases.add', (BackendBundle b) => code(b.aliases.add(
            id: EntityId('al-2'),
            companyId: company,
            entity: 'party',
            entityId: EntityId('p-1'),
            alias: 'probe-alias',
            deviceId: 'host-test',
            opId: 'op-al-2',
            eventId: 'ev-al-2',
            actor: 'tester',
          ))),
      MapEntry('vouchers.create', (BackendBundle b) => code(b.vouchers.create(
            id: EntityId('v-t3'),
            companyId: company,
            type: 'sales-invoice',
            series: 'SI',
            no: 'v-t3',
            date: NiavDate('2026-04-01'),
            deviceId: 'host-test',
            opId: 'op-v-t3',
            eventId: 'ev-v-t3',
            actor: 'tester',
          ))),
      MapEntry('vouchers.addLine', (BackendBundle b) => code(b.vouchers.addLine(
            lineId: EntityId('v-t2-l1'),
            voucherId: EntityId('v-t2'),
            companyId: company,
            lineNo: 1,
            qtyQ4: 10000,
            ratePaise: 1000,
            deviceId: 'host-test',
            opId: 'op-v-t2-l1',
            eventId: 'ev-v-t2-l1',
            actor: 'tester',
          ))),
      MapEntry('vouchers.updateHeldStatus', (BackendBundle b) => code(b.vouchers.updateHeldStatus(
            id: EntityId('v-held'),
            companyId: company,
            status: 'resumed',
            deviceId: 'host-test',
            opId: 'op-v-held-m',
            eventId: 'ev-v-held-m',
            actor: 'tester',
          ))),
      MapEntry('layoutProfiles.save', (BackendBundle b) => code(b.layoutProfiles.save(
            id: EntityId('p-t2'),
            companyId: company,
            profileKey: 'home-tiles',
            version: 2,
            layoutJson: '{"b":2}',
            deviceId: 'host-test',
            opId: 'op-p-t2',
            eventId: 'ev-p-t2',
            actor: 'tester',
          ))),
      MapEntry('links.create', (BackendBundle b) => code(b.links.create(
            id: EntityId('l-a2'),
            companyId: company,
            sourceVoucherId: EntityId('v-q'),
            targetVoucherId: EntityId('v-o'),
            qtyQ4: 5000,
            status: 'active',
            deviceId: 'host-test',
            opId: 'op-l-a2',
            eventId: 'ev-l-a2',
            actor: 'tester',
          ))),
      MapEntry('links.reverse', (BackendBundle b) => code(b.links.reverse(
            id: EntityId('l-a'),
            companyId: company,
            reason: 'gate probe',
            deviceId: 'host-test',
            opId: 'op-l-rev',
            eventId: 'ev-l-rev',
            actor: 'tester',
          ))),
      MapEntry('engine.postDraft', (BackendBundle b) => code(b.engine.postDraft(
            id: EntityId('v-pd'),
            companyId: company,
            deviceId: 'host-test',
            opId: 'op-post-v-pd',
            eventId: 'ev-post-v-pd',
            actor: 'tester',
          ))),
      MapEntry('engine.postWithStock', (BackendBundle b) => code(b.engine.postWithStock(
            id: EntityId('v-ps'),
            companyId: company,
            policy: StockPolicy.allow,
            deviceId: 'host-test',
            opId: 'op-post-v-ps',
            eventId: 'ev-post-v-ps',
            actor: 'tester',
          ))),
      MapEntry('engine.cancelPosted', (BackendBundle b) => code(b.engine.cancelPosted(
            id: EntityId('v-pc'),
            companyId: company,
            reason: 'gate probe cancel',
            deviceId: 'host-test',
            opId: 'op-can-v-pc',
            eventId: 'ev-can-v-pc',
            actor: 'tester',
          ))),
      MapEntry('flow.convert', (BackendBundle b) => code(b.flow.convert(
            linkId: EntityId('l-flow2'),
            companyId: company,
            sourceVoucherId: EntityId('v-q'),
            sourceLineId: EntityId('v-q-l1'),
            targetVoucherId: EntityId('v-o'),
            targetLineId: EntityId('v-o-l1'),
            qtyQ4: 20000,
            deviceId: 'host-test',
            opId: 'op-l-flow2',
            eventId: 'ev-l-flow2',
            actor: 'tester',
          ))),
    ];
  }

  group('single write choke point (A5)', () {
    test('trial: every public write command succeeds', () {
      final BackendBundle b = seedGate(nowMs: utcMs(2026, 4, 1));
      for (final MapEntry<String, String? Function(BackendBundle)> e
          in writeTable()) {
        expect(e.value(b), isNull, reason: e.key);
      }
    });

    test('grace: every public write command succeeds', () {
      final int now = utcMs(2026, 4, 1);
      final BackendBundle b = seedGate(nowMs: now);
      b.database.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[now - 100 * 24 * 60 * 60 * 1000, now - 24 * 60 * 60 * 1000, cid],
      );
      for (final MapEntry<String, String? Function(BackendBundle)> e
          in writeTable()) {
        expect(e.value(b), isNull, reason: e.key);
      }
    });

    test('expired: every public write command refuses with entitlement', () {
      final int now = utcMs(2026, 4, 1);
      final BackendBundle b = seedGate(nowMs: now);
      b.database.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[
          now - 200 * 24 * 60 * 60 * 1000,
          now - 11 * 24 * 60 * 60 * 1000,
          cid
        ],
      );
      for (final MapEntry<String, String? Function(BackendBundle)> e
          in writeTable()) {
        expect(e.value(b), 'entitlement', reason: e.key);
      }
    });

    test('denied: every public write command refuses with entitlement', () {
      final int now = utcMs(2026, 4, 1);
      final BackendBundle b = seedGate(nowMs: now);
      b.database.executeArgs(
        'INSERT INTO denylist_entry '
        '(entry_id, key_hash, reason, status, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'd-gate',
          installKeyHash(dev),
          'stolen install',
          'listed',
          now,
        ],
      );
      for (final MapEntry<String, String? Function(BackendBundle)> e
          in writeTable()) {
        expect(e.value(b), 'entitlement', reason: e.key);
      }
    });

    test('refusal carries no values and leaves no residue', () {
      final int now = utcMs(2026, 4, 1);
      final BackendBundle b = seedGate(nowMs: now);
      b.database.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[
          now - 200 * 24 * 60 * 60 * 1000,
          now - 11 * 24 * 60 * 60 * 1000,
          cid
        ],
      );
      final Result<dynamic> r = b.engine.postWithStock(
        id: EntityId('v-ps'),
        companyId: company,
        policy: StockPolicy.allow,
        deviceId: 'host-test',
        opId: 'op-post-v-ps',
        eventId: 'ev-post-v-ps',
        actor: 'tester',
      );
      expect(r.isErr, isTrue);
      final AppError err = (r as Err<dynamic>).error;
      expect(err.code, 'entitlement');
      expect(err.message, isNot(contains(cid)));
      expect(err.message, isNot(contains('v-ps')));
      // The refused post changed nothing: the voucher stays a draft, the
      // seed's single voucher-level lineage row (create; lines log under
      // voucher_line) stands alone, and the stock added by the seeded
      // v-pc post is untouched.
      expect(
        b.vouchers.get(company, EntityId('v-ps'))?.voucher.status,
        'draft',
      );
      expect(
        b.ops.forEntity(cid, 'voucher', 'v-ps'),
        hasLength(1),
      );
      expect(
        b.stock
            .balances(company, itemId: EntityId('i-stock'))
            .single
            .qtyQ4,
        100000,
      );
    });

    test('expired: reads, export and backup stay available (D-04)', () {
      final int now = utcMs(2026, 4, 1);
      final BackendBundle b = seedGate(nowMs: now);
      b.database.executeArgs(
        'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
        'WHERE company_id = ?',
        <Object?>[
          now - 200 * 24 * 60 * 60 * 1000,
          now - 11 * 24 * 60 * 60 * 1000,
          cid
        ],
      );
      expect(b.entitlementState(cid), EntitlementState.expired);
      expect(b.books.dayBook(company), isNotEmpty);
      expect(b.exportBackupAllowed(cid), isTrue);
      expect(canExportBackup(EntitlementState.expired), isTrue);
      expect(canExportBackup(EntitlementState.denied), isFalse);
    });
  });

  group('choke on a real encrypted file (production wiring)', () {
    test('anchor survives close/reopen; expired refuses with entitlement', () {
      final int now = utcMs(2026, 4, 1);
      final DbKey key =
          DbKey(Uint8List.fromList(List<int>.filled(32, 7)));
      CipherDatabaseOpener opener(String name) => CipherDatabaseOpener(
            dbPath: '${tmp.path}/$name.db',
            dbKey: key,
            sqlByVersion: loadMigrationSql(),
          );
      final NiavDatabase first = opener('gate').openCompanyDatabase();
      final BackendBundle b1 = CompositionRoot.backend(
        engine: first,
        sqlByVersion: loadMigrationSql(),
        clock: TestClock(now),
        deviceId: dev,
        trialFiles: TrialFileStore(tmp.path),
      );
      expect(
        b1.companies
            .create(
              id: CompanyId('c-enc'),
              name: 'Enc Co',
              deviceId: 'host-test',
              opId: 'op-c-enc',
              eventId: 'ev-c-enc',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(b1.trial.readAnchor('c-enc')!.installedAtMs, now);
      b1.database.close();
      // Reopen the same encrypted file: the anchor persists, trial holds.
      final NiavDatabase second = opener('gate').openCompanyDatabase();
      final BackendBundle b2 = CompositionRoot.backend(
        engine: second,
        sqlByVersion: loadMigrationSql(),
        clock: TestClock(now),
        deviceId: dev,
        trialFiles: TrialFileStore(tmp.path),
      );
      try {
        expect(b2.trial.readAnchor('c-enc')!.installedAtMs, now);
        expect(b2.entitlementState('c-enc'), EntitlementState.trialActive);
        // Expire and prove the choke on the encrypted handle (both columns
        // shift: trial_ends_at > installed_at always holds).
        b2.database.executeArgs(
          'UPDATE trial_anchor SET installed_at = ?, trial_ends_at = ? '
          'WHERE company_id = ?',
          <Object?>[
            now - 200 * 24 * 60 * 60 * 1000,
            now - 11 * 24 * 60 * 60 * 1000,
            'c-enc'
          ],
        );
        final Result<dynamic> r = b2.parties.create(
          id: EntityId('p-enc'),
          companyId: CompanyId('c-enc'),
          name: 'Enc Party',
          role: 'customer',
          deviceId: 'host-test',
          opId: 'op-p-enc',
          eventId: 'ev-p-enc',
          actor: 'tester',
        );
        expect(r.isErr, isTrue);
        expect((r as Err<dynamic>).error.code, 'entitlement');
      } finally {
        b2.database.close();
      }
    });
  });
}
