# RESULT B2 — Crypto primitives decision gate
Date (UTC): 2026-10-08   Overall status: PASS
Branch: `b2-20261008` (from `e1110e0`). B prompt: `docs/opencode_master_prompts/Delta/B2_crypto_primitives_decision_gate.md`. Rules: `B_COMMON_RULES.md`.

## 1. Baseline before changes
- `git rev-parse --short HEAD` → `e1110e0` (B1 committed); clean except pre-existing owner/draft files.
- `flutter analyze --no-pub` → `No issues found!`, exit 0 (`docs/implementation/evidence/analyze_20261008_b2_base.txt`).
- `flutter test` → `+530 ~2: All tests passed!` (530/0/2), exit 0 (`docs/implementation/evidence/flutter_test_full_20261008_b2_base.txt`).
- Green baseline: implementation proceeded.

## 2. Work-item table
| ID | Item | Status | Evidence |
|---|---|---|---|
| A1 | Inventory vs §3.2/§5.2/§5.4/OD-DB-004/005/O-FG-009 with no new package, proven by running code | implemented | §5: package:crypto 3.0.7 supplies SHA-256/HMAC only (lib/src listing on disk); PBKDF2 built over HMAC (KATs green); AES/Ed25519 absent (no AES symbol in closure; hand-rolled refused); sqlite3mc kdf_iter applies to passphrase keys only — opener uses raw keys so nothing to pin |
| A2 | Candidates with licence/maintenance/platform facts; decision doc + owner item | implemented | `docs/owner/DECISION_CRYPTO_PRIMITIVES.md`; `docs/owner/DECISIONS_TO_APPROVE.md` §11 (addition only). Recommended: `cryptography` 2.9.0 (Apache-2.0, verified publisher, 6 platforms, AesGcm+Ed25519+Pbkdf2/Argon2id, live pub.dev fetch); alternative `pointycastle` 4.0.0 (MIT, no Ed25519). Neither in pub cache, nothing added |
| A3 | Interfaces now; every available primitive implemented; rest typed-blocked + honest skips | implemented | `lib/data/security/crypto/crypto_primitives.dart` (`Kdf`/`Pbkdf2Sha256`, `Aead`/`BlockedAead`, `Signer`/`BlockedSigner`, `SignatureVerifier`/`BlockedSignatureVerifier`, `constantTimeEquals`, `randomBytes`, `zeroize`, sha/hmac helpers); 2 skipped tests name P-CRYPTO-AEAD/SIGN |
| A4 | Known-answer tests (cited) + tamper/wrong-key/truncation/empty + redaction | implemented | `test/data/security/crypto_primitives_test.dart` (27 pass + 2 skips): FIPS 180-4 SHA-256, RFC 4231 HMAC cases 1/2/4, RFC 6070 PBKDF2-SHA1 (incl. 2-block), Go x/crypto PBKDF2-SHA256 vectors, validation errors, determinism, redaction-safe messages, passphrase→DB-key run-proof with wrong-key refusal |
| A5 | Proposal rows P-CRYPTO-KDF/AEAD/SIGN | implemented | `niaverp/DECISIONS.md` (3 rows, all PROPOSAL) |
| Output | RESULT + UI_HANDOFF (codes only) + decision doc; register rows | implemented | this file, `docs/implementation/UI_HANDOFF_B2.md`, decision doc; register M22.4 only. OD-DB-005 has no register row (B0 schema is module-only): crypto part tracked here — per-file AES-GCM + wrapped keys BLOCKED on P-CRYPTO-AEAD; hash-only storage + chain already WIRED+TESTED |

## 3. Changed files (new / modified / deleted, one line each)
- NEW `niaverp/lib/data/security/crypto/crypto_primitives.dart`
- NEW `niaverp/test/data/security/crypto_primitives_test.dart`
- NEW `docs/owner/DECISION_CRYPTO_PRIMITIVES.md`
- NEW `docs/implementation/UI_HANDOFF_B2.md`
- NEW `docs/implementation/RESULT_B2_crypto_primitives.md` (this file)
- NEW `docs/implementation/evidence/analyze_20261008_b2_base.txt`, `flutter_test_full_20261008_b2_base.txt`, `analyze_20261008_b2.txt`, `flutter_test_full_20261008_b2.txt`
- MODIFIED `niaverp/DECISIONS.md` (3 proposal rows)
- MODIFIED `docs/owner/DECISIONS_TO_APPROVE.md` (§11 addition only)
- MODIFIED `docs/implementation/BACKEND_CAPABILITY_REGISTER.md` (M22.4 row only)
- MODIFIED `docs/implementation/RESULTS_INDEX.md` (append B2 line)
- No migration, pubspec, Android, ARB, HTML, backup/auth/licence code touched. No test weakened or deleted.

## 4. Tests
- Added: 29 tests in 1 file (27 pass + 2 honest skips).
- Final: `flutter test` → `+557 ~4: All tests passed!` (557 passed / 0 failed / 4 skipped — 530 baseline + 27 new passes; skips: 2 pre-existing cipher-pin + 2 new B2 blocked-stub skips).
- `flutter analyze` → PENDING.
- Transcription discipline: 4 hand-copied vectors initially mismatched (empty-SHA256, SHA-1 c=2/long, SHA-256 c=2); each actual was re-checked byte-by-byte against the RFC/Go tables and the implementation confirmed against 9 independent passing vectors — literals fixed, never the code, never blind actual-copying.

## 5. Commands run and exact output summary
- `git checkout -b b2-20261008` (from `e1110e0`).
- `flutter analyze --no-pub` (base) → clean; (final) → PENDING.
- `flutter test` (base) → 530/0/2; (final) → PENDING.
- Pub-cache disk listing: crypto-3.0.7 present; `cryptography*`/`pointycastle*` absent (candidates researched via live pub.dev fetch, labelled as such).
- Fetched vector sources: RFC 6070 (SHA-1 KATs), RFC 4231 (HMAC cases 1/2/4), golang/crypto pbkdf2_test.go (SHA-256 KATs + SO origin), pub.dev pages (candidate facts).
- Timing probe (deleted after): PBKDF2-SHA256 dkLen32 → 50k/138ms, 100k/233ms, 200k/466ms, 400k/931ms; proposal 100k.

## 6. Deviations from the prompt, with reason
- Candidate facts partly from live pub.dev fetch instead of the pub cache: the candidates are absent from the cache (proven by listing), so cache-only facts were impossible; every fetched fact carries its URL + date, nothing from memory.
- No `entitlements.json` change: KDF cost lives in code (`kPbkdf2Iterations`, pinned by test) and proposals; the matrix gains no crypto cells (B5 owns licence-key material).
- Repairs to earlier work: none needed (no regressions).

## 7. Owner questions and downstream evidence still pending
- §11 tick 1: PBKDF2-HMAC-SHA256 @100k interim (P-CRYPTO-KDF). Tick 2: add `cryptography` for AES-GCM + Ed25519 (P-CRYPTO-AEAD/SIGN).
- Downstream: B3/B5/B12 stay BLOCKED behind stubs until tick 2; KDF cost may move after device timing (G2/G5); Argon2id preferred long-term.
- `PENDING_INPUTS.md` untouched. No physical/legal/statutory claims.

## 8. Honesty statement
- Host-only (Dart JIT timings; encrypted temp-file run-proof; no device crypto timing).
- No home-made ciphers: PBKDF2 is an RFC 2898 construction over the audited HMAC primitive, KAT-proven against two independent vector sets.
- Blocked items throw typed errors naming their decisions; skipped tests name them too. Nothing physical/legal/statutory called PASS.

## 9. Next prompt
- Next: `docs/opencode_master_prompts/Delta/B3_backup_restore_engine.md` — NOTE: B3 needs AEAD (blocked until P-CRYPTO-AEAD tick); it can proceed with container/manifest/schedule/passphrase-policy work behind the `Aead` interface, or wait for the tick.
- Do not run B4–B14 until B2 passes.
