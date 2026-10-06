// A1: device_id behind proposal — UUIDv7, persisted, never hardware ID.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niaverp/data/security/device_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tmpDir = Directory.systemTemp.createTempSync('device_id_test_');
  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tmpDir.path;
          }
          throw MissingPluginException();
        });
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });
  test('first run creates device_id', () async {
    final id = await DeviceIdService().getOrCreate();
    expect(id, isNotEmpty);
    expect(id.contains('-'), isTrue);
  });
  test('second run reuses same id', () async {
    final a = await DeviceIdService().getOrCreate();
    final b = await DeviceIdService().getOrCreate();
    expect(a, equals(b));
  });
}
