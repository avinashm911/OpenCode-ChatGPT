# NiAvERP backend and frontend implementation strategy

Date: 2026-10-05  
Authority reviewed: the 15 NiAvERP HTML documents, G0 evidence/register files,
the current v1.1 prompt pack, and the current `niaverp/` Flutter source.

## 1. Independent review conclusion

The requirements are broad but the reconciled baseline is usable for staged
implementation. The system is a standalone, offline-first Android APK. There
is no approved V1 cloud backend. Therefore:

- **Backend for the first implementation** means the in-app local backend:
  SQLCipher-class encrypted SQLite, migrations, repositories, domain services,
  validation, audit, backup/restore, import/export and local search.
- **Future multi-user backend/transport** means the documented LAN/hotspot and
  file-sync adapter at S1. It must be an adapter around the local operation
  log, not a prerequisite for the first vertical slices.
- Direct e-invoice/e-way APIs, Tally/Busy native adapters, voice input,
  TDS/TCS, PF/ESI/payroll and automatic transliteration remain outside V1 as
  recorded in the reconciliation sections.

The current source is an in-progress foundation, not an empty project. Phase
00 completed the shell/value-object slice (+107 tests), Phase 01 completed the
engine-neutral database/repository foundation (+128 cumulative tests), and
Phase 02 completed the M03 masters/onboarding/search slice (+166 cumulative
tests). Production SQLCipher/Drift/Keystore wiring, real business screens,
broader voucher/report modules, Android platform evidence and release evidence
remain gated work. Prompts must continue from these reports and must not
rebuild completed migrations or replace passing tests.

## 2. Source-of-truth hierarchy

Use this order when implementing:

1. Approved decisions and reconciliation sections in the HTML documents and
   exception/evidence registers.
2. Data Schema Specification and Database Schema Document for persistence.
3. Functional Requirements and Functional Design Document for behavior.
4. UI/UX and UX specifications for screens and interaction.
5. Security, Sync, Release and Test documents for cross-cutting controls.
6. `docs/g0/` for current execution status and evidence boundaries.

If two active statements conflict, stop that slice, record the conflict and do
not invent a policy. Historical change-log text is not an active requirement.

## 3. Target architecture

```text
Flutter presentation
  screens, forms, navigation, view models, validation messages
        |
Application layer
  use cases, command/query handlers, entitlement checks, transaction scope
        |
Domain layer
  voucher, stock, costing, GST, settlement, period-lock, trial, audit rules
        |
Local backend/data layer
  Drift DAOs, SQLCipher SQLite connection, migrations, repositories,
  operation log, backup/restore, import/export, search indexes
        |
Platform adapters
  Android Keystore, FileProvider/share, Bluetooth/PDF printing, file picker
        |
Future adapters
  LAN/hotspot/file sync, statutory portal-mediated workflows, release channels
```

Recommended source layout:

```text
niaverp/lib/
  app/                 app bootstrap, routes, theme, dependency wiring
  core/                errors, result types, ids, clock, money/quantity types
  domain/
    entities/          immutable business entities
    value_objects/     paise, qtyQ4, GSTIN, voucher number, dates
    policies/          posting, period lock, entitlement, permissions
  application/
    commands/          create/edit/post/settle/import/backup actions
    queries/            dashboard/search/report reads
    services/          orchestration and transaction boundaries
  data/
    db/                Drift schema, DAOs, connection, migrations
    repositories/      domain-facing repository implementations
    accounting/        existing engines moved behind interfaces
    security/          existing contracts plus platform implementations
    printing/          existing template/renderers plus platform adapters
    import_export/     Excel/CSV mapping and validation
    sync/              operation envelope and versioning fields only initially
  presentation/
    shell/              five-item navigation shell
    home/
    billing/
    parties_items/
    reports/
    more/
    shared/
```

Do not create a server, REST API, cloud database or invented package selection
for V1. Riverpod, go_router, PDF/Excel/barcode/ESC-POS packages remain
candidate dependencies until their licence and compatibility are confirmed.

## 4. Delivery strategy: vertical slices

Implement one complete slice at a time: schema → repository → use case → UI →
tests → evidence. Avoid building all screens against fake data.

### Slice 0 — project and quality foundation

Deliver:

- replace the counter screen with the NiAvERP app shell;
- add environment/configuration and dependency injection;
- add typed `MoneyPaise`, `QuantityQ4`, `EntityId`, `CompanyId` and clock
  abstractions;
- define error/result handling and audit context;
- preserve CLI-only commands and minSdk 26.

Exit criteria: app launches to the five-item navigation model; no business
state is held only in widgets; unit/widget tests cover the shell and value
objects.

### Slice 1 — local backend foundation (G1)

Deliver:

- select and record the exact SQLCipher-class library, version and licence;
- wire Android Keystore-wrapped database key provisioning;
- integrate Drift over the encrypted SQLite connection;
- implement migration registry and the seven approved schema changes;
- add transaction, foreign-key, audit and schema-version checks;
- expose repositories through interfaces, not direct SQL from screens.

Use the existing migrations and tests as the starting point, but do not claim
production encryption until the selected library is wired and tested on the
target Android versions.

Exit criteria: clean install, upgrade, repeat-safe migration, rollback refusal,
encrypted open/close/key-failure behavior, and repository tests all pass.

### Slice 2 — master data and company setup

Implement the minimum data needed by every later slice:

- company, users/roles and permissions boundary;
- parties/customers/suppliers;
- items, units, HSN/tax references, godowns and series;
- create/edit validation, duplicate detection and audit history;
- universal search indexes and aliases.

Frontend: onboarding, company setup, Parties & Items, search and settings.

### Slice 3 — billing vertical slice (M04/M05/M11)

Implement end-to-end:

1. draft bill;
2. party/item lookup;
3. quantity/rate/discount entry;
4. paise and Q4 calculation;
5. GST calculation and invoice round-off ledger line;
6. post bill and generate voucher/audit/stock effects;
7. edit/cancel according to period and status rules;
8. render the same invoice model to screen, PDF and ESC/POS.

Frontend: Home, Billing, fast-billing form, bill detail, payment/settlement
dialog and print/share actions.

Exit criteria: a bill can be created and reopened from the encrypted local
database with no mock repository and with golden accounting/print tests.

### Slice 4 — purchasing, stock and costing

Implement purchase/receipt and issue/sale flows over the existing cost-layer
model:

- FIFO first, with weighted-average behind the selected costing policy;
- negative-stock last-known-cost fallback with warning;
- later reconciliation without rewriting history;
- stock movement, godown and item balances;
- period lock and authorised unlock with audit event.

Frontend: stock dashboard, item/godown views, purchase/issue forms, warnings
and stock reports.

### Slice 5 — settlements, accounting and reports

Implement:

- bill-wise settlement and reversal;
- cash/bank/expense/income/journal vouchers;
- account/group masters and posting templates;
- day book, ledger, trial balance, outstanding and stock reports;
- export to approved file formats;
- report filters, date range and company scope.

Every report must be a query over persisted data. Do not build report screens
from fixture arrays.

### Slice 6 — imports and statutory file boundary

Implement V1 Excel/CSV import with a review-before-commit pipeline:

```text
select file → inspect type/size → map columns → validate rows
→ show errors/warnings → preview changes → commit transaction → audit result
```

Tally/Busy input means Excel export mapping only. Do not implement native
Tally/Busy adapters. For GST/e-invoice/e-way, implement only the approved
file-first boundary and fields once the owner-approved field list and pinned
schemas exist. Do not add direct portal API calls.

### Slice 7 — security, backup, sharing and sync boundary

Implement after the local business flow works:

- trial/entitlement and denylist integration;
- Keystore failure-safe behavior and no-secret logging;
- encrypted backup manifest, tamper detection and restore validation;
- uninstall → previous APK → external backup restore procedure;
- FileProvider/share allowlist;
- operation envelope, record version, base version and dependencies;
- replay/idempotency tests for S1 sync fields only.

Do not implement the full conflict policy or a server. Keep sync transport
behind an interface for later LAN/hotspot/file-sync work.

### Slice 8 — hardware and release hardening (G5)

Only after the product flow exists:

- Android 8 and current-Android device tests;
- physical 58 mm and 80 mm ESC/POS tests;
- PDF A4/A5 Android print/share tests;
- actual release APK and ZIP checksums;
- real WhatsApp/email/₹0 hosted-link delivery evidence;
- legal review and retention/deletion decisions;
- performance, accessibility, crash recovery and upgrade/restore drills.

## 5. Frontend screen plan

The authoritative top-level navigation is:

1. Home
2. Billing
3. Parties & Items
4. Reports
5. More

Build the shell first, then add screens only when their local use cases exist.
Every form needs loading, empty, validation-error, conflict/locked, success,
and recoverable-failure states. Avoid hiding accounting decisions in UI code.

## 6. Backend implementation rules

- All writes go through application commands and a transaction boundary.
- All money is integer paise; quantity is integer ×10^4.
- Never use floating-point for accounting totals.
- Preserve history with compensating rows/events; do not silently delete or
  rewrite posted accounting data.
- Enforce company scope, period lock, entitlement and permission checks in the
  application/data layer, not only in widgets.
- Use stable IDs, operation lineage and audit events for every material write.
- Repository tests use real SQLite/Drift behavior where SQL semantics matter;
  pure domain tests cover arithmetic and policies.

## 7. Test and evidence strategy

For every vertical slice, require:

- domain unit tests;
- repository/migration integration tests;
- widget tests for key flows;
- golden tests for print/report output where applicable;
- negative/security tests;
- RTM mapping and evidence path;
- reproducible CLI command and environment.

The phase-02 +166 cumulative-test result is a verified foundation baseline,
not proof of a completed frontend/backend. Add tests as production modules
replace prototypes. Keep
device, printer, legal, statutory and release evidence in their downstream
gate records.

## 8. Execution order and stop rules

1. Freeze the exact package/licence decisions needed for the next slice.
2. Implement one vertical slice end-to-end.
3. Run analyze, unit, integration and widget tests.
4. Update RTM and evidence before starting the next slice.
5. Stop when a missing decision changes data shape, accounting behavior,
   security behavior or legal scope. Record the exact owner question.
6. Never replace a missing integration with a fake PASS or a permanently fake
   repository.

## 9. Continuation implementation sprint

The next practical sprint should be:

1. Run the read-only baseline and traceability audit against phase-00,
   phase-01 and phase-02 reports.
2. Continue the local backend: resolve or stop at the SQLCipher/Drift/Keystore
   decision boundary; preserve the engine-neutral seams and existing tests.
3. Complete unfinished onboarding/localisation work over the existing shell.
4. Verify and extend the existing masters/search slice only where an active P1
   source row requires it.
5. Implement the next P1 billing/voucher vertical slice, then update RTM,
   tests and the phase report.

Do not begin statutory adapters, printer certification, channel delivery or
full sync before this first persisted billing slice works.

## 10. Completeness audit against the principal module register

The earlier strategy was incomplete because it grouped several modules under
generic labels. The implementation plan must explicitly cover every registered
module M01–M24:

| Module | Required implementation work package | Prompt |
|---|---|---|
| M01 Onboarding, Company & Configuration | company creation, financial year, settings, first-user setup, company switch | 02_onboarding_and_localisation.md |
| M02 Language & Localisation | en/hi/gu resources, native-script entry/search, glossary, formatting; no automatic transliteration | 02_onboarding_and_localisation.md |
| M03 Masters | ledgers, parties, items, units, godowns, tax/HSN, series and master utilities | 03_masters_and_search_continuation.md |
| M04 Voucher Engine & Multi-Series Numbering | registry, base classes, series, numbering, lifecycle and common voucher services | 04_voucher_engine_and_orders.md |
| M05 Dual Vouchers | sales/purchase invoices and item returns with accounting + stock effects | 04_voucher_engine_and_orders.md |
| M06 Accounting Vouchers | payment, receipt, contra, journal, debit note, credit note | 04_voucher_engine_and_orders.md |
| M07 Inventory Vouchers | delivery, material issue/receive, transfer, stock journal | 04_voucher_engine_and_orders.md |
| M08 Orders & Quotations | sales/purchase quotation and sales/purchase order | 04_voucher_engine_and_orders.md |
| M09 Document Flow | conversion, partial fulfilment, lineage, reversal and linking | 05_document_flow_approvals_and_counter.md |
| M10 Approval Matrix & Workflows | threshold/type rules, submit/approve/reject/send-back, audit and inbox | 05_document_flow_approvals_and_counter.md |
| M11 Fast Billing / Mobile Counter | quick bill, held bills, shortcuts, counter mode, cash close and quick return | 04_voucher_engine_and_orders.md |
| M12 Universal Search | indexed search, aliases, filters, native-script search and latency tests | 03_masters_and_search_continuation.md |
| M13 Inventory Management | balances, godowns, batches/expiry if approved, valuation, stock take and reorder | 06_inventory_accounting_and_reports.md |
| M14 Accounting Books & Financial Reports | day book, ledger, trial balance, P&L, balance sheet, outstanding | 06_inventory_accounting_and_reports.md |
| M15 Inventory Reports | stock summary/ledger, valuation, movement, ageing and godown reports | 06_inventory_accounting_and_reports.md |
| M16 GST & Statutory | GST calculations/reports and file-first JSON boundary; no direct APIs | 07_import_gst_brs_and_statutory_boundary.md |
| M17 Data Import / Migration | Excel/CSV mapping, preview, validation, commit, backup/migration safety | 07_import_gst_brs_and_statutory_boundary.md |
| M18 Admin Module | users/roles administration, audit viewer, voucher controls, period locks, pairing and rebuild utility | 08_admin_users_and_licensing.md |
| M19 Users, Roles & Multi-user | rights, device limits, approval permissions, operation identity and future sync participation | 08_admin_users_and_licensing.md |
| M20 Licensing & Trial | key/edition/trial/grace/denylist state, expiry behavior, feature gates | 08_admin_users_and_licensing.md |
| M21 Printing, Sharing & Communication | shared print model, ESC/POS/PDF, file sharing, payment reminders and user-mediated channels | 10_outputs_customisation_and_support.md |
| M22 Backup, Sync, Security & Audit | encrypted backup, restore, Keystore, audit, operation log and S1 transport boundary | 09_security_backup_and_sync_boundary.md |
| M23 UI Customisation Framework | layout profiles, visible fields/order/labels, home tiles and role/user scope | 10_outputs_customisation_and_support.md |
| M24 Utilities & Support | diagnostics, rebuild, import/export support, incident data, help and safe recovery | 10_outputs_customisation_and_support.md |

The module register's TBC/VERIFY/R2/R1b items remain explicitly gated. A
prompt may implement a safe boundary or scaffold, but must not silently turn a
TBC or later-release item into a V1 requirement.

## 11. Revised implementation train

The correct prompt order is now:

```text
00 resume baseline and traceability
01 local backend continuation
02 onboarding and localisation
03 masters and search continuation
03 billing vertical slice
04 document flow and voucher orders
05 document flow, approvals and counters
06 inventory, accounting and reports
07 imports, GST, BRS and statutory boundary
08 admin, users and licensing
09 security, backup and sync boundary
10 outputs, customisation and support
11 frontend completion over real services
12 hardware, release and evidence
13 final verification and gate report
```

Each prompt must produce a phase report, changed-file list, commands/results,
RTM mapping, tests and unresolved decisions. The next prompt cannot silently
repair a previous prompt's failed invariant; it must report or fix it first.

## 12. Global no-invention contract for OpenCode

Every master prompt must include this exact behavior:

1. Read `AGENTS.md`, `DECISIONS.md`, this strategy, the prompt-pack global
   contract, the relevant principal documents and the prior phase
   report before editing code.
2. Treat active reconciled decisions as authority and historical rows as
   history only.
3. Never invent a field, voucher type, posting rule, tax rule, legal position,
   package, licence, API, permission, workflow state, performance target or
   release channel.
4. When a required value is absent or contradictory, stop only the affected
   work, record the exact source ID and question, and continue independent work.
5. Never represent a mock, host-only test, emulator-only test, public source or
   scaffold as physical, legal, production or delivery evidence.
6. Do not edit the 15 principal HTML documents, decision workbooks or source
   registers from implementation prompts.
7. Do not add cloud/server dependencies to standalone V1.
8. Preserve exclusions: voice, native Tally/Busy, payroll/TDS/TCS/PF/ESI,
   automatic transliteration and direct statutory APIs.

## 13. Revised completion definition

The implementation strategy is complete only when every M01–M24 module has a
traceability row with one of these truthful states:

- implemented and tested;
- implemented boundary with a named downstream gate;
- explicitly deferred with the recorded gate; or
- blocked by a named unresolved decision.

An empty prompt, generic “admin later” note, or unlinked screen does not count
as coverage. The v1.1 pack must also show every source traceability family,
priority, gate, deferred item, blocked evidence item and exactly-one
implementation/verification mapping.
