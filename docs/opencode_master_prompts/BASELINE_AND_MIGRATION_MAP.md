# v1.1 continuation baseline and prompt migration map

The source tree is not empty. OpenCode must continue from these verified phase
reports and must not rebuild completed work:

- `docs/implementation/phase-00.md`: shell/value objects complete; +107 tests.
- `docs/implementation/phase-01.md`: engine-neutral database/repository foundation complete; +128 cumulative tests; encrypted production wiring remains blocked by P-SQLIB/P-KEYSTORE.
- `docs/implementation/phase-02.md`: M03 masters, onboarding/Parties & Items foundation and search slice complete; +166 cumulative tests; placeholder shell wiring and later-gate features remain open.

The next implementation gate is local-backend continuation and then the next
unfinished slice. Each prompt must inspect the previous report and skip or
repair completed work rather than recreate migrations or screens.

## Migration from deleted v0.9 prompt names

Historical reports may mention the deleted v0.9 paths. Use this mapping:

| Historical prompt | v1.1 continuation prompt |
|---|---|
| 00_intake_and_architecture.md | 00_resume_baseline_and_traceability.md |
| 01_local_backend_foundation.md | 01_local_backend_continuation.md |
| 02_masters_and_search.md | 03_masters_and_search_continuation.md |
| 02A_onboarding_and_localisation.md | 02_onboarding_and_localisation.md |
| Remaining v0.9 prompts | Matching v1.1 numbered prompt after source/priority/gate review |

The reports remain historical records and must not be rewritten merely to
replace old prompt filenames.
