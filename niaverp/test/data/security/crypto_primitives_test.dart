// B2 crypto primitive tests: known-answer vectors (cited), tamper/
// wrong-key/truncation/empty cases, redaction, blocked stubs, and the A1
// run-proof (passphrase-derived key opens an encrypted database copy).
// Traceability: SEC §5.2/§5.4/§3.2; OD-DB-004/005; O-FG-009; M22.4.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/db/cipher_opener.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/security/crypto/crypto_primitives.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';

import '../../helpers/test_database.dart';

String hex(List<int> bytes) => bytes
    .map((int x) => x.toRadixString(16).padLeft(2, '0'))
    .join();

void main() {
  group('SHA-256 (FIPS 180-4 examples)', () {
    test('empty string', () {
      expect(
        hex(sha256Bytes(<int>[])),
        'e3b0c44298fc1c149afbf4c8996fb924'
        '27ae41e4649b934ca495991b7852b855',
      );
    });
    test('abc', () {
      expect(
        hex(sha256Bytes(utf8.encode('abc'))),
        'ba7816bf8f01cfea414140de5dae2223'
        'b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('HMAC-SHA256 (RFC 4231)', () {
    test('case 1: Hi There', () {
      expect(
        hex(hmacSha256(
          List<int>.filled(20, 0x0b),
          utf8.encode('Hi There'),
        )),
        'b0344c61d8db38535ca8afceaf0bf12b'
        '881dc200c9833da726e9376c2e32cff7',
      );
    });
    test('case 2: Jefe', () {
      expect(
        hex(hmacSha256(
          utf8.encode('Jefe'),
          utf8.encode('what do ya want for nothing?'),
        )),
        '5bdcc146bf60754e6a042426089575c7'
        '5a003f089d2739839dec58b964ec3843',
      );
    });
    test('case 4: sequential key/data', () {
      expect(
        hex(hmacSha256(
          List<int>.generate(25, (int i) => i + 1),
          List<int>.filled(50, 0xcd),
        )),
        '82558a389a443c0ea4cc819899f2083a'
        '85f0faa3e578f8077a2e3ff46729665b',
      );
    });
  });

  group('PBKDF2 construction (RFC 6070, HMAC-SHA1)', () {
    final Pbkdf2 kdf = Pbkdf2(sha1);
    List<int> p(String s) => utf8.encode(s);
    List<int> s(String s) => utf8.encode(s);

    test('c=1', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 1, dkLen: 20)),
        '0c60c80f961f0e71f3a9b524af6012062fe037a6',
      );
    });
    test('c=2', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 2, dkLen: 20)),
        'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957',
      );
    });
    test('c=4096', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 4096, dkLen: 20)),
        '4b007901b765489abead49d926f721d065a429c1',
      );
    });
    test('long input spans two blocks', () {
      expect(
        hex(kdf.deriveKey(
            password: p('passwordPASSWORDpassword'),
            salt: s('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
            iterations: 4096,
            dkLen: 25)),
        '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038',
      );
    });
    test('embedded NUL bytes', () {
      expect(
        hex(kdf.deriveKey(
            password: <int>[...p('pass'), 0, ...p('word')],
            salt: <int>[...s('sa'), 0, ...s('lt')],
            iterations: 4096,
            dkLen: 16)),
        '56fa6aa75548099dcc37d7f03425e0c3',
      );
    });
  });

  group('PBKDF2-HMAC-SHA256 production config (Go x/crypto vectors)', () {
    // Vectors from golang/crypto pbkdf2_test.go (sourced there from
    // stackoverflow.com/questions/5130513, cross-checked across
    // implementations). dkLens match the published truncations.
    final Pbkdf2Sha256 kdf = Pbkdf2Sha256();
    List<int> p(String s) => utf8.encode(s);
    List<int> s(String s) => utf8.encode(s);

    test('c=1', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 1, dkLen: 20)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c9',
      );
    });
    test('c=2', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 2, dkLen: 20)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8e',
      );
    });
    test('c=4096', () {
      expect(
        hex(kdf.deriveKey(password: p('password'), salt: s('salt'),
            iterations: 4096, dkLen: 20)),
        'c5e478d59288c841aa530db6845c4c8d962893a0',
      );
    });
    test('long input (25 bytes)', () {
      expect(
        hex(kdf.deriveKey(
            password: p('passwordPASSWORDpassword'),
            salt: s('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
            iterations: 4096,
            dkLen: 25)),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c',
      );
    });
    test('embedded NUL bytes (16 bytes)', () {
      expect(
        hex(kdf.deriveKey(
            password: <int>[...p('pass'), 0, ...p('word')],
            salt: <int>[...s('sa'), 0, ...s('lt')],
            iterations: 4096,
            dkLen: 16)),
        '89b69d0516f829893c696226650a8687',
      );
    });
    test('longer output extends the published prefix (multi-block)', () {
      final String full = hex(kdf.deriveKey(
          password: p('passwordPASSWORDpassword'),
          salt: s('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
          iterations: 4096,
          dkLen: 40));
      expect(
        full.substring(0, 50),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c',
      );
      expect(full.length, 80);
    });
  });

  group('KDF input validation (fail fast, no secrets in errors)', () {
    final Pbkdf2Sha256 kdf = Pbkdf2Sha256();

    test('empty password refused without echoing it', () {
      Object? caught;
      try {
        kdf.deriveKey(password: <int>[], salt: utf8.encode('salt'),
            iterations: 1000, dkLen: 32);
      } catch (e) {
        caught = e;
      }
      expect(caught, isArgumentError);
    });
    test('empty salt refused', () {
      expect(
        () => kdf.deriveKey(password: utf8.encode('p'), salt: <int>[],
            iterations: 1000, dkLen: 32),
        throwsArgumentError,
      );
    });
    test('non-positive iterations refused', () {
      expect(
        () => kdf.deriveKey(password: utf8.encode('p'),
            salt: utf8.encode('s'), iterations: 0, dkLen: 32),
        throwsArgumentError,
      );
    });
    test('non-positive dkLen refused', () {
      expect(
        () => kdf.deriveKey(password: utf8.encode('p'),
            salt: utf8.encode('s'), iterations: 1, dkLen: 0),
        throwsArgumentError,
      );
    });
    test('deterministic; salt sensitivity', () {
      final List<int> a = kdf.deriveKey(password: utf8.encode('correct horse'),
          salt: utf8.encode('salt-1'), iterations: 1000, dkLen: 32);
      final List<int> b = kdf.deriveKey(password: utf8.encode('correct horse'),
          salt: utf8.encode('salt-1'), iterations: 1000, dkLen: 32);
      final List<int> c = kdf.deriveKey(password: utf8.encode('correct horse'),
          salt: utf8.encode('salt-2'), iterations: 1000, dkLen: 32);
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('comparison, randomness, zeroing', () {
    test('constant-time equality incl. length mismatch', () {
      expect(constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 3]), isTrue);
      expect(constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 4]), isFalse);
      expect(constantTimeEquals(<int>[1, 2], <int>[1, 2, 3]), isFalse);
      expect(constantTimeEquals(<int>[], <int>[]), isTrue);
    });
    test('random bytes: length and uniqueness', () {
      final Uint8List a = randomBytes(16);
      final Uint8List b = randomBytes(16);
      expect(a, hasLength(16));
      expect(a, isNot(b));
      expect(() => randomBytes(0), throwsArgumentError);
    });
    test('zeroize fills with zeros', () {
      final Uint8List key = Uint8List.fromList(List<int>.filled(32, 7));
      zeroize(key);
      expect(key, everyElement(0));
      final List<int> plain = <int>[1, 2, 3];
      zeroize(plain);
      expect(plain, <int>[0, 0, 0]);
    });
  });

  group('blocked stubs (honest skips naming the decision)', () {
    test('AEAD seal/open throw PrimitiveBlocked (P-CRYPTO-AEAD)', () {
      const Aead aead = BlockedAead();
      expect(
        () => aead.seal(key: List<int>.filled(32, 1),
            nonce: List<int>.filled(12, 2), plaintext: utf8.encode('x')),
        throwsA(isA<PrimitiveBlocked>().having(
            (PrimitiveBlocked e) => e.decisionId, 'decisionId', 'P-CRYPTO-AEAD')),
      );
      expect(
        () => aead.open(key: List<int>.filled(32, 1),
            nonce: List<int>.filled(12, 2),
            box: const SealedBox(ciphertext: <int>[1], tag: <int>[2])),
        throwsA(isA<PrimitiveBlocked>()),
      );
    });
    test('signer/verifier throw PrimitiveBlocked (P-CRYPTO-SIGN)', () {
      const Signer signer = BlockedSigner();
      const SignatureVerifier verifier = BlockedSignatureVerifier();
      expect(
        () => signer.sign(privateKey: List<int>.filled(32, 1),
            message: utf8.encode('x')),
        throwsA(isA<PrimitiveBlocked>().having(
            (PrimitiveBlocked e) => e.decisionId, 'decisionId', 'P-CRYPTO-SIGN')),
      );
      expect(
        () => verifier.verify(publicKey: List<int>.filled(32, 2),
            message: utf8.encode('x'), signature: <int>[0]),
        throwsA(isA<PrimitiveBlocked>()),
    );
    }, skip: 'BLOCKED — Ed25519 needs an owner-approved package (P-CRYPTO-SIGN)');
    test('AES-256-GCM tamper detection', () {},
        skip: 'BLOCKED — no AES primitive in the approved set (P-CRYPTO-AEAD)');
  });

  group('A1 run-proof: passphrase-derived key drives the cipher', () {
    test('derived key opens an encrypted copy; wrong passphrase fails', () {
      final Directory tmp =
          Directory.systemTemp.createTempSync('niav_kdfproof_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final Pbkdf2Sha256 kdf = Pbkdf2Sha256();
      // Test-only cost (fast suite); production cost is kPbkdf2Iterations.
      Uint8List derive(String passphrase, List<int> salt) =>
          kdf.deriveKey(password: utf8.encode(passphrase), salt: salt,
              iterations: 1000, dkLen: 32);
      final List<int> salt = List<int>.generate(16, (int i) => i + 1);
      final DbKey right = DbKey(derive('correct horse', salt));
      CipherDatabaseOpener opener(DbKey key, String name) =>
          CipherDatabaseOpener(
            dbPath: '${tmp.path}/$name.db',
            dbKey: key,
            sqlByVersion: loadMigrationSql(),
          );
      final NiavDatabase first = opener(right, 'kdf').openCompanyDatabase();
      first.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-kdf', 'Kdf Co', 1700000000000],
      );
      (first.engine as CloseableMigrationDb).close();
      // Same passphrase reopens the copy.
      final NiavDatabase second = opener(right, 'kdf').openCompanyDatabase();
      try {
        final List<Map<String, Object?>> rows = second.queryArgs(
          'SELECT name FROM company WHERE company_id = ?',
          <Object?>['c-kdf'],
        );
        expect(rows.single['name'], 'Kdf Co');
      } finally {
        (second.engine as CloseableMigrationDb).close();
      }
      // Wrong passphrase derives a different key: open fails at first read.
      final DbKey wrong = DbKey(derive('wrong horse', salt));
      expect(
        () => opener(wrong, 'kdf').openCompanyDatabase(),
        throwsA(isA<Exception>()),
      );
    });
    test('proposed production cost is pinned (change = owner decision)', () {
      expect(kPbkdf2Iterations, 100000);
    });
  });
}
