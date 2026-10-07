package com.niaverp.niaverp

import java.io.File

/**
 * App-private storage for the wrapped database key — pure file and decision
 * logic with no Android Keystore/Cipher dependencies, so it is covered by
 * plain JVM unit tests (DbKeyStoreTest).
 *
 * Layout: ONE file ("niaverp_db_key.blob") holding the 12-byte GCM IV
 * followed by the ciphertext, written via temp-file + atomic rename. The old
 * two-file layout ("niaverp_db_key.wrapped" + "niaverp_db_key.iv") is still
 * understood on read. A half-written state (one legacy file without the
 * other, or a truncated single file) is reported as [Stored.Partial] and
 * must be treated as corruption — never as "missing".
 */
class DbKeyStore(private val dir: File) {

    companion object {
        const val SINGLE_NAME = "niaverp_db_key.blob"
        const val LEGACY_WRAPPED_NAME = "niaverp_db_key.wrapped"
        const val LEGACY_IV_NAME = "niaverp_db_key.iv"
        const val DB_NAME = "niaverp.db"
        const val GCM_IV_BYTES = 12

        /** Minimum plausible blob: IV plus a 16-byte GCM tag. */
        const val MIN_BLOB_BYTES = GCM_IV_BYTES + 16
    }

    /** Raw wrapped material (IV separated from ciphertext). */
    data class WrappedBlob(val iv: ByteArray, val ciphertext: ByteArray) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (other !is WrappedBlob) return false
            return iv.contentEquals(other.iv) &&
                ciphertext.contentEquals(other.ciphertext)
        }

        override fun hashCode(): Int {
            var result = iv.contentHashCode()
            result = 31 * result + ciphertext.contentHashCode()
            return result
        }
    }

    sealed interface Stored {
        /** No key file in any layout. */
        object Absent : Stored

        /** Complete wrapped material. */
        data class Ok(val blob: WrappedBlob) : Stored

        /** Half-written or truncated file: corruption, never "missing". */
        data class Partial(val reason: String) : Stored
    }

    /** What the caller may do with the stored state (pure decision matrix). */
    sealed interface KeyDecision {
        /** Unwrap path: decrypt with the existing wrapping key. */
        object Proceed : KeyDecision

        /** First run: minting a fresh key is allowed (no blob, no database). */
        object Provision : KeyDecision

        /** Database exists but no wrapped key: never mint over user data. */
        object RefuseExistingData : KeyDecision

        /** Blob present but the Keystore wrapping key is gone (reinstall). */
        object RefuseWiped : KeyDecision

        /** Half-written or undecryptable material. */
        object RefuseCorrupt : KeyDecision
    }

    /**
     * Decide without touching the Keystore (its presence is an input).
     * Decrypt failures surface later at the unwrap call site and map to
     * [KeyDecision.RefuseCorrupt] there.
     */
    fun decide(
        stored: Stored,
        wrappingKeyPresent: Boolean,
        databaseExists: Boolean,
    ): KeyDecision = when {
        stored is Stored.Partial -> KeyDecision.RefuseCorrupt
        stored is Stored.Absent && databaseExists -> KeyDecision.RefuseExistingData
        stored is Stored.Absent -> KeyDecision.Provision
        !wrappingKeyPresent -> KeyDecision.RefuseWiped
        else -> KeyDecision.Proceed
    }

    /** Read the wrapped material in either layout. Never throws for layout
     *  reasons: absence and partial states are values, not exceptions. */
    fun read(): Stored {
        val single = File(dir, SINGLE_NAME)
        if (single.exists()) {
            if (!single.isFile) return Stored.Partial("single-not-a-file")
            val all = single.readBytes()
            if (all.size < MIN_BLOB_BYTES) {
                return Stored.Partial("single-truncated:${all.size}")
            }
            return Stored.Ok(
                WrappedBlob(
                    iv = all.copyOfRange(0, GCM_IV_BYTES),
                    ciphertext = all.copyOfRange(GCM_IV_BYTES, all.size),
                ),
            )
        }
        val wrapped = File(dir, LEGACY_WRAPPED_NAME)
        val iv = File(dir, LEGACY_IV_NAME)
        val wrappedExists = wrapped.exists()
        val ivExists = iv.exists()
        if (!wrappedExists && !ivExists) return Stored.Absent
        if (!wrappedExists || !ivExists) {
            return Stored.Partial("half-written-legacy")
        }
        if (!wrapped.isFile || !iv.isFile) {
            return Stored.Partial("legacy-not-a-file")
        }
        return Stored.Ok(WrappedBlob(iv.readBytes(), wrapped.readBytes()))
    }

    /** Persist atomically: write beside the target, then rename over it. */
    fun write(blob: WrappedBlob) {
        val tmp = File(dir, "$SINGLE_NAME.tmp")
        val out = tmp.outputStream()
        try {
            out.write(blob.iv)
            out.write(blob.ciphertext)
            out.flush()
            out.fd.sync()
        } finally {
            out.close()
        }
        if (!tmp.renameTo(File(dir, SINGLE_NAME))) {
            tmp.delete()
            throw java.io.IOException("atomic rename of wrapped key failed")
        }
    }

    /** True when an app database file already exists (user data at stake). */
    fun databaseExists(): Boolean = File(dir, DB_NAME).exists()
}
