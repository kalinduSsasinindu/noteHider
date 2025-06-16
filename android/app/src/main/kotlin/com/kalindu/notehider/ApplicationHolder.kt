package com.kalindu.notehider

import android.content.Context

/**
 * Convenience singleton that exposes the `applicationContext` to classes which
 * cannot easily receive a Context (e.g. static utility objects inside the
 * Keystore layer).  The context is assigned once from `MainActivity`.
 */
object ApplicationHolder {
    /** Do NOT call before `MainActivity.configureFlutterEngine()` executes. */
    lateinit var appContext: Context
} 