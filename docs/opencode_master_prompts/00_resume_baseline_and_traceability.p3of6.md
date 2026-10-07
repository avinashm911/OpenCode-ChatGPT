<!-- Part 3 of 6 of 00_resume_baseline_and_traceability.md — read in order; see 00_resume_baseline_and_traceability.SPLIT_INDEX.md -->
### `G0-CON-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-CON-004 — Body contradiction — SYNC 6 / OD-DB-006 — Decided — Rewrite the body rule once and remove the contradictory alternative. — S1
- **Verification task:** V-G0-CON-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html, NiAv_UX_Specification_v0.2.html


### `G0-CON-005` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-CON-005 — Body contradiction — OD-UI-001 — Decided — Retire the superseded navigation variants in body sections and keep one five-item model. — G0
- **Verification task:** V-G0-CON-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `G0-DEF-001` — Deferred

- **Implementation task:** Do not implement this item in the current release. Record priority not stated and gate G0, and keep it out of active acceptance criteria. Source: G0-DEF-001 — Deferred item — O-FG-006 / A-FG-006 / O-13 — Deferred — R3 — Owner confirmed deferment: Confirm the R3 feasibility gate and evidence required. — R3
- **Verification task:** V-G0-DEF-001: priority/gate ledger confirms deferred status (not stated, G0); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-DEF-002` — Deferred

- **Implementation task:** Do not implement this item in the current release. Record priority not stated and gate G0, and keep it out of active acceptance criteria. Source: G0-DEF-002 — Deferred item — O-FG-007 / O-FG-008 — Deferred — Later release — Owner confirmed deferment: Confirm the later-release gate for TDS/TCS and removal from V1 traceability. — Later release
- **Verification task:** V-G0-DEF-002: priority/gate ledger confirms deferred status (not stated, G0); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `G0-DEF-003` — Deferred

- **Implementation task:** Do not implement this item in the current release. Record priority not stated and gate G0, and keep it out of active acceptance criteria. Source: G0-DEF-003 — Deferred item — O-M08 — Deferred — R2 — Owner confirmed deferment: Confirm the R2 gate and keep automatic transliteration out of V1 acceptance criteria. — R2
- **Verification task:** V-G0-DEF-003: priority/gate ledger confirms deferred status (not stated, G0); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Universal Master Plan v0.2.html, NiAv_UX_Specification_v0.2.html


### `G0-OWN-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-OWN-001 — Owner action required — D-12 — Decided — Confirm single APK with runtime edition gating, or override with the approved flavour model. — G5
- **Verification task:** V-G0-OWN-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html


### `G0-OWN-002` — Excluded

- **Implementation task:** Do not implement this item. Add a negative test proving the excluded capability is not exposed. Preserve the source decision: G0-OWN-002 — Owner action required — OD-UI-003 / FR-M02-002 — Rejected — Rejected — R3
- **Verification task:** V-G0-OWN-002: static scan plus negative UI/domain test confirms the excluded feature is absent.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `O-01` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-01 Native languages at launch Resolved: English, Hindi, Gujarati D-R1
- **Verification task:** V-O-01: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html


### `O-02` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-02 Platforms; offline-first and sync expectations Partly resolved: Android V1 (proposed); offline-first + LAN/hotspot sync D-R5, D-R6; ZCP §6
- **Verification task:** V-O-02: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html


### `O-03` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-09 / O-03 / O-M03 10-second bill benchmark From New Bill to Pay & Finish (cash): <=10 s and <=10 touch interactions; scripted harness + 3 volunteer timings; fixture TD-PERF-01 (5,000 items, 500 parties, 20,000 vouchers) Decided: proposed value G2
- **Verification task:** V-O-03: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UX_Specification_v0.2.html


### `O-04` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-15 / D-R2 / O-04 Meaning of 'Lifetime' yes V1.x patches count as upgrades Decided: owner value Go-live
- **Verification task:** V-O-04: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `O-05` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-04 / O-05 / D-FG-014 Post-expiry behaviour and entitlement matrix 10-day grace with full function + daily reminder, then read-only + export + backup; data never deleted; entitlements.json (edition x term x trial x grace x limits) is single source for gates and tests Decided: proposed value G5
- **Verification task:** V-O-05: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `O-06` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-10 / O-06 / O-15 / OD-007 Simple vs Advanced boundary Simple (R1a): masters, P1 dual+accounting vouchers, Delivery Note, Stock Transfer/Journal, basic quotation/order, Quick Bill, search, core reports, GST reports, Excel import/export, backup, en/hi/gu, 1 device. Advanced (R1b+): all Simple + multi-user/roles, approvals, document-flow automation, Material Issue/Receive, batch/expiry, price lists, multi-godown reports, LAN/hotspot + file sync, audit/admin tools Decided: proposed value G5
- **Verification task:** V-O-06: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `O-07` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-07 / OD-FD-004 / OD-UI-004 Approval scope Single-level approval by amount threshold and voucher type; no parallel; maker may recall before action; dashboard badge + inbox; no push notifications in V1; approval never bypasses posting validation Decided: proposed value R1b
- **Verification task:** V-O-07: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `O-08` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-001 / O-08 Voucher series scope and gap policy Invoice will have limited series, as CA advice on keeping number of invoice series to be minimum Decided: owner value G1
- **Verification task:** V-O-08: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `O-09` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M5 / D-08 / D-FG-013 / O-09 / OD-004 / OD-FD-001 Valuation policy (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock Decided: proposed value G1 G0 Approved design change — implementation required: Approved: Add cost-layer and stock-movement structures plus negative-stock costing/reconciliation rules. G0 Approved design change — implementation required: Approved: Add period-lock entity, rights, unlock reason and audit linkage.
- **Verification task:** V-O-09: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `O-10` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-10 / O-FG-002 / O-FG-003 E-invoice / e-way bill Stay in R3 as JSON export/manual upload (Level 0-4); capture IRN/ack/e-way fields in data model from R1a; GST return JSON stays R1a Decided: proposed value G3 G0 Evidence still required — owner confirmed action: Owner confirmed: Attach official schema/version evidence and update verification logs.
- **Verification task:** V-O-10: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `O-11` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-11 Industry presets In scope; delivered in R2 Decided: proposed value R2
- **Verification task:** V-O-11: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html


### `O-12` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-12 / O-M07 / OD-008 Printing hardware Bluetooth ESC/POS thermal 58 mm and 80 mm + PDF via Android print/share for A4/A5; Indic text rendered as raster image; USB/Wi-Fi printers later; test on >=3 printers; failures visible Decided: proposed value G5 G0 Evidence still required — owner confirmed action: Owner confirmed: Attach results for the supported ESC/POS/PDF printer matrix.
- **Verification task:** V-O-12: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `O-13` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-006 / A-FG-006 / O-13 Tally/Busy native import V1/R2: Excel import with documented templates; native adapters = R3 feasibility; FG-006 marked Deferred Decided: proposed value G4 G0 Deferred — R3: Owner confirmed deferment: Confirm the R3 feasibility gate and evidence required. G0 Decided: Replace V1 native-import promise with the Excel-template boundary.
- **Verification task:** V-O-13: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-14` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-14/R-13 DPDP obligations Official Act source attached; control/legal review pending
- **Verification task:** V-O-14: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html

