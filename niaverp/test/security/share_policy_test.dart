// Tests: share allowlist — only approved files leave app-private storage.
// Synthetic headers (magic bytes written inline, deterministic).
// Traceability: OD-DB-005/O-FG-015; G0-VER-008 (on-device proof pending).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/security/share_policy.dart';

void main() {
  group('attachments (≤5 MB, magic-checked)', () {
    test('allows real jpg/png/pdf under the cap', () {
      expect(
          canShare(
              fileName: 'bill.jpg',
              sizeBytes: 100,
              headerBytes: const <int>[0xFF, 0xD8, 0xFF, 0x00],
              forImport: false),
          ShareDecision.allow);
      expect(
          canShare(
              fileName: 'scan.png',
              sizeBytes: 100,
              headerBytes: const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
              forImport: false),
          ShareDecision.allow);
      expect(
          canShare(
              fileName: 'invoice.pdf',
              sizeBytes: 100,
              headerBytes: const <int>[0x25, 0x50, 0x44, 0x46, 0x2D],
              forImport: false),
          ShareDecision.allow);
    });

    test('denies spoofed content, oversize and unknown types', () {
      // PDF extension over a ZIP body.
      expect(
          canShare(
              fileName: 'evil.pdf',
              sizeBytes: 100,
              headerBytes: const <int>[0x50, 0x4B, 0x03, 0x04],
              forImport: false),
          ShareDecision.deny);
      // One byte over the 5 MB cap.
      expect(
          canShare(
              fileName: 'big.jpg',
              sizeBytes: kMaxAttachmentBytes + 1,
              headerBytes: const <int>[0xFF, 0xD8, 0xFF],
              forImport: false),
          ShareDecision.deny);
      // Executables, APKs, databases, extensionless files.
      for (final String name in <String>[
        'app.apk',
        'tool.exe',
        'data.db',
        'notes.txt',
        'noext'
      ]) {
        expect(
            canShare(
                fileName: name,
                sizeBytes: 100,
                headerBytes: const <int>[0xFF, 0xD8, 0xFF],
                forImport: false),
            ShareDecision.deny,
            reason: name);
      }
    });
  });

  group('imports (.xlsx/.csv ≤10 MB)', () {
    test('allows zip-magic xlsx and sane csv', () {
      expect(
          canShare(
              fileName: 'items.xlsx',
              sizeBytes: 100,
              headerBytes: const <int>[0x50, 0x4B, 0x03, 0x04],
              forImport: true),
          ShareDecision.allow);
      expect(
          canShare(
              fileName: 'items.csv',
              sizeBytes: 100,
              headerBytes: 'name,qty\nsugar,2\n'.codeUnits,
              forImport: true),
          ShareDecision.allow);
    });

    test('denies wrong-magic xlsx, binary csv, oversize', () {
      expect(
          canShare(
              fileName: 'items.xlsx',
              sizeBytes: 100,
              headerBytes: const <int>[0x25, 0x50, 0x44, 0x46],
              forImport: true),
          ShareDecision.deny);
      expect(
          canShare(
              fileName: 'items.csv',
              sizeBytes: 100,
              headerBytes: const <int>[0x00, 0x01, 0x02],
              forImport: true),
          ShareDecision.deny);
      expect(
          canShare(
              fileName: 'items.csv',
              sizeBytes: kMaxImportBytes + 1,
              headerBytes: 'a,b\n'.codeUnits,
              forImport: true),
          ShareDecision.deny);
    });
  });
}
