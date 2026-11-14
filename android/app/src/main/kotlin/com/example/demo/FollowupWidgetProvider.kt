package com.lbm.solufine

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

import es.antonborri.home_widget.HomeWidgetProvider

class FollowupWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {

        for (widgetId in appWidgetIds) {

            // ===================================================
            // 1. CREATE WIDGET REMOTE VIEWS
            // ===================================================

            val views = RemoteViews(
                context.packageName,
                R.layout.followup_widget
            )

            // ===================================================
            // 2. GET SAVED DATA FROM FLUTTER
            // ===================================================

            val count = widgetData.getInt(
                "followup_count",
                0
            )

            val dateRange = widgetData.getString(
                "followup_date_range",
                ""
            ).orEmpty()

            val selectedType = widgetData.getString(
                "followup_selected_type",
                "Dealer"
            ).orEmpty()

            val selectedDate = widgetData.getString(
                "followup_selected_date",
                ""
            ).orEmpty()

            // ===================================================
            // 3. SET WIDGET HEADER DATA
            // ===================================================

            views.setTextViewText(
                R.id.tvCount,
                count.toString()
            )

            views.setTextViewText(
                R.id.tvDateRange,
                if (selectedDate.isNotEmpty()) {
                    selectedDate
                } else {
                    dateRange
                }
            )

            views.setTextViewText(
                R.id.tvSelectedType,
                "$selectedType Followups"
            )

            // ===================================================
            // 4. DISPLAY EMPTY STATE
            // ===================================================

            if (count == 0) {
                views.setViewVisibility(
                    R.id.tvEmpty,
                    View.VISIBLE
                )
            } else {
                views.setViewVisibility(
                    R.id.tvEmpty,
                    View.GONE
                )
            }

            // ===================================================
            // 5. CONNECT SCROLLABLE FOLLOWUP LIST
            // ===================================================

            val serviceIntent = Intent(
                context,
                FollowupWidgetService::class.java
            )

            serviceIntent.putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                widgetId
            )

            // Unique URI for each widget instance.
            serviceIntent.data = Uri.parse(
                "solufine://followups/$widgetId"
            )

            views.setRemoteAdapter(
                R.id.lvFollowups,
                serviceIntent
            )

            views.setEmptyView(
                R.id.lvFollowups,
                R.id.tvEmpty
            )

            // ===================================================
            // 6. OPEN DATE PICKER WHEN CALENDAR IS CLICKED
            // ===================================================

            val dateIntent = Intent(
                context,
                FollowupDatePickerActivity::class.java
            )

            dateIntent.action =
                "com.lbm.solufine.SELECT_FOLLOWUP_DATE"

            dateIntent.putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                widgetId
            )

            val datePendingIntent = PendingIntent.getActivity(
                context,
                widgetId + 2000,
                dateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(
                R.id.btnWidgetDate,
                datePendingIntent
            )

            // ===================================================
            // 7. OPEN FLUTTER APP WHEN HEADER IS CLICKED
            // ===================================================

            val openIntent = Intent(
                context,
                MainActivity::class.java
            )

            openIntent.action = Intent.ACTION_VIEW

            openIntent.putExtra(
                "open_followup",
                true
            )

            openIntent.flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP

            val openPendingIntent = PendingIntent.getActivity(
                context,
                widgetId + 3000,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(
                R.id.widgetHeader,
                openPendingIntent
            )

            // ===================================================
            // 8. UPDATE WIDGET
            // ===================================================

            appWidgetManager.updateAppWidget(
                widgetId,
                views
            )

            // ===================================================
            // 9. REFRESH FOLLOWUP LIST
            // ===================================================

            @Suppress("DEPRECATION")
            appWidgetManager.notifyAppWidgetViewDataChanged(
                widgetId,
                R.id.lvFollowups
            )
        }
    }
}
