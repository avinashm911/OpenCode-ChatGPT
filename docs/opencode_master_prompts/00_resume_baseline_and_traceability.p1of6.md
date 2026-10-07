<!-- Part 1 of 6 of 00_resume_baseline_and_traceability.md — read in order; see 00_resume_baseline_and_traceability.SPLIT_INDEX.md -->
# NiAvERP OpenCode master prompt v1.1 — resume baseline and traceability

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

## Resume/baseline directive

This is a read-only intake and continuation plan. Compare the current tree with phase-00, phase-01 and phase-02 reports; record what is complete, what is genuinely missing and the next executable gate. Do not rebuild code or migrations in this prompt.

## Owned IDs (114)

- `A-07`
- `D-01`
- `D-02`
- `D-03`
- `D-04`
- `D-05`
- `D-06`
- `D-07`
- `D-08`
- `D-09`
- `D-10`
- `D-11`
- `D-12`
- `D-13`
- `D-14`
- `D-15`
- `D-16`
- `D-M1`
- `D-M2`
- `D-M3`
- `D-M6`
- `D-M7`
- `DSS-O03`
- `DSS-O04`
- `DSS-O05`
- `FR-M01`
- `FR-M02`
- `FR-M03`
- `FR-M04`
- `FR-M05`
- `FR-M06`
- `FR-M08`
- `FR-M10`
- `FR-M11`
- `FR-M12`
- `FR-M14`
- `FR-M16`
- `FR-M17`
- `FR-M18`
- `FR-M21`
- `FR-M22`
- `G0-CON-001`
- `G0-CON-002`
- `G0-CON-003`
- `G0-CON-004`
- `G0-CON-005`
- `G0-DEF-001`
- `G0-DEF-002`
- `G0-DEF-003`
- `G0-OWN-001`
- `G0-OWN-002`
- `O-01`
- `O-02`
- `O-03`
- `O-04`
- `O-05`
- `O-06`
- `O-07`
- `O-08`
- `O-09`
- `O-10`
- `O-11`
- `O-12`
- `O-13`
- `O-14`
- `O-15`
- `O-FG`
- `O-FG-001`
- `O-FG-002`
- `O-FG-003`
- `O-FG-005`
- `O-FG-006`
- `O-FG-007`
- `O-FG-008`
- `O-FG-009`
- `O-FG-010`
- `O-FG-011`
- `O-FG-012`
- `O-FG-013`
- `O-FG-014`
- `O-FG-015`
- `O-M`
- `O-M01`
- `O-M02`
- `O-M03`
- `O-M04`
- `O-M05`
- `O-M06`
- `O-M07`
- `O-M08`
- `O-XX`
- `REG-ACCT`
- `REG-IMPORT`
- `REG-M01`
- `REG-M02`
- `REG-M03`
- `REG-M04`
- `REG-M05`
- `REG-M08`
- `REG-M10`
- `REG-M11`
- `REG-M12`
- `REG-M14`
- `REG-M17`
- `REG-M18`
- `REG-M21`
- `REG-SEC`
- `REG-STK`
- `REG-SYNC`
- `REG-UX`
- `RTM-O01`
- `RTM-O02`
- `RTM-O03`
- `RTM-O04`

### `A-07` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: A-R6 Owner is the sole developer; scope must be deliverable by one person using AI and free tools (ZCP A-07) Active Phasing (Section 28)
- **Verification task:** V-A-07: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html


### `D-01` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-01 — Framework — Decided: Flutter/Dart, CLI-built — Section 4
- **Verification task:** V-D-01: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-02` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-02 — Multi-user scope in V1 — Decided: offline-first + LAN/hotspot sync, staged via file merge — Section 6
- **Verification task:** V-D-02: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-03` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-03 — Launch languages — Decided: English, Hindi, Gujarati — Extensible via ARB
- **Verification task:** V-D-03: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-04` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-04 / O-05 / D-FG-014 — Post-expiry behaviour and entitlement matrix — 10-day grace with full function + daily reminder, then read-only + export + backup; data never deleted; entitlements.json (edition x term x trial x grace x limits) is single source for gates and tests — Decided: proposed value — G5
- **Verification task:** V-D-04: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `D-05` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-05 / D-R5 — Android-only V1 — Accepted: Android-only V1 — Decided: proposed value — G0
- **Verification task:** V-D-05: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-06` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-06 — Android Keystore Android 8 — Official API source attached; device test pending
- **Verification task:** V-D-06: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `D-07` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-07 — Relax Rs0 rule later — V1 stays Rs0; server / Play Store / e-invoice provider reviewed only at V2 after revenue — Decided: proposed value — V2
- **Verification task:** V-D-07: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-08` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M5 / D-08 / D-FG-013 / O-09 / OD-004 / OD-FD-001 — Valuation policy — (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock — Decided: proposed value — G1
- **Verification task:** V-D-08: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `D-09` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-09 / O-03 / O-M03 — 10-second bill benchmark — From New Bill to Pay & Finish (cash): <=10 s and <=10 touch interactions; scripted harness + 3 volunteer timings; fixture TD-PERF-01 (5,000 items, 500 parties, 20,000 vouchers) — Decided: proposed value — G2
- **Verification task:** V-D-09: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UX_Specification_v0.2.html


### `D-10` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-10 / O-06 / O-15 / OD-007 — Simple vs Advanced boundary — Simple (R1a): masters, P1 dual+accounting vouchers, Delivery Note, Stock Transfer/Journal, basic quotation/order, Quick Bill, search, core reports, GST reports, Excel import/export, backup, en/hi/gu, 1 device. Advanced (R1b+): all Simple + multi-user/roles, approvals, document-flow automation, Material Issue/Receive, batch/expiry, price lists, multi-godown reports, LAN/hotspot + file sync, audit/admin tools — Decided: proposed value — G5
- **Verification task:** V-D-10: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `D-11` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-11 / D-13 / A-R2 — Trial edition — Trial 3 months, full feature set of installed release (R1a = Simple features; R1b+ = Advanced). On trial end buying Simple keeps Advanced data read-only/exportable — Decided: proposed value — G5
- **Verification task:** V-D-11: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-12` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-12 — Single APK vs flavours — Single APK with runtime edition gating — Pending — G5
- **Verification task:** V-D-12: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html


### `D-13` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-11 / D-13 / A-R2 — Trial edition — Trial 3 months, full feature set of installed release (R1a = Simple features; R1b+ = Advanced). On trial end buying Simple keeps Advanced data read-only/exportable — Decided: proposed value — G5
- **Verification task:** V-D-13: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-14` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-14 — Monthly licence model — Prepaid keys carrying an expiry date (1/3/6/12 months or lifetime); no monthly re-issue — Decided: proposed value — G5
- **Verification task:** V-D-14: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `D-15` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-15 / D-R2 / O-04 — Meaning of 'Lifetime' — yes V1.x patches count as upgrades — Decided: owner value — Go-live
- **Verification task:** V-D-15: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `D-16` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-16 — Optional online time check — Optional and opportunistic: used only to detect clock rollback when online; never required — Decided: proposed value — G5
- **Verification task:** V-D-16: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-M1` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M1 — MPL is the apex plan; precedence rule in the control block — Proposed
- **Verification task:** V-D-M1: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `D-M2` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M2 / D-M3 / O-M05 — Release train — R1a (Simple, single device) then R1b (Advanced, multi-device); if S2/S3 slip, R1b ships with file merge, LAN sync as R1b.1 — Decided: proposed value — G6
- **Verification task:** V-D-M2: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html

