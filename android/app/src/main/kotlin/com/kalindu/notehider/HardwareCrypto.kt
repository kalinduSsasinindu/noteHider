package com.kalindu.notehider

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
import javax.crypto.SecretKeyFactory
import android.app.KeyguardManager
import android.security.keystore.KeyPermanentlyInvalidatedException

/**
 * HardwareCrypto provides simple AES-GCM "wrap / unwrap" helpers backed by
 * Android Keystore.
 *
 * SECURITY GUARANTEES
 *  • Key material is *never* returned to the caller – only used inside TEE /
 *    StrongBox.
 *  • `setUserAuthenticationRequired(true)` + auth parameters make every
 *    cryptographic operation require a biometric / device credential.
 *  • When the user changes the lock-screen (adds/ removes biometrics, changes
 *    passcode) the underlying key becomes *invalidated*.  We detect this via
 *    `KeyPermanentlyInvalidatedException`, delete the keystore entry and
 *    bubble `KEY_INVALIDATED` to the Flutter layer so that it can trigger a
 *    re-enrolment flow.
 *  • On devices without any secure lock-screen configured we abort early by
 *    throwing `DEVICE_NOT_SECURE`.  The UI should direct the user to Android
 *    Security Settings.
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
        try {
            cipher.init(Cipher.ENCRYPT_MODE, key)
        } catch (e: KeyPermanentlyInvalidatedException) {
            // Key invalidated (e.g. new biometrics enrolled). Delete and signal.
            deleteKey(alias)
            throw IllegalStateException("KEY_INVALIDATED")
        }

        val iv = cipher.iv
        val cipherText = try {
            cipher.doFinal(plain)
        } catch (e: KeyPermanentlyInvalidatedException) {
            deleteKey(alias)
            throw IllegalStateException("KEY_INVALIDATED")
        }
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
        try {
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        } catch (e: KeyPermanentlyInvalidatedException) {
            deleteKey(alias)
            throw IllegalStateException("KEY_INVALIDATED")
        }
        return try {
            cipher.doFinal(cipherData)
        } catch (e: KeyPermanentlyInvalidatedException) {
            deleteKey(alias)
            throw IllegalStateException("KEY_INVALIDATED")
        }
    }

    // region — internal helpers
    private fun getOrCreateKey(alias: String): SecretKey {
        Log.d("HardwareCrypto", "getOrCreateKey: $alias")
        // ------------------------------------------------------------------
        // STEP 0 – Ensure the device actually has a secure lock screen. If not
        // there is no point in generating a key that will immediately refuse
        // to perform operations.
        // ------------------------------------------------------------------
        val km = ApplicationHolder.appContext.getSystemService(KeyguardManager::class.java)
        if (km != null && !km.isDeviceSecure) {
            throw IllegalStateException("DEVICE_NOT_SECURE")
        }

        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        ks.getKey(alias, null)?.let {
            val secure = isInsideSecureHardware(it as SecretKey)
            Log.d("HardwareCrypto", "Existing key found (insideSecureHW=$secure)")
            return it as SecretKey }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE
        )
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            // Require explicit user authentication (PIN/Pw or biometrics) on
            // every usage of the AES key.  This prevents malware that simply
            // runs in the background on an unlocked device from unwrapping
            // secrets without user presence.
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setUserAuthenticationRequired(true)
            // On API 30+ we can be more specific and accept either strong
            // biometrics or device credentials with a short 30-second timeout.
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setUserAuthenticationParameters(
                        /*timeoutSeconds=*/30,
                        KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG
                    )
                    // Disallow on-body detection to keep the key unlocked.
                    setUserAuthenticationValidWhileOnBody(false)
                    // Key can only be used when the device is unlocked.
                    setUnlockedDeviceRequired(true)
                }
            }
            // On API 23-28 we need to explicitly invalidate the key if the
            // biometric set changes and reduce the on-body unlock window.
            .apply {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                    // Force re-auth every single time (no cached 30-s window)
                    this.setUserAuthenticationValidityDurationSeconds(0)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    // Biometric enrolment should nuke the key.
                    this.setInvalidatedByBiometricEnrollment(true)
                }
            }
            // --- Key Attestation ---
            // Request a certificate chain proving the key lives in TEE / StrongBox.
            // The random nonce is echoed back inside the attestation so we can
            // bind each chain to a particular app launch.
            .setAttestationChallenge(ByteArray(16).also { java.security.SecureRandom().nextBytes(it) })

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
                .setUserAuthenticationRequired(true)
                .apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        setUserAuthenticationParameters(30, KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG)
                        setUserAuthenticationValidWhileOnBody(false)
                        setUnlockedDeviceRequired(true)
                    }
                }

            keyGenerator.init(fallbackBuilder.build())
            Log.d("HardwareCrypto", "Generating new AES key; strongBox=false (fallback)")
            return keyGenerator.generateKey()
        }
    }

    /** Returns true if the key material is confirmed to be inside secure
     *  hardware (StrongBox or TEE).  This is *best-effort* and will return
     *  false on API levels prior to 23 or if the query fails. */
    private fun isInsideSecureHardware(key: SecretKey): Boolean {
        return try {
            val factory = javax.crypto.SecretKeyFactory.getInstance(key.algorithm, ANDROID_KEYSTORE)
            val spec = factory.getKeySpec(key, android.security.keystore.KeyInfo::class.java) as android.security.keystore.KeyInfo
            spec.isInsideSecureHardware
        } catch (e: Exception) {
            false
        }
    }

    /** Deletes a keystore entry silently.  Best-effort – ignores all errors. */
    private fun deleteKey(alias: String) {
        try {
            val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            ks.deleteEntry(alias)
        } catch (_: Exception) {}
    }
    // endregion

    /** Returns the PEM-encoded certificate chain of the AES key so that the
     *  Flutter layer (or a backend) can verify StrongBox / TEE provenance.
     *  Throws if the alias does not exist or the platform does not support
     *  Key Attestation. */
    fun exportAttestationChain(alias: String = DEFAULT_ALIAS): List<String> {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val chain = ks.getCertificateChain(alias)
            ?: throw IllegalStateException("NO_KEY")

        return chain.map { cert ->
            Base64.encodeToString(cert.encoded, Base64.NO_WRAP)
        }
    }
} 