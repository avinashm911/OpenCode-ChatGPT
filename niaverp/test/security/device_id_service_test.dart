// A1: device_id behind proposal — UUIDv7, persisted, never hardware ID.
import 'package:flutter_test/flutter_test.dart';
import 'package:niaverp/data/security/device_id_service.dart';

void main() {
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
