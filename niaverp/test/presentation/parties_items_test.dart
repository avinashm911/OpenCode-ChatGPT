// Phase 02 widget tests: Parties & Items over real repositories.
// Real Party/Item/Alias repositories + MasterSearch over a real migrated
// database — no fakes. Proves: add party → listed; search filters; edit
// persists; add item with alias → alias search finds it; validation blocks
// empty names. Traceability: REG M03.3/M03.8, M12.3; OD-UI-001.

import 'package:flutter/material.dart';
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
import 'package:niaverp/presentation/parties_items/parties_items_screen.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late PartyRepository parties;
  late ItemRepository items;
  late AliasRepository aliases;
  late MasterSearch search;
  late CounterIdMint mint;
  final CompanyId companyId = CompanyId('c-w');

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    parties = PartyRepository(ctx, ops: ops, audit: audit);
    items = ItemRepository(ctx, ops: ops, audit: audit);
    aliases = AliasRepository(ctx, ops: ops, audit: audit);
    search = MasterSearch(db);
    mint = CounterIdMint();
    expect(
      companies
          .create(
            id: companyId,
            name: 'Widget Masters Co',
            deviceId: 'host-test',
            opId: 'op-cw',
            eventId: 'ev-cw',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Widget buildScreen() {
    return MaterialApp(
      home: PartiesItemsScreen(
        companyId: companyId,
        parties: parties,
        items: items,
        aliases: aliases,
        search: search,
        write: WriteContext(
          deviceId: 'host-test',
          actor: 'tester',
          idMint: mint.call,
        ),
      ),
    );
  }

  Future<void> addParty(
    WidgetTester t, {
    required String name,
    String alias = '',
  }) async {
    await t.tap(find.byKey(const ValueKey<String>('party-add-button')));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey<String>('party-name-field')),
      name,
    );
    if (alias.isNotEmpty) {
      await t.enterText(
        find.byKey(const ValueKey<String>('party-alias-field')),
        alias,
      );
    }
    await t.tap(find.byKey(const ValueKey<String>('party-save-button')));
    await t.pumpAndSettle();
  }

  group('parties tab', () {
    testWidgets('add party appears in the list', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      expect(find.text('No parties yet — add the first one.'), findsOneWidget);
      await addParty(t, name: 'Gupta Store');
      expect(find.text('Gupta Store'), findsWidgets);
    });

    testWidgets('search filters to matches', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await addParty(t, name: 'Gupta Store');
      await addParty(t, name: 'Mehta Traders');
      await t.enterText(
        find.byKey(const ValueKey<String>('party-search-field')),
        'gup',
      );
      await t.pumpAndSettle();
      expect(find.text('Gupta Store'), findsWidgets);
      expect(find.text('Mehta Traders'), findsNothing);
    });

    testWidgets('tap opens edit and rename persists', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await addParty(t, name: 'Old Name');
      await t.tap(find.text('Old Name').first);
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey<String>('party-name-field')),
        'New Name',
      );
      await t.tap(find.byKey(const ValueKey<String>('party-save-button')));
      await t.pumpAndSettle();
      expect(find.text('New Name'), findsWidgets);
      expect(find.text('Old Name'), findsNothing);
    });

    testWidgets('empty name is rejected in the form', (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('party-add-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey<String>('party-save-button')));
      await t.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);
    });
  });

  group('items tab', () {
    Future<void> goToItems(WidgetTester t) async {
      await t.tap(find.text('Items'));
      await t.pumpAndSettle();
    }

    Future<void> addItem(
      WidgetTester t, {
      required String name,
      String alias = '',
    }) async {
      await t.tap(find.byKey(const ValueKey<String>('item-add-button')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey<String>('item-name-field')),
        name,
      );
      if (alias.isNotEmpty) {
        await t.enterText(
          find.byKey(const ValueKey<String>('item-alias-field')),
          alias,
        );
      }
      await t.tap(find.byKey(const ValueKey<String>('item-save-button')));
      await t.pumpAndSettle();
    }

    testWidgets('add item with alias is found by alias search',
        (WidgetTester t) async {
      await t.pumpWidget(buildScreen());
      await t.pumpAndSettle();
      await goToItems(t);
      await addItem(t, name: 'Copper Wire', alias: 'તાંબાનો તાર');
      expect(find.text('Copper Wire'), findsWidgets);
      await t.enterText(
        find.byKey(const ValueKey<String>('item-search-field')),
        'તાંબા',
      );
      await t.pumpAndSettle();
      expect(find.text('Copper Wire'), findsWidgets);
    });
  });
}
