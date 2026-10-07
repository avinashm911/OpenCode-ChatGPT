# NiAvERP OpenCode master prompts v1.1

This is the replacement prompt pack. The previous prompt pack was deleted. Run from:

```powershell
cd "E:\NiavERP v2 OpenAI\niaverp"
```

## Mandatory order

1. `00_resume_baseline_and_traceability.SPLIT_INDEX.md` (parts p1of6–p6of6, in order)
2. `01_local_backend_continuation.md`
3. `02_onboarding_and_localisation.md`
4. `03_masters_and_search_continuation.md`
5. `04_voucher_engine_and_orders.md`
6. `05_document_flow_approvals_and_counter.md`
7. `06_inventory_accounting_and_reports.md`
8. `07_import_gst_brs_and_statutory_boundary.md`
9. `08_admin_users_and_licensing.md`
10. `09_security_backup_and_sync_boundary.md`
11. `10_outputs_customisation_and_support.md`
12. `11_frontend_completion.md`
13. `12_hardware_release_and_evidence.md`
14. `13_final_verification_and_gate_report.SPLIT_INDEX.md` (parts p1of5–p5of5, in order)

Run one prompt at a time:

```powershell
opencode run -f ..\docs\opencode_master_prompts\00_resume_baseline_and_traceability.p1of6.md "Execute the attached prompt part 1 of 6; the full prompt is the 6 parts in SPLIT_INDEX order."
```

Do not run the next prompt after FAIL or after a blocked decision affecting that prompt. Every prompt explicitly requires `AGENTS.md` and `DECISIONS.md` first.

## Coverage guarantee

- `TRACEABILITY_MATRIX.md` contains every one of the 431 core IDs extracted from the 15 HTML documents.
- Each ID has exactly one owner prompt and exactly one verification task.
- `STATUS_LEDGER.md` separates deferred, blocked/boundary-blocked and excluded items.
- The final prompt must re-scan the HTML files and fail on any missing, duplicate or newly discovered core ID.

## Regenerate after source changes

From the repository root, run:

```powershell
node tools\generate_prompt_pack_v1.mjs
```

Regeneration is required whenever a living HTML document changes. Review the generated diff before executing prompts.
