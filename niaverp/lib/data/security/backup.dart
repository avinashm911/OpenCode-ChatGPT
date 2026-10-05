// NiAvERP G0 backup guards — Phase 3.
// Manifest integrity + restore refusal rules. A backup carries a SHA-256 over
// its payload; restore re-verifies before touching the live database
// (DB §8: backup/recovery point before material migration; DSS §6).
// Restoring a NEWER-schema backup onto an OLDER app is refused: that would be
// an in-place downgrade (DSS-C-007 / RSP 5). After uninstall/reinstall the
// Keystore keys are gone, so restore MUST require key re-provisioning and
// must never silently decrypt (no hidden recovery path).
// Traceability: DB §8; DSS §6/C-007; RSP 5; FR-M22-001; D-06.

import 'package:crypto/crypto.dart';

/// Backup manifest: audit evidence accompanying every external backup.
class BackupManifest {
  BackupManifest({
    required this.companyId,
    required this.createdAtMs,
    required this.schemaVersion,
    required this.payloadSha256Hex,
    required this.files,
  });

  final String companyId;
  final int createdAtMs;
  final int schemaVersion;
  final String payloadSha256Hex;
  final List<String> files;
}

/// SHA-256 hex of a backup payload.
String sha256Hex(List<int> payload) => sha256.convert(payload).toString();

/// Build the manifest for a fresh backup.
BackupManifest createManifest({
  required String companyId,
  required int createdAtMs,
  required int schemaVersion,
  required List<int> payload,
  required List<String> files,
}) {
  return BackupManifest(
    companyId: companyId,
    createdAtMs: createdAtMs,
    schemaVersion: schemaVersion,
    payloadSha256Hex: sha256Hex(payload),
    files: List<String>.unmodifiable(files),
  );
}

/// Guard a restore. Returns error strings; empty means the restore may
/// proceed to the (device-side) key-gated decrypt step.
/// Refuses: payload hash mismatch (corruption/tamper), newer-schema
/// backups (in-place downgrade is unsupported), and company mismatch when
/// [liveCompanyId] is supplied (a restore must never silently overwrite
/// live data of another company — FR-M22-001, DSS-C-001).
List<String> checkRestorable({
  required BackupManifest manifest,
  required List<int> actualPayload,
  required int appSchemaVersion,
  String? liveCompanyId,
}) {
  final List<String> errors = <String>[];
  if (sha256Hex(actualPayload) != manifest.payloadSha256Hex) {
    errors.add('payload hash mismatch: backup is corrupt or tampered');
  }
  if (manifest.schemaVersion > appSchemaVersion) {
    errors.add('backup schema v${manifest.schemaVersion} is newer than app '
        'v$appSchemaVersion: restore refused (no in-place downgrade)');
  }
  if (liveCompanyId != null && liveCompanyId != manifest.companyId) {
    errors.add('backup company ${manifest.companyId} does not match live '
        'company $liveCompanyId: restore refused (no silent overwrite)');
  }
  return errors;
}

/// Restore key plan after reinstall: Keystore keys do not survive uninstall,
/// so a restore with [keystoreWiped] MUST force re-provisioning (licence key
/// / device auth) before any decrypt is attempted.
bool requiresKeyReprovision({required bool keystoreWiped}) => keystoreWiped;
