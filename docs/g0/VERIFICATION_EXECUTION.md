# Verification execution register — Phase 7 update (v0.8, new file)

Date (UTC): 2026-10-03
Source registers (read-only, untouched): `outputs/01a0f1dd-b8a2-7ba3-9346-01abef17f993/NiAv_G0_Verification_Evidence_Register_v0.1.xlsx` + `.inspect.ndjson`; `niav_final_reconciliation_report_20261001.json` (8 records); `niav_g0_closeout_report_20261001.json` (CONDITIONAL baseline).
This file updates execution status after Phases 1–6. It does not edit the sources.

| Record | Subject (gate) | Documentary source (from source register) | Execution since G0 v0.1 | Result | Evidence / closing step |
|---|---|---|---|---|---|
| V-FG-001 / G0-VER-001 | SQLCipher/Drift on Android 8+ (G0) | `https://pub.dev/packages/sqlcipher_flutter_libs` (pointer) | Approach recorded; no dependency added; disposable-DB tests green | PENDING-INPUT | `PROJECT_BASELINE.md` §7; P-SQLIB |
| GST-RND-001 / G0-VER-002 | GST rounding rules (G0) | Official e-invoice notification (two-decimal support) | 10-test fixture engine from D-M4 (PROPOSED golden) | PENDING-INPUT (source) | `F-GST-rounding.md`; P-GST-SRC |
| V-FG-003 (schemas) / G0-VER-003 | GST/e-invoice/e-way schemas (G3) | `https://docs.ewaybillgst.gov.in/apidocs/…` + G0_BOUNDARY §3 pointers | 4 boundary tests: no columns, no API, no credentials | PENDING-INPUT | `G0_BOUNDARY.md`; P-FIELD-LIST + schema rows |
| R-04 / G0-VER-004 | WhatsApp/email delivery limits (G5) | Gmail + WhatsApp support pointers | Checksum contract + PS verifier + 2 local runs (mechanism) | PENDING-INPUT | `RELEASE_DELIVERY.md`; P-APK/ZIP/CH-* |
| D-06 / G0-VER-005 | Android Keystore on Android 8 (G0) | `https://developer.android.com/reference/java/security/KeyStore.html` | 7 lifecycle/redaction tests (host); emulator fingerprinted; procedure ready | PENDING-INPUT | security log; DEVICE docs; P-KEYSTORE |
| O-M07 / G0-VER-006 | Printer compatibility (G5) | Internal test record required (no substitute) | 16 golden tests + sheet + script runs (host) | PENDING-INPUT | print log; `PRINTER_TEST_SHEET.md`; P-PRN-* |
| O-14/R-13 / G0-VER-007 | DPDP obligations (G5) | `https://www.meity.gov.in/…/Digital%20Personal%20Data%20Protection%20Act%202023.pdf` | DRAFT control map covering each area; no legal claim | PENDING-INPUT | Legal draft; P-LEGAL-001…005 |
| V-FG-003 (platform) / G0-VER-008 | File-provider/share/restore (G5) | `https://developer.android.com/guide/topics/providers/file-provider` | 5 share + 5 backup tests (host); procedure ready | PENDING-INPUT | security log; DEVICE docs; P-KEYSTORE |

No record is marked PASS from a simulation, mock, memory of a version number, or assumption (global rule 15). Host tests prove only host behavior — stated in each evidence file.

## Addendum 2026-10-05 — prompt 12 recheck (G0-VER-004/006/007/008, OD-FD-006)

No owner evidence was supplied for any item below in this run. Nothing is
marked PASS. Host-side coverage grew (printer capability guard,
backup company-match guard; full host suite green at recheck), but host
tests remain host-only and are not physical, legal, production or delivery
evidence.

| Record | Recheck result 2026-10-05 | Still missing (owner action) |
|---|---|---|
| R-04 / G0-VER-004 | BLOCKED — no APK/AAB artifact under `niaverp/build/` (verified by search); no checksums; no channel delivery run | Release APK/ZIP bytes + SHA-256 + WhatsApp/email/₹0-link delivery receipts (P-APK/ZIP-SHA, P-CH-*) |
| O-M07 / G0-VER-006 | BLOCKED — frozen printer matrix still absent, so no physical 58/80 mm or PDF results exist to attach; host byte-generation coverage extended (capability guard) | Frozen matrix + physical results on ≥3 printers (P-PRN-001…003); OD-FD-006 freeze stays open |
| O-14/R-13 / G0-VER-007 | BLOCKED — no named legal reviewer, review date, or signed interpretation; draft map unchanged and claims nothing | Legal reviewer + date + retention/deletion decision + control mapping (P-LEGAL-001…005) |
| V-FG-003 (platform) / G0-VER-008 | BLOCKED — no target-Android runs for backup/restore/share/FileProvider; host manifest/integrity/company-guard tests extended | Device test results per `DEVICE_TEST_PROCEDURE.md` (P-DEVICE-8/CUR, P-KEYSTORE) |
| OD-FD-006 | BOUNDARY — printer/transport matrix unfrozen; host renderers enforce only the two approved widths (32/48 cols) and fail others visibly | Owner-frozen printer/Android-transport matrix |

## Addendum 2026-10-05 — prompt 13 recheck (G0-VER-001/002/003/005)

Same rule: nothing marked PASS without a present, attributable, non-simulated
artifact. Host suite green at recheck (+229).

| Record | Recheck result 2026-10-05 | Basis / still missing |
|---|---|---|
| V-FG-001 / D-06 / G0-VER-001 | BLOCKED — no SQLCipher-class library selected, no dependency added, no Android 8 compatibility evidence | Library + version + licence + Android 8 proof (P-SQLIB); `EncryptedDatabaseOpener` stays interface-only by design |
| GST rounding / D-M4 / G0-VER-002 | IMPLEMENTED — rule source attached by owner decision (CGST Act §170; `PENDING_INPUTS.md` §E, owner evidence file) and the golden rounding fixture passes: `evidence/fixtures/F-GST-rounding.md` + `test/accounting/gst_test.dart`, green in every full-suite run including today's +229 | STATUS_LEDGER still lists this row as blocked; ledger catches up on owner review — the artifacts themselves are present and attributable |
| V-FG-001 / O-FG-002/O-FG-003 / G0-VER-003 | BLOCKED — no pinned official schema/version evidence, no samples; boundary posture verified (no IRN/ack/e-way columns, APIs, or credentials) | Pinned e-invoice/GST-return/e-way schemas + samples + field list (G3; P-FIELD-LIST, P-EINV/GSTR/EWAY-SCH) |
| D-06 / SEC §5 / G0-VER-005 | BLOCKED — Keystore lifecycle/redaction covered by host tests only; no Android 8 (or current-device) Keystore/key-wrap result | On-device Keystore gen/wrap/fail runs (P-KEYSTORE, P-DEVICE-8/CUR) |

## Addendum 2026-10-05 — P-SQLIB selection (G0-VER-001 partial)

Owner approved the cipher stack (decision prompt): package:sqlite3 3.7.0 +
build-hook `source: sqlite3mc` (hash-pinned prebuilt binaries incl. Android
arm/arm64/x64); Drift 2.35.1 approved for the later DAO slice; Dart licences
MIT (heads read from pub cache). Host proof green: `CipherDatabaseOpener`
keys via raw-hex `PRAGMA key`, proves the MC build per open, bootstraps v9,
persists across reopen, refuses wrong keys, and the file carries ciphertext
(no SQLite header, no plaintext) — `test/data/db/cipher_opener_test.dart`
(+4), full host suite +236. `EncryptedDatabaseOpener` is no longer
abstract-only. Still missing (G0-VER-001 stays open, not PASS): native
cipher licence text from the bundled manifest + Android 8 compatibility
proof on device; `main()` wiring waits on the sandbox-path decision
(path_provider unapproved) and Keystore key bytes.
