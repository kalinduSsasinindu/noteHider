package com.example.notehider

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import com.example.notehider.PepperBox

class MainActivity : FlutterActivity() {
    private val CHANNEL = "notehider/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
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
                            result.error("WRAP_ERROR", e.message, null)
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
                            result.error("UNWRAP_ERROR", e.message, null)
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
                    else -> result.notImplemented()
                }
            }
    }
}
