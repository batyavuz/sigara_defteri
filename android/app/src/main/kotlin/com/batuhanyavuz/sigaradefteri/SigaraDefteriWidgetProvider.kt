package com.batuhanyavuz.sigaradefteri

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Ana ekran widget'i: Bugun adet, maliyet (varsa), streak gosterir.
 * Veri Flutter tarafindan WidgetService ile guncellenir.
 */
class SigaraDefteriWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val todayCount = prefs.getInt("flutter.today_count", 0)
        val todayCost = prefs.getFloat("flutter.today_cost", 0f).toDouble()
        val streak = prefs.getInt("flutter.streak", 0)
        val showCost = prefs.getBoolean("flutter.show_cost", false)

        val views = RemoteViews(context.packageName, R.layout.widget_sigara_defteri).apply {
            setTextViewText(R.id.widget_today_count, "$todayCount adet")
            setTextViewText(R.id.widget_streak, if (streak > 0) "$streak gun trend" else "")
            if (showCost) {
                setViewVisibility(R.id.widget_cost_label, android.view.View.VISIBLE)
                setTextViewText(R.id.widget_cost_label, "TL " + "%.2f".format(todayCost))
            } else {
                setViewVisibility(R.id.widget_cost_label, android.view.View.GONE)
            }
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
