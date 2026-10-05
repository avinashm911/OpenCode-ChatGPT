# NiAvERP OpenCode master prompt v1.1 — hardware release and evidence

## Mandatory first actions

1. Read the project-root `AGENTS.md`.
2. Read the project-root `DECISIONS.md`.
3. Read `../GLOBAL_NO_INVENTION_CONTRACT.md`.
4. Read `../BASELINE_AND_MIGRATION_MAP.md`, `../SOURCE_INVENTORY.md`, the relevant slice of `../TRACEABILITY_MATRIX.md`, `../STATUS_LEDGER.md`, `../SOURCE_CLARIFICATIONS.md`, `../g0/PENDING_INPUTS.md`, the relevant living HTML rows and the previous phase report.
5. If either governance file is missing or unreadable, stop with `BLOCKED`.

The existing source and phase reports are part of the working baseline. Do not rebuild completed phases. Verify them, repair only evidence-backed gaps, and continue from the stated next gate.

Never invent fields, posting/tax rules, legal conclusions, package/licence choices, APIs, permissions, workflow states, schemas, performance targets or release channels. Do not edit the 15 HTML documents, workbooks or registers. Preserve standalone/offline-first V1 and all exclusions.

## Required result

Implement only the owned IDs below and only for their permitted priority/gate. For every ID, report its disposition exactly as `implemented`, `boundary`, `deferred`, `blocked` or `excluded`. Add code/tests only for permitted work. End with changed files, commands/results, test results, ID traceability, unresolved questions and the next gate.

## Owned IDs (5)

- `G0-VER-004`
- `G0-VER-006`
- `G0-VER-007`
- `G0-VER-008`
- `OD-FD-006`

### `G0-VER-004` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-004 — Verification evidence missing — R-04 — Evidence still required — owner confirmed action — Owner confirmed: Attach channel limits and a successful APK/ZIP/checksum delivery test. — G5
- **Verification task:** V-G0-VER-004: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `G0-VER-006` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-006 — Verification evidence missing — O-M07 / OD-008 — Evidence still required — owner confirmed action — Owner confirmed: Attach results for the supported ESC/POS/PDF printer matrix. — G5
- **Verification task:** V-G0-VER-006: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `G0-VER-007` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-007 — Verification evidence missing — O-14 / R-13 — Evidence still required — owner confirmed action — Owner confirmed: Attach the reviewed source and the resulting local-only/minimal-collection control mapping. — G5
- **Verification task:** V-G0-VER-007: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `G0-VER-008` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-008 — Verification evidence missing — V-FG-003 — Evidence still required — owner confirmed action — Owner confirmed: Attach target Android test results for backup, restore, share and file-provider behaviour. — G5
- **Verification task:** V-G0-VER-008: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `OD-FD-006` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-FD-006 — Printer compatibility — Freeze supported printer/Android transport matrix. — FR-M21-001
- **Verification task:** V-OD-FD-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html
