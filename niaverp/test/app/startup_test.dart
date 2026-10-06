// Production startup widget tests (D1-A4): the real startup sequence.
// Runs runStartup — migration assets → platform key → encrypted open →
// backend bundle → CompanyScope — with a fake key channel and a temp-file
// engine, then pumps the real NiavApp. Proves: tabs show real data after
// startup; a key failure shows the failure state (codes only); nothing is
// created and no plaintext path exists when the key is unusable. Host and
// fake-channel runs are not device evidence (G0-VER-005).
// Traceability: D1 (A3/A4); D-06; P-SQLIB; G0-CON-003.

import 'dart:io';



import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/app/startup.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/cipher_opener.dart';
import 'package:niaverp/data/db/key_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel(ChannelKeyProvider.kKeyChannelName);

  late Directory tmp;
  Map<String, Object?>? keyReply;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niav_startup_');
    keyReply = <String, Object?>{
      'state': 'available',
      'key': Uint8List(32),
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getDatabaseKey':
          return keyReply;
        case 'getFilesDirectory':
          return tmp.path;
        case 'getDeviceId':
          return 'test-device';
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

  group('production startup (D1-A4)', () {
    testWidgets('ready path shows real tab data from the encrypted database',
        (WidgetTester tester) async {
      final StartupOutcome outcome =
          (await tester.runAsync(() => runStartup(env('niav.db'))))!;
      expect(outcome.stage, StartupStage.ready);
      expect(outcome.scope, isNotNull);
      expect(outcome.backend, isNotNull);
      try {
        expect(
          outcome.backend!.companies
              .create(
                id: CompanyId('c-a4'),
                name: 'A4 Co',
                deviceId: 'test-device',
                opId: 'op-ca4',
                eventId: 'ev-ca4',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
        await tester.pumpWidget(NiavApp(
          root: CompositionRoot.system(),
          startup: outcome,
          companyId: CompanyId('c-a4'),
        ));
        await tester.pumpAndSettle();
        // Real data behind the Home tab: the company just written through
        // the encrypted backend.
        expect(find.text('A4 Co'), findsWidgets);
        expect(find.textContaining('Company data is unavailable'), findsNothing);
      } finally {
        outcome.backend!.database.close();
      }
    });

    testWidgets('key failure shows the failure state and creates nothing',
        (WidgetTester tester) async {
      keyReply = const <String, Object?>{
        'state': 'failed',
        'failure': 'keystoreUnavailable',
      };
      final StartupOutcome outcome =
          (await tester.runAsync(() => runStartup(env('niav.db'))))!;
      expect(outcome.stage, StartupStage.keyFailure);
      expect(outcome.code, StartupCode.keyUnavailable);
      expect(outcome.scope, isNull);
      expect(outcome.backend, isNull);

      await tester.pumpWidget(NiavApp(
        root: CompositionRoot.system(),
        startup: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Secure key unavailable'), findsOneWidget);
      expect(
        find.text('Reference: ${StartupCode.keyUnavailable}'),
        findsOneWidget,
      );
      // No database file was created: there is no plaintext fallback and no
      // unencrypted engine anywhere on this path.
      expect(File('${tmp.path}/niav.db').existsSync(), isFalse);
    });

    test('a missing key never opens anything (no plaintext fallback)', () {
      final CipherDatabaseOpener opener = CipherDatabaseOpener.fromKeyBytes(
        dbPath: '${tmp.path}/nokey.db',
        keyBytes: () => null,
        sqlByVersion: const <int, String>{},
        clock: TestClock(1777593600000),
      );
      expect(
        () => opener.openCompanyDatabase(),
        throwsA(isA<CipherOpenException>()),
      );
      expect(File('${tmp.path}/nokey.db').existsSync(), isFalse);
    });
  });
}
