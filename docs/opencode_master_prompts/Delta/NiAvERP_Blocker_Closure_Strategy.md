# NiAvERP: Blocker Closure Strategy
Branch reviewed: `phase-12-evidence-blocked` (commit f1d3e94). Review date: 2026-10-06.

## How to read this document
- **VERIFIED** means I read the code or document myself, or a reviewer read it and quoted it. Nothing was run, because no Flutter or Android tools are available to me.
- **INFERRED** means it is reasoned from code but not run. Treat it as likely, not proven.
- **Where this document differs from the project's own reports:** several "PASS" results in the D1 to D4 reports are too generous, and I say where.

## 1. The honest picture in one page

1. The project's own state is: prompts 00-11 are "complete with blocks"; prompt 12 is stopped; prompt 13 cannot run. The blocked evidence items are G0-VER-004, 006, 007 and 008, plus the earlier ones (001, 003, 005).
2. **The biggest finding is that nobody has yet proven the app starts on a real phone, and I found a bug that would stop it** (VERIFIED).
   - `main.dart:38` asks Android for `getDeviceId`.
   - `MainActivity.kt` only answers `getDatabaseKey` and `getFilesDirectory`.
   - The app therefore lands on the "database unavailable" screen before it ever asks for the key.
   - The 431 passing tests use a fake Android channel, so they could not catch this.
3. Many blockers are not "missing evidence". They are missing or half-finished work that AI can do:
   - backup and restore;
   - GST on invoices;
   - the company-switch bug;
   - report export;
   - import;
   - licence and users screens;
   - print and share;
   - the build and release setup.
4. Some blockers genuinely need a human or the real world:
   - a named legal reviewer;
   - a physical printer;
   - delivering the APK through WhatsApp or email;
   - a few owner decisions.

   AI must not "close" these on paper. Doing so would break the project's own honesty rule.

## 2. Every blocker, classified

**Legend:** 🟢 AI can close fully. 🟡 AI does most of the work and you do a small action or decision. 🔴 Needs a real-world action AI cannot do or fake.

### A. Defects and gaps in the code (all AI-closable)

| # | Blocker | Basis | Class |
|---|---|---|---|
| A1 | App cannot open its database on a device (`getDeviceId` not implemented in Kotlin). | VERIFIED | 🟢 |
| A2 | Keystore weaknesses (`MainActivity.kt`): a lost key alias is silently regenerated, the key blob and IV are saved as two separate files, and a new key can be created on top of an existing database. Any of these can lock you out of your data. | VERIFIED | 🟢 |
| A3 | Company switch can show the old company's data (test at `shell_test.dart:~180`). Home caches its data and tab keys do not include the company. The "test design issue" label is wrong; it is a real bug. | INFERRED from code | 🟢 |
| A4 | Invoices post no GST. The party receivable excludes tax, so the books are balanced but wrong for any taxed invoice (`voucher_engine.dart:869`). D3 reported PASS regardless. | VERIFIED | 🟡 (decision memo, §3 Step 2) |
| A5 | Backup and restore are not implemented. Only validation helpers exist, and the More-tab button is disabled. | VERIFIED | 🟢 |
| A6 | Backup integrity check can be bypassed by removing the MAC (`backup.dart:179-182`). | VERIFIED | 🟢 |
| A7 | Trial clock-rollback guard is never called by the app. | VERIFIED | 🟢 |
| A8 | Import (Excel/CSV), users/roles, licence/trial, print/PDF and share screens are missing or are disabled placeholders. | VERIFIED | 🟢 (each needs its own prompt) |
| A9 | Report export is not done (Excel/CSV). The "no new packages" rule blocked it, but a plain CSV or minimal XLSX needs no package. | Reviewer inference | 🟢 |
| A10 | Stock Journal valuation behaviour is unfrozen (OD-FD-001). | VERIFIED in docs | 🟡 (decision) |
| A11 | Some screens still have hard-coded English text (party/item dialog). The runtime reads a hand-copied Dart file, not the ARB files, with no test that they match. | VERIFIED | 🟢 |
| A12 | Build and release setup. | | |
| | • `applicationId` is still the template `com.niaverp.niaverp`. | VERIFIED | 🟢 |
| | • There is no CI workflow (no `.github`). | VERIFIED | 🟢 |
| | • `pubspec` is fixed at version `1.0.0+1`. | VERIFIED | 🟢 |
| | • The release signing guard may also break debug builds. | INFERRED | 🟢 |
| | • You must make the final app name and icon decisions. | | 🟡 |

### B. Missing evidence (the "gate" blockers)

| ID | What is missing | Class | Honest route |
|---|---|---|---|
| G0-VER-001 / P-SQLIB | Proof that the encrypted library works on Android 8, plus its licence text. | 🟡 | AI builds an automated Android 8 emulator test (§3 Step 3). Your register's own question says "physical or AVD", so an emulator is acceptable under your rules. I have not confirmed the sign-off text accepts it, so ask your reviewer. A real phone is stronger. |
| G0-VER-005 | Android 8 Keystore test result. | 🟡 | Same emulator run, then a real phone if you have one. |
| G0-VER-008 | Backup, restore, share and file-provider on the target Android. | 🟡 | Possible only after A5 is built. Emulator first. |
| G0-VER-003 | Official GST, e-invoice and e-way schemas. | 🟡 | AI can fetch and pin the public schema pages. You must approve it, because your register says "nothing vendored without approval". This is only needed at G3/R1a, not now. |
| G0-VER-004 | Real APK/ZIP delivery over WhatsApp, email and a link, with matching SHA-256. | 🔴 | AI builds the APK and the checksum checklist. You do the sends (§4). |
| G0-VER-006 | Real printer results (58 mm, 80 mm, PDF A4/A5). | 🔴 | A physical printer is required. AI writes the test sheet. |
| G0-VER-007 | Named legal reviewer and sign-off. | 🔴 | AI prepares a reviewer briefing pack. A human lawyer must sign. |
| G0-OWN-001 | Owner item (details not read). | ? | Read the detail first. |

### C. Items that are correct as they are
- Voice input is rejected, and Tally/Busy, TDS/TCS and transliteration are deferred. These are deliberate and are not blockers.
- Material Issue/Receive is placed in a later edition (R1b+) by the Modules Register. The code is right to leave it out.

## 3. The plan, in order
Run each step from the project folder, one at a time. After each, send me the results file. **Before anything else, commit the current state to a new branch and do not work on `main`.**

**Model advice:** use the strongest, largest-context coding model you can access with `-m`. Your earlier "Provider returned error" came from a small model. Weak models are the likeliest cause of the "PASS but really incomplete" reports.

### Step 1 (E1): Make the app start on a phone
Fixes A1, A2, A7 and the Kotlin gaps in A12. The prompt must require:
- Implement every channel method that Dart calls.
- Add a **contract test** that fails if Dart calls a method that Kotlin does not handle.
- Make the key alias and blob one atomic unit.
- Refuse to create a new key if a database file already exists.
- Distinguish a lost key from a corrupt blob.
- Call the clock-rollback guard at startup.

Exit proof: an Android 8 emulator test (Step 3) opens the database.

### Step 2 (E2): Fix correctness
**Company switch (A3).** Include the company id in each tab key, and reset the tab state on switch. Add a test that proves no stale company data appears.

**GST (A4).** Standard GST law compares the company state with the party state: the same state gives CGST+SGST, and a different state gives IGST. This is outside knowledge and not in your HTML documents. Your PENDING_INPUTS §E shows you already authorised the assistant to act as owner for decision-only inputs. The cleanest path is to write a dated one-page **owner decision memo** that you approve. It would record:
- the state-comparison rule;
- the tax ledger names (Output CGST/SGST/IGST, Input CGST/SGST/IGST);
- a documented treatment of unknown states.

Then AI implements tax posting and returns with it. You should still have an accountant check a few sample invoices.

**Backup security (A6).** Make the MAC mandatory, and bind the hash to the company and schema version.

**Language (A11).** Make the ARB files the real source, add a test that they match the runtime, and localise the party dialog.

### Step 3 (E3): Automated build and device-style proof
- Add a CI workflow (GitHub Actions) that does the following:
  - installs Flutter and the Android SDK;
  - runs analyze and the tests;
  - builds a signed release APK from secrets;
  - runs the app on an **API 26 emulator** and records the logs.
- Fix `applicationId`, the app label, the version, and the signing guard (it should fail only for release builds).
- Record the licence text of the bundled cipher library.

This closes the evidence for G0-VER-001 and 005, to the extent an emulator is acceptable.

**Your part:** create a GitHub account secret for the signing key. AI can walk you through it.

### Step 4 (E4 to E7): Missing features, one prompt each
1. Backup and restore (A5), including the real file picker and share. This is the safety net for the key-loss risk in A2.
2. Import from Excel/CSV, then report export (A8, A9).
3. Users/roles and licence/trial screens.
4. Print/PDF and share. The PDF A4/A5 layout is AI work; printer proof is yours.

Each prompt should ship with tests and a results file in the existing nine-section format.

### Step 5: Independent check
After each step, start a **fresh** opencode session with a different model and give it only this instruction: "Verify the claims in RESULT_Dx against the code. List anything marked PASS that is not proven." This catches the "PASS but incomplete" pattern seen in D1 and D3.

### Step 6: Re-run prompts 12 and 13
Only after Step 5, and only after the evidence in §4 exists. Prompt 12 will stay blocked until then.

## 4. What only you (or a person) can do
These are short and I can write exact instructions for each.

| Task | Effort | Closes |
|---|---|---|
| Approve the GST decision memo, and any other decision memos. | Reading and signing off. | A4, A10 |
| Confirm the library approval recorded in `pubspec.yaml` (P-SQLIB). | One reply. | G0-VER-001 |
| Pick a final app name and icon. | A decision. | A12 |
| Send the release APK to yourself by WhatsApp, by email, and by a link, then tell the checklist the file sizes and checksums. | About 30 minutes. | G0-VER-004 |
| Print the test sheet on at least one 58 mm, one 80 mm and one A4/A5 PDF printer. | Needs hardware. | G0-VER-006 |
| Install the APK on one Android 8 phone if you have one and run the checklist. | About 1 hour. | Strengthens 001/005/008 |
| Name a legal reviewer and get a signed note. | Needs a person. | G0-VER-007 |
| Approve vendoring the official GST schemas. | One reply. | G0-VER-003 |

## 5. What AI cannot honestly close
- Real printer output, real delivery receipts, and a lawyer's sign-off.
- Anything on a physical Android 8 phone, if you decide an emulator is not enough.
- A claim of "GST-correct". An accountant has to check sample invoices.

If a tool is told to mark these PASS without the evidence, that breaks your own honesty rule and the gate report would be false.

## 6. Order of effort (a realistic reading)
Steps 1 and 2 give the biggest risk reduction. Until Step 1 is done, nothing else can be trusted on a real device. Steps 3 and 4 turn the app from "tests pass" into "installable and usable". Step 5 stops the process from over-claiming. §4 can run in parallel with Steps 3 and 4.

## 7. Limits of this review
- I did not read every file. Not read in full: `composition_root.dart`, `niav_app.dart`, the m016 and m017 migration bodies, the `docs/g0/evidence/*` folders, and the G0-OWN-001 detail.
- I did not run any test, build or app.
- The count of 431 or 450 tests comes from the project's own reports.
- The invoices "post without tax" and "restore not implemented" statements were checked in code by reviewers and match the project's own reports.
