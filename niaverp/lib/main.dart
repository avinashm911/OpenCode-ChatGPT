// NiAvERP application entry point — Phase 00, production startup in D1.
// Counter scaffold replaced by the five-item shell (OD-UI-001 / G0-CON-005).
// `main()` owns the startup sequence and nothing else:
//   migration SQL assets → Keystore-wrapped key → encrypted database →
//   backend graph → tab scope.
// Until that sequence succeeds the app shows a startup state (starting, key
// failure, database failure, newer-schema refusal). It never falls back to
// plaintext, to an unencrypted engine or to fake data.
//
// Platform edges (method channel, asset bundle, clock, sandbox path, device
// id) are injected through [runStartup], so the exact same sequence runs in
// tests over an in-memory/temp engine and a fake channel.
// The sandbox path and device id come from the platform channel when it
// answers; when it does not, startup stops in a failure state instead of
// guessing a path (an empty path would be a plaintext-adjacent accident).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niaverp/app/composition_root.dart';
import 'package:niaverp/app/niav_app.dart';
import 'package:niaverp/app/startup.dart';
import 'package:niaverp/core/clock.dart';
import 'package:niaverp/data/db/key_provider.dart';
import 'package:niaverp/data/security/device_id_service.dart';

/// Database file inside the app-private sandbox (never a shared location).
const String kDatabaseFileName = 'niaverp.db';

/// Device identity for operation lineage. Returns null when the identity
/// cannot be established (missing/corrupt/unwritable file, platform fault);
/// the caller turns null into the visible device-identity failure state.
Future<String?> _resolveDeviceId() async {
  try {
    return await DeviceIdService().getOrCreate();
  } on DeviceIdCorruptException {
    return null;
  } on DeviceIdWriteException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      MethodChannel(ChannelKeyProvider.kKeyChannelName);

  // Sandbox path: the platform owns it (app-private files directory). If the
  // channel cannot answer, startup fails honestly instead of opening anything.
  String filesDir = '';
  try {
    filesDir = await channel.invokeMethod<String>('getFilesDirectory') ?? '';
  } on PlatformException {
    filesDir = '';
  } on MissingPluginException {
    filesDir = '';
  }

  final deviceId = await _resolveDeviceId();
  final StartupOutcome outcome;
  if (deviceId == null) {
    // Device identity unusable: visible failure screen, never a blank
    // screen or a crash, and no backend without lineage.
    outcome = const StartupOutcome.deviceIdFailure(
        StartupCode.deviceIdUnavailable);
  } else if (filesDir.isEmpty) {
    outcome = const StartupOutcome.databaseFailure(
        StartupCode.databaseUnavailable);
  } else {
    outcome = await runStartup(StartupEnvironment(
      channel: channel,
      loadString: rootBundle.loadString,
      clock: const SystemClock(),
      dbPath: '$filesDir/$kDatabaseFileName',
      deviceId: deviceId,
      actor: deviceId,
      dbFileName: kDatabaseFileName,
    ));
  }
  runApp(NiavApp(root: CompositionRoot.system(), startup: outcome));
}