// NiAvERP trial install copy — B1 (M20.1).
// One app-private copy of the installation instant, written once beside the
// device_id file (DeviceIdService pattern: never overwrite, typed errors).
// The database anchors stay the primary record; this copy only prevents a
// silent trial reset. Deleting every copy (this file + all anchors) starts a
// new trial — accepted residual risk R1 (SEC §3.4), covered by a named test.
// Traceability: SEC §3.3/§3.4; D-11/D-13/A-R2; G0-SCH-006.

import 'dart:io' show File, FileSystemEntity, FileSystemEntityType, Platform;

/// The stored install copy exists but is invalid or unreadable.
/// Thrown instead of overwriting (mirrors DeviceIdCorruptException).
class TrialStoreCorruptException implements Exception {
  const TrialStoreCorruptException(this.reason);
  final String reason;

  @override
  String toString() => 'TrialStoreCorruptException($reason)';
}

/// A fresh install copy could not be persisted.
/// Thrown instead of continuing silently (mirrors DeviceIdWriteException).
class TrialStoreWriteException implements Exception {
  const TrialStoreWriteException(this.reason);
  final String reason;

  @override
  String toString() => 'TrialStoreWriteException($reason)';
}

/// Write-once file store for the installation instant (epoch-ms UTC).
/// The directory is injected (app sandbox in production, temp dir in tests)
/// so no path_provider mock is ever needed.
class TrialFileStore {
  TrialFileStore(this.dirPath);

  final String dirPath;

  String get filePath =>
      '$dirPath${Platform.pathSeparator}trial_install.ms';

  /// The stored install instant, or null when no copy was ever written.
  /// Throws [TrialStoreCorruptException] (leaving the file untouched) when
  /// a copy exists but cannot be read or parsed.
  int? readInstallMs() {
    final File file = File(filePath);
    FileSystemEntityType kind;
    try {
      kind = FileSystemEntity.typeSync(file.path);
    } catch (_) {
      throw const TrialStoreCorruptException('stat-failed');
    }
    if (kind == FileSystemEntityType.notFound) return null;
    String text;
    try {
      text = file.readAsStringSync();
    } catch (_) {
      throw const TrialStoreCorruptException('unreadable');
    }
    final int? ms = int.tryParse(text.trim());
    if (ms == null || ms <= 0) {
      throw const TrialStoreCorruptException('invalid-content');
    }
    return ms;
  }

  /// Return the stored instant, writing [nowMs] once on first launch.
  /// Throws [TrialStoreWriteException] when the first write fails.
  int ensureInstallMs(int nowMs) {
    final int? existing = readInstallMs();
    if (existing != null) return existing;
    try {
      File(filePath).writeAsStringSync('$nowMs');
    } catch (_) {
      throw const TrialStoreWriteException('write-failed');
    }
    return nowMs;
  }
}
