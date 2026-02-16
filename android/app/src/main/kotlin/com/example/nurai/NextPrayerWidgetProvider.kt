package com.example.nurai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

class NextPrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_WIDGETS) {
            updateAllWidgets(context)
        }
    }

    companion object {
        const val ACTION_REFRESH_WIDGETS = "com.example.nurai.action.REFRESH_NEXT_PRAYER_WIDGETS"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, NextPrayerWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { id -> updateWidget(context, manager, id) }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.next_prayer_widget)
            val payload = readPayload(context)

            if (payload == null) {
                views.setTextViewText(R.id.widget_title, "Next Prayer")
                views.setTextViewText(R.id.widget_primary, "Open NurAi to update")
                views.setTextViewText(R.id.widget_secondary, "")
                views.setViewVisibility(R.id.widget_location, View.GONE)
                views.setViewVisibility(R.id.widget_notifications, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_title, "Next Prayer")
                views.setTextViewText(
                    R.id.widget_location,
                    payload.locationLabel.ifBlank { "Current" },
                )
                views.setViewVisibility(R.id.widget_location, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_primary,
                    "${payload.nextPrayerLabel} ${payload.nextPrayerTime}",
                )
                views.setTextViewText(R.id.widget_secondary, payload.countdownLabel)
                val notifStatus = if (payload.isNotificationsEnabled) "Notifications: ON" else "Notifications: OFF"
                views.setTextViewText(R.id.widget_notifications, notifStatus)
                views.setViewVisibility(R.id.widget_notifications, View.VISIBLE)
            }

            views.setOnClickPendingIntent(R.id.widget_root, appOpenIntent(context))
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun readPayload(context: Context): NextPrayerPayload? {
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(MainActivity.PREF_KEY_PAYLOAD, null) ?: return null
            return try {
                val json = JSONObject(raw)
                NextPrayerPayload(
                    locationLabel = json.optString("locationLabel", "Current"),
                    nextPrayerLabel = json.optString("nextPrayerLabel", "Next Prayer"),
                    nextPrayerTime = json.optString("nextPrayerTime", "--:--"),
                    countdownLabel = json.optString("countdownLabel", ""),
                    isNotificationsEnabled = json.optBoolean("isNotificationsEnabled", false),
                )
            } catch (_: Exception) {
                null
            }
        }

        private fun appOpenIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "adhan")
            }
            return PendingIntent.getActivity(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}

private data class NextPrayerPayload(
    val locationLabel: String,
    val nextPrayerLabel: String,
    val nextPrayerTime: String,
    val countdownLabel: String,
    val isNotificationsEnabled: Boolean,
)
