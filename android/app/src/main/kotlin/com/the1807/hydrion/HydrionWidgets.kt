package com.the1807.hydrion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

private data class HydrationSnapshot(
    val todayMl: Int,
    val goalMl: Int,
    val progressPercent: Int,
    val quickAddMl: Int,
    val quickAddSmallMl: Int,
    val quickAddLargeMl: Int,
    val status: String,
)

private data class ActiveChallengeSnapshot(
    val challengeId: String,
    val title: String,
    val status: String,
    val progressPercent: Int,
    val action: String,
)

private fun android.content.SharedPreferences.hydrationSnapshot() = HydrationSnapshot(
    todayMl = getInt("today_ml", 0),
    goalMl = getInt("goal_ml", 2200),
    progressPercent = getInt("progress_percent", 0),
    quickAddMl = getInt("quick_add_ml", 250),
    quickAddSmallMl = getInt("quick_add_small_ml", 150),
    quickAddLargeMl = getInt("quick_add_large_ml", 500),
    status = getString("status", "Ready for a sip") ?: "Ready for a sip",
)

private fun android.content.SharedPreferences.activeChallengeSnapshot() =
    ActiveChallengeSnapshot(
        challengeId = getString("active_challenge_id", "") ?: "",
        title = getString("active_challenge_title", "No active challenge")
            ?: "No active challenge",
        status = getString("active_challenge_status", "Open Hydrion to choose a challenge.")
            ?: "Open Hydrion to choose a challenge.",
        progressPercent = getInt("active_challenge_progress", 0),
        action = getString("active_challenge_action", "Open challenges")
            ?: "Open challenges",
    )

private fun homeIntent(context: Context) =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("hydrion://home"),
    )

private fun quickLogIntent(context: Context, amountMl: Int, widgetId: Int) =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("hydrion://quick-log?amount=$amountMl&tap=${System.currentTimeMillis()}-$widgetId-$amountMl"),
    )

class HydrionDailyProgressWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val state = widgetData.hydrationSnapshot()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_progress)
            views.setTextViewText(R.id.widget_progress, "${state.progressPercent}%")
            views.setTextViewText(R.id.widget_amount, "${state.todayMl} / ${state.goalMl} ml")
            views.setTextViewText(R.id.widget_status, state.status)
            views.setProgressBar(R.id.widget_progress_bar, 100, state.progressPercent.coerceIn(0, 100), false)
            views.setOnClickPendingIntent(R.id.widget_root, homeIntent(context))
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class HydrionQuickLogWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val state = widgetData.hydrationSnapshot()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_log)
            views.setTextViewText(R.id.widget_progress, "${state.progressPercent}%")
            views.setTextViewText(R.id.widget_amount, "${state.todayMl} / ${state.goalMl} ml")
            views.setTextViewText(R.id.widget_status, state.status)
            views.setProgressBar(R.id.widget_progress_bar, 100, state.progressPercent.coerceIn(0, 100), false)
            val amounts = listOf(state.quickAddSmallMl, state.quickAddMl, state.quickAddLargeMl)
            val ids = listOf(R.id.widget_quick_small, R.id.widget_quick_saved, R.id.widget_quick_large)
            ids.zip(amounts).forEach { (id, amount) ->
                views.setTextViewText(id, "+$amount")
                views.setOnClickPendingIntent(id, quickLogIntent(context, amount, widgetId))
            }
            views.setOnClickPendingIntent(R.id.widget_content, homeIntent(context))
            views.setOnClickPendingIntent(
                R.id.widget_custom_log,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hydrion://log"),
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class HydrionActiveChallengeWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val state = widgetData.activeChallengeSnapshot()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_active_challenge)
            views.setTextViewText(R.id.widget_challenge_title, state.title)
            views.setTextViewText(R.id.widget_challenge_status, state.status)
            views.setTextViewText(R.id.widget_challenge_action, state.action)
            views.setProgressBar(R.id.widget_challenge_progress, 100, state.progressPercent.coerceIn(0, 100), false)
            val uri = if (state.challengeId.isEmpty()) {
                Uri.parse("hydrion://challenges")
            } else {
                Uri.parse("hydrion://challenge?id=${state.challengeId}")
            }
            val launch = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
            views.setOnClickPendingIntent(R.id.widget_root, launch)
            views.setOnClickPendingIntent(R.id.widget_challenge_action, launch)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
