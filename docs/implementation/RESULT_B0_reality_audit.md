# RESULT B0 — Reality audit, schema coverage and backend capability register
Date (UTC): 2026-10-08   Overall status: PASS
Branch: `b0-20261008` (from `bb215de`). B prompt: `docs/opencode_master_prompts/Delta/B0_reality_audit_and_capability_register.md`. Rules: `B_COMMON_RULES.md`.

## 1. Baseline before changes
- `git rev-parse --short HEAD` → `bb215de`; `git status --short` → `M docs/owner/DECISIONS_TO_APPROVE.md` + 17 untracked `docs/opencode_master_prompts/Delta/*` drafts (B-series, not yet run) + `docs/owner/Your_Reply_Completed.docx`. No code edits before audit.
- `flutter analyze --no-pub` (from `niaverp/`, Flutter 3.47.6 / Dart 3.13.5) → `No issues found! (ran in 5.3s)`, exit 0. Evidence: `docs/implementation/evidence/analyze_20261008_b0.txt`.
- `flutter test` (same env) → `+508 ~2: All tests passed!` = 508 passed / 0 failed / 2 skipped (skips = 2 honest cipher-pin BLOCKED placeholders in `cipher_pin_blocked_test.dart`). Exit 0. Evidence: `docs/implementation/evidence/flutter_test_full_20261008_b0.txt`.
- Green baseline: B0 audited normally (§2 of common rules). No figures copied from earlier reports.

## 2. Work-item table
| ID | Item | Status | Evidence |
|---|---|---|---|
| A1 | Capability register, one row per sub-module M01.1–M24.5 | implemented | `docs/implementation/BACKEND_CAPABILITY_REGISTER.md` — 209 rows (194 numbered + 15 M15 unnumbered); conflicts table; per-row status/call-chain/test/gap/owner |
| A2 | Schema coverage vs m001–m018 | implemented | `docs/implementation/SCHEMA_COVERAGE.md` — 28 spec entities present, 18 missing, naming notes; no migrations created |
| A3 | Claims audit phase-04…phase-12 | implemented | §5 below + register; phase-04–12 name zero `test/*.dart` paths (nothing attributable); cross-check trio: `channel_contract_test.dart` MISSING, `wrong_key_opens_time_test.dart` MISSING, `startup_error_state_test.dart` EXISTS |
| A4 | Backend facade inventory + bypass list | implemented | §5 below; `BackendBundle` 27 fields (`composition_root.dart:187-213`); no `application/commands/` dir; all presentation writes are direct `scope.<repo>` calls |
| A5 | Exclusion grep proof | implemented | §5 below; all 9 exclusions ABSENT as implementation (text-only doc mentions: transliteration ×4, WhatsApp ×3, downgrade-guard ×9) |
| A6 | Register summary + recommended order | implemented | table below; order B1–B14 stands (facts only) |

### A6 summary: counts per status per module group (from the register)
| Group | rows | WIRED+TESTED | PARTIAL | ABSENT | BLOCKED | BOUNDARY | DEFERRED | EXCLUDED | ISLAND | CONTRADICTED |
|---|---|---|---|---|---|---|---|---|---|---|
| M01–M04 | 45 | 24 | 8 | 9 | 1 | 0 | 2 | 1 | 0 | 0 |
| M05–M11 | 49 | 28 | 7 | 4 | 0 | 0 | 10 | 0 | 0 | 0 |
| M12–M15 | 44 | 13 | 12 | 13 | 3 | 0 | 3 | 0 | 0 | 0 |
| M16–M17 | 21 | 1 | 1 | 11 | 5 | 0 | 1 | 2 | 0 | 0 |
| M18–M20 | 25 | 3 | 5 | 15 | 0 | 1 | 1 | 0 | 0 | 0 |
| M21–M24 | 25 | 3 | 8 | 8 | 2 | 1 | 3 | 0 | 0 | 0 |
| TOTAL | 209 | 72 | 41 | 60 | 11 | 2 | 20 | 3 | 0 | 0 |
Recommended order: unchanged from `README_B.md` B1–B14. Facts forcing it: B6 must precede B7–B9 (no price/batch/import tables); B1 choke-point + B4 rights must precede command-layer closure of the 30+ direct-write sites (§5-A4); B2 crypto decision gates B3/B12; B10 statutory schemas gate all M16 reports/exports; B13 transport gates M21/M22 device proofs.

## 3. Changed files (new / modified / deleted, one line each)
- NEW `docs/implementation/BACKEND_CAPABILITY_REGISTER.md` (register + conflicts table)
- NEW `docs/implementation/SCHEMA_COVERAGE.md` (present/missing/differing with anchors)
- NEW `docs/implementation/RESULT_B0_reality_audit.md` (this file)
- NEW `docs/implementation/evidence/analyze_20261008_b0.txt` (analyze output)
- NEW `docs/implementation/evidence/flutter_test_full_20261008_b0.txt` (full test output)
- MODIFIED `docs/implementation/phase-04.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-05.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-06.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-07.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-08.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-09.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-10.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-11.md` (one NOTE header line only)
- MODIFIED `docs/implementation/phase-12.md` (one NOTE header line only)
- MODIFIED `docs/implementation/RESULTS_INDEX.md` (append B0 line)
- No code, test, migration, pubspec, Android, ARB or HTML edits. No test weakened or deleted.

## 4. Tests
- Added: none (read-only prompt; forbidden).
- Baseline `flutter test`: 508 passed / 0 failed / 2 skipped (see §1). Matches `bb215de` evidence `flutter_test_full_20261007_intparse.txt` (+508 ~2); `MASTER_STATE.md` §1 still cites stale 501/0/2 (not edited — earlier-result bodies untouched per rule 11).
- 91 test files present (`test/**/*_test.dart` count 91); 83 lib files. Named-trio check: `test/app/startup_error_state_test.dart` EXISTS (contradicts the old "known missing" note — file now exists); the other two named files do not exist and no phase-04–12 row names them, so nothing is marked CONTRADICTED on that basis.

## 5. Commands run and exact output summary
- `git checkout -b b0-20261008` → `Switched to a new branch 'b0-20261008'`; HEAD `bb215de`.
- `..\tools\flutter\bin\flutter.bat analyze --no-pub` → `No issues found! (ran in 5.3s)`, `ANALYZE_EXIT:0`.
- `..\tools\flutter\bin\flutter.bat test` → `00:40 +508 ~2: All tests passed!`, `TEST_EXIT:0`.
- `Select-String TRACEABILITY_MATRIX.md -Pattern "^| M0"` → no `M01.1`-style rows (matrix is keyed by FR/FG/OD/DB/DSS IDs, not register sub-IDs); reconciled gates taken from `STATUS_LEDGER.md` + matrix ID rows instead (recorded per register row).
- Subagent-assisted reads (no edits): modules register → 209 rows; `migration_registry.dart:29-162` chain v1–v18; spec/DB-doc §3 + §G0 tables; `main.dart:43-80` → `startup.dart:194-296` → `composition_root.dart:51-245`; `BackendBundle` fields `:187-213` (27: database, ops, audit, companies, fyYears, accountGroups, ledgers, banks, allocations, periodLocks, parties, items, units, groups, types, godowns, aliases, vouchers, layoutProfiles, links, search, stock, books, outstanding, numbering, engine, flow); application API (`services/voucher_engine.dart:104,223,231,250,265,353,395,684`; `services/document_flow.dart:44,58,69,82,101`; `services/numbering.dart:27,37,65,80,97`; `queries/ledger.dart:135,186,212,271,285,350`; `queries/master_search.dart:43,80,113`; `queries/outstanding.dart:256,260,264,281,368,411,507,571`; `queries/stock_levels.dart:87,118,148,165`; `queries/tax_rates.dart:16`; `tax/gst_posting.dart:63,73,106,163,184`).
- A4 bypasses (all direct, none via application command): `onboarding_screen.dart:90`; `more_tab_screen.dart:174,211,247,277,311,337` + direct SQL `:128`; `parties_items_screen.dart:271,286,311,605,626,650,672`; `voucher_form_screen.dart:283,333,415,436` (+ lawful `402 nextNumber`, `458 postWithStock`); `new_transfer_screen.dart:197,249,277`; `new_stock_journal_screen.dart:214,266,290`; `invoice_view_screen.dart:213,231`; `ledger_voucher_form_screen.dart:296,322`; plus direct-SQL reads `onboarding_screen.dart:60`, `more_tab_screen.dart:128`. No `lib/application/commands/` directory exists.
- A3 per-phase: phase-04: 24 implemented + 1 deferred (FR-M08-003); phase-05: 7 implemented; phase-06: 10 implemented; phase-07: 3 implemented; phase-08: 8 implemented; phase-09: 6 implemented; phase-10: 5 implemented; phase-11: grouped implemented/boundary; phase-12: 1 boundary + 4 BLOCKED. Zero named test paths in all nine files (grep `test/.*\.dart` → 0 hits).
- A5 grep (case-insensitive, `niaverp/lib`): `\bvoice\b` 0, `microphone` 0, speech 0, audio 0; `tally` 0, `\bbusy\b` 0; `\btds\b|\btcs\b` 0; `payroll` 0, pf/esi word 0; `transliterat` 4 doc-comments only (`master_search.dart:7`, `alias_repository.dart:4`, `m009:5,94`); e-invoice/e-way/IRP/dio/http/credentials 0; `whatsapp` 3 doc-comments only (`print/release_delivery.dart:2,5,14`), sms/twilio 0; firebase/supabase/telemetry/analytics/cloud/server/relay 0 (`rest` hits are `restore/restrict/restart` + English `the rest`); `downgrade` 9 refusal-guard docs only (`startup.dart:17,58,254`, `backup.dart:13,155,173`, `niav_database.dart:55,64`, `migration_runner.dart:6` = `no DOWN migrations exist`).

## 6. Deviations from the prompt, with reason
- TRACEABILITY search by register sub-ID (`M01.1`) returns nothing — the v1.1 matrix is keyed by requirement IDs, not register sub-IDs. Used `STATUS_LEDGER.md` + matrix requirement rows for the reconciled column instead; recorded in the register conflicts table. No invention.
- `startup_error_state_test.dart` EXISTS, contrary to the prompt's "known missing" hint (stale from CLAIMS_REVERIFIED_20261007). Recorded as found; the other two named files remain missing but are unnamed by phases 04–12, so no CONTRADICTED row is manufactured.
- Branch is `b0-20261008`, not `b<n>-<date>` from the current branch tip only in name — created from current branch `e3-20261006` per §2 as required.

## 7. Owner questions (exact source ID + question) and downstream evidence still pending
- No new owner questions from B0 (read-only; §5 of common rules not triggered — nothing missing *within* B0's scope).
- Downstream pending (unchanged, single source `BLOCKER_REGISTER.md`): P-SQLIB device remainder, P-DEVICE-8/CUR, P-KEYSTORE, P-FIELD-LIST, P-EINV/GSTR/EWAY-SCH, P-LEGAL-001–005, P-PRN-001–003, P-APK/ZIP-SHA, P-CH-WA/EM/LINK, RELEASE-KEYSTORE secrets, TRANSLATIONS review. B-prompts will add numbered `DECISIONS_TO_APPROVE.md` items only for their own gated values (B1 trial arithmetic … B13 passphrase handling); the nine existing ticks still gate release.

## 8. Honesty statement
- This audit ran on host only: `flutter analyze` + `flutter test` on real encrypted SQLite files in temp dirs (close→reopen, wrong-key, MAC-tamper cases all host). Nothing here is device, printer, legal, statutory-schema or release-channel evidence.
- WIRED+TESTED means reachable from `lib/main.dart` and covered by a passing host test — not production/device proof. PARTIAL/ABSENT rows (notably all of M17 import, M18.1/M18.3–M18.5/M19/M20.3–M20.4 licence/activation, M10 approvals, batch/price-list, P&L/Balance Sheet, report export, PDF/ESC-POS transport, sync transport, restore flow) are stated as such; no fake PASS.
- `PENDING_INPUTS.md` untouched. No HTML/workbook/register edited. Phase bodies untouched except the one-line NOTE headers.

## 9. Next prompt
- Next: `docs/opencode_master_prompts/Delta/B1_entitlement_clock_and_write_choke_point.md` on a fresh branch from `b0-20261008`, consuming this register (B1 owns the single write choke-point that §5-A4 proves missing).
- Do not run B2–B14 until B1 passes (README_B order + §10 result rule).
