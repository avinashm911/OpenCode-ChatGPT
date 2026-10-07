package com.niaverp.niaverp

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.SecureRandom
import java.util.Arrays
import javax.crypto.BadPaddingException
import javax.crypto.Cipher
import javax.crypto.IllegalBlockSizeException
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Android platform side of the NiAvERP database-key boundary (D-06 / D1-A1).
 *
 * Contract implemented here, matching `lib/data/db/key_provider.dart`
 * (`ChannelKeyProvider`) and `lib/data/security/key_lifecycle.dart`:
 *
 *  - method `getDatabaseKey` returns a map with
 *      `state`   : "missing" | "available" | "locked" | "failed"
 *      `key`     : 32 raw bytes, present only when state == "available"
 *      `failure` : "keystoreUnavailable" | "authFailed" | "corruptWrapper" |
 *                  "wipedByUninstall" | "existingDataLocked" (failure cause)
 *  - a random 256-bit database key is generated once, wrapped with an
 *    Android Keystore AES-GCM key and stored wrapped (single atomic file) in
 *    app-private storage; the plaintext key exists in memory only for the
 *    duration of the reply and its working array is zeroed afterwards.
 *  - there is NO recovery API and NO plaintext fallback: if the Keystore key
 *    or the wrapped blob is unusable, the channel reports a failure code and
 *    the database stays closed. A fresh key is NEVER minted when a wrapped
 *    blob exists (decrypt failure / missing alias) or when database data
 *    exists without a blob (`existingDataLocked`).
 *  - key bytes are never logged and never placed in an exception message.
 *
 * File layout and the provision/refuse decision matrix live in [DbKeyStore]
 * (pure logic with JVM unit tests). Keystore access and crypto stay here.
 *
 * minSdk stays 26 (Android 8); GCMParameterSpec and the standard KeyStore
 * provider are available from API 23.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        /** Must match `ChannelKeyProvider.kKeyChannelName`. */
        const val CHANNEL = "com.niaverp.niaverp/keystore"
        const val KEY_ALIAS = "niaverp_db_wrap_v1"
        const val KEY_STORE = "AndroidKeyStore"
        const val WRAP_TRANSFORMATION = "AES/GCM/NoPadding"
        const val WRAP_ALGORITHM = "AES"
        const val GCM_TAG_BITS = 128
        const val DB_KEY_BYTES = 32
    }

    private val secureRandom = SecureRandom()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "getDatabaseKey" -> result.success(databaseKeyReply())
                    // The app-private files directory for the database file.
                    // Returning the path only: no key material crosses here.
                    "getFilesDirectory" -> result.success(filesDir.absolutePath)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Resolve the database key for this reply, without ever logging it.
     * Every failure path returns a code; nothing throws to the Dart side with
     * key material in the message.
     */
    private fun databaseKeyReply(): Map<String, Any?> {
        return try {
            val store = DbKeyStore(filesDir)
            val stored = store.read()
            val keyStore = try {
                keyStore()
            } catch (e: KeystoreUnavailable) {
                return failureReply("keystoreUnavailable")
            }
            val wrappingPresent =
                storeWrappingKey(keyStore) != null
            when (store.decide(
                stored = stored,
                wrappingKeyPresent = wrappingPresent,
                databaseExists = store.databaseExists(),
            )) {
                is DbKeyStore.KeyDecision.Proceed ->
                    availableReply(keyStore, (stored as DbKeyStore.Stored.Ok).blob)
                is DbKeyStore.KeyDecision.Provision ->
                    provisionReply(keyStore, store)
                is DbKeyStore.KeyDecision.RefuseExistingData ->
                    failureReply("existingDataLocked")
                is DbKeyStore.KeyDecision.RefuseWiped ->
                    failureReply("wipedByUninstall")
                is DbKeyStore.KeyDecision.RefuseCorrupt ->
                    failureReply("corruptWrapper")
            }
        } catch (e: KeystoreUnavailable) {
            failureReply("keystoreUnavailable")
        } catch (e: CorruptWrapper) {
            failureReply("corruptWrapper")
        } catch (e: Exception) {
            // Unexpected platform fault: reported as a code, never as text.
            failureReply("keystoreUnavailable")
        }
    }

    private fun availableReply(
        keyStore: KeyStore,
        blob: DbKeyStore.WrappedBlob,
    ): Map<String, Any?> {
        val wrapping = storeWrappingKey(keyStore)
            ?: throw KeystoreUnavailable()
        val cipher = Cipher.getInstance(WRAP_TRANSFORMATION)
        val plaintext: ByteArray
        try {
            cipher.init(
                Cipher.DECRYPT_MODE,
                wrapping,
                GCMParameterSpec(GCM_TAG_BITS, blob.iv),
            )
            plaintext = cipher.doFinal(blob.ciphertext)
        } catch (e: BadPaddingException) {
            throw CorruptWrapper()
        } catch (e: IllegalBlockSizeException) {
            throw CorruptWrapper()
        }
        if (plaintext.size != DB_KEY_BYTES) {
            // Wrong length is a corrupt wrapper, not a usable key.
            Arrays.fill(plaintext, 0.toByte())
            throw CorruptWrapper()
        }
        // The reply carries a copy; the working array is zeroed at once.
        val replyKey = plaintext.copyOf()
        Arrays.fill(plaintext, 0.toByte())
        return mapOf<String, Any?>("state" to "available", "key" to replyKey)
    }

    /**
     * First run only (no blob, no database): provision a fresh database key,
     * wrap it with a newly minted wrapping key and store it atomically.
     */
    private fun provisionReply(
        keyStore: KeyStore,
        store: DbKeyStore,
    ): Map<String, Any?> {
        val fresh = newDatabaseKey()
        val cipher = Cipher.getInstance(WRAP_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, mintWrappingKey(keyStore))
        val ciphertext = cipher.doFinal(fresh)
        store.write(DbKeyStore.WrappedBlob(cipher.iv, ciphertext))
        val replyKey = fresh.copyOf()
        Arrays.fill(fresh, 0.toByte())
        return mapOf<String, Any?>("state" to "available", "key" to replyKey)
    }

    private fun failureReply(failure: String): Map<String, Any?> =
        mapOf<String, Any?>("state" to "failed", "failure" to failure)

    private fun newDatabaseKey(): ByteArray {
        val bytes = ByteArray(DB_KEY_BYTES)
        secureRandom.nextBytes(bytes)
        return bytes
    }

    /**
     * Open the platform Keystore. Any failure to reach it throws
     * [KeystoreUnavailable] (this is where the code path the contract
     * documents originates).
     */
    private fun keyStore(): KeyStore {
        try {
            val store = KeyStore.getInstance(KEY_STORE)
            store.load(null)
            return store
        } catch (e: Exception) {
            throw KeystoreUnavailable()
        }
    }

    /**
     * Look up the wrapping key WITHOUT creating one. Null means the alias is
     * gone (e.g. wiped by an uninstall) — the caller must refuse, never mint
     * over an existing blob.
     */
    private fun storeWrappingKey(store: KeyStore): SecretKey? {
        return try {
            store.getKey(KEY_ALIAS, null) as? SecretKey
        } catch (e: Exception) {
            throw KeystoreUnavailable()
        }
    }

    /**
     * Create the wrapping key. Called only on the provision path (no blob
     * and no database exist), never over existing material.
     */
    private fun mintWrappingKey(store: KeyStore): SecretKey {
        try {
            val generator = KeyGenerator.getInstance(WRAP_ALGORITHM, KEY_STORE)
            val spec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                // No user-authentication requirement: the wrap key only protects the
                // database key at rest. An app lock/unlock gate, when the product
                // adds one, is enforced by the Dart lifecycle states, not by
                // re-inventing a Keystore policy here.
                .build()
            generator.init(spec)
            return generator.generateKey()
        } catch (e: Exception) {
            throw KeystoreUnavailable()
        }
    }

    private class KeystoreUnavailable : Exception()

    private class CorruptWrapper : Exception()
}
