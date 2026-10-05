package com.niaverp.niaverp

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
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
 *                  "wipedByUninstall" (when a failure is the cause)
 *  - a random 256-bit database key is generated once, wrapped with an
 *    Android Keystore AES-GCM key and stored wrapped in app-private storage;
 *    the plaintext key exists only in memory for the duration of the reply.
 *  - there is NO recovery API and NO plaintext fallback: if the Keystore key
 *    or the wrapped blob is unusable, the channel reports a failure code and
 *    the database stays closed.
 *  - key bytes are never logged and never placed in an exception message.
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
        const val GCM_IV_BYTES = 12
        const val DB_KEY_BYTES = 32
        const val WRAPPED_SUFFIX = ".wrapped"
        const val IV_SUFFIX = ".iv"
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
            val wrapped = readWrapped()
            when {
                wrapped == null -> missingReply()
                else -> availableReply(wrapped)
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

    private fun availableReply(wrapped: WrappedKey): Map<String, Any?> {
        val keyStore = keyStore()
        val cipher = Cipher.getInstance(WRAP_TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, wrappingKey(keyStore), GCMParameterSpec(GCM_TAG_BITS, wrapped.iv))
        val plaintext = cipher.doFinal(wrapped.ciphertext)
        if (plaintext.size != DB_KEY_BYTES) {
            // Wrong length is a corrupt wrapper, not a usable key.
            throw CorruptWrapper()
        }
        return mapOf<String, Any?>("state" to "available", "key" to plaintext)
    }

    private fun missingReply(): Map<String, Any?> {
        // First run (or after an uninstall wiped the Keystore entry): provision
        // a new key pair and store the wrapped database key app-privately.
        val fresh = newDatabaseKey()
        val keyStore = keyStore()
        val cipher = Cipher.getInstance(WRAP_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey(keyStore))
        val ciphertext = cipher.doFinal(fresh)
        writeWrapped(WrappedKey(ciphertext, cipher.iv))
        return mapOf<String, Any?>("state" to "available", "key" to fresh)
    }

    private fun failureReply(failure: String): Map<String, Any?> =
        mapOf<String, Any?>("state" to "failed", "failure" to failure)

    private fun newDatabaseKey(): ByteArray {
        val bytes = ByteArray(DB_KEY_BYTES)
        secureRandom.nextBytes(bytes)
        return bytes
    }

    private fun keyStore(): KeyStore {
        val store = KeyStore.getInstance(KEY_STORE)
        store.load(null)
        return store
    }

    /**
     * The Keystore AES-GCM key that wraps the database key. Created on first
     * use; it is non-exportable by construction and never leaves the Keystore.
     */
    private fun wrappingKey(store: KeyStore): SecretKey {
        val existing = store.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing
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
    }

    private fun wrappedFile() = java.io.File(filesDir, "niaverp_db_key$WRAPPED_SUFFIX")

    private fun ivFile() = java.io.File(filesDir, "niaverp_db_key$IV_SUFFIX")

    private fun readWrapped(): WrappedKey? {
        val wrapped = wrappedFile()
        val iv = ivFile()
        if (!wrapped.exists() || !iv.exists()) return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!wrapped.isFile || !iv.isFile) return null
        }
        return WrappedKey(wrapped.readBytes(), iv.readBytes())
    }

    private fun writeWrapped(value: WrappedKey) {
        wrappedFile().writeBytes(value.ciphertext)
        ivFile().writeBytes(value.iv)
    }

    private class WrappedKey(val ciphertext: ByteArray, val iv: ByteArray)

    private class KeystoreUnavailable : Exception()

    private class CorruptWrapper : Exception()
}