// NiAvERP G0 release-delivery verification — Phase 6.
// Approved channels (RSP / pack): WhatsApp/email, ZIP fallback, ₹0 hosted
// link. This file defines the channel list, the SHA-256 checksum contract,
// and the local verify function the checklist script mirrors in PowerShell.
// Actual channel delivery (sending bytes over WhatsApp/email/hosted link)
// stays PENDING-INPUT until a real delivery test is captured — computing a
// hash locally proves nothing about the channel.
// Traceability: R-04; G0-VER-004 (G5); RSP release sections.

import 'package:crypto/crypto.dart';

/// Approved V1 delivery channels (fixed strings; not invented per run).
const List<String> kApprovedChannels = <String>[
  'WhatsApp/email',
  'ZIP fallback',
  'Rs0 hosted link',
];

/// SHA-256 hex of a payload (APK bytes, ZIP bytes, or any artifact).
String sha256HexBytes(List<int> payload) => sha256.convert(payload).toString();

/// Verify [payload] against [expectedHex] (case-insensitive).
bool verifyPayload(List<int> payload, String expectedHex) =>
    sha256HexBytes(payload).toLowerCase() == expectedHex.toLowerCase();

/// Delivery checklist row: one channel × one artifact.
class DeliveryRow {
  DeliveryRow({
    required this.channel,
    required this.artifact,
    required this.sha256Hex,
    required this.status,
  });
  final String channel;
  final String artifact;
  final String sha256Hex;
  final String status; // PASS with evidence, else PENDING-INPUT
}
