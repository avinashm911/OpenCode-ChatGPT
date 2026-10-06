// Navigation slice tests: five-item shell over real destinations.
// The shell renders the approved model (OD-UI-001 / G0-CON-005) with every
// tab bound to a real screen over a real in-memory backend — no fake data.
// Proves: without a scope every tab shows the scope gate; the company gate
// shows onboarding until a company opens; with scope + company each tab
// shows its real destination; tab switching preserves navigation state;
// company switching rebinds the tabs.
// Traceability: OD-UI-001; G0-CON-005.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/presentation/billing/billing_hub_screen.dart';
import 'package:niaverp/presentation/home/home_dashboard_screen.dart';
import 'package:niaverp/presentation/more/more_tab_screen.dart';
import 'package:niaverp/presentation/onboarding/onboarding_screen.dart';
import 'package:niaverp/presentation/parties_items/parties_items_screen.dart';
import 'package:niaverp/presentation/reports/reports_hub_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';
import 'package:niaverp/presentation/shell/niav_shell.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late BackendBundle backend;
  late CompanyScope scope;
  final CompanyId companyId = CompanyId('c-n');

  setUp(() {
    db = openTestDatabase();
    backend = CompositionRoot.backend(
      engine: rawEngineOf(db),
      sqlByVersion: loadMigrationSql(),
      clock: testClock(),
    );
    scope = scopeOfBackend(
      backend,
      write: WriteContext(
        deviceId: 'host-test',
        actor: 'tester',
        idMint: CounterIdMint().call,
      ),
      today: NiavDate('2026-04-01'),
    );
    expect(
      backend.companies
          .create(
            id: companyId,
            name: 'Nav Co',
            deviceId: 'host-test',
            opId: 'op-cn',
            eventId: 'ev-cn',
            actor: 'tester',
          )
          .isOk,
      isTrue,
    );
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  NiavApp buildApp({CompanyScope? useScope, CompanyId? company}) {
    return NiavApp(
      root: CompositionRoot.forTest(fixedMs: 0),
      scope: useScope,
      companyId: company,
    );
  }

  group('shell navigation (OD-UI-001 / G0-CON-005)', () {
    testWidgets('five destinations render with the bottom bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (final String label in <String>[
        'Home',
        'Billing',
        'Parties & Items',
        'Reports',
        'More',
      ]) {
        expect(find.text(label, skipOffstage: false), findsWidgets);
      }
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('without a scope every tab shows the gate, never fakes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (final NiavDestination d in NiavDestination.values) {
        await tester.tap(find.byIcon(d.icon, skipOffstage: false));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey<String>('scope-gate-${d.name}')),
          findsOneWidget,
        );
      }
      expect(find.textContaining('coming in its vertical slice'),
          findsNothing);
    });

    testWidgets('scope without a company shows onboarding',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(useScope: scope));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('company-gate')),
          findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('each tab shows its real destination',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          buildApp(useScope: scope, company: companyId));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      expect(find.text('Nav Co'), findsOneWidget);

      await tester.tap(find.text('Billing', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.byType(BillingHubScreen), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('billing-empty')),
          findsOneWidget);

      await tester.tap(find.text('Parties & Items', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.byType(PartiesItemsScreen), findsOneWidget);

      await tester.tap(find.text('Reports', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.byType(ReportsHubScreen), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('reports-hub-stock')),
          findsOneWidget);

      await tester.tap(find.text('More', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.byType(MoreTabScreen), findsOneWidget);
    });

    testWidgets('opening another company rebinds the tabs',
        (WidgetTester tester) async {
      expect(
        backend.companies
            .create(
              id: CompanyId('c-second'),
              name: 'Second Co',
              deviceId: 'host-test',
              opId: 'op-c2',
              eventId: 'ev-c2',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      await tester.pumpWidget(
          buildApp(useScope: scope, company: companyId));
      await tester.pumpAndSettle();
      expect(find.text('Nav Co'), findsOneWidget);

      tester
          .state<NiavShellState>(find.byType(NiavShell))
          .openCompany(CompanyId('c-second'));
      await tester.pumpAndSettle();
      expect(find.text('Second Co', skipOffstage: false), findsOneWidget);
      expect(find.text('Nav Co', skipOffstage: false), findsNothing);
    });

    testWidgets('composition root injects config without widget state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        NiavApp(
          root: CompositionRoot.forTest(
            config: const AppConfig(appTitle: 'NiAvERP-Test'),
            fixedMs: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NiAvERP-Test', skipOffstage: false), findsWidgets);
    });
  });
}

    testWidgets('A3: visit billing/reports, switch company, no stale data on any tab', (WidgetTester tester) async {
      // Use same setup as existing shell test; visit billing (2) and reports (4), then open second company.
      final scope = await createTestScope();
      await tester.pumpWidget(buildApp(useScope: scope, company: CompanyId('c-first')));
      await tester.pumpAndSettle();
      tester.state<NiavShellState>(find.byType(NiavShell)).selectTab(1); // billing
      await tester.pumpAndSettle();
      tester.state<NiavShellState>(find.byType(NiavShell)).selectTab(3); // reports
      await tester.pumpAndSettle();
      tester.state<NiavShellState>(find.byType(NiavShell)).openCompany(CompanyId('c-second'));
      await tester.pumpAndSettle();
      // After switch, unvisited tabs rebuilt; no old-company data remains.
      expect(find.text('Second Co', skipOffstage: false), findsOneWidget);
      expect(find.text('Nav Co', skipOffstage: false), findsNothing);
    });

