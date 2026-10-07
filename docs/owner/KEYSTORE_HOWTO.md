# Release keystore HOWTO (Windows, plain English)
Date (UTC): 2026-10-07. For the owner only. Nothing here is decided for you — it tells you how to create the signing key IF you decide to cut a signed release (see `docs/owner/DECISIONS_TO_APPROVE.md` §8).

## What this key is
Android trusts app updates only if every version carries the same digital signature. The signature comes from a private `keystore` file you create once. **If you lose it, the app can never be updated again** — users would have to uninstall and reinstall. There is no recovery.

## Step 1 — Open a terminal
1. Press `Win + X`, click **Terminal** (or Windows PowerShell).
2. The key tool lives inside Android Studio's own Java — verified on this PC at:
   `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`
   It is NOT on the normal command path, so every command below quotes the full path.

## Step 2 — Create the key (run once, ever)
1. Make a folder outside the project: `C:\secure` (NOT inside `E:\niaverp-root`).
2. Run (choose your own two passwords; type them when asked, they stay invisible):
   ```powershell
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore C:\secure\niav-release.jks -alias niav -keyalg RSA -keysize 2048 -validity 9125
   ```
   Answer the name/organisation questions with your business details. Validity 9125 days ≈ 25 years (Google requires a long life).
3. Confirm the file exists: `C:\secure\niav-release.jks`.

## Step 3 — Back it up in two places (same day)
1. Copy `niav-release.jks` to a USB stick you store separately.
2. Copy it to a second offline location (e.g. your other PC's `C:\secure`).
3. NEVER email it, NEVER put it in chat, NEVER commit it to git (see warning below).

## Step 4 — Convert to base64 (Windows, single clean line for GitHub)
Run:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secure\niav-release.jks")) | Set-Content C:\secure\niav-release.b64 -NoNewline
```
This writes one long text line with no headers (the alternative, `certutil -encode`, adds header lines that break the CI decode step — do not use it without stripping them).

## Step 5 — Create the 4 GitHub secrets (names exactly as in `.github/workflows/build.yml`)
1. Open the repo on GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**, four times:
   - `NIAV_RELEASE_KEYSTORE_B64` ← paste the whole content of `C:\secure\niav-release.b64`
   - `NIAV_RELEASE_STORE_PASSWORD` ← the keystore password from Step 2
   - `NIAV_RELEASE_KEY_ALIAS` ← `niav` (or whatever alias you chose)
   - `NIAV_RELEASE_KEY_PASSWORD` ← the key password from Step 2
2. Values are never shown again and never printed in build logs (the workflow references names only).

## ⚠ Warning — never commit the key
- Before every `git commit`, run `git status` and confirm NO `.jks` or `.b64` file is listed.
- The repo's `.gitignore` currently has NO keystore rule — so git will NOT stop you; you must check by hand.
- If a key file ever gets pushed by accident, tell the team immediately: the key must be considered compromised and replaced.
