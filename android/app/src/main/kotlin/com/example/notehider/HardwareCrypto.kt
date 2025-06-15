package com.example.notehider

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.util.Base64
import android.util.Log

/**
 * HardwareCrypto provides simple wrap/unwrap utilities backed by Android
 * Keystore. It tries to create the key inside StrongBox (TEE) on devices that
 * support it; otherwise it falls back to default Keystore protection.
 */
object HardwareCrypto {
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val DEFAULT_ALIAS = "notehider_hardware_key"

    /** Wraps (encrypts) [plain] with a hardware-backed AES key. Returns a Base-64
     * string containing 12-byte IV + ciphertext. */
    fun wrapBytes(alias: String = DEFAULT_ALIAS, plain: ByteArray): String {
        Log.d("HardwareCrypto", "wrapBytes called, alias=$alias, len=${plain.size}")
        val key = getOrCreateKey(alias)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val iv = cipher.iv
        val cipherText = cipher.doFinal(plain)
        val out = ByteArray(iv.size + cipherText.size)
        System.arraycopy(iv, 0, out, 0, iv.size)
        System.arraycopy(cipherText, 0, out, iv.size, cipherText.size)
        return Base64.encodeToString(out, Base64.NO_WRAP)
    }

    /** Unwraps previously wrapped data (produced by [wrapBytes]). */
    fun unwrapBytes(alias: String = DEFAULT_ALIAS, wrapped: String): ByteArray {
        Log.d("HardwareCrypto", "unwrapBytes called, alias=$alias, b64Len=${wrapped.length}")
        val key = getOrCreateKey(alias)
        val bytes = Base64.decode(wrapped, Base64.NO_WRAP)
        val iv = bytes.copyOfRange(0, 12) // GCM 96-bit nonce
        val cipherData = bytes.copyOfRange(12, bytes.size)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        return cipher.doFinal(cipherData)
    }

    // region — internal helpers
    private fun getOrCreateKey(alias: String): SecretKey {
        Log.d("HardwareCrypto", "getOrCreateKey: $alias")
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        ks.getKey(alias, null)?.let {
            Log.d("HardwareCrypto", "Existing key found (StrongBox=${Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && (it as SecretKey).algorithm == "AES"})")
            return it as SecretKey }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE
        )
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setUserAuthenticationRequired(false)

        var useStrongBox = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
            useStrongBox = true
        }

        try {
            keyGenerator.init(builder.build())
            Log.d("HardwareCrypto", "Generating new AES key; strongBox=$useStrongBox")
            return keyGenerator.generateKey()
        } catch (e: Exception) {
            // StrongBox might be unsupported or out of space. Retry without it.
            Log.w("HardwareCrypto", "StrongBox keygen failed (${e.message}). Falling back to normal Keystore")
            val fallbackBuilder = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(false)

            keyGenerator.init(fallbackBuilder.build())
            Log.d("HardwareCrypto", "Generating new AES key; strongBox=false (fallback)")
            return keyGenerator.generateKey()
        }
    }
    // endregion
} 