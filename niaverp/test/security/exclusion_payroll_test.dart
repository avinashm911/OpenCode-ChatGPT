// Negative test: PF/ESI and payroll are out of scope for V1 (FG-008).
// Proves the excluded capability is not exposed: no payroll/PF/ESI markers
// in lib/, no such tables in the migration chain, and no related
// dependencies in pubspec. TDS/TCS are deliberately NOT scanned here — they
// are deferred (FG-007), and deferred items allow no V1 test activity.
// Traceability: FG-008 (excluded; prerequisite payroll model undefined).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Capability markers for the excluded payroll/PF/ESI domain. Plain-word
/// matching would false-positive (e.g. "these" contains "esi"), so
/// PF/ESI use whole-word uppercase tokens only; all tokens below are
/// verified absent from lib/ as of this test's authoring.
final RegExp _excludedMarker = RegExp(
  r'payroll|provident|gratuity|salary|EPF|ESIC|\bESI\b|\bPF\b',
  caseSensitive: false,
);

/// Dart sources under [dir] (package root is the `flutter test` cwd).
List<File> _dartSources(String dir) {
  return Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  group('FG-008 PF/ESI/payroll exclusion (negative)', () {
    test('lib/ carries no payroll/PF/ESI capability markers', () {
      final List<String> hits = <String>[];
      for (final File f in _dartSources('lib')) {
        for (final String line in f.readAsLinesSync()) {
          if (_excludedMarker.hasMatch(line)) {
            hits.add('${f.path}: $line');
          }
        }
      }
      expect(hits, isEmpty, reason: 'excluded marker found: $hits');
    });

    test('migration chain defines no payroll/PF/ESI tables', () {
      final RegExp createTable = RegExp(
        r'CREATE\s+TABLE[^;]*(payroll|provident|gratuity|salary|_pf_|_esi_)',
        caseSensitive: false,
      );
      final List<File> sqlFiles = Directory('lib/data/migrations')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.sql'))
          .toList();
      expect(sqlFiles, isNotEmpty, reason: 'migration SQL files must exist');
      final List<String> hits = <String>[];
      for (final File f in sqlFiles) {
        if (createTable.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
      expect(hits, isEmpty, reason: 'excluded table found in: $hits');
    });

    test('pubspec declares no payroll/statutory dependency', () {
      final String text = File('pubspec.yaml').readAsStringSync();
      expect(_excludedMarker.hasMatch(text), isFalse);
      expect(text.contains('package:http'), isFalse);
      expect(text.contains('package:dio'), isFalse);
    });
  });
}
