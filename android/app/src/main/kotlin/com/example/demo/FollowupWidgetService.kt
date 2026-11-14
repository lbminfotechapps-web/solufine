package com.lbm.solufine

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class FollowupWidgetService : RemoteViewsService() {

    override fun onGetViewFactory(
        intent: Intent
    ): RemoteViewsFactory {

        return FollowupViewsFactory(applicationContext)
    }
}

// =======================================================
// FOLLOWUP LIST FACTORY
// =======================================================

class FollowupViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private var followups = JSONArray()

    // ===================================================
    // CREATE
    // ===================================================

    override fun onCreate() {
        loadFollowups()
    }

    // ===================================================
    // REFRESH DATA
    // ===================================================

    override fun onDataSetChanged() {
        loadFollowups()
    }

    // ===================================================
    // READ FLUTTER SAVED JSON
    // ===================================================

    private fun loadFollowups() {
        try {
            val prefs = HomeWidgetPlugin.getData(context)

            val json = prefs.getString(
                "followup_list_json",
                "[]"
            ) ?: "[]"

            followups = JSONArray(json)

            Log.d(
                "FollowupWidget",
                "Total followups: ${followups.length()}"
            )

        } catch (e: Exception) {

            followups = JSONArray()

            Log.e(
                "FollowupWidget",
                "Failed to load followups",
                e
            )
        }
    }

    // ===================================================
    // TOTAL LIST COUNT
    // ===================================================

    override fun getCount(): Int {
        return followups.length()
    }

    // ===================================================
    // CREATE FOLLOWUP ROW
    // ===================================================

    override fun getViewAt(position: Int): RemoteViews? {

        if (position < 0 || position >= followups.length()) {
            return null
        }

        return try {

            val item: JSONObject =
                followups.getJSONObject(position)

            val name = item.optString(
                "name",
                "Unknown"
            )

            val type = item.optString(
                "type",
                ""
            )

            val date = item.optString(
                "date",
                ""
            )

            val mobile = item.optString(
                "mobile",
                ""
            )

            val nextDate = item.optString(
                "nextDate",
                ""
            )

            val views = RemoteViews(
                context.packageName,
                R.layout.followup_widget_item
            )

            views.setTextViewText(
                R.id.tvItemName,
                name
            )

            views.setTextViewText(
                R.id.tvItemType,
                type
            )

            views.setTextViewText(
                R.id.tvItemDate,
                "Date: $date"
            )

            views.setTextViewText(
                R.id.tvItemMobile,
                "Mobile: $mobile"
            )

            val nextFollowupText =
                if (nextDate.isNotEmpty() && nextDate != date) {
                    "Next Followup: $nextDate"
                } else {
                    ""
                }

            views.setTextViewText(
                R.id.tvItemNextDate,
                nextFollowupText
            )

            views

        } catch (e: Exception) {

            Log.e(
                "FollowupWidget",
                "Error rendering item at position $position",
                e
            )

            null
        }
    }

    // ===================================================
    // LOADING VIEW
    // ===================================================

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    // ===================================================
    // VIEW TYPES
    // ===================================================

    override fun getViewTypeCount(): Int {
        return 1
    }

    // ===================================================
    // ITEM ID
    // ===================================================

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return false
    }

    // ===================================================
    // DESTROY
    // ===================================================

    override fun onDestroy() {
        followups = JSONArray()
    }
}
