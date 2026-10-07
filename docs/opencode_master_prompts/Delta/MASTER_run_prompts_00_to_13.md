# MASTER — Execute master prompts 00–13 in order, with full document reads and detailed phase reports

You are the orchestrator for the NiAvERP prompt pack in `docs/opencode_master_prompts/`. Each time you are invoked you execute
EXACTLY ONE numbered prompt (the next unfinished one), write its detailed phase report, update the master state, and stop.
You never start a second prompt in the same invocation (this keeps context fresh and lets the owner review each report).
Run from `niaverp/` (the Flutter project folder). All `docs/...` paths below are relative to the repository root (`..\docs\...` from `niaverp/`).

## 0. Fixed files

- Pack folder: `docs/opencode_master_prompts/`. Prompt order is the one in its `README.md` "Mandatory order":
  `00_resume_baseline_and_traceability`, `01_local_backend_continuation`, `02_onboarding_and_localisation`, `03_masters_and_search_continuation`,
  `04_voucher_engine_and_orders`, `05_document_flow_approvals_and_counter`, `06_inventory_accounting_and_reports`, `07_import_gst_brs_and_statutory_boundary`,
  `08_admin_users_and_licensing`, `09_security_backup_and_sync_boundary`, `10_outputs_customisation_and_support`, `11_frontend_completion`,
  `12_hardware_release_and_evidence`, `13_final_verification_and_gate_report` (each `.md`). If a file name differs in the folder, use the README order and say so in the report.
- State file: `docs/implementation/MASTER_STATE.md`. Log file: `docs/implementation/MASTER_LOG.md` (append-only).
- Phase report for prompt NN: `docs/implementation/phase-NN.md`. If that file already exists from an earlier run, do NOT edit or overwrite it; write `phase-NN-r2.md`
  (then `-r3`, ...) and cite the earlier report in it. Historical reports are records.

## 1. Step 1 — Read the state and choose the prompt

1. If `MASTER_STATE.md` does not exist, create it with: `Current prompt: 00`, `Status: CONTINUE`, `Started (UTC): <now>`, and an empty table
   `| Prompt | Status | Phase report | Tests (passed/failed) | Blocked items | Date |`.
2. Read it. If `Status` is `STOPPED-FAIL`, `STOPPED-BLOCKED` or `DONE`, do nothing except print the status and the reason, and stop.
3. Otherwise the target is `Current prompt`. Never skip ahead and never re-run a prompt whose row says `COMPLETE` unless the owner changed the state file.

## 2. Step 2 — Mandatory document reads BEFORE any edit (log each read in the phase report with a one-line takeaway)

Read in full unless noted:
1. `niaverp/AGENTS.md` and `niaverp/DECISIONS.md` (if either is missing or unreadable: stop with `BLOCKED`, state `STOPPED-BLOCKED`).
2. `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md` (slices, source-of-truth hierarchy, stop rules, backend rules, evidence strategy, no-invention contract §12).
3. `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `SOURCE_CLARIFICATIONS.md`, `STATUS_LEDGER.md`, `SOURCE_INVENTORY.md`, `BASELINE_AND_MIGRATION_MAP.md` (if present) and `README.md`.
4. `docs/g0/PENDING_INPUTS.md`, and `docs/g0/MIGRATION_DESIGN.md`, `docs/g0/PROJECT_BASELINE.md` when the prompt touches schema, packages or platform.
5. The target prompt file itself, in full.
6. `docs/opencode_master_prompts/TRACEABILITY_MATRIX.md`: read the header and ONLY the rows for the IDs listed under the target prompt's "Owned IDs" (search by ID; do not paste
   the whole 169 KB matrix into context). Do the same for `VERIFICATION_CATALOG.md` (the `V-<ID>` lines of the owned IDs).
7. The relevant rows/sections of the 15 living HTML documents (read-only) for every owned ID: the source files named in the matrix "Source documents" column. Active reconciled rows control;
   historical, change-log and superseded rows are history only. For priority tags: P1 = MVP/launch, P2 = Phase 2, P3 = later; implement P1 only unless the prompt says otherwise.
8. The previous phase report(s): the latest `docs/implementation/phase-*.md` for the previous prompt number (and `RESULT_D*.md`/`TEST_RUN_*.md` if present). If a report the prompt cites is
   missing, say so in the report; never invent its content.
9. The real code state relevant to the owned IDs (grep the tree). Completed work is skipped or repaired, never recreated: do not recreate migrations or screens that exist
   (`lib/data/migrations/` holds the authoritative chain; read `migration_registry.dart` for the latest version).

## 3. Step 3 — Baseline gate

1. Record `git rev-parse --short HEAD` and `git status --short`.
2. Run `flutter analyze` and `flutter test`. If `flutter.bat` is unavailable use the SDK's `flutter_tools.snapshot` via `dart.exe`; if the sqlite3 native-assets hook fails on a path containing a space,
   run from a no-space drive alias (`subst N: "<repo root>"`, then `cd N:\niaverp`). Record the exact invocation.
3. If either is red: do NOT start the prompt's work. Enter BASELINE-REPAIR mode: (a) commit a safety snapshot to a new local branch (`git switch -c baseline-<date>`; `git add -A`; commit; never push, reset or delete);
   (b) classify every failing test as `real-regression` / `broken-helper` / `stale-by-documented-rule` / `environment` / `unknown`, with evidence (follow `docs/opencode_master_prompts/delta/D0_baseline_triage.md`
   sections A–C if that file exists); (c) repair in that order, changing a test assertion only where a documented rule changed (cite the rule) and never skipping or deleting a test; (d) re-run both commands.
   If still red after repair, write the phase report with Overall status `FAIL`, set state `STOPPED-FAIL`, and stop.

## 4. Step 4 — Execute the prompt

Follow the target prompt exactly, together with every rule below (these are the existing rules of the pack and AGENTS.md, restated; they bind every prompt):
- Standalone, offline-first Android V1; minSdk 26. No cloud/server/REST/telemetry. CLI-only Flutter commands.
- Never invent a field, voucher type, posting/tax rule, legal position, package, licence, API, permission, workflow state, schema, performance target or release channel.
  Missing/contradictory required value: stop only the affected item, record exact source ID and owner question, continue independent work.
- Money integer paise; quantity integer ×10^4; no floating point in accounting; round-half-up per D-M4; invoice round-off is its own ledger line; UUIDv7 text IDs; ISO dates; epoch-ms timestamps.
- All writes through application commands in one transaction with company scope, period lock, entitlement/permission checks, audit and operation lineage. Posted history is immutable; corrections are compensating records.
- Vertical slices: schema → repository → use case → UI → tests → evidence. No permanent fake repositories; no business rules in widgets; reuse the shared voucher engine and invoice/report models.
- Migrations: additive, repeat-safe, guarded ADD COLUMN, FK/CHECK, downgrade refusal; update `kLatestVersion`, the registry, `pubspec.yaml` assets and migration tests together.
- Do not edit the 15 HTML documents, decision workbooks or source registers. Do not edit `docs/g0/PENDING_INPUTS.md` except for a dated note when the prompt explicitly allows it.
- Exclusions stay excluded: voice input, native Tally/Busy adapters, TDS/TCS, PF/ESI/payroll, automatic transliteration, direct statutory (e-invoice/e-way/GST) APIs, automated WhatsApp/SMS APIs, cloud backup/relay, in-place APK downgrade.
- Deferred/blocked items keep their gate (R1a, R1b, R2, R3, G1, G3, G5, S1, TBC, VERIFY). Build only the explicitly permitted boundary.
- A mock, host-only, emulator-only, fake-channel or scaffold result is never physical, legal, production or delivery evidence. Never write PASS for device, printer, legal, statutory-schema, Keystore, cipher-licence or release-channel evidence without the real artifact.
- No new pub.dev package unless the prompt names it and the owner approved it in `DECISIONS.md`/`pubspec.yaml`; record every dependency decision.
- For every owned ID report exactly one disposition: `implemented`, `boundary`, `deferred`, `blocked` or `excluded`, with evidence (file:line and test name). Do not claim completion when a test failed.
- Do not silently repair a previous prompt's failed invariant: report it, then fix it in this prompt's report under "Repairs to earlier work".

## 5. Step 5 — Exit gate

1. `flutter analyze` must report no issues; `flutter test` must pass fully (record totals and the delta vs baseline). Every owned ID must have a disposition and, for `implemented`/`boundary`, a passing test.
2. For prompt 13 also run `node tools\verify_prompt_pack_v1.mjs` (or the PowerShell verifier) and the final one-to-one audit it requires; any missing/duplicate/unclassified/newly discovered ID is FAIL; no unconditional sign-off while any active ID is unresolved, blocked or lacks evidence.
3. Decide the outcome:
   - `COMPLETE`: gate green, all owned IDs dispositioned, no blocked item that a later prompt depends on.
   - `COMPLETE-WITH-BLOCKS`: gate green, some owned items are `blocked`/`deferred`, and NONE of them is a prerequisite of a later prompt. List for each blocked item whether later prompts depend on it (yes/no, which).
   - `FAIL`: any gate red, an invariant broken, or an owned ID undispositioned.
   - `BLOCKED-DEPENDENT`: a blocked decision affects a later prompt (README rule: do not run the next prompt after FAIL or after a blocked decision affecting that prompt).

## 6. Step 6 — Detailed phase report `docs/implementation/phase-NN.md` (all sections mandatory)

```
# Implementation Phase NN — <prompt title>
Date (UTC): ...   Prompt: docs/opencode_master_prompts/<file>   Contract: GLOBAL_NO_INVENTION_CONTRACT.md
Outcome: COMPLETE | COMPLETE-WITH-BLOCKS | FAIL | BLOCKED-DEPENDENT      Previous phase report: <path or "missing">
## 1. Document-read log        (every file/section read in Step 2 with a one-line takeaway; list anything unreadable or missing)
## 2. Objective                (what this prompt is for, and which parts were already present in the tree)
## 3. Baseline                 (HEAD, git status summary, analyze result, test totals, invocation/alias, baseline-repair actions if any)
## 4. Owned-ID table           (| ID | Priority/Gate | Disposition | What was done | Evidence file:line | Test name |) — one row per owned ID, none omitted
## 5. Work performed           (grouped by schema / repository / application / UI / platform; what was reused, what was new, what was repaired)
## 6. Repairs to earlier work  (invariants of earlier prompts found broken and fixed, or reported and left)
## 7. Changed files            (NEW / MODIFIED / DELETED, one line each, with migration numbers and trigger/index names)
## 8. Tests                    (added by file and count; totals before/after; negative/denied/restart/atomic-rollback cases covered)
## 9. Commands and environment (exact commands, SDK versions, OS, alias, results)
## 10. Traceability            (REG/FR/FG/OD/DSS/DB/SEC IDs and RTM mapping, V-<ID> verification tasks executed or classified)
## 11. Decisions and blockers  (exact source ID + owner question per blocked item; whether later prompts depend on it)
## 12. Downstream pending evidence (device, Keystore, cipher licence, printers, legal, statutory schemas, release channels — all unclaimed)
## 13. Acceptance checklist    (each exit-gate condition ticked or failed with reason)
## 14. Honesty statement       (anything that is host/in-memory/fake-channel only; nothing physical, legal or statutory called PASS)
## 15. Next gate               (next prompt number, prerequisites, anything the owner must supply first)
```

## 7. Step 7 — Update state and stop

1. Update the table in `MASTER_STATE.md` for this prompt (status, report path, tests, blocked items, date). Set `Current prompt` to the next number only when the outcome is `COMPLETE` or
   `COMPLETE-WITH-BLOCKS`, with `Status: CONTINUE`. After `13` completes set `Status: DONE`. On `FAIL` set `STOPPED-FAIL`; on `BLOCKED-DEPENDENT` set `STOPPED-BLOCKED` and write the owner questions into the state file.
2. Append one line to `MASTER_LOG.md`: `NN | <date> | <outcome> | tests <passed>/<failed> | <one-line summary> | <report path>`.
3. Final chat message (and nothing else): `Prompt NN: <outcome>. Report: <path>. State: <Status>. Next: <NN+1 or reason for stopping>.`

## 8. Never

Never run two numbered prompts in one invocation; never push or reset git history; never delete tests; never edit earlier phase reports; never fabricate a report, test result, evidence record or owner decision;
never mark a blocked item implemented to keep the sequence moving.
