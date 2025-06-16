package com.kalindu.notehider

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import com.kalindu.notehider.PepperBox
import com.kalindu.notehider.ApplicationHolder

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "notehider/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Provide the application context to utility singletons (e.g.
        // HardwareCrypto) early in the app lifecycle.
        ApplicationHolder.appContext = applicationContext
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "probe" -> {
                        try {
                            val bitmask = IntegrityBridge.probe()
                            result.success(bitmask)
                        } catch (e: Exception) {
                            result.error("PROBE_ERROR", e.message, null)
                        }
                    }
                    "wrapBytes" -> {
                        Log.d("MainActivity","wrapBytes via channel")
                        try {
                            val alias = call.argument<String>("alias") ?: "default"
                            val data = call.argument<String>("data") ?: ""
                            val wrapped = HardwareCrypto.wrapBytes(alias, android.util.Base64.decode(data, android.util.Base64.NO_WRAP))
                            result.success(wrapped)
                        } catch (e: Exception) {
                            // Map internal sentinel exceptions into distinct
                            // MethodChannel error codes so the Dart layer can
                            // react (show settings redirect, start
                            // re-enrolment, etc.).
                            val code = when (e.message) {
                                "DEVICE_NOT_SECURE" -> "DEVICE_NOT_SECURE"
                                "KEY_INVALIDATED" -> "KEY_INVALIDATED"
                                else -> "WRAP_ERROR"
                            }
                            result.error(code, e.message, null)
                        }
                    }
                    "unwrapBytes" -> {
                        Log.d("MainActivity","unwrapBytes via channel")
                        try {
                            val alias = call.argument<String>("alias") ?: "default"
                            val wrapped = call.argument<String>("data") ?: ""
                            val plain = HardwareCrypto.unwrapBytes(alias, wrapped)
                            val encoded = android.util.Base64.encodeToString(plain, android.util.Base64.NO_WRAP)
                            result.success(encoded)
                        } catch (e: Exception) {
                            // Map internal sentinel exceptions into distinct
                            // MethodChannel error codes so the Dart layer can
                            // react (show settings redirect, start
                            // re-enrolment, etc.).
                            val code = when (e.message) {
                                "DEVICE_NOT_SECURE" -> "DEVICE_NOT_SECURE"
                                "KEY_INVALIDATED" -> "KEY_INVALIDATED"
                                else -> "UNWRAP_ERROR"
                            }
                            result.error(code, e.message, null)
                        }
                    }
                    "computePepperTag" -> {
                        try {
                            val pwd = call.argument<String>("password") ?: ""
                            val tag = PepperBox.computeTag(pwd)
                            result.success(tag)
                        } catch (e: Exception) {
                            result.error("PEPPER_ERROR", e.message, null)
                        }
                    }
                    "getKeyAttestation" -> {
                        // Returns a base-64 list of DER certificates that
                        // prove the AES key's origin (TEE / StrongBox). The
                        // Flutter layer can forward this to a backend or
                        // verify the root locally.
                        try {
                            val alias = call.argument<String>("alias") ?: "default"
                            val chain = HardwareCrypto.exportAttestationChain(alias)
                            result.success(chain)
                        } catch (e: Exception) {
                            val code = when (e.message) {
                                "NO_KEY" -> "NO_KEY"
                                else -> "ATTEST_ERROR"
                            }
                            result.error(code, e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
