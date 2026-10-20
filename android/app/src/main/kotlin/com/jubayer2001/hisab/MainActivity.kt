package com.jubayer2001.hisab

import android.content.Context
import android.os.Bundle
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Two small security jobs that need Android itself:
 *
 *  1. Keep the screen out of screenshots and the recent-apps picture (FLAG_SECURE).
 *  2. (Being a FragmentActivity is what lets the phone's fingerprint/PIN prompt appear over the app.)
 *  3. Keep the database's encryption key. The key is random, never leaves the phone, and is
 *     stored only in encrypted form. The key that encrypts it lives inside Android's hardware-backed
 *     Keystore and cannot be read out, not even by this app.
 */
class MainActivity : FlutterFragmentActivity() {
    private val prefs by lazy { getSharedPreferences(PREFS, Context.MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Applied before the first frame, so nothing is ever shown unprotected on start-up.
        // On by default; Flutter writes the person's choice here through setSecure below.
        if (prefs.getBoolean(KEY_SECURE, true)) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val on = call.argument<Boolean>("on") ?: true
                    prefs.edit().putBoolean(KEY_SECURE, on).apply()
                    if (on) {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "isSecure" -> result.success(prefs.getBoolean(KEY_SECURE, true))
                "databaseKey" -> {
                    try {
                        result.success(databaseKeyHex())
                    } catch (e: Exception) {
                        // The caller decides what to do (it must never fall back to a guess).
                        result.error("KEY_UNAVAILABLE", e.javaClass.simpleName, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** The 256-bit database key as 64 hex characters. Created on first use. */
    private fun databaseKeyHex(): String {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val wrapped = prefs.getString(KEY_WRAPPED, null)

        if (wrapped != null) {
            val data = Base64.decode(wrapped, Base64.NO_WRAP)
            val iv = data.copyOfRange(0, GCM_IV_BYTES)
            val cipherText = data.copyOfRange(GCM_IV_BYTES, data.size)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, wrappingKey(keyStore), GCMParameterSpec(GCM_TAG_BITS, iv))
            return toHex(cipher.doFinal(cipherText))
        }

        val raw = ByteArray(KEY_BYTES).also { SecureRandom().nextBytes(it) }
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey(keyStore))
        val sealed = cipher.iv + cipher.doFinal(raw)
        // commit(), not apply(): the key must be on disk before the database is encrypted with it.
        check(prefs.edit().putString(KEY_WRAPPED, Base64.encodeToString(sealed, Base64.NO_WRAP)).commit())
        return toHex(raw)
    }

    private fun wrappingKey(keyStore: KeyStore): SecretKey {
        (keyStore.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }

    private fun toHex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it) }

    private companion object {
        const val CHANNEL = "hisab/security"
        const val PREFS = "hisab_vault"
        const val KEY_SECURE = "secure_window"
        const val KEY_WRAPPED = "wrapped_db_key"
        const val ALIAS = "hisab_db_wrapping_key_v1"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val GCM_IV_BYTES = 12
        const val GCM_TAG_BITS = 128
        const val KEY_BYTES = 32
    }
}
