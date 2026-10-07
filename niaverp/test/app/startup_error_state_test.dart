// Startup error states (E1 A6/A10): every platform key failure code maps to
// a DISTINCT visible failure screen (headline + detail + reference code).
// Drives runStartup with a fake key channel per code, then pumps the real
// NiavApp. Host + fake-channel runs are not device evidence (G0-VER-005).
// Traceability: D1 (A6/A10); StartupCode; G0-CON-003.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/app/startup.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/data/db/key_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel(ChannelKeyProvider.kKeyChannelName);

  late Directory tmp;
  Map<String, Object?>? keyReply;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niav_errstate_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getDatabaseKey':
          return keyReply;
        case 'getFilesDirectory':
          return tmp.path;
      }
      throw MissingPluginException();
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  StartupEnvironment env(String dbName) => StartupEnvironment(
        channel: channel,
        loadString: (String assetPath) async =>
            File(assetPath).readAsString(),
        clock: TestClock(1777593600000), // 2026-05-01 UTC.
        dbPath: '${tmp.path}/$dbName',
        deviceId: 'test-device',
        actor: 'tester',
        dbFileName: dbName,
      );

  Future<Map<String, String>> headlineFor(
    WidgetTester tester,
    String failure,
  ) async {
    keyReply = <String, Object?>{
      'state': 'failed',
      'failure': failure,
    };
    final StartupOutcome outcome =
        (await tester.runAsync(() => runStartup(env('niav.db'))))!;
    expect(outcome.stage, StartupStage.keyFailure, reason: failure);
    await tester.pumpWidget(NiavApp(
      root: CompositionRoot.system(),
      startup: outcome,
    ));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('startup-status')),
      findsOneWidget,
      reason: failure,
    );
    final String headline = tester
        .widget<Text>(find.byKey(const ValueKey<String>('startup-headline')))
        .data!;
    final String code = tester
        .widget<Text>(find.byKey(const ValueKey<String>('startup-code')))
        .data!;
    return <String, String>{'headline': headline, 'code': code};
  }

  group('startup error state per platform failure code (E1 A6/A10)', () {
    testWidgets('keystoreUnavailable shows the key failure screen',
        (WidgetTester tester) async {
      final Map<String, String> seen =
          await headlineFor(tester, 'keystoreUnavailable');
      expect(seen['headline'], 'Secure key unavailable');
      expect(seen['code'], contains('key-unavailable'));
    });

    testWidgets('authFailed shows the locked screen',
        (WidgetTester tester) async {
      final Map<String, String> seen =
          await headlineFor(tester, 'authFailed');
      expect(seen['headline'], 'Device locked');
      expect(seen['code'], contains('key-locked'));
    });

    testWidgets('corruptWrapper shows the damaged-data screen',
        (WidgetTester tester) async {
      final Map<String, String> seen =
          await headlineFor(tester, 'corruptWrapper');
      expect(seen['headline'], 'Security data damaged');
      expect(seen['code'], contains('key-corrupt'));
    });

    testWidgets('wipedByUninstall shows the missing-key screen',
        (WidgetTester tester) async {
      final Map<String, String> seen =
          await headlineFor(tester, 'wipedByUninstall');
      expect(seen['headline'], 'Secure key missing');
      expect(seen['code'], contains('key-missing'));
    });

    testWidgets('existingDataLocked shows the locked-data screen',
        (WidgetTester tester) async {
      final Map<String, String> seen =
          await headlineFor(tester, 'existingDataLocked');
      expect(seen['headline'], 'Existing data is locked');
      expect(seen['code'], contains('existing-data-locked'));
    });

    testWidgets('all five headlines are mutually distinct',
        (WidgetTester tester) async {
      final Set<String> headlines = <String>{};
      for (final String failure in <String>[
        'keystoreUnavailable',
        'authFailed',
        'corruptWrapper',
        'wipedByUninstall',
        'existingDataLocked',
      ]) {
        headlines.add((await headlineFor(tester, failure))['headline']!);
      }
      expect(headlines, hasLength(5));
    });
  });
}
