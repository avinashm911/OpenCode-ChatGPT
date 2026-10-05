# Statutory boundary test evidence — Phase 4 re-verification — 2026-10-03 (UTC)

G0 scope: data-model capture + schema-version evidence only. No IRN/
acknowledgement/e-way columns invented. No direct statutory API. No full G3
file workflow claimed. No credentials stored.

## Command

Workdir: `E:\NiavERP v2 OpenAI\niaverp`
Full-path binary:
`C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\flutter.bat`

```
flutter.bat --version
flutter.bat test test\adapters
```

Supporting read-only checks (same workdir):

```
Select-String -Path "lib\data\migrations\*.sql" -Pattern "(?i)irn|ack_no|ackno|eway|e_way|einvoice|e_invoice|gstr|signed_qr"
Grep lib/**/*.dart for einvoice|ewaybill|gst.gov.in|nic.in|package:http|package:dio|api_key|apikey|client_secret|passwd
Grep lib/**/*.sql for irn|ack_no|ackno|eway|e_way|einvoice|e_invoice|gstr|signed_qr
Glob **/*{schema,einvoice,eway,gstr,IRN}*.* (repo-wide)
```

## Environment

- OS: Windows 10 Pro 64-bit 22H2 (10.0.19045.6466), locale en-IN
- Flutter: 3.47.5, channel stable, Framework revision 6a19cca564 (2026-09-17), Engine revision af7e796e16
- Dart: 3.13.4, DevTools 2.60.0
- Project: `niaverp` 1.0.0+1, `com.niaverp.niaverp`, minSdk 26
- Dependencies: `cupertino_icons`, `crypto` (prod); `flutter_test`, `flutter_lints`, `sqlite3` (dev-only disposable test DBs). No `http`/`dio`/`retrofit`/`chopper`.

## Result

```
00:00 +0: loading E:/NiavERP v2 OpenAI/niaverp/test/adapters/statutory_boundary_test.dart
00:00 +0: G0 boundary: no invented statutory columns migrated schema has no IRN/ack/e-way/GSTR identifiers
00:00 +1: G0 boundary: no statutory API surface no network client dependencies in pubspec
00:00 +2: G0 boundary: no statutory API surface lib/ sources reference no portal endpoints
00:00 +3: G0 boundary: no credentials in code lib/ sources carry no credential literals
00:00 +4: All tests passed!
```

- Passed: 4 (boundary tests in `test/adapters/statutory_boundary_test.dart`)
- Failed: 0
- Statutory columns added: 0
- Statutory API surface added: none
- Credentials added: none

Supporting check results (this run):

- Migration SQL (`lib/data/migrations/m001..m008`): zero hits for banned schema identifiers.
- `lib/**/*.dart`: zero hits for portal/API/credential markers.
- `pubspec.yaml`: zero hits for `http:`/`dio:`/`retrofit:`/`chopper:`.
- Repo-wide glob for vendored schema/e-invoice/e-way/GSTR/IRN artifacts: no files found.
- Sample response files in repo: none found.

## G0 boundary record (no invention)

- Owner-approved IRN / acknowledgement / e-way field list: NOT FOUND in documents.
  Documents state only "capture IRN/ack/e-way fields in data model from R1a"
  (O-10 resolution in REG; FR-M16-003/004 trace) and "where the response format
  is available and verified" (ZCP), plus open decision DSS-O03 "Detailed
  statutory/GST fields and response artifacts — Verify before final physical
  schema". No exact column list exists. No columns were created.
- FR-M16-003 (GST return/export preparation): recorded as R1a requirement —
  "produce the locally generated file/data required by the supported workflow,
  with schema version recorded" (fields: export batch; schema version; period;
  file; source totals; condition: formats remain VERIFY until official schema
  is recorded). No JSON generator is claimed; schema/source verification is a
  separate BLOCKED item.
- FR-M16-004 (e-invoice/e-way adapters): "prepare locally validated payload
  data and support user-mediated submission and response/result import when the
  verified format is available" (fields: invoice/transport data; payload
  version; response identifiers; result file; condition: exact fields and
  response schema are VERIFY; direct API is separate). Full user-mediated file
  workflow belongs to R3 / gate G3 unless separately approved; not claimed
  as V1 complete.
- Request/response correlation design input (unresolved, NOT implemented): a
  future G3 import must correlate local voucher → exported payload → portal
  response (request hash + response status + timestamps + audit link). Column
  names are deliberately not frozen here; freezing them without the field list
  would invent schema.
- Never called the statutory portal from the V1 APK. Never stored credentials
  in source code or fixtures. Credentials, endpoint access and sandbox access
  are not required for this G0 phase and none was created.

## Official schema/version pointers for the future G3 workflow

Pointers only (public sources; not vendored; nothing downloaded into the repo).
Owner to pin versions + attach samples before G3 implementation. As recorded in
`docs/g0/evidence/adapters/G0_BOUNDARY.md` §3, researched 2026-10-03:

- E-invoice schema: `gstn.org.in/e-invoicing` → schema notified as Form GST
  INV-1; `E-INVOICE-SCHEMA.pdf` at `einvoice1.gst.gov.in/Documents/`; API specs
  at `einv-apisandbox.nic.in`; master portal `einvoice.gst.gov.in`.
- E-way bill: API developer portal `docs.ewaybillgst.gov.in/apidocs`, current
  v1.03 (archives incl. v1.01); portal `ewaybillgst.gov.in`; attributes/JSON
  schema via portal Bulk Generation Tools.
- GST return JSON (R1a, FR-M16-003): `gst.gov.in/download/returns` → Returns
  Offline Tool V3.2.4 (GSTR-1/IFF JSON convention); tutorials at
  `tutorial.gst.gov.in`. Schema pin + samples still owner-verified.

Pinned official schema copies + required sample response files in repo: NONE.
Status for each: MISSING → BLOCKED (see below).

## Phase status: BLOCKED (global rule 8)

| Missing decision/evidence | Affected IDs | Gate |
|---|---|---|
| Owner-approved IRN / acknowledgement / e-way field list for R1a data-model capture | O-10/O-FG-002/O-FG-003; DSS-O03; G0-VER-003; FR-M16-004 | G3 (fields persist only after list lands) |
| Official e-invoice schema pinned version + sample response files | FG-002; G0-VER-003 | G3 |
| Official GST return JSON schema source/version (FR-M16-003) | FR-M16-003 | R1a/G3 |
| Official e-way schema pinned version + sample response files | O-FG-003; G0-VER-003 | G3 |

Smallest proposed owner question: please supply (a) the exact R1a field list
for IRN/acknowledgement/e-way capture, and (b) which pinned official schema
versions + sample response files in §3 above are authoritative for G3 — or
confirm that G0 stays fields-free until R1a review.

## Change log (this evidence file only)

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Re-ran 4 boundary tests (pass); recorded FR-M16-003/004 wording, DSS-O03 open status, and missing schema/sample evidence; no fields, no API, no credentials added | O-10/O-FG-002/003; FR-M16-003/004; DSS-O03; G0-VER-003; pack rule 11 |

No migration, fixture, or lib/ change was made in this re-verification.
Money/quantity rules (paise / ×10⁴ / half-up / D-M4 round-off line),
deterministic/idempotent migrations, and uninstall→install→restore rollback
(no in-place downgrade) are unchanged.
