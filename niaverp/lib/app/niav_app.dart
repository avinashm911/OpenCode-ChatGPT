// NiAvERP application root widget — Phase 00, navigation slice, startup states
// in D1.
// Owns the [CompositionRoot] and hosts the five-item shell with the active
// [CompanyScope] produced by the startup sequence. Holds no business state; the
// shell keeps only navigation chrome.
// Startup states are distinct and non-technical: starting, key failure
// (codes only), database failure, newer-schema refusal. When the outcome is
// not [StartupStage.ready] the shell is never built, so no tab can show fake
// or unencrypted data.
// Traceability: OD-UI-001 / G0-CON-005 (five-item model); D1 (A3).

import 'package:flutter/material.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';
import 'package:niaverp/presentation/shell/niav_shell.dart';

import 'composition_root.dart';
import 'startup.dart';

/// Application root. Created once by `main()` with its [root] and the
/// [startup] outcome of the production sequence.
class NiavApp extends StatelessWidget {
  const NiavApp({
    super.key,
    required this.root,
    this.startup,
    this.scope,
    this.companyId,
  });

  final CompositionRoot root;

  /// Result of the production startup sequence. Null only in unit tests that
  /// inject a scope directly; production always supplies one.
  final StartupOutcome? startup;

  /// Tab backend surface. Normally taken from [startup]; tests may pass it
  /// directly (the shell then renders the scope gate if it is null).
  final CompanyScope? scope;

  /// Pre-selected company (tests, deep links). Null starts at onboarding.
  final CompanyId? companyId;

  @override
  Widget build(BuildContext context) {
    final StartupOutcome? outcome = startup;
    final CompanyScope? active = scope ?? outcome?.scope;
    return MaterialApp(
      title: root.config.appTitle,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.indigo),
      ),
      home: outcome != null && outcome.stage != StartupStage.ready
          ? StartupStatusScreen(outcome: outcome)
          : NiavShell(
              title: root.config.appTitle,
              scope: active,
              initialCompanyId: companyId,
            ),
    );
  }
}

/// Cold-start / failure surface. Non-technical wording on purpose: the codes
/// stay in the widget tree for tests and diagnostics, never key bytes, paths,
/// SQL or driver text.
class StartupStatusScreen extends StatelessWidget {
  const StartupStatusScreen({super.key, required this.outcome});

  final StartupOutcome outcome;

  String get _headline {
    switch (outcome.stage) {
      case StartupStage.starting:
        return 'Preparing your company data';
      case StartupStage.keyFailure:
        return 'Secure key unavailable';
      case StartupStage.databaseFailure:
        return 'Company data could not be opened';
      case StartupStage.schemaRefused:
        return 'This build is older than your data';
      case StartupStage.ready:
        return 'Ready';
    }
  }

  String get _detail {
    switch (outcome.stage) {
      case StartupStage.starting:
        return 'Unlocking your encrypted company database.';
      case StartupStage.keyFailure:
        return 'The secure key on this device is not usable. '
            'Your data stays encrypted and nothing has been changed.';
      case StartupStage.databaseFailure:
        return 'Your encrypted company database could not be opened. '
            'Nothing has been changed.';
      case StartupStage.schemaRefused:
        return 'Your data was created by a newer version. '
            'Restore is supported; downgrading in place is not.';
      case StartupStage.ready:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: const ValueKey<String>('startup-status'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (outcome.stage == StartupStage.starting)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(),
              ),
            Text(_headline,
                key: const ValueKey<String>('startup-headline'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _detail,
                textAlign: TextAlign.center,
                key: const ValueKey<String>('startup-detail'),
              ),
            ),
            if (outcome.code != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Reference: ${outcome.code}',
                  key: const ValueKey<String>('startup-code'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}