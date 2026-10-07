// NiAvERP device_id — owner-approved 2026-10-06 (DECISIONS.md P-DEVICEID).
// UUIDv7 generated once at first launch; persisted in app-private file.
// Never a hardware/advertising ID; never regenerated silently over DB.
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/uuid_v7.dart';

/// The stored device_id file exists but is invalid or unreadable.
/// Thrown instead of overwriting: callers must surface a visible failure.
class DeviceIdCorruptException implements Exception {
  const DeviceIdCorruptException(this.reason);
  final String reason;

  @override
  String toString() => 'DeviceIdCorruptException($reason)';
}

/// A fresh device_id could not be persisted (missing directory, permissions).
class DeviceIdWriteException implements Exception {
  const DeviceIdWriteException(this.reason);
  final String reason;

  @override
  String toString() => 'DeviceIdWriteException($reason)';
}

class DeviceIdService {
  final UuidV7 _gen = UuidV7();
  String? _cached;

  /// Read, or generate once and persist. Three cases, no silent behaviour:
  /// (a) file missing → create and persist a new UUIDv7;
  /// (b) file valid → reuse it;
  /// (c) file exists but is invalid or unreadable → throw
  ///     [DeviceIdCorruptException] and leave the file untouched.
  /// A failed write throws [DeviceIdWriteException].
  Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/device_id.uuid');
    // NB: File.exists() is false for a directory, so a directory squatting
    // at the path must count as "exists" here — use the entity type.
    FileSystemEntityType kind;
    try {
      kind = await FileSystemEntity.type(file.path);
    } catch (_) {
      throw const DeviceIdCorruptException('stat-failed');
    }
    if (kind != FileSystemEntityType.notFound) {
      String text;
      try {
        text = await file.readAsString();
      } catch (_) {
        throw const DeviceIdCorruptException('unreadable');
      }
      final String id = text.trim();
      if (!_isValidUuid(id)) {
        throw const DeviceIdCorruptException('invalid-content');
      }
      _cached = id;
      return _cached!;
    }
    // First launch: create and persist.
    final String id = _gen.next();
    try {
      await file.writeAsString(id);
    } catch (_) {
      throw const DeviceIdWriteException('write-failed');
    }
    _cached = id;
    return id;
  }

  bool _isValidUuid(String s) => RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(s);
}
