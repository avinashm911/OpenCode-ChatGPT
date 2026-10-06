# NiAvERP G0 Phase-wise Prompts Pack

Version: v0.1  
Purpose: prompts for OpenCode CLI using a free model  
Baseline: NiAvERP standalone Android APK, offline-first accounting baseline, with server/cloud capabilities only where explicitly marked future phase.

## How to use this pack

Run one phase at a time. Do not give the free model the next phase until the current phase’s acceptance gate passes. Each prompt is intentionally explicit because the CLI must create the implementation from the approved documents rather than assume an existing codebase.

The attached NiAvERP HTML documents and the G0 exception/evidence registers are the only requirements authority. The confirmed implementation baseline is Flutter/Dart, Drift over encrypted SQLite using a SQLCipher-class approach, minSdk 26 / Android 8, CLI-only build and test, integer paise for money, and integer quantity units of quantity ×10^4. If a requirement is missing, contradictory, or technically ambiguous, stop and report the exact decision needed. Do not invent accounting, tax, security, sync, permission, or release policy.

## Global instructions to include in every prompt

```text
You are implementing NiAvERP as a greenfield standalone Android APK.

Read all supplied NiAvERP documents before coding. Treat the approved G0 reconciliation sections and the latest owner decisions as authoritative. Preserve unresolved or execution-pending items as explicit blockers.

Rules:
1. Do not invent requirements, tax rules, accounting policy, permissions, sync conflict rules, or security behavior.
2. Do not add server/cloud dependencies to the standalone APK baseline.
3. Do not replace an approved decision with a convenient default.
4. Keep migrations deterministic, idempotent, reversible where practical, and auditable.
5. Store money as integer paise. Store quantities as integer quantity ×10^4. Use round-half-up for line amounts. Record invoice round-off as a separate ledger line under D-M4.
6. Every implementation change must have tests, fixtures, traceability IDs, and a short change log.
7. Never claim a test passed without showing the command, environment, result, and saved evidence.
8. On missing information, STOP with: BLOCKED, exact missing decision/evidence, affected IDs, and the smallest proposed owner question.
9. Work only inside the supplied project directory. Do not rewrite unrelated files.
10. Before finishing, report changed files, commands run, tests passed/failed, known limitations, and next gate.
11. Do not build these excluded capabilities: voice input; Tally/Busy native import; TDS/TCS; PF/ESI or payroll; automatic transliteration; direct e-invoice/e-way APIs.
12. LAN/hotspot and file-based sync remain in scope at gate S1. This pack covers only the G0 schema versioning fields for sync, not the complete sync implementation.
13. Project gates remain distinct: G0 is this acceptance baseline; each item retains its own gate such as G1, G3, G5 or S1.
```

## Phase 0 — Project intake and controlled baseline

```text
Apply the global instructions.

Create the greenfield project using the confirmed baseline. Scaffold with Flutter/Dart and CLI-only commands. Configure minSdk 26 / Android 8, Drift over encrypted SQLite using a SQLCipher-class approach, integer paise, quantity ×10^4 and the approved build structure. Then inventory:
- Flutter/Dart and build-tool versions;
- database engine and encryption approach;
- source documents and their versions;
- current project structure, if any;
- existing tests, fixtures, migration files and CI commands.

Create `docs/g0/PROJECT_BASELINE.md` containing the inventory and a requirement-to-file map.

If an implementation project is absent, create the project with `flutter create` and document the exact command and versions. Do not choose a different stack. Do not implement business features in this phase.

Acceptance:
- the confirmed stack is scaffolded and inventory is complete;
- every implementation assumption is labelled as confirmed or blocked;
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

Acceptance:
- all positive, boundary and negative cases pass;
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

Run tests on the declared minimum Android version and current supported version. Record device model, Android version, build number, test command or manual procedure, result and evidence path.

Do not weaken encryption, bypass licence controls, or add a hidden recovery path. If the device is unavailable, mark the test BLOCKED rather than simulated-pass.

Acceptance:
- no secrets are logged;
- backup/restore does not expose protected data or corrupt the database;
- file sharing exposes only approved files;
- Keystore failure is handled safely;
- evidence is saved under `docs/g0/evidence/android/`.
``` 

## Phase 4 — GST, e-invoice and e-way file workflow verification

```text
Apply the global instructions.

Implement and verify the V1 GST, e-invoice and e-way file workflow. Direct e-invoice/e-way API integration is out of V1 scope. The APK must generate local JSON/file payloads, validate them against the approved official schema version, allow user-mediated portal upload, and import the saved response file.

For each file workflow:
- generate the required JSON payload;
- validate the request against the recorded official schema/version;
- export a user-reviewable file;
- import a user-supplied response file;
- validate the response schema and rejected-response handling;
- preserve request/response correlation and audit information;
- never call the statutory portal from the V1 APK;
- never store credentials in source code or fixtures.

Use official current schemas and record their version/source in the evidence log. If credentials, endpoint access, sandbox access or exact schema is missing, STOP that adapter and report BLOCKED.

Acceptance:
- JSON generation and official-schema validation tests pass;
- response-file import and negative-response handling pass;
- no direct statutory API call exists in V1;
- no claim of live statutory success is made;
- evidence is saved under `docs/g0/evidence/adapters/`.
``` 

## Phase 5A — Data-protection legal/control review

```text
Apply the global instructions.

Close verification record O-14/R-13 as a review activity, not as a coding assumption. Attach the applicable official source, obtain the owner/legal review, and map the resulting obligations to NiAvERP controls: local-only storage, minimal collection, backup handling, access/recovery behavior, retention/deletion decisions and incident/audit evidence.

If the legal reviewer, source interpretation or retention decision is missing, mark O-14/R-13 BLOCKED. Do not invent legal policy or claim legal compliance from a source citation alone.

Acceptance:
- reviewed source and reviewer/date are recorded;
- each applicable obligation maps to a control or explicit owner decision;
- evidence is saved under `docs/g0/evidence/legal/`.
```

## Phase 5 — Printer and release-delivery verification

```text
Apply the global instructions.

Test the three approved printer targets and the supported PDF/print fallback. For each printer record:
- make/model;
- connection method;
- Android version;
- paper/layout profile;
- sample invoice/report;
- character, alignment, currency, tax and page-break results;
- retry/offline behavior;
- evidence photo or captured output.

Because printer models are not named in the documents, require the owner to supply and freeze the printer model matrix under OD-FD-006. If it is missing, mark the printer gate BLOCKED. Test Bluetooth ESC/POS thermal output at 58 mm and 80 mm, PDF through Android print/share at A4 and A5, and Indic text rendered as a raster image. Also execute APK/ZIP delivery and checksum verification through the approved channels: WhatsApp/email, ZIP fallback and the ₹0 hosted link. Do not mark printer compatibility verified without physical or captured output evidence.

Acceptance:
- the owner-supplied three-printer matrix produces legible, reconciled output; until the matrix is frozen, printer status is BLOCKED;
- PDF fallback is visually checked;
- failed targets remain explicitly unsupported with owner action;
- evidence is saved under `docs/g0/evidence/printers/` and `docs/g0/evidence/release/`.
``` 

## Phase 6 — RTM, regression and evidence consolidation

```text
Apply the global instructions.

Re-run the full RTM and regression suite after Phases 1–5. For every affected requirement, show:
- requirement/decision ID;
- implementation file or module;
- migration or fixture ID where applicable;
- test case ID;
- result: PASS, FAIL or BLOCKED;
- evidence path;
- defect or owner action if not PASS.

Regress at minimum:
- voucher creation and edit;
- GST calculation and rounding;
- stock movements, costing and negative stock;
- bill settlement;
- period lock/unlock and audit;
- sync versioning/conflict behavior;
- trial/denylist controls;
- backup/restore and file sharing;
- print/PDF output;
- upgrade from prior schema.

Do not convert BLOCKED into PASS because a test was not available. Generate:
- `docs/g0/RTM_EXECUTION_RESULT.md`;
- `docs/g0/REGRESSION_RESULT.md`;
- updated verification register;
- machine-readable test summary if the project supports it.

Acceptance:
- every G0 schema change has implementation and test traceability;
- every verification record has evidence or an explicit blocker;
- no high-severity regression remains open;
- all test commands and environments are reproducible.
``` 

## Phase 7 — Final unconditional G0 sign-off

```text
Apply the global instructions.

Conduct a formal G0 acceptance review. Do not sign off merely because the build compiles.

Start from the current closeout status: G0 is CONDITIONAL, not unconditional. Before beginning this phase, complete the prerequisite editorial correction for G0-CON-004: remove the remaining Zero-Cost Strategy Plan wording that says master-data edits use last-writer-wins. The authoritative rule is field merge; when the same field clashes, host arrival wins and the loser is logged. Re-run the body-text contradiction check after this correction.

Check:
1. all owner decisions are recorded;
2. all deferred items have a gate/date and remain out of current acceptance scope;
3. all eight verification records contain acceptable evidence, including the separate legal-review result for O-14/R-13;
4. all seven schema changes are migrated and tested;
5. RTM and regression results contain no unresolved critical/high defect;
6. body-text contradictions are reconciled, including G0-CON-004;
7. release, rollback and support evidence is present.

If every condition passes, create `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md` containing:
- decision and date;
- build/schema versions;
- evidence index;
- test summary;
- known deferred future-release items;
- approver names/roles as supplied by the owner.

If any condition fails, create `docs/g0/G0_CONDITIONAL_OR_BLOCKED.md` instead. State the exact failed gate and never issue unconditional sign-off.
``` 

## Required final CLI report format

```text
G0 PHASE RESULT
Phase: <number and name>
Status: PASS | FAIL | BLOCKED
Commands run:
- ...
Changed files:
- ...
Tests:
- Passed: ...
- Failed: ...
- Blocked: ...
Evidence:
- ...
Traceability IDs:
- ...
Open decisions or owner actions:
- ...
Next gate:
- ...
```

## Owner handoff order

Run the prompts in this order: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5A → Phase 5 → Phase 6 → Phase 7. Phase 7 starts from the existing CONDITIONAL baseline and must not be requested until the G0-CON-004 body-text prerequisite, evidence register and regression report show no unresolved G0 blocker.
