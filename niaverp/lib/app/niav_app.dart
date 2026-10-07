// NiAvERP application root widget — Phase 00, navigation slice, startup states
// in D1, localisation in D4.
// Owns the [CompositionRoot] and hosts the five-item shell with the active
// [CompanyScope] produced by the startup sequence. Holds no business state; the
// shell keeps only navigation chrome.
// Startup states are distinct and non-technical: starting, key failure
// (codes only), database failure, newer-schema refusal, device-identity
// failure. When the outcome is
// not [StartupStage.ready] the shell is never built, so no tab can show fake
// or unencrypted data.
// D4: MaterialApp carries the launch locales (D-03 en/hi/gu), the NiAvERP
// delegate plus the SDK delegates, and a 48dp minimum on primary (Filled)
// actions (UX-009). The language controller defaults to English so legacy
// test trees without one render exactly the old strings.
// Traceability: OD-UI-001 / G0-CON-005 (five-item model); D1 (A3);
// FR-M02-001; REG M02.1/M02.3; UX-008/UX-009.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
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
    this.language,
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

  /// Language choice. Null renders English (legacy test trees unchanged).
  final LanguageController? language;

  @override
  Widget build(BuildContext context) {
    final StartupOutcome? outcome = startup;
    final CompanyScope? active = scope ?? outcome?.scope;
    final LanguageController lang = language ?? LanguageController();
    return ListenableBuilder(
      listenable: lang,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: root.config.appTitle,
          locale: lang.locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.indigo),
            // UX-009: primary actions meet the 48dp touch target.
            filledButtonTheme: const FilledButtonThemeData(
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll<Size>(Size(64, 48)),
              ),
            ),
          ),
          home: outcome != null && outcome.stage != StartupStage.ready
              ? StartupStatusScreen(outcome: outcome)
              : NiavShell(
                  title: root.config.appTitle,
                  scope: active,
                  initialCompanyId: companyId,
                  language: lang,
                ),
        );
      },
    );
  }
}

/// Cold-start / failure surface. Non-technical wording on purpose: the codes
/// stay in the widget tree for tests and diagnostics, never key bytes, paths,
/// SQL or driver text.
class StartupStatusScreen extends StatelessWidget {
  const StartupStatusScreen({super.key, required this.outcome});

  final StartupOutcome outcome;

  String _headline(AppLocalizations l10n) {
    switch (outcome.stage) {
      case StartupStage.starting:
        return l10n.t('stStarting');
      case StartupStage.keyFailure:
        return l10n.t('stKeyFail');
      case StartupStage.databaseFailure:
        return l10n.t('stDbFail');
      case StartupStage.schemaRefused:
        return l10n.t('stSchemaOld');
      case StartupStage.deviceIdFailure:
        return l10n.t('stDeviceFail');
      case StartupStage.ready:
        return l10n.t('stReady');
    }
  }

  String _detail(AppLocalizations l10n) {
    switch (outcome.stage) {
      case StartupStage.starting:
        return l10n.t('stStartingDetail');
      case StartupStage.keyFailure:
        return l10n.t('stKeyDetail');
      case StartupStage.databaseFailure:
        return l10n.t('stDbDetail');
      case StartupStage.schemaRefused:
        return l10n.t('stSchemaDetail');
      case StartupStage.deviceIdFailure:
        return l10n.t('stDeviceDetail');
      case StartupStage.ready:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
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
            Text(_headline(l10n),
                key: const ValueKey<String>('startup-headline'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _detail(l10n),
                textAlign: TextAlign.center,
                key: const ValueKey<String>('startup-detail'),
              ),
            ),
            if (outcome.code != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  l10n.referenceCode(outcome.code!),
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