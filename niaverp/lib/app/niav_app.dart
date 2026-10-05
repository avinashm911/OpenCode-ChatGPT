// NiAvERP application root widget — Phase 00, navigation slice.
// Owns the [CompositionRoot] and hosts the five-item shell with the active
// [CompanyScope] (null until the production engine is ready — P-SQLIB).
// Holds no business state; the shell keeps only navigation chrome.
// Traceability: OD-UI-001 / G0-CON-005 (five-item model).

import 'package:flutter/material.dart';

import 'composition_root.dart';
import '../core/value_objects/ids.dart';
import '../presentation/shared/company_scope.dart';
import '../presentation/shell/niav_shell.dart';

/// Application root. Created once by `main()` with its [root].
class NiavApp extends StatelessWidget {
  const NiavApp({super.key, required this.root, this.scope, this.companyId});

  final CompositionRoot root;

  /// Tab backend surface. Null in production until the encrypted engine
  /// exists (P-SQLIB); tabs render the scope gate instead of fake data.
  final CompanyScope? scope;

  /// Pre-selected company (tests, deep links). Null starts at onboarding.
  final CompanyId? companyId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: root.config.appTitle,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.indigo),
      ),
      home: NiavShell(
        title: root.config.appTitle,
        scope: scope,
        initialCompanyId: companyId,
      ),
    );
  }
}
