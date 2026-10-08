# RESULT B1 — Entitlement clock and write choke point
Date (UTC): 2026-10-08   Overall status: PASS
Branch: `b1-20261008` (from `1e6d7c9`). B prompt: `docs/opencode_master_prompts/Delta/B1_entitlement_clock_and_write_choke_point.md`. Rules: `B_COMMON_RULES.md`.

## 1. Baseline before changes
- `git rev-parse --short HEAD` → `1e6d7c9` (B0 committed); `git status` clean except pre-existing owner/draft files.
- `flutter analyze --no-pub` → `No issues found!`, exit 0 (`docs/implementation/evidence/analyze_20261008_b1_base.txt`).
- `flutter test` → `+508 ~2: All tests passed!` (508 passed / 0 failed / 2 skipped), exit 0 (`docs/implementation/evidence/flutter_test_full_20261008_b1_base.txt`).
- Green baseline: implementation proceeded.

## 2. Work-item table
| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | Trial start: anchor row per company + app-private copy beside device_id; earliest-wins; new companies inherit install start | implemented | `lib/data/security/trial_service.dart` (`TrialService.ensureCompanyAnchor`), `lib/data/security/trial_store.dart` (`TrialFileStore`), `lib/data/repositories/company_repository.dart:75` (same-tx anchor), `lib/app/startup.dart` (4b install-file ensure) ; `trial_service_test.dart` (anchor lifecycle, file-wins, R1 named ×2) |
| A2 | Trial end = start + 3 months; ONE month function + proposal; entitlements.json with approved cells only | implemented (proposal) | `trial_service.dart: `trialEndsAtMs`` (+`kTrialMonths`), `niaverp/entitlements.json`, DECISIONS.md P-TRIAL-END, `docs/owner/DECISIONS_TO_APPROVE.md` §10 ; `trial_service_test.dart` (5 arithmetic cases incl. clamp/leap, JSON parity) |
| A3 | Clock guard in runStartup + company open/switch; observation on facade; rollback audit; typed diagnostics | implemented / boundary | `trial_service.dart: observeAndGuard`, `composition_root.dart: guardCompanyOpen`, `startup.dart` (4b per-company guard) ; `trial_service_test.dart` (rollback warns/trusted/audits/writes-allowed, switch re-observes). BOUNDARY: `openCompany` widget not wired (no widgets in B; see UI_HANDOFF_B1.md) — backend method ready |
| A4 | Entitlement facade queries | implemented | `composition_root.dart: entitlementState/daysLeft/reminderDue/clockWarning/exportBackupAllowed` ; `trial_service_test.dart` (facade queries) |
| A5 | ONE write choke point + B4 permission hook | implemented | `lib/data/repositories/repository.dart: EntitlementGate + ctx.gate`, `lib/data/repositories/audit_log.dart: recordLineage gate check`, `trial_service.dart: TrialWriteGate/WritePermission/AllowAllPermission` ; `write_gate_test.dart` (31/31 commands × 4 states) |
| A6 | Denylist hash-only lookup, no key format invented | implemented | `trial_service.dart: isDenied/installKeyHash` (sha256(deviceId) preimage documented; B5 replaces) ; `trial_service_test.dart` + `write_gate_test.dart` (denied state) |
| Tests | Through CompositionRoot.backend on real encrypted file + close/reopen + denied/invalid + atomic rollback | implemented | `write_gate_test.dart` (encrypted-file group, residue test, D-04 reads test) |
| Output | RESULT + UI_HANDOFF + register rows | implemented | `RESULT_B1_entitlement_clock_choke_point.md` (this file), `docs/implementation/UI_HANDOFF_B1.md`, register M20.1/M20.2/M20.6/M22.4 |

## 3. Changed files (new / modified / deleted, one line each)
- NEW `niaverp/lib/data/security/trial_service.dart` (anchors, evaluation, gate, guard, facade logic, month arithmetic)
- NEW `niaverp/lib/data/security/trial_store.dart` (write-once install copy, typed errors)
- NEW `niaverp/entitlements.json` (trial/grace approved cells; edition/limit BLOCKED)
- NEW `niaverp/test/data/security/trial_service_test.dart` (15 tests)
- NEW `niaverp/test/data/security/write_gate_test.dart` (7 tests incl. 31-command table)
- NEW `docs/implementation/UI_HANDOFF_B1.md`
- NEW `docs/implementation/RESULT_B1_entitlement_clock_choke_point.md` (this file)
- NEW `docs/implementation/evidence/analyze_20261008_b1_base.txt`, `flutter_test_full_20261008_b1_base.txt`, `analyze_20261008_b1.txt`, `flutter_test_full_20261008_b1.txt`
- MODIFIED `niaverp/lib/data/repositories/repository.dart` (EntitlementGate, ctx.gate, ctx.trialFiles)
- MODIFIED `niaverp/lib/data/repositories/audit_log.dart` (choke check in recordLineage)
- MODIFIED `niaverp/lib/data/repositories/company_repository.dart` (same-tx anchor via TrialService)
- MODIFIED `niaverp/lib/app/composition_root.dart` (TrialService + gate wiring, bundle.trial, 6 facade members)
- MODIFIED `niaverp/lib/app/startup.dart` (install-file ensure + per-company guard)
- MODIFIED `niaverp/DECISIONS.md` (P-TRIAL-END proposal row)
- MODIFIED `docs/owner/DECISIONS_TO_APPROVE.md` (§10 addition only; existing ticks untouched)
- MODIFIED `niaverp/test/security/clock_rollback_test.dart` (repair: UPDATE fixture row — see §6)
- MODIFIED `docs/implementation/BACKEND_CAPABILITY_REGISTER.md` (M20.1/M20.2/M20.6/M22.4 rows only)
- MODIFIED `docs/implementation/RESULTS_INDEX.md` (append B1 line)
- No migration, pubspec, Android, ARB, HTML or workbook edits. No test weakened or deleted.

## 4. Tests
- Added: 22 tests in 2 files (15 trial_service + 7 write_gate; the table covers all 31 public write commands in 4 states).
- Repaired: 6 `clock_rollback_test.dart` setup collisions (see §6); zero behaviour change (same anchor window).
- Final: `flutter test` → `+530 ~2: All tests passed!` (530 passed / 0 failed / 2 skipped — 508 baseline + 22 new, skips unchanged).
- `flutter analyze` → `No issues found!` (`docs/implementation/evidence/analyze_20261008_b1.txt`).
- Previously failing scenarios now covered: expired/denied refusal per command with `entitlement` code; no-residue atomic rollback; close/reopen persistence on encrypted file; R1 residuals by name; rollback audit + trusted time.

## 5. Commands run and exact output summary
- `git checkout -b b1-20261008` (from `1e6d7c9`); B0 committed first (`1e6d7c9`).
- `flutter analyze --no-pub` (base) → clean; (final) → clean.
- `flutter test` (base) → 508/0/2; (final) → PENDING.
- Grep re-verification of B1 known facts before edit: `evaluateEntitlement/canWrite/canExportBackup/needsExpiryReminder/observeDeviceClock` uncalled in lib (definition sites only); no production `trial_anchor` writer; `observeDeviceClock` updates existing rows only.
- Full-suite regression from the CompanyRepository change caught 6 setup failures in `clock_rollback_test.dart` (UNIQUE company_id); repaired in-test, re-run green.

## 6. Deviations from the prompt, with reason
- `CompanyScope.openCompany` widget NOT edited: B prompts build backend only (§9 UI handoff). The backend exposes `guardCompanyOpen`; `UI_HANDOFF_B1.md` assigns the one-line shell wiring to the UI series. Recorded as boundary, not silently skipped.
- `RepositoryContext.gate` defaults to null (allow-all) instead of required: 90+ existing test constructions keep compiling; production always wires the enforcing gate in `CompositionRoot.backend`. The choke is proven enforced through production wiring (write_gate tests).
- Repairs to earlier work (not silent): `clock_rollback_test.dart` setup INSERT→UPDATE (B1 anchor side-effect; same window, behaviour unchanged).
- Trial-file failure degrades to anchor-only enforcement (documented R1 residual) instead of a new startup-failure stage: avoids inventing UI states; gap stays queryable via `trial.fileCopyUsable`.

## 7. Owner questions (exact source ID + question) and downstream evidence still pending
- P-TRIAL-END (new §10 tick): is trial end = install start + 3 calendar months (UTC, day clamped)? Downstream: none (implementation complete behind proposal).
- Unchanged downstream: B5 licence-key format (denylist preimage now sha256(deviceId)); B4 rights model (AllowAllPermission placeholder); translator/legal/device/printer/release evidence per BLOCKER_REGISTER.md.
- `PENDING_INPUTS.md` untouched. No new physical/legal/statutory claims.

## 8. Honesty statement
- Host-only verification (in-memory SQLite + one real encrypted temp-file open/close/reopen through CipherDatabaseOpener). No device, Keystore, printer, legal, statutory or release evidence claimed.
- The choke is proven on production wiring paths (`CompositionRoot.backend`, `runStartup` guard code, real `recordLineage` funnel — 32 call sites, zero bypasses found by grep), not on a mock gate.
- `entitlements.json` edition/limit cells are explicitly BLOCKED, never defaulted. The trial month arithmetic is labelled PROPOSAL everywhere it appears.

## 9. Next prompt
- Next: `docs/opencode_master_prompts/Delta/B2_crypto_primitives_decision_gate.md` on a fresh branch from `b1-20261008` (needs B1's TrialService/file handling for KDF-wrapped key decisions).
- Do not run B3–B14 until B1 passes.
