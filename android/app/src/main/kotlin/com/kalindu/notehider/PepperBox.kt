package com.kalindu.notehider

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey

/**
 * PepperBox keeps a symmetric HMAC-SHA256 key inside Android Keystore (StrongBox when available)
 * and computes a HMAC tag for a given password. The key material is never extractable.
 */
object PepperBox {
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val PEPPER_ALIAS = "notehider_pepper_key"
    private const val MAC_ALGO = "HmacSHA256"

    fun computeTag(plainPassword: String): String {
        val key = getOrCreateKey()
        val mac = Mac.getInstance(MAC_ALGO)
        mac.init(key)
        val tag = mac.doFinal(plainPassword.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(tag, Base64.NO_WRAP)
    }

    // ---------------------------------------------------------------------
    private fun getOrCreateKey(): SecretKey {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        ks.getKey(PEPPER_ALIAS, null)?.let {
            val strong = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
            Log.d("PepperBox", "Existing pepper key found (StrongBox=$strong)")
            return it as SecretKey
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_HMAC_SHA256,
            ANDROID_KEYSTORE
        )
        val builder = KeyGenParameterSpec.Builder(
            PEPPER_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setUserAuthenticationParameters(
                        30,
                        KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG
                    )
                    setUnlockedDeviceRequired(true)
                    setUserAuthenticationValidWhileOnBody(false)
                }
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }
        try {
            keyGenerator.init(builder.build())
        } catch (e: Exception) {
            // StrongBox failure – fallback
            Log.w("PepperBox", "StrongBox HMAC keygen failed (${e.message}). Falling back to Keystore")
            val fb = KeyGenParameterSpec.Builder(
                PEPPER_ALIAS,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setKeySize(256)
                .setUserAuthenticationRequired(true)
                .apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        setUserAuthenticationParameters(30, KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG)
                        setUnlockedDeviceRequired(true)
                        setUserAuthenticationValidWhileOnBody(false)
                    }
                }
            keyGenerator.init(fb.build())
        }
        Log.d("PepperBox", "Generated new pepper key")
        return keyGenerator.generateKey()
    }
} 