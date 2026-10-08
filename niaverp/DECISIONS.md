# NiAvERP implementation decisions

This file is an implementation ledger derived from the active reconciled
project documents. It is not permission to invent values. When a decision is
marked pending, implementation must stop only the dependent behavior and
record the exact question.

## Accepted baseline

| ID | Decision | Status / gate |
|---|---|---|
| D-01 / D-05 / D-R5 | Flutter/Dart, standalone Android V1, CLI-only implementation | Accepted, G0 |
| O-M04 | Minimum Android API 26 / Android 8; low-end device targets apply | Accepted, device evidence later |
| D-M4 | Money integer paise; quantity integer ×10^4; line round-half-up; invoice round-off is a separate ledger line; UUIDv7 text IDs; ISO dates; epoch-ms timestamps | Accepted design, G0/G1 |
| D-M5 / D-08 | FIFO and weighted-average costing; item override over group default; method locks after first posted movement; negative stock uses last-known cost with warning; no retroactive revaluation | Accepted design, G1 |
| D-M6 | Orders do not reserve stock in V1 | Accepted |
| D-04 / O-05 / D-FG-014 | Trial/grace/expiry: approved entitlement matrix; data is not deleted on expiry | Accepted design, G5 implementation/evidence |
| D-10 / O-06 / O-15 | Simple/Advanced boundary as recorded in the master plan and workbook | Accepted decision, later edition gate |
| OD-UI-001 | Top navigation: Home, Billing, Parties & Items, Reports, More | Accepted, G0 |
| G0-CON-001 | TDS/TCS later release; PF/ESI/payroll out of scope for V1 | Accepted exclusion |
| G0-CON-002 | Tally/Busy native adapters are R3 feasibility only; V1 uses Excel templates | Accepted exclusion |
| G0-CON-003 | Rollback is uninstall current APK → install previous APK → restore external backup; in-place downgrade unsupported | Accepted |
| G0-CON-004 | Master-data sync uses field merge; host arrival wins on same-field clash; loser is logged | Accepted rule; full sync is S1 |
| G0-CON-005 | Five-item navigation model is authoritative | Accepted |
| G0-OWN-002 | Voice input is rejected/excluded from V1 | Accepted exclusion |
| G0-DEF-001 | Native Tally/Busy adapters deferred to R3 | Deferred |
| G0-DEF-002 | TDS/TCS later release; PF/ESI/payroll out of scope | Deferred/excluded |
| G0-DEF-003 | Automatic transliteration deferred to R2 | Deferred |

## Voucher types required by the documents

The shared voucher engine must represent all documented types:

- Sales Invoice
- Purchase Invoice
- Sales Return / Credit Note with items
- Purchase Return / Debit Note with items
- Payment
- Receipt
- Contra
- Journal
- Debit Note without items
- Credit Note without items
- Delivery Note / Delivery Challan
- Material Issue to Party
- Material Receive from Party
- Stock Transfer
- Stock Journal
- Sales Quotation / Proforma Invoice
- Purchase Quotation
- Sales Order
- Purchase Order

No type may be omitted silently. A type with a later gate must be represented
with an explicit gate and boundary.

## Schema scope

The seven approved schema changes are:

- G0-SCH-001 cost layers and stock movements;
- G0-SCH-002 period locks;
- G0-SCH-003 bill allocations;
- G0-SCH-004 effective-dated tax/HSN and layout profiles;
- G0-SCH-005 record/operation versioning and sync fields;
- G0-SCH-006 trial anchors and denylist storage;
- G0-SCH-007 voucher-line discount fields.

Implement them through migrations with repeat-safe upgrades, FK/CHECK
validation, auditability and downgrade refusal.

## Gate boundaries

- **G0:** requirements/design acceptance and reproducible host verification.
- **G1:** schema, database and core accounting implementation.
- **G2:** performance and search targets.
- **G3/R1a:** official statutory schemas, approved fields and file workflows.
- **G4:** import/migration and document-flow boundaries where assigned.
- **G5:** Android/device, legal, printer and release/channel evidence.
- **S1/S3:** sync transport, multi-user and device-fleet behavior.
- **R2/R3:** deferred transliteration and native adapter feasibility.

Downstream pending evidence does not authorise a false G0 or product-release
claim.

## Pending decisions/evidence — do not invent

- exact production SQLCipher-class library, version, licence and Android 8
  compatibility;
- owner-approved IRN/acknowledgement/e-way field list and pinned schemas;
- GST statutory source/fixture confirmation where not already recorded;
- legal reviewer, applicability, retention/deletion and signed interpretation;
- physical Android, printer, APK/ZIP and channel evidence;
- any field, rule or workflow marked TBC in the principal documents;
- exact licence key issuance/cryptographic format and payment integration.

## Proposed (needs owner approval) — recorded 2026-10-06

- device_id (A1 / E1b): source evidence = Sync Protocol Specification (device_id UUID, "Originating trusted device"), Data Schema (`device` table `device_id PK`), O-FG-009 (`device_id` with `seq`); no document defines a hardware/advertising identifier. Proposal (NOT approved): device_id = UUIDv7 generated once at first launch, persisted in app-private storage (`app_data/device_id.uuid`); never a hardware or advertising ID; never changed on restore without explicit re-pair flow. Implementation behind proposal completed; owner approval required before marking PASS.

## Change rule

If a new decision is supplied, append a dated row with source ID, exact value,
affected modules, gate and evidence requirement. Do not rewrite historical
decisions. If the change alters schema, accounting, security, legal scope or
navigation, stop the affected implementation slice until the principal source
set is reconciled.

## Appended decisions

| Date (UTC) | ID | Decision | Affected modules | Gate / evidence |
|---|---|---|---|---|
| 2026-10-05 | P-BOOKS | Books (M14.1 day book/register/ledger account, M14.2 trial balance ledger-wise and group-wise) implemented as projections of posted `voucher`/`voucher_line` rows inside `LedgerBooks`. No new schema, no report-side arithmetic: `dayBook`, `ledgerAccount`, `trialBalance`, `groupTrialBalance` all read posted rows plus master openings. Signed convention Dr positive, Cr negative (house convention already used by `LedgerBooks`). Openings always count in full while `from`/`to` window only posted lines — openings are master values, not period-derived. P&L (M14.3), Balance Sheet (M14.4), GST reports and Trading Account (M14.5) NOT implemented: FR-M03-001 names a group "classification" but no source defines the vocabulary or its storage, and GST reports wait on G0-VER-003 (no line-tax columns). Statements are never derived from group names by guesswork. | `lib/application/queries/ledger.dart`, `lib/presentation/reports/books_report_screen.dart`, Reports tab | G1 for the books above; M14.3/14.4/14.5 and GST reports remain deferred/blocked pending a group-classification decision and G3 statutory schemas |
| 2026-10-05 | P-PERIODLOCK | Period-lock administration implemented (`PeriodLockRepository`): create a dated `company` scope lock; unlock requires a non-empty reason and records the unlocking actor, both persisted with operation + audit rows, row status moves `locked` → `unlocked` (never deleted). Repeated unlock refused. The engine remains the enforcement point. Permission/rights checking for unlock waits on the users/roles slice (M19) — the actor identity is stored, never invented as an authorization. | `lib/data/repositories/period_lock.dart`, `CompositionRoot.backend()` | G1; rights model for unlock pending M19 |
| 2026-10-06 | P-SQLIB + P-PATHPROVIDER | path_provider 2.1.6 (BSD-3-Clause, pub.dev) added to pubspec.yaml to resolve `device_id_service.dart` import (getApplicationSupportDirectory). Owner named package; version/ licence recorded. | `pubspec.yaml`, `lib/data/security/device_id_service.dart` | G0 — evidence: package downloaded, analyse/build passes |
| 2026-10-06 | P-DEVICEID | Owner approves device_id proposal (2026-10-05 entry): random UUIDv7 generated once at first launch, persisted in app-private storage (`app_data/device_id.uuid`), never a hardware/advertising ID, never changed without explicit re-pair. Implementation behind proposal considered done; owner approval recorded here. | `lib/data/security/device_id_service.dart`, DECISIONS.md | G0 — remaining evidence: native cipher licence + Android 8 proof (P-DEVICE-8) not required now |
| 2026-10-05 | P-BILLDEF | Outstanding "bill" set tightened: Payment, Receipt, Contra and Journal documents are never bills (settle or adjust, they are not receivables); their unallocated money is reported as advances, and Payment/Receipt remain the only advance carriers (FR-M06-002). `includeSettlementTypes` still exposes them for callers that want the raw rows. Previously only Payment/Receipt were excluded, so a posted Journal could appear as a receivable. | `lib/application/queries/outstanding.dart` | G1 |
| 2026-10-05 | P-SQLIB | SQLCipher-class stack approved: package:sqlite3 3.7.0 with build-hook source sqlite3mc (SQLite3MultipleCiphers, prebuilt Android arm/arm64/x64); Drift 2.35.1 approved for the later DAO slice (unused so far). Dart-package licences MIT (LICENSE heads read from pub cache). sqlcipher_flutter_libs rejected (EOL — 0.7.0+eol is an empty package); git-only encrypted_drift rejected (unversioned). Owner: explicit approval via decision prompt. | Local backend/data layer (db opener, FFI engine, migration bootstrap, CompositionRoot backend) | G0 — remaining evidence: native cipher licence text from the bundled asset manifest + Android 8 compatibility proof on device (P-DEVICE-8); Drift DAO use lands only with its own slice (licence already MIT) |
| 2026-10-07 | P-GST-POST | GST tax posting implemented exactly per CA reply 2026-10-07 (`docs/implementation/evidence/CA_REPLY_SIGNED_OFF_20261007.md` — signed-off markdown conversion of `docs/owner/Your_Reply_Completed.docx`; research-based, not a certified opinion): goods-only place of supply (s.10 movement/direction/no-movement/(ca); registered state from GSTIN digits, block when invalid; unregistered falls back to recorded address then supplier; never silent IGST); blocked categories (reverse_charge/export_sez/zero_rated/composition/services) refuse; exempt/nil-rated allow tax-free lines only; per-line kept-paise math with separately computed equal CGST/SGST halves (no odd-paise split); IGST inter-state; invoice totals sum lines; nearest-rupee Round Off (±50p cap) via the existing arm on net+tax; returns/cancel mirror sides; Dr=Cr enforced including tax; period lock refuses. Tax ledgers (Output/Input CGST/SGST/IGST) required as master accounts, never auto-created. Boundaries: same-code UT pairs post CGST+SGST in v1 (UTGST deferred with ledgers); Section 170 not cited for line math; CA line-2 example arithmetic follows its formula (figures corrected); ITC eligibility gating awaits CA input. | `lib/application/tax/gst_posting.dart`, `lib/application/services/voucher_engine.dart`, `lib/data/accounting/gst.dart`, m018, voucher/party/company repositories | G1 implementation; G3 statutory schemas + NIC/IRP validation re-verification pending; e-invoice export pending |
| 2026-10-08 | P-TRIAL-END (PROPOSAL — needs owner tick in `docs/owner/DECISIONS_TO_APPROVE.md` §10) | Trial end = install start + 3 calendar months (UTC, day clamped to target month end). Effective start = EARLIEST copy found (app-private install file vs `trial_anchor` rows vs now). Denylist preimage until B5: sha256 hex of the device identity (hash-only lookup, no key format invented). `entitlements.json` created with trial/grace cells only; edition/limit cells BLOCKED until B5. Implementation behind proposal completed. | `lib/data/security/trial_service.dart` (`trialEndsAtMs`, `TrialService`), `lib/data/security/trial_store.dart`, `niaverp/entitlements.json`, M20/M22 | G1 proposal; owner month-arithmetic tick + B5 licence-key format pending |
