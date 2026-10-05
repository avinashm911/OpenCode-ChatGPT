# NiAvERP delta prompts (D1–D4)

These prompts continue the work already produced by `docs/opencode_master_prompts`
(prompts 00–06 were run). They repair defects found in a code review of branch
`niaverp-codebase` (2026-10-05) and close the gaps between the engine and a usable app.
They do NOT replace prompts 07–13; run D1–D4 first, then continue with 07 onward.

## Where to put the files

Copy this folder's four prompt files into `docs/opencode_master_prompts/delta/`.
Each prompt writes its own results file into `docs/implementation/`.

## Order and command (one at a time, from the Flutter project folder)

```powershell
cd "E:\NiavERP v2 OpenAI\niaverp"
opencode run -f ..\docs\opencode_master_prompts\delta\D1_repair_and_production_wiring.md "Execute the attached prompt exactly."
opencode run -f ..\docs\opencode_master_prompts\delta\D2_schema_and_security_hardening.md "Execute the attached prompt exactly."
opencode run -f ..\docs\opencode_master_prompts\delta\D3_invoice_posting_ledger_vouchers_reports.md "Execute the attached prompt exactly."
opencode run -f ..\docs\opencode_master_prompts\delta\D4_localisation_more_tab_and_polish.md "Execute the attached prompt exactly."
```

Do not start the next prompt until you have read the previous results file and its
`Overall status` line is PASS or PASS-WITH-BLOCKS. Do not run it after FAIL.

If `flutter test` fails with the sqlite3 native-assets hook on a path containing a
space (seen on 2026-10-05), run from a no-space drive alias, e.g.
`subst N: "E:\NiavERP v2 OpenAI"` then `cd N:\niaverp`. Record the alias used.

## Results files

| Prompt | Results file |
|---|---|
| D1 | `docs/implementation/RESULT_D1_repair_and_production_wiring.md` |
| D2 | `docs/implementation/RESULT_D2_schema_and_security_hardening.md` |
| D3 | `docs/implementation/RESULT_D3_invoice_posting_ledger_vouchers_reports.md` |
| D4 | `docs/implementation/RESULT_D4_localisation_more_tab_and_polish.md` |

Every prompt also appends one line to `docs/implementation/RESULTS_INDEX.md`.
Send the results file back for review after each run.

## Results file template (every prompt must follow it exactly)

```
# RESULT <Dn> — <title>
Date (UTC): ...   Overall status: PASS | PASS-WITH-BLOCKS | FAIL
## 1. Baseline before changes
(flutter analyze result; flutter test total passed/failed; git HEAD; environment/alias)
## 2. Work-item table
| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
## 3. Changed files (new / modified / deleted, one line each)
## 4. Tests
(added count by file; final total passed/failed; each previously-failing scenario now covered)
## 5. Commands run and exact output summary
## 6. Deviations from the prompt, with reason
## 7. Owner questions (exact source ID + question) and downstream evidence still pending
## 8. Honesty statement
(list anything claimed done that was only tested on host/in-memory; nothing device/legal/statutory may be called PASS)
## 9. Next prompt
```
