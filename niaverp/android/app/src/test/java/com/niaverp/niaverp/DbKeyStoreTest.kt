package com.niaverp.niaverp

import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * JVM unit tests for [DbKeyStore] — file layout, atomic write and the
 * provision/refuse decision matrix. Keystore access and AES-GCM unwrapping
 * stay in MainActivity (Android-only) and are NOT covered here; the matrix
 * input `wrappingKeyPresent` stands in for the Keystore state.
 */
class DbKeyStoreTest {

    @get:Rule
    val tmp = TemporaryFolder()

    private fun store(): DbKeyStore = DbKeyStore(tmp.root)

    private fun blob(fill: Byte): DbKeyStore.WrappedBlob {
        val iv = ByteArray(DbKeyStore.GCM_IV_BYTES) { fill }
        val ct = ByteArray(32) { (fill + 1).toByte() }
        return DbKeyStore.WrappedBlob(iv, ct)
    }

    @Test
    fun `first run provisions and round-trips`() {
        val store = store()
        assertEquals(DbKeyStore.Stored.Absent, store.read())
        assertEquals(
            DbKeyStore.KeyDecision.Provision,
            store.decide(
                stored = DbKeyStore.Stored.Absent,
                wrappingKeyPresent = false,
                databaseExists = false,
            ),
        )
        val written = blob(7)
        store.write(written)
        val read = store.read()
        assertTrue(read is DbKeyStore.Stored.Ok)
        assertArrayEquals(written.iv, (read as DbKeyStore.Stored.Ok).blob.iv)
        assertArrayEquals(written.ciphertext, read.blob.ciphertext)
        // Single atomic file only: no stray temp file left behind.
        assertEquals(
            listOf(DbKeyStore.SINGLE_NAME),
            tmp.root.listFiles()!!.map { it.name }.sorted(),
        )
    }

    @Test
    fun `existing database with missing key refuses instead of minting`() {
        File(tmp.root, DbKeyStore.DB_NAME).writeBytes(ByteArray(16))
        assertTrue(store().databaseExists())
        assertEquals(
            DbKeyStore.KeyDecision.RefuseExistingData,
            store().decide(
                stored = DbKeyStore.Stored.Absent,
                wrappingKeyPresent = false,
                databaseExists = true,
            ),
        )
        // Even with a wrapping key present, absence + data refuses.
        assertEquals(
            DbKeyStore.KeyDecision.RefuseExistingData,
            store().decide(
                stored = DbKeyStore.Stored.Absent,
                wrappingKeyPresent = true,
                databaseExists = true,
            ),
        )
    }

    @Test
    fun `half-written legacy file is corruption, never missing`() {
        File(tmp.root, DbKeyStore.LEGACY_WRAPPED_NAME).writeBytes(ByteArray(32))
        val read = store().read()
        assertTrue(read is DbKeyStore.Stored.Partial)
        assertEquals(
            DbKeyStore.KeyDecision.RefuseCorrupt,
            store().decide(
                stored = read,
                wrappingKeyPresent = true,
                databaseExists = false,
            ),
        )
    }

    @Test
    fun `truncated single file is corruption, never missing`() {
        File(tmp.root, DbKeyStore.SINGLE_NAME).writeBytes(ByteArray(10))
        val read = store().read()
        assertTrue(read is DbKeyStore.Stored.Partial)
        assertEquals(
            DbKeyStore.KeyDecision.RefuseCorrupt,
            store().decide(
                stored = read,
                wrappingKeyPresent = false,
                databaseExists = false,
            ),
        )
    }

    @Test
    fun `old two-file layout still reads`() {
        val written = blob(9)
        File(tmp.root, DbKeyStore.LEGACY_WRAPPED_NAME).writeBytes(written.ciphertext)
        File(tmp.root, DbKeyStore.LEGACY_IV_NAME).writeBytes(written.iv)
        val read = store().read()
        assertTrue(read is DbKeyStore.Stored.Ok)
        assertEquals(
            written,
            (read as DbKeyStore.Stored.Ok).blob,
        )
    }

    @Test
    fun `blob present but wrapping key gone refuses as wiped`() {
        store().write(blob(3))
        val read = store().read()
        assertTrue(read is DbKeyStore.Stored.Ok)
        assertEquals(
            DbKeyStore.KeyDecision.RefuseWiped,
            store().decide(
                stored = read,
                wrappingKeyPresent = false,
                databaseExists = false,
            ),
        )
    }

    @Test
    fun `blob present with wrapping key proceeds to decrypt`() {
        store().write(blob(5))
        val read = store().read()
        assertEquals(
            DbKeyStore.KeyDecision.Proceed,
            store().decide(
                stored = read,
                wrappingKeyPresent = true,
                databaseExists = false,
            ),
        )
    }
}
