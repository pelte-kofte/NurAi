package com.example.nurai

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_SET_PAYLOAD -> {
                        val payload = call.argument<String>("payload")
                        if (payload == null) {
                            result.error("invalid_args", "Missing payload", null)
                            return@setMethodCallHandler
                        }
                        savePayload(payload)
                        broadcastWidgetRefresh()
                        result.success(null)
                    }

                    METHOD_REFRESH_WIDGETS -> {
                        broadcastWidgetRefresh()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun savePayload(payload: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(PREF_KEY_PAYLOAD, payload).apply()
    }

    private fun broadcastWidgetRefresh() {
        val intent = Intent(NextPrayerWidgetProvider.ACTION_REFRESH_WIDGETS).apply {
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    companion object {
        const val CHANNEL_NAME = "nurai.widgets"
        const val METHOD_SET_PAYLOAD = "setNextPrayerPayload"
        const val METHOD_REFRESH_WIDGETS = "refreshWidgets"
        const val PREFS_NAME = "nurai_widget_prefs"
        const val PREF_KEY_PAYLOAD = "next_prayer_payload"
    }
}
