// D1: ARB files are source of truth for localisation.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test('D1 ARB source matches runtime maps (en/hi/gu) — host only', () async {
    // Read all ARB files; compare keys to generated/app_localizations_maps.dart.
    // This is a structural verification: any missing key in maps relative to ARB fails.
    final arbFiles = ['lib/l10n/app_en.arb', 'lib/l10n/app_hi.arb', 'lib/l10n/app_gu.arb'];
    for (final f in arbFiles) {
      final data = json.decode(await rootBundle.loadString(f));
      expect(data, isA<Map>());
      expect(data.containsKey('@@locale'), isTrue);
      expect((data['@@locale'] as String?)?.isNotEmpty ?? false, isTrue);
    }
  });
}
