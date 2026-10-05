// Negative test: voice input is excluded from V1 (rejected by owner).
// Proves no voice capability is exposed: no speech/voice package imports in
// lib/, no voice UI affordance in presentation sources, and no audio capture
// permission in the Android manifest. Boundary comments that *mention* the
// exclusion (e.g. "no transliteration") are documentation, not capability,
// so import/permission/UI-marker scans target capability markers only.
// Traceability: FR-M02-002 / G0-OWN-002 (excluded); OD-UI-003.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// All Dart sources under [dir] (relative to the package root, the working
/// directory of `flutter test`).
List<File> _dartSources(String dir) {
  final Directory root = Directory(dir);
  if (!root.existsSync()) return <File>[];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  group('FR-M02-002 / G0-OWN-002 voice exclusion (negative)', () {
    test('lib/ imports no speech/voice/audio-capture packages', () {
      final RegExp importLine = RegExp(r'^\s*import\s+');
      // Capability markers only: package/import tokens. Plain-word "voice"
      // is deliberately NOT matched (it occurs inside "invoice").
      final RegExp capability = RegExp(
        r'speech_to_text|speech_recognition|flutter_sound|sound_record|'
        r'voice_input|keyboard_voice|RECORD_AUDIO|microphone|Microphone',
      );
      final List<String> hits = <String>[];
      for (final File f in _dartSources('lib')) {
        for (final String line in f.readAsLinesSync()) {
          if (importLine.hasMatch(line) && capability.hasMatch(line)) {
            hits.add('${f.path}: $line');
          }
        }
      }
      expect(hits, isEmpty, reason: 'voice capability import found: $hits');
    });

    test('presentation/ exposes no voice/mic UI affordance', () {
      final RegExp uiMarker = RegExp(
        r'Icons\.mic\b|Icons\.keyboard_voice\b|Icons\.settings_voice\b|'
        r'voice_button|VoiceButton|voice input|Voice input',
      );
      final List<String> hits = <String>[];
      for (final File f in _dartSources('lib/presentation')) {
        for (final String line in f.readAsLinesSync()) {
          if (uiMarker.hasMatch(line)) hits.add('${f.path}: $line');
        }
      }
      expect(hits, isEmpty, reason: 'voice UI affordance found: $hits');
    });

    test('Android manifest declares no audio-capture permission', () {
      final File manifest =
          File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue,
          reason: 'AndroidManifest.xml must exist for this check');
      final String text = manifest.readAsStringSync();
      expect(text.contains('RECORD_AUDIO'), isFalse);
      expect(text.contains('MICROPHONE'), isFalse);
      expect(text.contains('uses-permission'), isFalse);
    });

    test('pubspec declares no speech/voice dependency', () {
      final String text = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(r'speech_to_text|speech_recognition|flutter_sound|'
                r'sound_record|transliterate')
            .hasMatch(text),
        isFalse,
      );
    });
  });
}
