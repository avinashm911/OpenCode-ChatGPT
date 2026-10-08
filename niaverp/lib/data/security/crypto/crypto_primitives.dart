// NiAvERP crypto primitives — B2 (one decision, one wrapper).
// Interfaces for every later need (B3 backup AEAD, B4 PIN hashing, B5
// licence signatures, B12/attachments) plus every implementation that the
// approved dependency set already allows. Anything else ships as a stub
// that throws the typed [PrimitiveBlocked] naming its decision — never a
// home-made cipher, never a silent fallback.
//
// A1 inventory (proven by the B2 tests, not by memory):
// - package:crypto 3.0.7 (Dart-team, BSD-style; pub cache): SHA-256,
//   HMAC-SHA256. No KDF, no AES/block cipher, no asymmetric signatures
//   (lib/src holds only digest/hash/hmac/md5/sha files — verified on disk).
// - PBKDF2-HMAC-SHA256: implemented here OVER HMAC (RFC 2898 §5.2
//   construction, not a new cipher); slowness is CPU iterations only —
//   Argon2id/scrypt memory-hardness is NOT met (documented in the decision).
// - AES-256-GCM (§5.4) and Ed25519 (§3.2): NOT available without a new
//   package (no AES primitive exists in the dependency closure; writing AES
//   by hand would be a home-made cipher). Blocked stubs + decision doc.
// - Random.secure (dart:math, OS source) and Uint8List fill (best-effort
//   zeroing; real keys live in the Keystore/cipher, see key_lifecycle.dart).
// Traceability: SEC §3.2/§5.2/§5.4; OD-DB-004/005; O-FG-009; D-FG-012.

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show Hash, Hmac, Digest, sha256;

/// A primitive the approved dependency set cannot supply yet.
/// Names the owner decision that unblocks it (never thrown silently: every
/// stub documents the decision id in its message).
class PrimitiveBlocked implements Exception {
  const PrimitiveBlocked(this.decisionId, this.primitive);

  /// Owner decision id, e.g. `P-CRYPTO-AEAD`.
  final String decisionId;

  /// Primitive name, e.g. `AES-256-GCM`.
  final String primitive;

  @override
  String toString() =>
      'PrimitiveBlocked($primitive): blocked until $decisionId is approved '
      '(see docs/owner/DECISION_CRYPTO_PRIMITIVES.md)';
}

/// Proposed PBKDF2 cost (P-CRYPTO-KDF, needs owner tick).
/// Measured 2026-10-08 on this host (Windows, `flutter test` JIT):
/// 50k→138ms, 100k→233ms, 200k→466ms, 400k→931ms (dkLen 32).
/// 100k sits in the interactive-unlock budget; device timing on a low-end
/// Android target is PENDING (G2/G5) and may move this number.
/// Argon2id remains the preferred password-hashing KDF once a package is
/// approved (memory-hardness PBKDF2 cannot supply); this count is the
/// no-new-dependency route.
const int kPbkdf2Iterations = 100000;

/// Random salt length for passphrase KDF use (B3/B4).
const int kPbkdf2SaltBytes = 16;

/// Derived key length for 256-bit keys (B3 backup keys, D-06 shape).
const int kPbkdf2KeyBytes = 32;

/// Password-based key derivation (B3 backup keys, B4 PIN hashing).
/// Production uses PBKDF2-HMAC-SHA256 ([Pbkdf2Sha256]); the hash is
/// injectable only so the RFC 6070 construction vectors can run.
abstract class Kdf {
  const Kdf();

  /// Derive exactly [dkLen] bytes. Refuses empty password/salt and
  /// non-positive iterations/length with [ArgumentError] (fail fast:
  /// B3/B4 always pass a 16-byte random salt and a non-empty passphrase).
  Uint8List deriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int dkLen,
  });
}

/// PBKDF2-HMAC-SHA256 (RFC 2898 §5.2) over a package:crypto HMAC hash.
class Pbkdf2 implements Kdf {
  const Pbkdf2(this.hash);

  /// Production configuration.
  factory Pbkdf2.sha256() => const Pbkdf2(sha256);

  final Hash hash;

  @override
  Uint8List deriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int dkLen,
  }) {
    if (password.isEmpty) {
      throw ArgumentError('PBKDF2 password must not be empty');
    }
    if (salt.isEmpty) {
      throw ArgumentError('PBKDF2 salt must not be empty');
    }
    if (iterations < 1) {
      throw ArgumentError('PBKDF2 iterations must be >= 1');
    }
    if (dkLen < 1) {
      throw ArgumentError('PBKDF2 dkLen must be >= 1');
    }
    final Hmac prf = Hmac(hash, password);
    final int hLen = prf.convert(<int>[]).bytes.length;
    if (dkLen > 0xFFFFFFFF * hLen) {
      throw ArgumentError('PBKDF2 dkLen too large');
    }
    final int blocks = (dkLen + hLen - 1) ~/ hLen;
    final BytesBuilder out = BytesBuilder();
    for (int i = 1; i <= blocks; i++) {
      final List<int> saltBlock = <int>[
        ...salt,
        (i >> 24) & 0xff,
        (i >> 16) & 0xff,
        (i >> 8) & 0xff,
        i & 0xff,
      ];
      List<int> u = prf.convert(saltBlock).bytes;
      final List<int> t = List<int>.from(u);
      for (int c = 1; c < iterations; c++) {
        u = prf.convert(u).bytes;
        for (int k = 0; k < hLen; k++) {
          t[k] ^= u[k];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, dkLen));
  }
}

/// Production configuration: PBKDF2-HMAC-SHA256.
class Pbkdf2Sha256 extends Pbkdf2 {
  const Pbkdf2Sha256() : super(sha256);
}

/// Authenticated encryption with associated data (§5.4 AES-256-GCM shape).
/// PROPOSED API for B3; the implementation stays blocked until the owner
/// approves a package (P-CRYPTO-AEAD).
abstract class Aead {
  const Aead();

  SealedBox seal({
    required List<int> key,
    required List<int> nonce,
    required List<int> plaintext,
    List<int> associatedData = const <int>[],
  });

  List<int> open({
    required List<int> key,
    required List<int> nonce,
    required SealedBox box,
    List<int> associatedData = const <int>[],
  });
}

/// Ciphertext + authentication tag container (API proposal for B3).
class SealedBox {
  const SealedBox({required this.ciphertext, required this.tag});

  final List<int> ciphertext;
  final List<int> tag;
}

/// AEAD stub: throws [PrimitiveBlocked] naming P-CRYPTO-AEAD.
class BlockedAead extends Aead {
  const BlockedAead();

  @override
  SealedBox seal({
    required List<int> key,
    required List<int> nonce,
    required List<int> plaintext,
    List<int> associatedData = const <int>[],
  }) {
    throw const PrimitiveBlocked('P-CRYPTO-AEAD', 'AES-256-GCM');
  }

  @override
  List<int> open({
    required List<int> key,
    required List<int> nonce,
    required SealedBox box,
    List<int> associatedData = const <int>[],
  }) {
    throw const PrimitiveBlocked('P-CRYPTO-AEAD', 'AES-256-GCM');
  }
}

/// Asymmetric signing (§3.2 Ed25519 shape). PROPOSED API for B5.
abstract class Signer {
  const Signer();

  List<int> sign({
    required List<int> privateKey,
    required List<int> message,
  });
}

/// Signature verification (§3.2). PROPOSED API for B5.
abstract class SignatureVerifier {
  const SignatureVerifier();

  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
  });
}

/// Signer stub: throws [PrimitiveBlocked] naming P-CRYPTO-SIGN.
class BlockedSigner extends Signer {
  const BlockedSigner();

  @override
  List<int> sign({
    required List<int> privateKey,
    required List<int> message,
  }) {
    throw const PrimitiveBlocked('P-CRYPTO-SIGN', 'Ed25519');
  }
}

/// Verifier stub: throws [PrimitiveBlocked] naming P-CRYPTO-SIGN.
class BlockedSignatureVerifier extends SignatureVerifier {
  const BlockedSignatureVerifier();

  @override
  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
  }) {
    throw const PrimitiveBlocked('P-CRYPTO-SIGN', 'Ed25519');
  }
}

/// Constant-time byte equality (secret comparison only).
/// Returns false on length mismatch (length itself is not secret here:
/// hashes, tags and stored verifiers have fixed public lengths).
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// OS-sourced random bytes (dart:math Random.secure).
Uint8List randomBytes(int length) {
  if (length < 1) {
    throw ArgumentError('randomBytes length must be >= 1');
  }
  final Random rng = Random.secure();
  return Uint8List.fromList(
    <int>[for (int i = 0; i < length; i++) rng.nextInt(256)],
  );
}

/// Best-effort key zeroing (fills with zeros; Dart GC copies may persist —
/// keys of record live in the Keystore/cipher, see key_lifecycle.dart).
void zeroize(List<int> bytes) {
  if (bytes is Uint8List) {
    bytes.fillRange(0, bytes.length, 0);
    return;
  }
  for (int i = 0; i < bytes.length; i++) {
    bytes[i] = 0;
  }
}

/// SHA-256 digest (thin wrapper for B3/B4; bytes in, bytes out, never logs).
Uint8List sha256Bytes(List<int> data) =>
    Uint8List.fromList(sha256.convert(data).bytes);

/// HMAC-SHA256 (thin wrapper; bytes in, bytes out, never logs).
Uint8List hmacSha256(List<int> key, List<int> data) =>
    Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);

/// SHA-256 digest as lowercase hex (non-secret identifiers only, e.g.
/// denylist key hashes — never for key material display).
String sha256Hex(List<int> data) =>
    Digest(sha256Bytes(data)).toString();
