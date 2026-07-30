package com.the1807.hydrion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

private data class WidgetSnapshot(
    val todayMl: Int,
    val goalMl: Int,
    val progressPercent: Int,
    val quickAddMl: Int,
    val status: String,
)

private fun android.content.SharedPreferences.widgetSnapshot(): WidgetSnapshot {
    return WidgetSnapshot(
        todayMl = getInt("today_ml", 0),
        goalMl = getInt("goal_ml", 2200),
        progressPercent = getInt("progress_percent", 0),
        quickAddMl = getInt("quick_add_ml", 250),
        status = getString("status", "Ready for a sip") ?: "Ready for a sip",
    )
}

class HydrionDailyProgressWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val state = widgetData.widgetSnapshot()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_progress)
            views.setTextViewText(R.id.widget_progress, "${state.progressPercent}%")
            views.setTextViewText(R.id.widget_amount, "${state.todayMl} / ${state.goalMl} ml")
            views.setTextViewText(R.id.widget_status, state.status)
            views.setProgressBar(R.id.widget_progress_bar, 100, state.progressPercent.coerceAtMost(100), false)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
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
        val state = widgetData.widgetSnapshot()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_log)
            views.setTextViewText(R.id.widget_progress, "${state.progressPercent}%")
            views.setTextViewText(R.id.widget_amount, "${state.todayMl} / ${state.goalMl} ml")
            views.setTextViewText(R.id.widget_status, state.status)
            views.setTextViewText(R.id.widget_quick_log, "+ ${state.quickAddMl} ml")
            views.setProgressBar(R.id.widget_progress_bar, 100, state.progressPercent.coerceAtMost(100), false)
            val uri = Uri.parse(
                "hydrion://quick-log?amount=${state.quickAddMl}&tap=${System.currentTimeMillis()}-$widgetId",
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_log,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
            )
            views.setOnClickPendingIntent(
                R.id.widget_content,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
