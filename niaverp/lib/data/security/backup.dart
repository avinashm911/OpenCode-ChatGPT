// NiAvERP G0 backup guards — Phase 3, manifest authentication in D2.
// Manifest integrity + restore refusal rules. A backup carries a SHA-256 over
// its payload; restore re-verifies before touching the live database
// (DB §8: backup/recovery point before material migration; DSS §6).
// D2-E1/E2: manifests additionally carry per-file hashes plus an HMAC-SHA256
// over the canonical manifest (package:crypto, already a dependency) when the
// caller supplies a key. The Security plan defines no manifest-MAC
// key-derivation source (backup encryption keys derive from a user passphrase
// flow that does not exist in the app), so keyed authentication stays an
// injected-key interface (D2-E1 blocked): unkeyed manifests keep working
// exactly as before, and verification only enforces a MAC that is present.
// Restoring a NEWER-schema backup onto an OLDER app is refused: that would be
// an in-place downgrade (DSS-C-007 / RSP 5). After uninstall/reinstall the
// Keystore keys are gone, so restore MUST require key re-provisioning and
// must never silently decrypt (no hidden recovery path).
// Traceability: DB §8; DSS §6/C-007; RSP 5; FR-M22-001; D-06; D2 (E1/E2).

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Backup manifest: audit evidence accompanying every external backup.
class BackupManifest {
  BackupManifest({
    required this.companyId,
    required this.createdAtMs,
    required this.schemaVersion,
    required this.payloadSha256Hex,
    required this.files,
    this.fileHashes = const <String, String>{},
    this.macHex,
  });

  final String companyId;
  final int createdAtMs;
  final int schemaVersion;
  final String payloadSha256Hex;
  final List<String> files;

  /// Per-file SHA-256 hex keyed by file name (empty when not recorded).
  final Map<String, String> fileHashes;

  /// HMAC-SHA256 over the canonical manifest (null when created unkeyed).
  final String? macHex;
}

/// SHA-256 hex of a backup payload.
String sha256Hex(List<int> payload) => sha256.convert(payload).toString();

/// Canonical manifest map for MAC computation (sorted file keys; the MAC
/// itself is never part of its own input).
Map<String, Object?> manifestMacInput({
  required String companyId,
  required int createdAtMs,
  required int schemaVersion,
  required String payloadSha256Hex,
  required Map<String, String> fileHashes,
}) {
  final List<String> names = fileHashes.keys.toList()..sort();
  return <String, Object?>{
    'company_id': companyId,
    'created_at_ms': createdAtMs,
    'schema_version': schemaVersion,
    'payload_sha256': payloadSha256Hex,
    'files': <Object?>[
      for (final String n in names) <String>[n, fileHashes[n]!],
    ],
  };
}

/// HMAC-SHA256 hex over the canonical manifest with an injected [macKey].
/// The key-derivation source is intentionally a caller input (D2-E1 blocked:
/// the Security plan derives backup encryption from a user passphrase, not a
/// manifest-MAC key).
String manifestMacHex({
  required Map<String, Object?> macInput,
  required List<int> macKey,
}) {
  final List<String> keys = macInput.keys.toList()..sort();
  final Map<String, Object?> canonical = <String, Object?>{
    for (final String k in keys) k: macInput[k],
  };
  return Hmac(sha256, macKey).convert(utf8.encode(jsonEncode(canonical))).toString();
}

/// Verify a manifest's MAC with an injected [macKey]. False when the manifest
/// carries no MAC or when any covered field differs (tamper, or replay across
/// companies, versions, payloads or file sets).
bool verifyManifestMac({
  required BackupManifest manifest,
  required List<int> macKey,
}) {
  final String? mac = manifest.macHex;
  if (mac == null) return false;
  final String recomputed = manifestMacHex(
    macInput: manifestMacInput(
      companyId: manifest.companyId,
      createdAtMs: manifest.createdAtMs,
      schemaVersion: manifest.schemaVersion,
      payloadSha256Hex: manifest.payloadSha256Hex,
      fileHashes: manifest.fileHashes,
    ),
    macKey: macKey,
  );
  return _constantTimeEqual(mac, recomputed);
}

bool _constantTimeEqual(String a, String b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Build the manifest for a fresh backup. Pass [macKey] (with [fileHashes])
/// to authenticate it; omit both to keep the legacy unkeyed shape.
BackupManifest createManifest({
  required String companyId,
  required int createdAtMs,
  required int schemaVersion,
  required List<int> payload,
  required List<String> files,
  Map<String, String> fileHashes = const <String, String>{},
  List<int>? macKey,
}) {
  final String payloadHash = sha256Hex(payload);
  final String? mac = macKey == null
      ? null
      : manifestMacHex(
          macInput: manifestMacInput(
            companyId: companyId,
            createdAtMs: createdAtMs,
            schemaVersion: schemaVersion,
            payloadSha256Hex: payloadHash,
            fileHashes: fileHashes,
          ),
          macKey: macKey,
        );
  return BackupManifest(
    companyId: companyId,
    createdAtMs: createdAtMs,
    schemaVersion: schemaVersion,
    payloadSha256Hex: payloadHash,
    files: List<String>.unmodifiable(files),
    fileHashes: Map<String, String>.unmodifiable(fileHashes),
    macHex: mac,
  );
}

/// Guard a restore. Returns error strings; empty means the restore may
/// proceed to the (device-side) key-gated decrypt step.
/// Refuses: payload hash mismatch (corruption/tamper), newer-schema
/// backups (in-place downgrade is unsupported), and company mismatch when
/// [liveCompanyId] is supplied (a restore must never silently overwrite
/// live data of another company — FR-M22-001, DSS-C-001). When [macKey] is
/// supplied AND the manifest carries a MAC, a failed verification is also
/// refused (D2-E2; unkeyed legacy manifests keep the hash-only path).
List<String> checkRestorable({
  required BackupManifest manifest,
  required List<int> actualPayload,
  required int appSchemaVersion,
  String? liveCompanyId,
  List<int>? macKey,
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
  if (macKey != null) {
    if (manifest.macHex == null) {
      errors.add('manifest MAC missing: backup requires authentication');
    } else if (!verifyManifestMac(manifest: manifest, macKey: macKey)) {
      errors.add('manifest authentication failed: backup is tampered or replayed');
    }
  }
  return errors;
}

/// Restore key plan after reinstall: Keystore keys do not survive uninstall,
/// so a restore with [keystoreWiped] MUST force re-provisioning (licence key
/// / device auth) before any decrypt is attempted.
bool requiresKeyReprovision({required bool keystoreWiped}) => keystoreWiped;
