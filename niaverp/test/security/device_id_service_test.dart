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

  group('corrupt / unwritable file (typed errors, never overwrite)', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('device_id_case_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return dir.path;
        }
        throw MissingPluginException();
      });
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('first run creates and persists a valid UUIDv7', () async {
      final String id = await DeviceIdService().getOrCreate();
      final File file = File('${dir.path}/device_id.uuid');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), id);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(id),
        isTrue,
      );
    });

    test('valid file is reused', () async {
      const String known = '12345678-1234-7abc-8123-123456789abc';
      File('${dir.path}/device_id.uuid').writeAsStringSync(known);
      expect(await DeviceIdService().getOrCreate(), known);
    });

    test('invalid content throws and leaves the file untouched', () async {
      const String garbage = 'not-a-device-id';
      final File file = File('${dir.path}/device_id.uuid')..writeAsStringSync(garbage);
      await expectLater(
        DeviceIdService().getOrCreate(),
        throwsA(isA<DeviceIdCorruptException>()),
      );
      expect(file.readAsStringSync(), garbage);
    });

    test('unreadable file (directory at the path) throws and is untouched', () async {
      final Directory block = Directory('${dir.path}/device_id.uuid')..createSync();
      await expectLater(
        DeviceIdService().getOrCreate(),
        throwsA(isA<DeviceIdCorruptException>()),
      );
      expect(block.existsSync(), isTrue);
    });

    test('write failure throws a typed error', () async {
      final Directory gone = Directory('${dir.path}/no-such-dir');
      expect(gone.existsSync(), isFalse);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return gone.path;
        }
        throw MissingPluginException();
      });
      await expectLater(
        DeviceIdService().getOrCreate(),
        throwsA(isA<DeviceIdWriteException>()),
      );
    });
  });
}
