# Decisions to approve — NiAvERP owner checklist
Date (UTC): 2026-10-07. Nothing below is decided. Each item needs your tick before the related work can proceed. Sources: `niaverp/DECISIONS.md`, `docs/g0/PENDING_INPUTS.md`, `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md`.

How to use this file: read one item, pick an option, tick the box, add your name + date at the bottom. Work stays stopped on unticked items only; everything else continues.

## 1. Device ID rule (how the app recognises each phone/tablet)
Plain English: when the app needs to tell two devices apart (for audit trails and later sync), it currently creates one random ID on first launch and stores it privately in the app. It never reads the phone's hardware or advertising ID.
Recommended default: keep the random-ID approach (already built, tested, and recorded in DECISIONS.md as P-DEVICEID on 2026-10-06 — your tick confirms that record).
Risk of recommended: none known; this is the privacy-safe industry norm.
Risk of the alternative (hardware ID): privacy trouble, possible Play Store policy issues, and IDs that break when users change phones.
Who decides: you (owner).
- [ ] Approved: random ID on first launch, app-private, never hardware ID. Name/date: _OWNER/07/10/2026___

## 2. Application ID (the app's permanent Android name)
Plain English: Android identifies the app as `com.niav.niav`. This name can never change later without forcing every user to uninstall and reinstall.
Recommended default: keep `com.niav.niav`.
Risk of keeping: none, if you are happy with the name.
Risk of changing later: existing users lose automatic updates; data must be migrated by hand.
Who decides: you (owner).
- [ ] Approved: keep `com.niav.niav` as final. Name/date: __OWNER/07/10/2026_____________

## 3. GST posting (how tax is calculated and booked)
Plain English: the app can post tax lines on bills, but the exact rules (when CGST+SGST vs IGST applies, ship-to vs bill-to, rounding authority, ledger names) need a Chartered Accountant's answers first. The one-page question sheet is `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md` — please forward it to your CA.
Recommended default: adopt whatever your CA confirms; the draft proposal in the memo is a starting point only, not a decision.
Risk of deciding without a CA: wrong tax on invoices, GST return mismatches, penalties.
Risk of waiting: tax posting stays blocked (billing without tax lines works meanwhile).
Who decides: your CA answers; you sign off.
- [ ] CA answers received and attached. Name/date: _____OWNER/07/10/2026__________
- [ ] Tax rules approved for implementation. Name/date: ______OWNER/07/10/2026_________

## 4. Android 8 proof via emulator (simulator) instead of a real old phone
Plain English: the app must support Android 8. Proving it needs either a real Android 8 phone or an emulator (a free virtual phone that runs on our build machines).
Recommended default: accept emulator proof now (already wired into the build pipeline), and run one real-device check before the first customer release.
Risk of emulator-only: emulators can miss real-hardware quirks (key storage, printers).
Risk of demanding a physical phone now: you must find/buy an Android 8 device and everything waits on it.
Who decides: you (owner).
- [ ] Approved: emulator (API 26) evidence accepted for now; physical device before release: yes. Name/date: ____OWNER/07/10/2026___________

## 5. Hindi and Gujarati translations
Plain English: new screen texts were machine-drafted — the Hindi and Gujarati versions currently just repeat the English. A native speaker must review them before release.
Recommended default: get a native Hindi and Gujarati speaker to review the flagged texts (list in the E2 report), then tick.
Risk of shipping as-is: confusing or embarrassing text in front of customers.
Risk of waiting: small delay to find reviewers.
Who decides: you (appoint reviewers); the reviewers sign the texts.
- [ ] Hindi reviewed by a native speaker. Name/date: ______OWNER/07/10/2026_________
- [ ] Gujarati reviewed by a native speaker. Name/date: ____OWNER/07/10/2026___________

## 6. Legal reviewer
Plain English: the project needs a named legal reviewer who confirms data-retention/deletion rules, privacy (DPDP Act) readings, and overall legal scope, with a signed note.
Recommended default: appoint the reviewer now; the review itself can be scheduled.
Risk of skipping: unknown legal exposure; release evidence stays incomplete.
Who decides: you (name the reviewer); the reviewer (signs the opinion).
- [ ] Reviewer named + role: ____Avinash + Auditor___________. Date: ____07-10-2026___________
- [ ] Signed review attached under `docs/g0/evidence/legal/`. Date: ______OWNER/07/10/2026_________

## 7. Printers (58 mm, 80 mm, PDF)
Plain English: the app prints bills on small thermal printers (58 mm and 80 mm) and shares PDFs. Each size must be tested once on a real printer, and the exact printer models must be frozen in a list.
Recommended default: freeze one model per size now and test when hardware is available.
Risk of not testing: first real print failure happens at a customer site.
Who decides: you (freeze the model list; supply or approve test hardware).
- [ ] Printer matrix frozen (models): 58 mm ___Ok_______, 80 mm ___OK_______, PDF path __Device Downloads folder________. Date: ______07-10-2026_________
- [ ] Test prints attached. Date: _______________

## 8. Release keystore (the private signature key for the app)
Plain English: every releasable app must be digitally signed with a private key. Four secrets must be stored in GitHub (key file + 3 passwords/names). If this key is lost, the app can never be updated again — users would have to reinstall.
Recommended default: generate one dedicated release key now, back it up offline in two places, and store the four secrets in GitHub (secret names are listed in `.github/workflows/build.yml`; values are never shown or printed).
Risk of doing nothing: no signed release is possible.
Risk of losing the key later: permanent loss of the update path.
Who decides: you (generate + back up + enter secrets).
- [ ] Keystore generated, backed up offline (2 copies), 4 GitHub secrets set. Name/date: _______OWNER/07/10/2026________

## 9. Release channel (how the app reaches users)
Plain English: decide how customers get the app and updates (direct APK download, hosted link, email/WhatsApp with hash check, etc.), and verify the first release by its fingerprint (SHA-256).
Recommended default: pick one channel now; verify the first release fingerprint before announcing it.
Risk of no decision: ad-hoc distribution, users may install tampered copies.
Who decides: you (owner).
- [ ] Release channel decided: ____email/WhatsApp with hash check___________. First-release SHA-256 verified: pending. Name/date: ________OWNER/07/10/2026_______

## 10. Trial month arithmetic (how the 3-month trial end is calculated)
Plain English: the trial lasts 3 months from install. The app computes the end date as the same calendar day 3 months later; if that day does not exist (for example 31 August + 3 months), it uses the last day of that month (30 November). Until you tick this, the app runs on this draft rule and the trial end could shift by a day or two if you pick a different rule later.
Recommended default: keep calendar months with end-of-month clamping (already built and tested).
Risk of keeping: none known; matches ordinary subscription arithmetic.
Risk of changing later: trial lengths already issued would need recomputation.
Who decides: you (owner).
- [ ] Approved: trial end = install start + 3 calendar months (UTC), day clamped to month end. Name/date: _____

## 11. Cryptographic primitives (slow KDF now, AES/signatures need a package)
Plain English: passwords and backup passphrases are stretched with a slow,
standard key function (PBKDF2, 100,000 rounds — measured at a quarter of a
second on our machine; phones may differ). Real backup encryption and licence
signatures need one well-known extra code package (`cryptography`, free
Apache licence, works on all phones). Until you approve it, backups cannot be
encrypted and licence keys cannot be checked — the app refuses those steps
with a clear message instead of using weak homemade crypto.
Recommended default: keep PBKDF2/100k now; approve the `cryptography` package
for the encryption and signature steps (full comparison in
`docs/owner/DECISION_CRYPTO_PRIMITIVES.md`).
Risk of keeping PBKDF2 only: password-guessing resistance is CPU-only (no
memory-hardness); acceptable interim, Argon2id later via the same package.
Risk of adding the package: a new third-party dependency to trust and update.
Who decides: you (owner).
- [ ] Approved: PBKDF2-HMAC-SHA256 at 100,000 iterations as the interim KDF (P-CRYPTO-KDF). Name/date: _____
- [ ] Approved: add `cryptography` (Apache-2.0) for AES-256-GCM + Ed25519 (P-CRYPTO-AEAD, P-CRYPTO-SIGN). Name/date: _____

---
Overall sign-off: _____OWNER/07/10/2026____________________ Date: ____07/10/2026___________
Note: GST detail lives in the CA brief; legal detail lives with the reviewer. This file decides nothing by itself — only your ticks do.
