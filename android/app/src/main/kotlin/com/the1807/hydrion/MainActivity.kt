package com.the1807.hydrion

import android.app.LocaleManager
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.util.Locale
import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.net.Uri

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hydrion/app_locale")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setApplicationLocale" -> {
                        val languageTag = call.argument<String>("languageTag")?.trim().orEmpty()
                        if (languageTag.isEmpty()) {
                            result.error("invalid_locale", "A language tag is required.", null)
                            return@setMethodCallHandler
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            getSystemService(LocaleManager::class.java).applicationLocales =
                                LocaleList.forLanguageTags(languageTag)
                        } else {
                            val locale = Locale.forLanguageTag(languageTag)
                            Locale.setDefault(locale)
                            @Suppress("DEPRECATION")
                            resources.updateConfiguration(
                                resources.configuration.apply { setLocale(locale) },
                                resources.displayMetrics,
                            )
                        }
                        result.success(null)
                    }
                    "getApplicationLocale" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val locales = getSystemService(LocaleManager::class.java).applicationLocales
                            result.success(
                                mapOf(
                                    "usesDeviceLocale" to locales.isEmpty,
                                    "languageTag" to if (locales.isEmpty) "" else locales[0].toLanguageTag(),
                                ),
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            val locale = resources.configuration.locale
                            result.success(
                                mapOf(
                                    "usesDeviceLocale" to false,
                                    "languageTag" to locale.toLanguageTag(),
                                ),
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hydrion/permission_revocation",
        ).setMethodCallHandler { call, result ->
            if (call.method != "revokeRuntimePermissionsOnKill") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                result.success("settings_required")
                return@setMethodCallHandler
            }
            try {
                revokeSelfPermissionsOnKill(
                    listOf(
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.POST_NOTIFICATIONS,
                    ),
                )
                result.success("scheduled")
            } catch (exception: Exception) {
                result.error("revocation_failed", exception.message, null)
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hydrion/timed_session",
        ).setMethodCallHandler { call, result ->
            val notificationManager = getSystemService(NotificationManager::class.java)
            when (call.method) {
                "cancel" -> {
                    notificationManager.cancel(call.argument<Int>("id") ?: 0)
                    result.success(null)
                }
                "show" -> {
                    showTimedSessionNotification(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showTimedSessionNotification(arguments: Map<*, *>) {
        val id = arguments["id"] as? Int ?: return
        val challengeId = arguments["challengeId"] as? String ?: return
        val title = arguments["title"] as? String ?: return
        val state = arguments["state"] as? String ?: "running"
        val pausedText = arguments["pausedText"] as? String
            ?: getString(R.string.timed_session_paused)
        val remainingSeconds = (arguments["remainingSeconds"] as? Int ?: 0).coerceAtLeast(0)
        val completionAt = arguments["completionAtMillis"] as? Long
        val pauseLabel = arguments["pauseLabel"] as? String
            ?: getString(R.string.timed_session_pause)
        val stopLabel = arguments["stopLabel"] as? String
            ?: getString(R.string.timed_session_stop)
        val openLabel = arguments["openLabel"] as? String
            ?: getString(R.string.timed_session_open)
        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "hydrion_timed_sessions"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    getString(R.string.timed_session_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = getString(R.string.timed_session_channel_description)
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(R.drawable.ic_challenge_pomodoro_sip)
            .setColor(Color.rgb(0, 137, 123))
            .setContentTitle(title)
            .setContentText(if (state == "paused") pausedText else title)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setAutoCancel(false)
            .setContentIntent(sessionIntent(challengeId, "open", id, 0))
            .addAction(0, pauseLabel, sessionIntent(
                challengeId,
                if (state == "paused") "resume" else "pause",
                id,
                1,
            ))
            .addAction(0, stopLabel, sessionIntent(challengeId, "stop", id, 2))
            .addAction(0, openLabel, sessionIntent(challengeId, "open", id, 3))
        if (state == "running" && completionAt != null) {
            builder
                .setWhen(completionAt)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setTimeoutAfter(remainingSeconds * 1000L)
            }
        } else {
            builder.setShowWhen(false)
        }
        manager.notify(id, builder.build())
    }

    private fun sessionIntent(
        challengeId: String,
        action: String,
        notificationId: Int,
        actionIndex: Int,
    ): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            this.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data = Uri.parse("hydrion://session?id=$challengeId&action=$action")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            notificationId * 10 + actionIndex,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
