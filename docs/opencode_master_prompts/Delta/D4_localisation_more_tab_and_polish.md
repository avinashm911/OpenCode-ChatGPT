# D4 — Localisation, More tab, accessibility and UI robustness

## Mandatory first actions
1. Read `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`, `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
   `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `SOURCE_CLARIFICATIONS.md`, `STATUS_LEDGER.md`, and `docs/implementation/RESULT_D1_*.md`, `RESULT_D2_*.md`, `RESULT_D3_*.md`
   (each must be PASS or PASS-WITH-BLOCKS; otherwise stop with FAIL).
2. Read, read-only: Modules Register (M01, M02, M18–M24 sub-modules with priority tags: P1 = MVP/launch, P2 = Phase 2, P3 = later; implement P1 only), FR-M01/M02/M18–M24, UI/UX Specification,
   UX Specification, Functional Design Document.
3. Run `flutter analyze` and `flutter test` first; record totals.

## Rule for this prompt
Implement only P1 items the documents define. Voice input, automatic transliteration, direct statutory APIs, cloud sync and payroll stay excluded. For anything marked TBC/VERIFY or P2/P3, record it
as `boundary` or `deferred` with its gate; do not build it. No new pub.dev packages; `flutter_localizations` from the Flutter SDK and `flutter gen-l10n` are permitted for this prompt only (record this in section 6).

## Work items

### A. Localisation (M02, D-03: English, Hindi, Gujarati at launch)
A1. Set up Flutter localisation with ARB resources for `en`, `hi`, `gu`; wire `supportedLocales`, delegates and a language selector persisted per company or user as the documents specify.
A2. Move every user-visible string in `lib/presentation/**` and shared widgets into resources. Provide Hindi and Gujarati translations for all P1 strings. Mark any string you could not translate with a
translator-review list in the results file; do not machine-guess terms that the glossary requires (use the documented glossary, FR-M02-001). Add a test that fails if a hard-coded user-visible literal is added to a screen
(for example an analyzer-free scan of widget `Text('...')` literals with an allowlist) and a test that every ARB key exists in all three locales.
A3. Number, date and currency formatting through one formatter (paise to rupee display, ISO storage preserved), with tests including Indian digit grouping.
A4. Native-script data entry and search must keep working (existing alias-based search); add tests for Hindi and Gujarati names in party/item search. No automatic transliteration.

### B. More tab
B1. Replace "company create/open only" with the P1 sub-modules the documents assign to More: company switch/create (keep), financial year management (FinancialYearRepository exists), settings and company features
toggles (M01.4), period lock management (PeriodLockRepository), language, about/diagnostics (app version, schema version, test-safe info only), and a clearly labelled backup/restore entry that shows the documented
status and is disabled until device evidence exists. Users/roles (M18/M19), licence/trial (M20) screens are built only if D2's entitlement logic and the documents define their P1 UI; otherwise list them as deferred.
B2. Every screen: loading, empty, validation, locked, success and recoverable-failure states; no raw exception text shown to users (map codes to localised messages).

### C. Robustness and accessibility
C1. `HomeDashboardScreen` must not re-run queries on every rebuild (cache the future in state and refresh explicitly); `IndexedStack` must not run heavy synchronous DB work for all tabs at startup (build tabs lazily).
C2. Add `mounted` checks after awaits where missing; dispose controllers; no `Future.delayed(Duration.zero)` workarounds.
C3. Long lists must not block the UI thread: page or limit queries per the documents; do not invent latency targets.
C4. Accessibility basics: semantic labels for icon-only buttons and the offline badge, minimum 48dp touch targets on primary actions, correct behaviour at 200% text scale (add widget tests at scale 2.0 for the five tab roots and the voucher form), sufficient contrast for status colours.
C5. Android: set the user-visible app label from a localised resource using the owner-approved product name `NiAvERP` (already used by `AppConfig`); do not change the application id.

## Required tests (minimum)
Locale switch widget test (en/hi/gu) on each tab; ARB parity test; formatter tests; native-script search tests; More-tab widget tests over real repositories and a real migrated database; text-scale tests; Home does not
re-query on rebuild test (count queries); lazy-tab test. Final `flutter analyze` clean; all prior tests pass.

## Do not
No new business rules, no schema changes unless a P1 More-tab item cannot work without one (then add the smallest additive migration and say so), no statutory or hardware work, no edits to HTML documents.

## Required output
Write `docs/implementation/RESULT_D4_localisation_more_tab_and_polish.md` using the template in `delta/README.md`, one row per item A1–C5 in section 2, plus a translator-review list and a deferred-features list (with gates) as extra
subsections of section 7. Append to `docs/implementation/RESULTS_INDEX.md`:
`D4 | <date> | <overall status> | tests <passed>/<failed> | <one-line summary>`.
End your final chat message with the Overall status and the path of the results file only.
