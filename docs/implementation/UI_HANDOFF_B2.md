# UI_HANDOFF_B2 — crypto error codes for screens

Date (UTC): 2026-10-08. Source: B2 (`lib/data/security/crypto/crypto_primitives.dart`).
No widgets or ARB were changed in B2. Crypto runs synchronously in the data
layer; screens only surface these codes (B3/B4/B5 will add the flows).

## Error codes (plain English)

| Code / exception | Meaning | UI text suggestion |
|---|---|---|
| `PrimitiveBlocked(P-CRYPTO-AEAD)` | backup encryption unavailable until the owner approves a crypto package | "Encrypted backup is not available yet" |
| `PrimitiveBlocked(P-CRYPTO-SIGN)` | licence verification unavailable until the owner approves a crypto package | "Licence check is not available yet" |
| `ArgumentError` (KDF/r random) | empty passphrase/salt, non-positive iterations/length | developer-facing (never from user input paths without B4 validation) |

## Notes for the UI series

- KDF cost (100k iterations, ~0.25s host) runs on the calling isolate: B4
  PIN entry must show progress and never block the tab animation.
- Never log or display passphrases, salts-as-secrets, keys, nonces or tags.
  All B2 errors are already value-free (tested).
- No new states or enums for screens in B2.
