# v1.1 status ledger

## Deferred

- `FG-006` — FG-006 — Tally/Busy native-file import — NIAV-REG M17.11; NIAV-ZCP M17 — Partial / Verify — Direct native import deferred to R3 feasibility; V1 Excel-template import is targeted only for validated formats and representative sample files. — Versions and native formats vary; supported coverage is undefined.
- `FG-007` — FG-007 — TDS/TCS statutory files — NIAV-REG M16; NIAV-ZCP M16 — Gap / Verify — TDS/TCS is deferred to a later release; no V1 implementation or file workflow is permitted. — Large statutory scope and high error cost.
- `FR-M03-008` — Optional batch/expiry input shall capture batch number, manufacturing date and expiry date where batch/expiry is enabled.
- `FR-M03-009` — Price-list input shall support multiple lists, party-wise applicability and effective-date pricing.
- `FR-M08-003` — Purchase quotation input shall record supplier quotes; comparison is deferred unless accepted.
- `FR-M10-001` — Approval-matrix input shall define rules by document type, series, amount threshold, party, branch and user/role.
- `FR-M10-002` — Approvers shall be able to approve, reject with remarks, send back or recall applicable documents.
- `FR-M13-002` — Physical-stock count input shall capture counted quantity and variance for stock-journal posting.
- `FR-M14-003` — Payment reminder preparation shall generate reminder text and/or statement artifacts for user-mediated sharing.
- `FR-M20-002` — The customer-facing payment workflow shall not require in-app payment in V1; payment evidence is handled externally before licence issuance if that workaround is adopted.
- `FR-M24-001` — Support input shall allow users to view in-app help/guides and initiate support through existing WhatsApp/email channels.
- `G0-DEF-001` — G0-DEF-001 — Deferred item — O-FG-006 / A-FG-006 / O-13 — Deferred — R3 — Owner confirmed deferment: Confirm the R3 feasibility gate and evidence required. — R3
- `G0-DEF-002` — G0-DEF-002 — Deferred item — O-FG-007 / O-FG-008 — Deferred — Later release — Owner confirmed deferment: Confirm the later-release gate for TDS/TCS and removal from V1 traceability. — Later release
- `G0-DEF-003` — G0-DEF-003 — Deferred item — O-M08 — Deferred — R2 — Owner confirmed deferment: Confirm the R2 gate and keep automatic transliteration out of V1 acceptance criteria. — R2
- `M10` — M10 — Approval Matrix & Workflows [U10] — P2
- `M24` — M24 — Utilities & Support — P2

## Blocked or boundary-blocked

- `FG-002` — FG-002 / 003 / 004 — Statutory schema verification — Verify GST/e-invoice/e-way schemas from official sources; record in verification logs — Decided: owner value — G1
- `FG-003` — FG-003 — E-way bill — NIAV-REG M16; NIAV-ZCP §11 — Partial — JSON preparation, user-mediated upload and result import are targeted; direct API is separate. — Bulk/consolidated and response variants may differ by workflow/version.
- `FR-M16-003` — GST return/export preparation shall produce the locally generated file/data required by the supported workflow, with schema version recorded.
- `FR-M16-004` — E-invoice/e-way input adapters shall prepare locally validated payload data and support user-mediated submission and response/result import when the verified format is available.
- `G0-VER-001` — G0-VER-001 — Verification evidence missing — V-FG-001 / D-06 — Evidence still required — owner confirmed action — Owner confirmed: Attach official library/version/licence and Android 8 compatibility evidence. — G0
- `G0-VER-002` — G0-VER-002 — Verification evidence missing — GST rounding / D-M4 — Evidence still required — owner confirmed action — Owner confirmed: Attach the rule source and a passing golden rounding fixture. — G0
- `G0-VER-003` — G0-VER-003 — Verification evidence missing — V-FG-001 / O-FG-002/O-FG-003 — Evidence still required — owner confirmed action — Owner confirmed: Attach official schema/version evidence and update verification logs. — G3
- `G0-VER-004` — G0-VER-004 — Verification evidence missing — R-04 — Evidence still required — owner confirmed action — Owner confirmed: Attach channel limits and a successful APK/ZIP/checksum delivery test. — G5
- `G0-VER-005` — G0-VER-005 — Verification evidence missing — D-06 / SEC §5 — Evidence still required — owner confirmed action — Owner confirmed: Attach Android 8 Keystore test result and key-wrap behaviour. — G0
- `G0-VER-006` — G0-VER-006 — Verification evidence missing — O-M07 / OD-008 — Evidence still required — owner confirmed action — Owner confirmed: Attach results for the supported ESC/POS/PDF printer matrix. — G5
- `G0-VER-007` — G0-VER-007 — Verification evidence missing — O-14 / R-13 — Evidence still required — owner confirmed action — Owner confirmed: Attach the reviewed source and the resulting local-only/minimal-collection control mapping. — G5
- `G0-VER-008` — G0-VER-008 — Verification evidence missing — V-FG-003 — Evidence still required — owner confirmed action — Owner confirmed: Attach target Android test results for backup, restore, share and file-provider behaviour. — G5
- `OD-DB-003` — OD-DB-003 — Detailed GST/statutory table fields — Effective-dated, data-driven rate/HSN tables; statutory fields after schema verification — Decided: owner value — G1
- `OD-FD-002` — OD-FD-002 — Statutory adapters — Verify current schemas, applicability and response formats before adapter sign-off. — FR-M16-003/004

## Excluded

- `FG-008` — FG-008 — PF/ESI statutory files — NIAV-REG M16; NIAV-ZCP M16 — Out of scope — PF/ESI and payroll are out of scope for V1; full payroll remains out of scope. — Prerequisite employee/payroll data model is undefined.
- `FR-M02-002` — Rejected by owner; no R3 gate
- `G0-OWN-002` — G0-OWN-002 — Owner action required — OD-UI-003 / FR-M02-002 — Rejected — Rejected — R3
- `OD-UI-003` — OD-UI-003 / FR-M02-002 — Voice input feasibility — Rejected by owner; no R3 gate — Rejected: owner rejected voice input for V1 — R3

An item may move from blocked/deferred only when the exact source decision or evidence is supplied. No prompt may convert these statuses into PASS by assumption.
