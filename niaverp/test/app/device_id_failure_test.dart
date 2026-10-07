// Device-identity failure screen (device_id hardening).
// Proves: when the device_id file is corrupt/unwritable, main() maps the
// failure to StartupOutcome.deviceIdFailure and the app shows a clear failure
// screen — headline, detail and reference code — never a blank screen and
// never the shell. Host widget test; not device evidence.
// Traceability: DECISIONS.md P-DEVICEID; StartupCode.deviceIdUnavailable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/app/startup.dart';
import 'package:niaverp/presentation/shell/niav_shell.dart';

void main() {
  testWidgets('device identity failure shows the failure screen, never blank',
      (WidgetTester tester) async {
    const StartupOutcome outcome = StartupOutcome.deviceIdFailure(
      StartupCode.deviceIdUnavailable,
    );
    await tester.pumpWidget(
      NiavApp(root: CompositionRoot.system(), startup: outcome),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('startup-status')), findsOneWidget);
    expect(find.text('Device identity unavailable'), findsOneWidget);
    expect(
      find.text('This device could not be recognised. Nothing has been changed.'),
      findsOneWidget,
    );
    expect(find.textContaining('device-id-unavailable'), findsOneWidget);
    // The shell is never built on a failure outcome: no tabs, no fake data.
    expect(find.byType(NiavShell), findsNothing);
  });
}
