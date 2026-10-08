# Crypto primitives decision — what is proven, what needs a package

Date (UTC): 2026-10-08. Prompt: B2. Sources: Security plan §3.2/§5.2/§5.4,
OD-DB-004/005, O-FG-009, `docs/g0/evidence/SQLITE3MC_CONFIG_20261007.md`,
`CIPHER_LIB_LICENSE_20261007.md`. Nothing below is decided — each numbered
item needs an owner tick in `docs/owner/DECISIONS_TO_APPROVE.md` (§11).

## 1. What the approved dependency set already supplies (proven by tests)

| Need | Source | Verdict | Proof |
|---|---|---|---|
| SHA-256 hashing (hash-only fields, chains) | package:crypto 3.0.7 (Dart team; BSD-style licence, pub cache) | MET | FIPS 180-4 KATs in `crypto_primitives_test.dart` |
| HMAC-SHA256 (MACs, KDF building block) | same | MET | RFC 4231 cases 1/2/4 in `crypto_primitives_test.dart` |
| Slow password KDF (PIN hashing, backup passphrase) | PBKDF2-HMAC-SHA256 implemented over HMAC (RFC 2898 construction, not a new cipher) | MET in software | RFC 6070 + Go x/crypto KATs; measured 100k→233ms this host; proposed cost `kPbkdf2Iterations = 100000` (device timing pending G2/G5) |
| OS random, constant-time compare, key zeroing | dart:math / typed-data | MET | unit tests; zeroing documented best-effort |
| DB encryption at rest | sqlite3mc (chacha20 pin, raw 256-bit keys) | MET (unchanged) | existing cipher tests; passphrase-KDF→DB-key path proven in `crypto_primitives_test.dart` (A1 run-proof) |

`package:crypto` ships no KDF, no AES/block cipher and no asymmetric
signatures (verified: lib/src holds only digest/hash/hmac/md5/sha files).
Writing AES or Ed25519 by hand would be a home-made cipher — refused.

## 2. What is NOT met (blocked, needs one approved package)

| Need | Source | Missing | Effect until approved |
|---|---|---|---|
| Authenticated backup encryption | §5.4 AES-256-GCM | AES-GCM primitive | B3 cannot encrypt backups; `BlockedAead` throws `PrimitiveBlocked(P-CRYPTO-AEAD)` |
| Licence signatures | §3.2 Ed25519, embedded public keys | Ed25519 sign/verify | B5 cannot verify keys; `BlockedSigner` throws `PrimitiveBlocked(P-CRYPTO-SIGN)` |
| Memory-hard password hashing | §5.2 Argon2id/scrypt preferred | Argon2id | PBKDF2 is the approved interim (CPU-only slowness documented) |

## 3. Candidate packages (facts fetched 2026-10-08, not from memory)

Neither package is in the local pub cache or in `pubspec.yaml`. Adding
either needs the owner tick below plus licence acceptance.

### Route A (recommended): `cryptography` 2.9.0
- Licence Apache-2.0; verified publisher dint.dev; Dart+Flutter; all six
  platforms (Android/iOS/Linux/macOS/Windows/web).
- Health at fetch: 314 likes, 130 pub points, ~906k downloads, published
  Nov 2025. Deps: collection, crypto, ffi, meta, typed_data.
- Covers ALL three gaps: `AesGcm.with256bits()`, `Ed25519()`,
  `Pbkdf2`/`Argon2id`, OS-backed `Random.secure`. Sibling
  `cryptography_flutter` delegates to Android/iOS OS crypto for speed.
- Risk: third-party dependency (supply-chain + API churn); pure-Dart
  fallback is slower than OS crypto (sibling package mitigates on device).

### Route B (alternative): `pointycastle` 4.0.0
- Licence MIT; publisher bouncycastle.org; Dart+Flutter; all six
  platforms. Health at fetch: 417 likes, 140 points, ~3.98M downloads,
  published ~19 months ago. Deps: collection, convert.
- Covers AES-GCM + PBKDF2/scrypt/argon2 KDFs + RSA/ECDSA signers — but its
  published algorithm list shows NO Ed25519, so §3.2 would need ECDSA/RSA
  instead (a source deviation needing its own decision).
- Risk: same supply-chain exposure, plus no Ed25519 path for licence keys.

## 4. Numbered decisions for the owner list

- §11 item 1: approve PBKDF2-HMAC-SHA256 at 100,000 iterations as the
  interim KDF (P-CRYPTO-KDF).
- §11 item 2: approve adding `cryptography` (Apache-2.0) for AES-GCM +
  Ed25519 (+ Argon2id later) — or pick Route B / defer (P-CRYPTO-AEAD,
  P-CRYPTO-SIGN).

Until item 2 is ticked, B3/B5/B12 stay honestly BLOCKED behind typed stubs.
