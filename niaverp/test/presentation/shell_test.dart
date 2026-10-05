// Phase 00 tests: five-item shell (OD-UI-001 / G0-CON-005).
// Asserts the approved navigation model renders and switches tabs. Tab pages
// are placeholders until their vertical slices land; no business state is
// asserted here. Traceability: OD-UI-001; G0-CON-005; DECISIONS.md.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/presentation/shell/niav_shell.dart';

void main() {
  NiavApp buildApp() =>
      NiavApp(root: CompositionRoot.forTest(fixedMs: 0));

  testWidgets('shell shows all five destinations', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    for (final String label in <String>[
      'Home',
      'Billing',
      'Parties & Items',
      'Reports',
      'More',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('tapping tabs switches the visible page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    final NiavShellState state =
        tester.state<NiavShellState>(find.byType(NiavShell));
    expect(state.selectedIndex, NiavDestination.reports.index);

    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(state.selectedIndex, NiavDestination.billing.index);
  });

  testWidgets('composition root injects config without widget state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      NiavApp(
        root: CompositionRoot.forTest(
          config: const AppConfig(appTitle: 'NiAvERP-Test'),
          fixedMs: 0,
        ),
      ),
    );
    expect(find.text('NiAvERP-Test'), findsWidgets);
  });
}
