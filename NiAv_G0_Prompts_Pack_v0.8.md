# NiAvERP G0 Phase-wise Prompts Pack

Version: v0.8  
Purpose: prompts for OpenCode CLI using a free model  
Baseline: NiAvERP standalone Android APK, offline-first accounting baseline, with server/cloud capabilities only where explicitly marked future phase.

Change from v0.6: a missing owner input no longer halts the run. The affected item is recorded as PENDING-INPUT, all independent work continues, and ready-to-run scaffolding is produced so the item can be closed later. Nothing is ever marked PASS without real evidence, and unconditional sign-off remains impossible while any item is PENDING-INPUT or FAIL.

## How to use this pack

Run the phases in order, Phase 0 to Phase 8. A phase may be started when the previous phase is COMPLETE or PARTIAL (only PENDING-INPUT items outstanding). Do not start the next phase if the previous phase has any FAIL item.

Each prompt is intentionally explicit because the CLI must create the implementation from the approved documents rather than assume an existing codebase.

The attached NiAvERP HTML documents and the G0 exception/evidence registers are the only requirements authority. The confirmed implementation baseline is Flutter/Dart, Drift over encrypted SQLite using a SQLCipher-class approach, minSdk 26 / Android 8, CLI-only build and test, integer paise for money, and integer quantity units of quantity ×10^4. If a requirement is missing, contradictory, or technically ambiguous, record the item as PENDING-INPUT with the exact decision needed. Do not invent accounting, tax, security, sync, permission, or release policy.

## Status vocabulary (used by every phase)

| Item status | Meaning |
|---|---|
| PASS | Required evidence exists and is saved. The command, environment and result are recorded. |
| FAIL | A test ran and failed, or an invariant is violated. Must be fixed before the next phase. |
| PENDING-INPUT | A named owner input, device, reviewer, schema source or physical test is missing. Scaffolding is complete; the item cannot be closed yet. |
| DEFERRED | The owner has deferred the item with a recorded gate (for example G0-DEF-004). Not counted as passed. |

| Phase status | Meaning |
|---|---|
| COMPLETE | Every item is PASS or DEFERRED. |
| PARTIAL | No FAIL, but at least one item is PENDING-INPUT. The run continues. |
| FAIL | At least one item is FAIL. |

## Owner inputs that close PENDING-INPUT items

None of these stops the run. Each one converts the listed items from PENDING-INPUT to PASS once supplied. Until then, the model builds everything else.

| Owner input | Affects | What the model does meanwhile |
|---|---|---|
| Approved IRN, acknowledgement and e-way field list (or the G0-DEF-004 deferral) | Phase 4 | Creates no columns. Records official schema sources as unconfirmed. Closes as DEFERRED if G0-DEF-004 exists. |
| Official e-invoice and GST return JSON schema source/version | Phase 4 | Records sources as unconfirmed pointers only. |
| Frozen printer model matrix (OD-FD-006), at least three printers | Phase 6 | Builds ESC/POS and PDF renderers with host-side golden tests and a printer test sheet. |
| Named legal reviewer and review date for O-14/R-13 | Phase 5 | Produces a DRAFT control map marked "not a legal review." |
| Android 8 device and a current-Android device | Phase 3 | Builds device tests and a manual procedure with a result template. |
| Confirmed SQLCipher-class library, version and licence evidence | Phase 0, 3 | Records the library as a candidate; licence status stays VERIFY. |
| A real WhatsApp/email delivery test | Phase 6 | Computes and verifies checksums locally; channel delivery stays PENDING-INPUT. |

## Global instructions to include in every prompt

```text
You are implementing NiAvERP as a greenfield standalone Android APK.

Read all supplied NiAvERP documents before coding. Treat the approved G0 reconciliation sections and the latest owner decisions as authoritative. Preserve unresolved or execution-pending items as explicit PENDING-INPUT items.

Rules:
1. Do not invent requirements, tax rules, accounting policy, permissions, sync conflict rules, or security behavior.
2. Do not add server/cloud dependencies to the standalone APK baseline.
3. Do not replace an approved decision with a convenient default.
4. Keep migrations deterministic, idempotent, auditable and recoverable via the approved rollback procedure. In-place downgrade is not supported.
5. Store money as integer paise. Store quantities as integer quantity ×10^4. Use round-half-up for line amounts. Record invoice round-off as a separate ledger line under D-M4.
6. Every implementation change must have tests, fixtures, traceability IDs, and a short change log.
7. Never claim a test passed without showing the command, environment, result, and saved evidence.
8. On missing information, do NOT stop the run. For the affected item only: do not implement the part that depends on the missing input, do not invent a substitute, record the item as PENDING-INPUT with the exact missing decision/evidence, the affected IDs and the smallest proposed owner question, then complete all independent work and continue.
9. Work only inside the supplied project directory. Do not rewrite unrelated files. Never edit the requirements documents (HTML), workbooks or registers; they are read-only inputs.
10. Before finishing, report changed files, commands run, tests passed/failed/pending, known limitations, and next gate.
11. Do not build these excluded capabilities: voice input (rejected); Tally/Busy native import (R3 feasibility only); TDS/TCS (later release); PF/ESI or payroll (out of scope); automatic transliteration (R2); direct e-invoice/e-way APIs.
12. LAN/hotspot and file-based sync remain in scope at gate S1. This pack covers only the G0 schema versioning fields for sync, not the complete sync implementation.
13. Project gates remain distinct: G0 is this acceptance baseline; each item retains its own gate such as G1, G3, G5 or S1.
14. Use only the status vocabulary PASS, FAIL, PENDING-INPUT, DEFERRED for items, and COMPLETE, PARTIAL, FAIL for phases.
15. Never fabricate evidence. Never mark a device, printer, legal, channel or schema item PASS from a simulation, a mock, a memory of a version number, or an assumption. A host-side test proves only what it runs on; say so in the evidence.
16. For every PENDING-INPUT item, leave behind the scaffolding needed to close it: the test code or procedure, an evidence template, and the exact command or step the owner must run.
```

## Phase 0 — Project intake and controlled baseline

```text
Apply the global instructions.

Create the greenfield project using the confirmed baseline. Scaffold with Flutter/Dart and CLI-only commands. Configure minSdk 26 / Android 8, Drift over encrypted SQLite using a SQLCipher-class approach, integer paise and quantity ×10^4. Do not invent an unapproved application build structure. Then inventory:
- Flutter/Dart and build-tool versions;
- database engine and encryption approach;
- source documents and their versions;
- current project structure, if any;
- Riverpod, go_router, PDF, Excel, barcode and ESC/POS packages as unverified candidates only; do not lock them in until the owner confirms them;
- SQLCipher-class library licence as VERIFY / PENDING-INPUT until the owner confirms the library and licence evidence;
- existing tests, fixtures, migration files and CI commands.

Create `docs/g0/PROJECT_BASELINE.md` containing the inventory and a requirement-to-file map.

If an implementation project is absent, create the project with `flutter create` and document the exact command and versions. Do not choose a different stack. Do not implement business features in this phase.

Acceptance:
- the confirmed stack is scaffolded and inventory is complete;
- every implementation assumption is labelled as confirmed or PENDING-INPUT;
- no source document is silently superseded.
```

## Phase 1 — Schema delta and migration design

```text
Apply the global instructions.

Implement the approved seven G0 schema changes. First produce a migration design and review it against DB/DSS. Then create versioned migration files.

Required deltas:
G0-SCH-001: cost-layer and stock-movement structures for FIFO/weighted-average costing, including negative-stock fallback and later reconciliation.
G0-SCH-002: period-lock entity with date range, scope, status, authorised unlock actor, reason, timestamp and audit linkage.
G0-SCH-003: bill-allocation entity with source voucher line, settlement voucher line, allocated amount, date, status and operation lineage.
G0-SCH-004: effective-dated tax/HSN profile data and versioned layout-profile data with sync and backup metadata.
G0-SCH-005: record versioning plus operation.base_version and operation.dependencies.
G0-SCH-006: trial-anchor and denylist storage with lifecycle, revoke state and audit evidence.
G0-SCH-007: voucher-line discount fields with explicit calculation and rounding behavior.

For each delta provide:
- table/column/index/constraint definition;
- invariants and validation rules;
- migration order and dependencies;
- upgrade approach; rollback follows the approved procedure: uninstall the current APK, install the previous APK, then restore the external backup. In-place downgrade is not supported;
- seed or backfill behavior;
- traceability to DB, DSS, FRD, SEC or SYNC IDs;
- migration tests.

Do not execute against production data. Run only against disposable test databases until a human approves the migration plan.

Acceptance:
- clean install creates the complete schema;
- upgrade from the previous schema succeeds;
- migration is repeat-safe or fails safely without partial corruption;
- schema inspection proves all seven deltas exist;
- the uninstall/install/restore rollback procedure is documented; no in-place downgrade is claimed.
```

## Phase 2 — Accounting and statutory fixture engine

```text
Apply the global instructions.

Create deterministic fixtures and tests for:
1. GST rounding, including boundary values, line-level versus invoice-level rounding, and maximum two-decimal output where required by the approved rule.
2. FIFO/weighted-average cost layers, including partial consumption, opening stock, returns, transfers and negative stock.
3. Negative-stock fallback costing and subsequent reconciliation when stock arrives.
4. Voucher-line discounts, including percentage/amount behavior, tax base impact and rounding.
5. Bill-wise settlement, partial settlement, over-allocation rejection, reversal and remaining balance.

Every fixture must include:
- fixture ID;
- input rows in human-readable form;
- expected postings/balances;
- expected rounding/costing explanation;
- executed command and result;
- traceability IDs.

Do not use random data. Do not mark a fixture passed if expected values were changed to match the implementation.

If a rounding rule or costing rule is not stated in the approved documents, record that fixture as PENDING-INPUT with the exact rule needed. Do not choose a rule.

Acceptance:
- all positive, boundary and negative cases pass, or are PENDING-INPUT with the missing rule named;
- invariants detect invalid allocations, impossible balances and duplicate application;
- results are reproducible from a clean database;
- evidence is saved under `docs/g0/evidence/fixtures/`.
```

## Phase 3 — Security and Android platform verification

```text
Apply the global instructions.

Implement and test the approved security/platform controls:
- encrypted local database and key handling;
- Android Keystore behavior on the minimum supported Android version, including key generation, wrapping/unwrapping and failure handling;
- trial anchor lifecycle and denylist behavior;
- file-provider/share behavior;
- backup and restore behavior;
- encrypted-backup restore after uninstall/reinstall, because uninstalling removes Keystore keys.

Split the work in two:
A. Host-side work. Implement the controls and run every test that can run on the build machine. State plainly in the evidence that these tests do not prove Android Keystore or FileProvider behavior on a device.
B. Device work. Write the on-device tests (for example integration tests) and a manual procedure at `docs/g0/evidence/android/DEVICE_TEST_PROCEDURE.md`, plus a result template that records device model, Android version, build number, test command or manual step, result and evidence path. If an Android 8 device and a current-Android device are not available to you, mark each device test PENDING-INPUT (DEVICE). Do not simulate a pass.

Do not weaken encryption, bypass licence controls, or add a hidden recovery path.

Acceptance:
- no secrets are logged;
- host-side backup/restore tests pass and do not expose protected data or corrupt the database;
- file sharing exposes only approved files (host-side check; device check PENDING-INPUT if no device);
- Keystore failure is handled safely in code, with the failure paths unit-tested;
- device tests exist and are ready to run, and each is PASS with evidence or PENDING-INPUT (DEVICE);
- evidence is saved under `docs/g0/evidence/android/`.
```

## Phase 4 — GST, e-invoice and e-way G0 boundary verification

```text
Apply the global instructions.

Keep G0 limited to data-model capture and schema-version evidence. Direct e-invoice/e-way API integration is out of V1 scope, and the full user-mediated file workflow belongs to R3 / gate G3 unless separately approved. The documents do not define the IRN, acknowledgement or e-way field list. Do not invent columns.

If the Exception Register records G0-DEF-004 (IRN/acknowledgement/e-way field capture deferred to the R1a design review), do not create or propose any columns. Close the field-capture item as DEFERRED with the G0-DEF-004 gate, not PASS. If neither an approved field list nor G0-DEF-004 exists, record the field-capture item as PENDING-INPUT and create no columns.

For the G0 boundary:
- once an owner-approved field list exists, define those fields and their lineage; until then, do not implement them;
- record GST return JSON as an R1a requirement under FR-M16-003 and record its schema/source as PENDING-INPUT until the owner confirms it;
- record official schema/version sources for e-invoice, e-way and GST return JSON for the future G3 workflow. Mark each version UNCONFIRMED unless the owner has confirmed it. Do not state a version number from memory as authoritative;
- create local validation fixtures for field shape and persistence only where a field list exists;
- never call the statutory portal from the V1 APK;
- never store credentials in source code or fixtures.

Credentials, endpoint access and sandbox access are not required for this G0 phase.

Acceptance:
- either the owner-approved field list exists and those fields persist and round-trip, or the field-capture item is DEFERRED (G0-DEF-004) or PENDING-INPUT;
- schema/version evidence is recorded as owner-confirmed or marked UNCONFIRMED, and GST return JSON status is recorded;
- no direct statutory API or full G3 file workflow is claimed as V1 complete;
- evidence is saved under `docs/g0/evidence/adapters/`.
```

## Phase 5 — Data-protection legal/control review

```text
Apply the global instructions.

Close verification record O-14/R-13 as a review activity, not as a coding assumption.

Do the following yourself:
- record the applicable official source (the Digital Personal Data Protection Act 2023 source already in the evidence register);
- draft a mapping of the likely obligations to NiAvERP controls: local-only storage, minimal collection, backup handling, access/recovery behavior, retention/deletion decisions and incident/audit evidence;
- save it as `docs/g0/evidence/legal/LEGAL_CONTROL_MAP_DRAFT.md`, headed "DRAFT — not a legal review."

Leave these as PENDING-INPUT: the named legal reviewer, the review date, any source interpretation, and any retention/deletion decision. Do not invent legal policy or claim legal compliance from a source citation or from your own draft.

Acceptance:
- the official source is recorded and the draft mapping covers each listed control area;
- each mapped obligation points to a control or to an explicit owner decision still needed;
- reviewer, review date and sign-off are PENDING-INPUT until supplied;
- evidence is saved under `docs/g0/evidence/legal/`.
```

## Phase 6 — Printer and release-delivery verification

```text
Apply the global instructions.

The printer model matrix is not named in the documents. The owner supplies and freezes it under OD-FD-006, covering at least three printers.

Do the following yourself:
- implement the Bluetooth ESC/POS thermal output for 58 mm and 80 mm, PDF output through Android print/share for A4 and A5, and Indic text rendered as a raster image, using the same template model;
- write host-side golden tests (expected byte sequences, layout widths, currency, tax and page-break results) and state plainly that these do not prove behavior on a physical printer;
- create `docs/g0/evidence/printers/PRINTER_TEST_SHEET.md` with a result template per printer: make/model, connection method, Android version, paper/layout profile, sample invoice/report, character, alignment, currency, tax and page-break results, retry/offline behavior, evidence photo or captured output;
- for release delivery, compute SHA-256 checksums for the APK and the ZIP fallback, write a verification script, and run it locally; record the command and result;
- document the approved channels: WhatsApp/email, ZIP fallback and the ₹0 hosted link.

Leave these as PENDING-INPUT: each physical printer result (until the matrix is frozen and a printer is available), and each actual channel delivery test (WhatsApp, email, hosted link). Do not mark printer compatibility or channel delivery verified without physical or captured output evidence.

Acceptance:
- renderers and golden tests pass on the host;
- the printer test sheet and checksum script exist and the checksum run is recorded;
- each printer row and each channel row is PASS with evidence or PENDING-INPUT;
- failed targets remain explicitly unsupported with owner action;
- evidence is saved under `docs/g0/evidence/printers/` and `docs/g0/evidence/release/`.
```

## Phase 7 — RTM, regression and evidence consolidation

```text
Apply the global instructions.

Re-run the full RTM and regression suite after Phases 1–6, including the legal review in Phase 5. For every affected requirement, show:
- requirement/decision ID;
- implementation file or module;
- migration or fixture ID where applicable;
- test case ID;
- result: PASS, FAIL, PENDING-INPUT or DEFERRED;
- evidence path;
- defect or owner action if not PASS.

Regress at minimum:
- voucher creation and edit;
- GST calculation and rounding;
- stock movements, costing and negative stock;
- bill settlement;
- period lock/unlock and audit;
- sync versioning-field, dependency and replay behavior only; complete conflict policy implementation remains outside this pack;
- trial/denylist controls;
- backup/restore and file sharing;
- print/PDF output;
- upgrade from prior schema.

Do not convert PENDING-INPUT into PASS because a test was not available. Generate:
- `docs/g0/RTM_EXECUTION_RESULT.md`;
- `docs/g0/REGRESSION_RESULT.md`;
- `docs/g0/PENDING_INPUTS.md`: one table listing every PENDING-INPUT and DEFERRED item with its ID, the exact missing input, the owner question, the command or step that closes it, and the gate;
- updated verification register;
- machine-readable test summary if the project supports it.

Acceptance:
- every G0 schema change has implementation and test traceability;
- every verification record has evidence, or is listed in PENDING_INPUTS.md with its closing step;
- no high-severity regression remains open;
- all test commands and environments are reproducible.
```

## Phase 8 — Final G0 sign-off

```text
Apply the global instructions.

Conduct a formal G0 acceptance review. Do not sign off merely because the build compiles.

Start from the current closeout status: G0 is CONDITIONAL, not unconditional. This phase is read-only for requirements documents. Do not edit any HTML, workbook or requirements source. Re-check each of these and record any correction that is absent as a finding:
- G0-CON-001: verify the Zero-Cost Strategy Plan, Universal Master Plan, Modules Register, Fit-Gap Register (including rows FG-007 and FG-008) and Functional Requirements §10 state that TDS/TCS is later-release and PF/ESI/payroll are out of scope;
- G0-CON-002: verify FR-M17-003, FG-006, Modules Register M17.11, Zero-Cost Strategy Plan, Universal Master Plan and Fit-Gap Register state that Tally/Busy native import is not a V1 promise and remains R3/deferred;
- G0-CON-003: verify the Release and Support Playbook states uninstall current APK, install previous APK, then restore the external backup; in-place downgrade is unsupported;
- G0-CON-004: verify both the Zero-Cost Strategy Plan and Sync Protocol Specification state field merge, host arrival wins on same-field clash, and the loser is logged;
- G0-CON-005: verify the Universal Master Plan, UI/UX Specification §3 and UX Specification §2 use the decided Home, Billing, Parties & Items, Reports, More model; no active navigation variant may contradict it.
- Voice input: verify Modules Register M02.5, Master Plan roadmap text, FR-M02-002, FRD OD-002, the FRD input-methods “Voice” row, UIUX OD-UI-003, UX OD-UI-003 and all reconciliation rows state rejected/excluded from V1; no conditional or deferred voice capability may remain.

Check:
1. all owner decisions are recorded;
2. all deferred items have a gate, with a date where one was set, and remain out of current acceptance scope;
3. all eight verification records contain acceptable evidence, including the separate legal-review result for O-14/R-13;
4. all seven schema changes are migrated and tested;
5. RTM and regression results contain no unresolved critical/high defect;
6. all named body-text contradiction families above are reconciled in every listed document;
7. release, rollback and support evidence is present.

Decision rule:
- Issue `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md` ONLY if every check passes, there is no PENDING-INPUT item, no FAIL item, and no document finding. Include: decision and date; build/schema versions; evidence index; test summary; known deferred future-release items; approver names/roles as supplied by the owner.
- Otherwise create `docs/g0/G0_CONDITIONAL_OR_BLOCKED.md`. It must list every PENDING-INPUT item, every DEFERRED item with its gate, every FAIL item, and every document finding, and state the exact closing step for each. Never issue unconditional sign-off in this case. A conditional result is a normal outcome, not an error.
```

## Resume prompt (use when an owner input arrives)

```text
Apply the global instructions.

Resume only these PENDING-INPUT items: <list IDs from docs/g0/PENDING_INPUTS.md>.
Inputs now supplied: <describe, attach files or paths>.

Re-verify only the listed items using the scaffolding already in the project. Update the evidence files, the verification register and docs/g0/PENDING_INPUTS.md. Do not change items already marked PASS. If an input is still incomplete, leave that item PENDING-INPUT and say exactly what is still missing.
```

## Required final CLI report format

```text
G0 PHASE RESULT
Phase: <number and name>
Phase status: COMPLETE | PARTIAL | FAIL
Commands run:
- ...
Changed files:
- ...
Tests:
- Passed: ...
- Failed: ...
- Pending input: ...
Evidence:
- ...
Traceability IDs:
- ...
Item statuses:
- <ID>: PASS | FAIL | PENDING-INPUT | DEFERRED — <one line>
Pending inputs and owner questions:
- <ID>: <exact missing input> — <smallest owner question>
Next gate:
- ...
```

## Owner handoff order

Run the prompts in this order: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8.

A phase that ends PARTIAL does not stop the run. Phases 3, 4, 5 and 6 depend on owner inputs and devices, and each may end PARTIAL; later phases still run. Carry every PENDING-INPUT and DEFERRED item into Phases 7 and 8. Phase 7 produces `PENDING_INPUTS.md`, and Phase 8 reads it.

Phase 8 will normally end CONDITIONAL on the first full run. That is expected. To reach unconditional sign-off, supply the owner inputs above, run the Resume prompt for each closed item, then re-run Phases 7 and 8. Phase 8 starts from the existing CONDITIONAL baseline and issues unconditional sign-off only when no item is PENDING-INPUT or FAIL.
