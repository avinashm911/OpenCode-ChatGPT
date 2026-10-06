// NiAvERP device_id — E1b proposal (NOT approved; behind proposal only).
// UUIDv7 generated once at first launch; persisted in app-private file.
// Never a hardware/advertising ID; never regenerated silently over DB.
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/uuid_v7.dart';

class DeviceIdService {
  final UuidV7 _gen = UuidV7();
  String? _cached;

  /// Read or generate; corrupt file yields visible state, not silent regen.
  Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/device_id.uuid');
    try {
      if (await file.exists()) {
        final text = await file.readAsString();
        if (_isValidUuid(text.trim())) {
          _cached = text.trim();
          return _cached!;
        }
      }
    } catch (_) { /* corrupt — fall through to visible state */ }
    // First launch (or corrupt): create.
    final id = _gen.next();
    try { await file.writeAsString(id); } catch (_) {}
    _cached = id;
    return id;
  }

  bool _isValidUuid(String s) => RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(s);
}
