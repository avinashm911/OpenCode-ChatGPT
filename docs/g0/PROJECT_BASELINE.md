# NiAvERP G0 — Project Baseline (Phase 0)

Date (UTC): 2026-10-03
Phase: 0 — Project intake and controlled baseline
Prompt authority: `NiAv_G0_Prompts_Pack_v0.7.md` (latest; v0.1–v0.6 retained as history, not authority)
Sign-off baseline: **CONDITIONAL** per `niav_g0_closeout_report_20261001.json` (8 verification records, 7 schema changes). No unconditional sign-off is claimed.
Scope of this file: inventory + requirement-to-file map only. No business features are implemented in Phase 0.

Global rules applied: standalone Android APK baseline only (no server/cloud deps); no invented tax/accounting/permission/sync/security behavior; migrations deterministic/idempotent/auditable with approved rollback only (uninstall current APK → install previous APK → restore external backup; in-place downgrade unsupported); money = integer paise, quantity = integer ×10⁴, round-half-up line amounts, invoice round-off as separate ledger line under D-M4; excluded capabilities are not built; gates remain distinct (G0/G1/G3/G5/S1/R3/etc.).

---

## 1. Confirmed implementation baseline

| Item | Value | Status | Source |
|---|---|---|---|
| Stack | Flutter/Dart, CLI-only build and test, Android-only V1 | CONFIRMED | ZCP §D-01; reconciliation D-05/D-R5; Pack v0.7 baseline |
| Application ID / project | `com.niaverp.niaverp` / `niaverp` 1.0.0+1, standard `flutter create` structure | CONFIRMED (scaffold) | This phase, §5 |
| minSdk / minimum Android | minSdk **26** / Android 8, pinned in `niaverp/android/app/build.gradle.kts` | CONFIRMED | O-M04; TEST/MPL device baseline |
| Reference low-end device | Android 8–9, 2 GB RAM, 32 GB storage; budgets: cold start ≤5 s, quick bill ≤15 s, core report on 20,000 vouchers ≤5 s, APK ≤40 MB per ABI | CONFIRMED (target; not yet measured) | O-M04 |
| Database engine | Drift over encrypted SQLite, SQLCipher-class approach | CONFIRMED (approach only; library pending) | D-06; §3 |
| Money / quantity | Money INTEGER paise; quantity INTEGER ×10⁴ (pcs disp 0, kg/litre 3, other ≤4); line amount = round-half-up(qty×rate/10⁴); invoice round-off separate ledger line to nearest rupee; stock value paise; IDs UUIDv7 TEXT; dates ISO TEXT; timestamps epoch ms UTC | CONFIRMED (rule; not yet implemented — Phase 1/2) | D-M4 / OD-DB-001 |
| Costing | Weighted Average + FIFO only; item overrides group, default Weighted Average; locked after first posted stock movement; negative stock allowed with warning, no-layer issues at last known cost, no retro revaluation in V1 | CONFIRMED (rule; implementation = G0-SCH-001, gate G1) | D-M5/D-08/D-FG-013/O-09/OD-004/OD-FD-001 |
| Period lock | By date; unlock needs right + reason + audit | CONFIRMED (rule; implementation = G0-SCH-002, gate G1) | D-M5 |
| Sync baseline (G0 scope only) | Record versioning + `operation.base_version` + `operation.dependencies` (G0-SCH-005, gate S1); `sync_conflict` record shape (OD-DB-006); master rule = field merge, same-field clash → host arrival wins, loser logged (SYNC 6 / G0-CON-004, gate S1). LAN/hotspot + file sync remain S1; full sync implementation is out of this pack. | CONFIRMED (fields only; conflict policy implementation remains outside this pack) | SYNC; Pack v0.7 §Phase 7 |
| Rollback procedure | Uninstall current APK → install previous APK → restore external backup. In-place downgrade NOT supported. | CONFIRMED | RSP 5 / G0-CON-003 |
| Navigation model | Home, Billing, Parties & Items, Reports, More (MPL bottom bar; UIUX tree superseded) | CONFIRMED | OD-UI-001 / G0-CON-005 |
| Voice input | Rejected/excluded from V1 (not deferred, not conditional) | CONFIRMED (excluded) | G0-OWN-002 (OD-UI-003/FR-M02-002) |
| Excluded from V1 baseline | Voice input; Tally/Busy native import; TDS/TCS; PF/ESI/payroll; automatic transliteration; direct e-invoice/e-way APIs | CONFIRMED (not built) | Pack global rule 11; G0-DEF-001/002/003; G0-CON-001/002 |
| GST/e-invoice G0 boundary | G0 = data-model capture + schema-version evidence only; no direct portal calls; full file workflow = R3/G3 unless separately approved; GST return JSON = R1a under FR-M16-003 | CONFIRMED (boundary; fields BLOCKED until owner field list exists) | Pack v0.7 Phase 4; O-10/O-FG-002/O-FG-003 |

No source document is silently superseded. Filename versions (e.g. `…v0.4.html`) are stale labels; the operative versions are the internal living-document versions in §4. Historical change logs and backup directories are retained as history; the G0 reconciliation sections (`niav-workbook-reconciliation`, `niav-g0-final-reconciliation`, `niav-g0-body-corrections`, `niav-g0-schema-implementation`, `niav-g0-rtm-test-impact`, verification-evidence and closeout logs) plus the latest owner decisions in `niav_final_reconciliation_report_20261001.json` are authoritative where they conflict with older body text.

---

## 2. Toolchain inventory (measured, not assumed)

| Component | Version / path | How verified |
|---|---|---|
| Flutter | 3.47.5, channel stable, Framework revision `6a19cca564` (2026-09-17), Engine revision `af7e796e16` | `flutter.bat --version`, `flutter doctor -v` |
| Dart | 3.13.4 (`sdk: ^3.13.4` in `niaverp/pubspec.yaml`) | `flutter doctor -v`; pubspec |
| DevTools | 2.60.0 | `flutter doctor -v` |
| Flutter SDK path | `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter` | `flutter doctor -v`; `niaverp/android/local.properties` (`flutter.sdk=…`) |
| PATH note | Flutter/Dart are **not on PATH**. Stale PATH entry `C:\Users\USER\niav-erp-build\flutter\bin` does not exist. All Flutter commands in this phase used the full path above. | `flutter doctor -v` (“flutter binary is not on your path”); `Test-Path` checks |
| Android SDK | 36.0.0 at `C:\Users\USER\AppData\Local\Android\sdk`; Platform `android-37.0`; build-tools `36.0.0`; Emulator `37.1.11.0` | `flutter doctor -v` |
| Java runtime | OpenJDK 25.0.3 (Android Studio JBR at `C:\Program Files\Android\Android Studio\jbr\bin\java`); app `compileOptions` JavaVersion.VERSION_17, Kotlin `jvmTarget` JVM_17 | `flutter doctor -v`; `android/app/build.gradle.kts` |
| Gradle wrapper | 9.3.1 (`gradle-9.3.1-all.zip`) | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle.kts` |
| Kotlin Gradle plugin | 2.4.0 | `android/settings.gradle.kts` |
| compileSdk / targetSdk | `flutter.compileSdkVersion` / `flutter.targetSdkVersion` (Flutter-resolved; not pinned in this phase) | `android/app/build.gradle.kts` |
| minSdk | **26** (explicitly pinned; replaced template default `flutter.minSdkVersion`) | `android/app/build.gradle.kts` (edited this phase) |
| OS / host | Windows 10 Pro 64-bit 22H2 (10.0.19045.6466), locale en-IN; Chrome/Edge available; Visual Studio NOT installed (Windows desktop target not required for Android APK baseline) | `flutter doctor -v` |
| Exact scaffold command | `& "C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\flutter.bat" create --org com.niaverp --project-name niaverp niaverp` run in `E:\NiavERP v2 OpenAI` → `Wrote 131 files.` | Terminal output, §5 |

Build-tool note: `flutter.minSdkVersion` default was not recorded as a versioned value (it is SDK-resolved); Phase 0 pins `minSdk = 26` explicitly per O-M04 so the baseline does not float with SDK upgrades.

---

## 3. Database engine and encryption approach

- Engine (CONFIRMED approach, NOT yet added as a dependency): **Drift over encrypted SQLite using a SQLCipher-class approach**. No `drift`/`sqlite` package is present in `niaverp/pubspec.yaml` in this phase (only `flutter`, `cupertino_icons`, `flutter_test`, `flutter_lints`). Packages are not locked in until the owner confirms them (§6).
- Approved crypto/key shape (CONFIRMED rule, implementation pending Phase 3): whole-DB encryption, SQLCipher-class engine (AES-256); random 256-bit key wrapped by Android Keystore; PIN/biometric gates key use; final library chosen in G0 spike (D-06).
- Audit payload (CONFIRMED rule): field-level old/new deltas as JSON; sensitive fields hash-only; hash chain over canonical record (OD-DB-004).
- Attachments/imports (CONFIRMED rule): JPEG/PNG/PDF only, ≤5 MB each, downscaled images, magic-byte validation, never executed, app-private storage, per-file AES-GCM with keys wrapped by DB key; imports `.xlsx`/`.csv` only, 10 MB / 50,000-row caps (OD-DB-005 / O-FG-015).
- Conflict record shape (CONFIRMED shape): `sync_conflict(conflict_id, entity, entity_id, losing_op_id, winning_op_id, base_version, status, resolution, resolver, resolved_at)` (OD-DB-006).
- G0 schema deltas G0-SCH-001…007 are **approved design changes — implementation required** (gates G1/G0/S1 as listed in §9). No migration files exist yet; they belong to Phase 1.
- **BLOCKED**: SQLCipher-class library licence and Android 8 compatibility evidence. Status = `VERIFY/BLOCKED` until the owner confirms the exact library, version, and licence evidence (G0-VER-001 / V-FG-001 / D-06, gate G0). Keystore Android 8 behavior is likewise evidence-required (G0-VER-005, gate G0). No encryption code was added in Phase 0.

---

## 4. Source documents and their versions (on-disk, operative)

Living-document rule: the internal version in the document body is operative. Backup directories (`*.bak.html`, `niav_*_backups_*`) are history only and are not requirements authority.

### 4a. Requirements HTML (15)

| Key | File (stale filename label) | Operative internal version | Last updated | Role |
|---|---|---|---|---|
| REG | `NiAv_ Modules & Sub-Modules Register v0.4.html` | **v0.9** (Draft) | 30 Sep 2026 (+ G0 sections 2026-10-01/03) | Modules register NIAV-REG |
| SEC | `NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html` | **v0.7** (Draft) | 30 Sep 2026 (+ G0 2026-10-01) | Security NIAV-SEC |
| MPL | `NiAv_ Universal Master Plan v0.2.html` | **v0.7** (Draft) | 30 Sep 2026 (+ G0 2026-10-01/03) | Master plan NIAV-MPL; gates MPL 11.4 authoritative |
| ZCP | `NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html` | **v0.10** (Draft) | 30 Sep 2026 (+ G0 2026-10-01/03) | Zero-cost plan NIAV-ZCP; D-01 Flutter CLI |
| DSS | `NiAv_Data_Schema_Specification_v0.1.html` | **v0.4** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-01) | Data schema NIAV-DSS |
| DB | `NiAv_Database_Schema_Document_v0.1.html` | **v0.4** (Logical baseline/Living) | 30 Sep 2026 (+ G0 2026-10-01) | Database schema NIAV-DB |
| FGA | `NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html` | **v0.6** (title v0.6) | 30 Sep 2026 (+ G0 2026-10-03) | Fit-gap register |
| FDD | `NiAv_Functional_Design_Document_v0.1.html` | **v0.4** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-01) | Functional design NIAV-FDD |
| FRD | `NiAv_Functional_Requirements_Input_Data_v0.1.html` | **v0.6** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-03) | 75+ input requirements NIAV-FRD-INPUT |
| RSP | `NiAv_Release_and_Support_Playbook_v0.1.html` | **v0.6** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-03) | Release/support NIAV-RSP |
| RTM | `NiAv_Requirements_Traceability_Matrix_v0.1.html` | **v0.4** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-01) | Traceability NIAV-RTM |
| SYNC | `NiAv_Sync_Protocol_Specification_v0.1.html` | **v0.6** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-03) | Sync protocol NIAV-SYNC |
| TEST | `NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html` | **v0.4** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-01) | Test plan NIAV-TEST |
| UIUX | `NiAv_UI_UX_Specification_Document_v0.1.html` | **v0.5** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-03) | UI/UX NIAV-UIUX |
| UX | `NiAv_UX_Specification_v0.2.html` | **v0.6** (Draft/Living) | 30 Sep 2026 (+ G0 2026-10-03) | UX NIAV-UX-SPEC |

### 4b. G0 prompt packs (authoritative = v0.7)

| File | Version | Standing |
|---|---|---|
| `NiAv_G0_Phasewise_Prompts_Pack_v0.1.md` | v0.1 | Historical precursor (explicit global rules v4 form) |
| `NiAv_G0_Prompts_Pack_v0.2.md` … `v0.6.md` | v0.2–v0.6 | Historical iterations (retained, not authority) |
| `NiAv_G0_Prompts_Pack_v0.7.md` | **v0.7** | **Authoritative for this phase** (owner prerequisites, 9 phases 0–8, global rules v4 form, G0-boundary clarifications) |

### 4c. Reconciliation / closeout evidence (authoritative for G0 disposition)

| File | Date | Content |
|---|---|---|
| `niav_reconciliation_report_20261001.json` | 2026-10-01 | Workbook decisions integration (source: `NiAv_Decisions_Workbook_v0.1.xlsx` Decisions sheet; that workbook itself is an external reference under `C:/Users/USER/Downloads/…`, not present in this directory) |
| `niav_final_reconciliation_report_20261001.json` | 2026-10-01 | G0 exception register rows: G0-OWN-001/002, G0-DEF-001/002/003, G0-VER-001…008, G0-CON-001…005, G0-SCH-001…007 |
| `niav_g0_closeout_report_20261001.json` | 2026-10-01 | 15 documents, 8 verification records, 7 schema changes, sign-off **CONDITIONAL** |
| `outputs/01a0f1dd-b8a2-7ba3-9346-01abef17f993/NiAv_G0_Exception_Register_v0.1.xlsx` (+ `.inspect.ndjson`, `.png`) | 2026-10-01 | Exception register v0.1 (owner inputs applied) |
| `outputs/…/NiAv_G0_Verification_Evidence_Register_v0.1.xlsx` (+ `.png`, `.inspect.ndjson`) | 2026-10-01 | Verification evidence register v0.1 (8 records; sources attached, execution pending) |
| `.niav_linker_closures.json` | 2026-10-01 | Single closure D-06 (suggest recommendation, ZCP) |

G0 reconciliation IDs authoritative for implementation: G0-SCH-001…007 (approved design changes), G0-CON-001…005 (body-contradiction decisions), G0-VER-001…008 (evidence-required), G0-OWN-001/002, G0-DEF-001/002/003. See §9 for file mapping.

---

## 5. Project structure

### 5a. Pre-scaffold (as found)
- Container `E:\NiavERP v2 OpenAI` held only requirements/tooling: 15 HTML specs, 7 prompt packs, 3 JSON reports, `outputs/…` registers, `*.mjs`/`*.py`/`*.ps1` linker/reconciliation scripts, and backup directories.
- **No implementation project existed**: no `pubspec.yaml`, no `android/`, `lib/`, `test/`, no migration files, no fixtures, no CI workflows (verified by glob: `**/pubspec.yaml` = none, `**/test/**/*.dart` = none, `.github/workflows/*` = none, `**/migrations/*` = none).

### 5b. Post-scaffold (this phase)
- Created `niaverp/` via the exact `flutter create` command in §2 (131 files, standard template; no custom build structure invented).
- Top level: `.dart_tool/`, `.idea/`, `analysis_options.yaml`, `android/`, `ios/`, `lib/` (`main.dart` template counter app — **not** NiAvERP business UI), `linux/`, `macos/`, `test/` (`widget_test.dart` template smoke test), `web/`, `windows/`, `pubspec.yaml`, `pubspec.lock`, `README.md`, `.metadata`, `.gitignore`.
- Android: `android/app/build.gradle.kts` (minSdk 26 pinned this phase), `android/settings.gradle.kts` (AGP 9.1.0, Kotlin 2.4.0), `android/gradle/wrapper/gradle-wrapper.properties` (Gradle 9.3.1), `android/local.properties` (SDK + flutter.sdk paths).
- Only implementation edit in Phase 0: the minSdk pin (see change log). No Drift tables, no Riverpod/router/PDF/Excel/barcode/ESC-POS code, no Keystore code, no sync code, no GST code, no printer code were added.

---

## 6. Package candidates — UNVERIFIED (do not lock in)

Per Pack v0.7 Phase 0, the following are **unverified candidates only**. None is in `niaverp/pubspec.yaml`; none is approved for `flutter pub add` until the owner confirms the exact package and version.

| Candidate | Purpose (per pack) | Status |
|---|---|---|
| Riverpod | State management | UNVERIFIED — owner confirmation required |
| go_router | Navigation/routing | UNVERIFIED — owner confirmation required |
| PDF (`pdf`/`printing` or owner-named equivalent) | PDF via Android print/share, A4/A5 | UNVERIFIED — owner confirmation required; printer matrix OD-FD-006 also required |
| Excel | Excel import/export (documented templates; native Tally/Busy adapters remain R3) | UNVERIFIED — owner confirmation required |
| Barcode | Scanning (scope per REG/FRD; no invented scope) | UNVERIFIED — owner confirmation required |
| ESC/POS | Bluetooth thermal 58 mm / 80 mm | UNVERIFIED — owner confirmation required; ≥3-printer physical evidence required |

Any future `flutter pub add` must record package, version, licence, and owner approval in the change log. No server/cloud package may be added to the standalone APK baseline.

---

## 7. SQLCipher-class library licence — VERIFY/BLOCKED

- Status: **VERIFY/BLOCKED** (Pack v0.7 Phase 0 prerequisite; G0-VER-001, gate G0).
- Missing: confirmed library name, exact version, licence text/evidence, and Android 8 compatibility evidence (V-FG-001/D-06). Keystore Android 8 wrap/unwrap behavior evidence is separately missing (G0-VER-005, gate G0).
- Effect: Phase 0 records the approach (§3) but adds no encrypted-DB code and makes no licence claim. Phase 1 (migrations) and Phase 3 (security/platform) remain BLOCKED on this input to the extent they require the named library.

---

## 8. Tests, fixtures, migrations, CI

| Area | Pre-existing | Added this phase | CI command |
|---|---|---|---|
| Unit/widget tests | None | `niaverp/test/widget_test.dart` (Flutter template `Counter increments smoke test`; unmodified) | `flutter test` in `niaverp/` → **All tests passed** (1/1). Evidence: `docs/g0/evidence/baseline/flutter-test-20261003.log.md` |
| Fixtures (accounting/statutory) | None | None (Phases 1–2) | — |
| Migration files | None | None (Phase 1: G0-SCH-001…007) | — |
| CI workflows | None (no `.github/workflows/`, no local CI script for the app) | None in Phase 0 | Manual CLI only: `flutter test` (this phase). `flutter analyze` / APK build not run in Phase 0. |

Every future implementation change must add tests + fixtures + traceability IDs + short change log, and must show command + environment + result + saved evidence (global rules 6–7). Phase 0 claims no business-test pass.

---

## 9. Requirement-to-file map (G0 acceptance baseline)

“Impl.” = implementation file in this repo (TBD = deferred to the listed gate/phase; no file invented).

### 9a. Baseline, money/quantity, rollback, navigation, exclusions

| Requirement / decision ID | Topic | Source file(s) | Impl. file (Phase 0) |
|---|---|---|---|
| D-01 | Flutter/Dart, Android-only V1, CLI-only | ZCP v0.10; reconciliation D-05/D-R5 | `niaverp/pubspec.yaml`, `niaverp/lib/main.dart` (template scaffold) |
| O-M04 | minSdk 26; low-end Android 8–9/2 GB/32 GB; perf budgets | MPL v0.7; TEST v0.4 | `niaverp/android/app/build.gradle.kts` (minSdk 26 pinned) |
| D-M4 / OD-DB-001 | Paise / ×10⁴ / round-half-up / round-off ledger line; UUIDv7/ISO/epoch | DB v0.4; DSS v0.4; MPL/SEC/FRD reconciliation | TBD Phase 1/2 (no money code in Phase 0) |
| RSP 5 / G0-CON-003 | Rollback: uninstall → install previous → restore external backup; no in-place downgrade | RSP v0.6; DSS; TEST | TBD (documented policy; no rollback code in Phase 0) |
| OD-UI-001 / G0-CON-005 | Navigation: Home, Billing, Parties & Items, Reports, More | MPL v0.7; UIUX v0.5; UX v0.6 | TBD (no nav code in Phase 0) |
| G0-OWN-002 (OD-UI-003/FR-M02-002) | Voice input rejected from V1 | FRD v0.6; UIUX v0.5; UX v0.6 | Excluded — no file (no voice code) |
| G0-CON-001 (O-FG-007/008) | TDS/TCS later release; PF/ESI/payroll out of scope | MPL/ZCP/REG/FRD/RTM | Excluded — no file |
| G0-CON-002 (O-FG-006/A-FG-006) | Tally/Busy native import = R3 feasibility only; V1 = Excel templates | REG/FDD/FRD/FGA/RTM | Excluded native path — no file; Excel TBD R2/G-phase |
| SYNC 6 / OD-DB-006 / G0-CON-004 | Field merge; same-field clash host-arrival-wins + loser logged; `sync_conflict` shape | SYNC v0.6; DSS/DB | TBD S1 (G0-SCH-005 fields only in Phase 1) |
| G0-DEF-001/002/003 | Deferred: native adapters R3; TDS/TCS later + PF/ESI out; auto-transliteration R2 | FGA/FDD/FRD/REG/MPL/UX | Out of G0 acceptance — no file |
| G0-OWN-001 (D-12) | Single APK vs flavours (gate G5) | SEC v0.7 | TBD G5 — no flavour split in Phase 0 |

### 9b. Seven approved schema changes (implementation = Phase 1)

| ID | Change | Source | Impl. file |
|---|---|---|---|
| G0-SCH-001 (G1) | Cost-layer + stock-movement (FIFO/weighted-avg, negative-stock fallback + reconciliation) | DB/DSS; D-M5/D-08/OD-DB-002 | TBD Phase 1 migration + tests |
| G0-SCH-002 (G1) | Period-lock entity (range, scope, status, unlock actor/reason/timestamp, audit link) | DB/DSS/FDD/UIUX/TEST; D-M5 | TBD Phase 1 |
| G0-SCH-003 (G1) | Bill-allocation entity (source/settlement lines, amount, date, status, operation lineage) | DB/DSS/FRD/TEST; FR-M06 | TBD Phase 1 |
| G0-SCH-004 (G1) | Effective-dated tax/HSN + versioned layout-profile (sync/backup metadata) | DB/DSS/MPL/FRD/UIUX | TBD Phase 1 |
| G0-SCH-005 (S1) | Record version + `operation.base_version` + `operation.dependencies` | DB/DSS/SYNC/TEST; SYNC 3/6 | TBD Phase 1 (S1 fields only) |
| G0-SCH-006 (G0) | Trial-anchor + denylist storage (lifecycle, revoke, audit evidence) | DB/DSS/SEC/TEST | TBD Phase 1 |
| G0-SCH-007 (G1) | Voucher-line discount fields (calculation + rounding) | DB/DSS/FRD/UX/TEST | TBD Phase 1 |

### 9c. Eight verification records (evidence-required; none closed by Phase 0)

| Record | Subject | Gate | Source | Evidence / impl. |
|---|---|---|---|---|
| G0-VER-001 (V-FG-001/D-06) | Encrypted SQLite library for Drift on Android 8+ | G0 | ZCP/SEC/FGA | BLOCKED — §7 |
| G0-VER-002 (GST-RND/D-M4) | GST rounding rule + golden fixture | G0 | MPL/DSS/DB/TEST | BLOCKED — Phase 2 fixture required |
| G0-VER-003 (V-FG-001/O-FG-002/003) | GST/e-invoice/e-way official schemas | G3 | FGA/REG/ZCP/TEST | BLOCKED — Phase 4 (G0 boundary only) |
| G0-VER-004 (R-04) | WhatsApp/email APK delivery limits + checksum test | G5 | ZCP/RSP/FGA | BLOCKED — Phase 6 |
| G0-VER-005 (D-06/SEC §5) | Keystore behavior on Android 8 | G0 | SEC/ZCP/TEST | BLOCKED — Phase 3 device test |
| G0-VER-006 (O-M07/OD-008) | Printer compatibility (≥3-printer matrix) | G5 | REG/FRD/TEST/UIUX | BLOCKED — Phase 6 + OD-FD-006 matrix |
| G0-VER-007 (O-14/R-13) | Data-protection obligations + control mapping | G5 | ZCP/REG/SEC | BLOCKED — Phase 5 legal review |
| G0-VER-008 (V-FG-003) | File-provider/share/restore on target Android | G5 | FGA/SEC/RSP/TEST | BLOCKED — Phase 3/6 device test |

Full RTM/test-impact review table for G0-SCH-001…007 is in RTM v0.4 and TEST v0.4 (`niav-g0-rtm-test-impact` sections); reuse those rows for implementation traceability in Phase 1+.

---

## 10. Confirmed vs blocked assumptions

| # | Assumption | Label |
|---|---|---|
| A-01 | Flutter/Dart CLI-only Android APK baseline; scaffold at `niaverp/` with standard template | CONFIRMED |
| A-02 | minSdk 26 / Android 8 pinned | CONFIRMED |
| A-03 | Money paise / qty ×10⁴ / half-up / D-M4 round-off line | CONFIRMED (rule; implementation pending) |
| A-04 | Drift + SQLCipher-class AES-256 approach with Keystore-wrapped key | CONFIRMED (approach; library/licence pending) |
| A-05 | Rollback = uninstall/install/restore; no in-place downgrade | CONFIRMED (policy) |
| A-06 | Sync G0 scope = versioning fields only (S1); field-merge/host-wins rule recorded | CONFIRMED (scope/boundary) |
| A-07 | Riverpod / go_router / PDF / Excel / barcode / ESC-POS selections | BLOCKED (unverified candidates) |
| A-08 | SQLCipher-class library name/version/licence + Android 8 evidence | BLOCKED (G0-VER-001) |
| A-09 | IRN/ack/e-way field list (R1a capture); official e-invoice + GST-return schemas (FR-M16-003) | BLOCKED (Phase 4) |
| A-10 | Printer matrix OD-FD-006 (≥3 models); legal reviewer + date (O-14/R-13); Android 8 + current test devices | BLOCKED (Phases 5–6 / Phase 3) |
| A-11 | GST rounding golden fixture source | BLOCKED (G0-VER-002, Phase 2) |
| A-12 | Any tax/accounting/permission/sync/security value not in §9 | BLOCKED (not invented) |

---

## 11. Change log (Phase 0)

| Date | Change | Files | Traceability |
|---|---|---|---|
| 2026-10-03 | Scaffold greenfield Flutter project (`flutter create --org com.niaverp --project-name niaverp niaverp`; 131 files, template counter app, no business logic) | `niaverp/**` (new) | D-01, D-05/D-R5, O-M04 |
| 2026-10-03 | Pin `minSdk = 26` (was template `flutter.minSdkVersion`) with G0 comment | `niaverp/android/app/build.gradle.kts` | O-M04 |
| 2026-10-03 | Add G0 baseline inventory + requirement map (this file) | `docs/g0/PROJECT_BASELINE.md` (new) | G0 Phase 0 acceptance |
| 2026-10-03 | Save scaffold test evidence | `docs/g0/evidence/baseline/flutter-test-20261003.log.md` (new) | Global rule 7 |

No migration, fixture, CI, licence-screen, or business-code change was made in Phase 0.

---

## 12. Blockers and smallest owner questions

Phase 0 itself is not blocked, but the following owner prerequisites (Pack v0.7) block later phases. Each needs a single input before the listed phase is re-run.

1. **SQLCipher-class library + licence (blocks G0/P1/P3)**: Which exact SQLCipher-class library, version, and licence evidence is approved, with Android 8 compatibility proof? (G0-VER-001)
2. **GST rounding source (blocks Phase 2)**: Which official rounding rule source attaches to G0-VER-002, and is the golden fixture in TEST authoritative?
3. **Schemas (blocks Phase 4/G3)**: What are the official e-invoice / GST-return (FR-M16-003) / e-way schema sources + versions, and what is the owner-approved IRN/ack/e-way field list for R1a capture?
4. **Printers (blocks Phase 6/G5)**: What is the frozen 3-printer matrix under OD-FD-006 (make/model, connection, paper)?
5. **Legal (blocks Phase 5/G5)**: Who is the named legal reviewer and review date for O-14/R-13, and which official data-protection source + retention decisions attach?
6. **Devices (blocks Phase 3)**: Which physical Android 8 device and which current-Android device (model, version, build) are assigned for Keystore/backup/share/restore tests?

---

## 13. Commands, tests, limitations, next gate

**Commands run (CLI only):**
- `flutter.bat --version` and `flutter.bat doctor -v` (inventory; full-path binary, §2)
- `flutter.bat create --org com.niaverp --project-name niaverp niaverp` in `E:\NiavERP v2 OpenAI` → `Wrote 131 files.`
- `flutter.bat test` in `E:\NiavERP v2 OpenAI\niaverp` → `00:00 +1: All tests passed!` (evidence §8 / `docs/g0/evidence/baseline/flutter-test-20261003.log.md`)
- Read-only inventory: `Get-ChildItem`, `Test-Path`, `Get-Content` (gradle-wrapper, local.properties, pubspec.lock head), `Read`/`Glob`/`Grep` over the 15 HTML specs, 7 packs, 3 JSON reports, and `outputs/…` registers.

**Tests:** Passed 1 (template smoke test); Failed 0; Blocked 0 at scaffold level. No business tests exist yet by design.

**Changed files:** `niaverp/**` (131 new scaffold files); `niaverp/android/app/build.gradle.kts` (minSdk pin); `docs/g0/PROJECT_BASELINE.md` (new); `docs/g0/evidence/baseline/flutter-test-20261003.log.md` (new). No unrelated files rewritten.

**Known limitations:** Scaffold is a template counter app, not NiAvERP functionality; compileSdk/targetSdk float with the Flutter SDK; Flutter not on PATH (full-path documented); Android 8 device, printer matrix, schemas, field list, library/licence, and legal review remain downstream-gate items (see §12); G0 baseline acceptance is recorded separately in `G0_UNCONDITIONAL_SIGNOFF.md`; backup dirs and stale filename labels intentionally untouched.

**Next gate:** Phase 1 — Schema delta and migration design (G0-SCH-001…007). Do not start Phase 1 implementation until the SQLCipher-class library decision (§7) is recorded, since migrations depend on the encrypted-DB engine choice.

---

## G0 PHASE RESULT

```text
G0 PHASE RESULT
Phase: 0 — Project intake and controlled baseline
Status: PASS
Commands run:
- & "<flutter-sdk>\bin\flutter.bat" --version
- & "<flutter-sdk>\bin\flutter.bat" doctor -v
- & "<flutter-sdk>\bin\flutter.bat" create --org com.niaverp --project-name niaverp niaverp (in E:\NiavERP v2 OpenAI)
- & "<flutter-sdk>\bin\flutter.bat" test (in E:\NiavERP v2 OpenAI\niaverp)
Changed files:
- niaverp/** (new scaffold, 131 files)
- niaverp/android/app/build.gradle.kts (minSdk = 26 pinned)
- docs/g0/PROJECT_BASELINE.md (new)
- docs/g0/evidence/baseline/flutter-test-20261003.log.md (new)
Tests:
- Passed: 1 (template Counter increments smoke test)
- Failed: 0
- Blocked: 0 (scaffold level; business phases remain evidence-gated per §9c/§12)
Evidence:
- docs/g0/evidence/baseline/flutter-test-20261003.log.md
- niav_g0_closeout_report_20261001.json (CONDITIONAL baseline)
- niav_final_reconciliation_report_20261001.json (G0 IDs)
- outputs/.../NiAv_G0_Exception_Register_v0.1.xlsx and NiAv_G0_Verification_Evidence_Register_v0.1.xlsx
Traceability IDs:
- D-01, D-05/D-R5, O-M04, D-M4/OD-DB-001, D-06, SYNC 6/OD-DB-006, RSP 5, OD-UI-001, G0-SCH-001…007, G0-CON-001…005, G0-VER-001…008, G0-OWN-001/002, G0-DEF-001/002/003
Open decisions or owner actions:
- SQLCipher library/version/licence + Android 8 evidence (G0-VER-001)
- IRN/ack/e-way field list + official schemas FR-M16-003 (Phase 4/G3)
- Printer matrix OD-FD-006 (Phase 6/G5)
- Legal reviewer/date O-14/R-13 (Phase 5/G5)
- Android 8 + current test devices (Phase 3)
- Package confirmations: Riverpod, go_router, PDF, Excel, barcode, ESC/POS (all unverified)
Next gate:
- Phase 1 — Schema delta and migration design (G0-SCH-001…007)
```
