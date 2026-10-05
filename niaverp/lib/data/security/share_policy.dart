// NiAvERP G0 share policy — Phase 3.
// Default-deny file allowlist from OD-DB-005: attachments JPEG/PNG/PDF
// (≤5 MB each, magic-byte validated); imports .xlsx/.csv only (≤10 MB).
// Anything else — executables, APKs, databases, unknown types — is denied.
// Magic bytes are checked against the file header sample; CSV (text format)
// is accepted by extension plus a text-sanity check (no NUL/control bytes).
// Traceability: OD-DB-005/O-FG-015; G0-VER-008 (on-device proof pending).

/// Maximum attachment size: 5 MB each (OD-DB-005).
const int kMaxAttachmentBytes = 5 * 1024 * 1024;

/// Maximum import file size: 10 MB (OD-DB-005).
const int kMaxImportBytes = 10 * 1024 * 1024;

enum ShareDecision { allow, deny }

bool _startsWith(List<int> bytes, List<int> magic) {
  if (bytes.length < magic.length) return false;
  for (int i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return false;
  }
  return true;
}

/// Decide whether [fileName] of [sizeBytes] with leading [headerBytes] may
/// leave app-private storage. [forImport] selects the import allowlist
/// (.xlsx/.csv); otherwise the attachment allowlist (jpg/png/pdf).
ShareDecision canShare({
  required String fileName,
  required int sizeBytes,
  required List<int> headerBytes,
  required bool forImport,
}) {
  final String ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  if (forImport) {
    if (sizeBytes > kMaxImportBytes || sizeBytes <= 0) {
      return ShareDecision.deny;
    }
    if (ext == 'xlsx' && _startsWith(headerBytes, const <int>[0x50, 0x4B, 0x03, 0x04])) {
      return ShareDecision.allow; // ZIP container magic
    }
    if (ext == 'csv') {
      final bool sane = headerBytes.isNotEmpty &&
          headerBytes.every((int b) => b == 0x0A || b == 0x0D || b == 0x09 || (b >= 0x20 && b != 0x7F));
      if (sane) return ShareDecision.allow;
    }
    return ShareDecision.deny;
  }
  if (sizeBytes > kMaxAttachmentBytes || sizeBytes <= 0) {
    return ShareDecision.deny;
  }
  if ((ext == 'jpg' || ext == 'jpeg') &&
      _startsWith(headerBytes, const <int>[0xFF, 0xD8, 0xFF])) {
    return ShareDecision.allow;
  }
  if (ext == 'png' &&
      _startsWith(headerBytes,
          const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return ShareDecision.allow;
  }
  if (ext == 'pdf' &&
      _startsWith(headerBytes, const <int>[0x25, 0x50, 0x44, 0x46])) {
    return ShareDecision.allow; // %PDF
  }
  return ShareDecision.deny;
}
