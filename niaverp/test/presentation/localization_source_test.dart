// D1: ARB files are source of truth for localisation (host only).
// Reads lib/l10n/*.arb with dart:io relative to the package root — ARB files
// are deliberately NOT app assets, so rootBundle must never be used here.
// Checks, for en/hi/gu: (a) the file is valid JSON, (b) @@locale is present
// and correct, (c) every key in app_en.arb exists in hi and gu, (d) every key
// in the runtime maps (kArbMaps) exists in the matching ARB and vice versa.
// Missing keys are listed in the failure message.
// Traceability: D1; FR-M02 / O-01.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/presentation/localization/app_localizations_maps.dart';

Map<String, Object?> _readArb(String locale) {
  final File file = File('lib/l10n/app_$locale.arb');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'lib/l10n/app_$locale.arb not found — run flutter test from niaverp/ (cwd: ${Directory.current.path})',
  );
  String text = file.readAsStringSync();
  // Some editors save ARB files with a UTF-8 BOM; strip it before parsing.
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  try {
    final Object? decoded = json.decode(text);
    expect(decoded, isA<Map>());
    return (decoded as Map).cast<String, Object?>();
  } on FormatException catch (e) {
    fail('lib/l10n/app_$locale.arb is not valid JSON: $e');
  }
}

Set<String> _contentKeys(Map<String, Object?> arb) =>
    arb.keys.where((String k) => !k.startsWith('@')).toSet();

String _describe(String what, Set<String> keys) {
  final List<String> sorted = keys.toList()..sort();
  final String shown = sorted.take(50).join(', ');
  final String more = sorted.length > 50 ? ' (+${sorted.length - 50} more)' : '';
  return '$what (${sorted.length}): $shown$more';
}

void main() {
  test('D1 ARB source matches runtime maps (en/hi/gu) — host only', () {
    const List<String> locales = <String>['en', 'hi', 'gu'];
    final Map<String, Map<String, Object?>> arbs = <String, Map<String, Object?>>{
      for (final String locale in locales) locale: _readArb(locale),
    };

    // (b) @@locale present and correct.
    for (final String locale in locales) {
      expect(
        arbs[locale]!['@@locale'],
        locale,
        reason: 'app_$locale.arb @@locale must be "$locale"',
      );
    }

    // (c) every key in app_en.arb exists in hi and gu.
    final Set<String> enKeys = _contentKeys(arbs['en']!);
    for (final String locale in <String>['hi', 'gu']) {
      final Set<String> missing = enKeys.difference(_contentKeys(arbs[locale]!));
      expect(
        missing,
        isEmpty,
        reason: _describe('keys in app_en.arb missing from app_$locale.arb', missing),
      );
    }

    // (d) runtime maps mirror the ARB files, both directions.
    for (final String locale in locales) {
      final Set<String>? mapKeys = kArbMaps[locale]?.keys.toSet();
      expect(mapKeys, isNotNull, reason: 'kArbMaps has no "$locale" section');
      final Set<String> arbKeys = _contentKeys(arbs[locale]!);
      final Set<String> missingInMaps = arbKeys.difference(mapKeys!);
      expect(
        missingInMaps,
        isEmpty,
        reason: _describe('ARB keys missing from kArbMaps["$locale"]', missingInMaps),
      );
      final Set<String> missingInArb = mapKeys.difference(arbKeys);
      expect(
        missingInArb,
        isEmpty,
        reason: _describe('kArbMaps["$locale"] keys missing from app_$locale.arb', missingInArb),
      );
    }
  });
}
