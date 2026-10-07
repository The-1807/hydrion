package com.the1807.hydrion

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.util.UUID

/**
 * Invisible, non-exported trampoline for quick-log widget buttons.
 *
 * The widget's PendingIntent is built when the widget is drawn, so anything it
 * carries is shared by every tap until the next redraw. This activity runs once
 * per tap, mints a fresh nonce for that tap and forwards
 * `hydrion://quick-log?amount=<ml>&tap=<nonce>` to [MainActivity] with the
 * home_widget launch action. The Dart side keeps deduplicating by
 * `widget-<tap>`, so distinct taps log separately while a redelivered intent
 * (activity recreation, process restore) carries the same nonce and logs once.
 */
class WidgetQuickLogActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Only a first launch is a tap. A recreated trampoline must not mint a
        // second nonce for the same tap.
        if (savedInstanceState == null) {
            startActivity(forwardIntent(this, intent?.data))
        }
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    companion object {
        private const val MIN_ML = 50
        private const val MAX_ML = 2000

        /** Render-time URI: the amount only, never a tap identifier. */
        fun tapUri(amountMl: Int): Uri =
            Uri.parse("hydrion://quick-log?amount=$amountMl")

        internal fun forwardIntent(context: Context, source: Uri?): Intent {
            val amount = source
                ?.takeIf { it.scheme == "hydrion" && it.host == "quick-log" }
                ?.getQueryParameter("amount")
                ?.toIntOrNull()
                ?.takeIf { it in MIN_ML..MAX_ML }
            val target = if (amount == null) {
                Uri.parse("hydrion://home")
            } else {
                Uri.Builder()
                    .scheme("hydrion")
                    .authority("quick-log")
                    .appendQueryParameter("amount", amount.toString())
                    .appendQueryParameter("tap", UUID.randomUUID().toString())
                    .build()
            }
            return Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                data = target
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
    }
}
