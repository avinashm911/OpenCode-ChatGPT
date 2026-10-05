# Statutory G0 boundary record — Phase 4 (2026-10-03 UTC)

G0 is limited to data-model capture + schema-version evidence for
e-invoice/e-way. Direct portal APIs are out of V1 scope (pack rule 11); the
full user-mediated file workflow belongs to R3 / gate G3 unless separately
approved. No IRN/acknowledgement/e-way columns were invented: the
owner-approved field list does not exist in the documents.

## 1. Phase status: BLOCKED (rule 8)

| Missing decision/evidence | Affected IDs | Gate |
|---|---|---|
| Owner-approved IRN / acknowledgement / e-way field list for R1a data-model capture (documents only say "capture … from R1a" and "where the response format is available and verified" — no list) | O-10/O-FG-002/O-FG-003; DSS-O03; G0-VER-003 | G3 (fields persist only after list lands) |
| Official e-invoice schema pinned version + sample response files | FG-002; G0-VER-003 | G3 |
| Official GST return JSON schema source/version (FR-M16-003) | FR-M16-003 | R1a/G3 |
| Official e-way schema pinned version + sample response files | O-FG-003; G0-VER-003 | G3 |

Smallest proposed owner question: please supply (a) the exact R1a field list
for IRN/acknowledgement/e-way capture, and (b) which pinned official schema
versions + sample response files in §3 below are authoritative for G3 — or
confirm that G0 stays fields-free until R1a review.

## 2. What G0 does and does not contain (attested by tests)

- No statutory columns: `test/adapters/statutory_boundary_test.dart` migrates
  the full v1–v8 chain and asserts no table/column matches IRN/ack/e-way/
  e-invoice/GSTR identifiers — PASS (4/4 boundary tests).
- No statutory API surface: no `http/dio/retrofit/chopper` dependency in
  pubspec; no portal endpoint in any `lib/` source — PASS.
- No credentials: no `api_key/apikey/client_secret/passwd` literals in `lib/`
  — PASS. (Credentials, endpoint and sandbox access are not required for G0
  and none was created.)
- GST return JSON: recorded as an **R1a requirement under FR-M16-003**
  (approved: "GST return JSON stays R1a"); its schema/source verification is
  a separate BLOCKED item above — no JSON generator is claimed.
- Correlation design input (unresolved, NOT implemented): a future G3 import
  must correlate local voucher → exported payload → portal response
  (request hash + response status + timestamps + audit link). Column names are
  deliberately not frozen here; freezing them without the field list would
  invent schema.

## 3. Official schema/version pointers for the future G3 workflow

Researched 2026-10-03 (public sources only; pointers, not vendored copies —
nothing downloaded into the repo). Owner to pin versions + attach samples
before G3 implementation.

| Workflow | Official source (pointer) | Observed 2026-10-03 |
|---|---|---|
| E-invoice schema | `gstn.org.in/e-invoicing` → schema notified as **Form GST INV-1**; `E-INVOICE-SCHEMA.pdf` at `einvoice1.gst.gov.in/Documents/`; API specs at `einv-apisandbox.nic.in`; master portal `einvoice.gst.gov.in` (6 IRPs) | JSON prep tools labelled Version 1.01; 30-day reporting restriction for AATO ≥ ₹10 Cr (eff 2025-04-01); 40% slab + RSP-based validation changes (2026-02-01) |
| E-way bill | API developer portal `docs.ewaybillgst.gov.in/apidocs`, **current v1.03** (archives incl. v1.01); portal `ewaybillgst.gov.in`; attributes/JSON schema via portal Bulk Generation Tools (bulk tool Ver 1.0.0618); announcements current to 30/07/2026 | v1.03 current; enhancement notices through Jul 2026 |
| GST return JSON (R1a) | `gst.gov.in/download/returns` → **Returns Offline Tool V3.2.4** (GSTR-1/IFF JSON, ≤5 MB convention); tutorials at `tutorial.gst.gov.in` | V3.2.4 current listing; schema pin + samples still owner-verified |

## 4. Change log (Phase 4)

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Boundary attestation tests (4 pass); this record; phase reported BLOCKED per rule 8 — no fields, no API, no credentials added | O-10/O-FG-002/003; FR-M16-003; G0-VER-003; pack rule 11 |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\adapters` → `+4: All tests passed!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4.
