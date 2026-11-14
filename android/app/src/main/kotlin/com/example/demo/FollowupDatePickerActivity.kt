package com.lbm.solufine

import android.app.Activity
import android.app.DatePickerDialog
import android.os.Bundle
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import android.net.Uri

class FollowupDatePickerActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = HomeWidgetPlugin.getData(this)

        val formatter = SimpleDateFormat(
            "dd-MM-yyyy",
            Locale.ENGLISH
        ).apply {
            isLenient = false
        }

        val calendar = Calendar.getInstance()

        val savedDate = prefs.getString(
            "followup_selected_date",
            ""
        ).orEmpty()

        if (savedDate.isNotEmpty()) {
            try {
                calendar.time = formatter.parse(savedDate)!!
            } catch (e: Exception) {
                Log.e("FollowupWidget", "Invalid saved date", e)
            }
        }

        val dialog = DatePickerDialog(
            this,
            { _, year, month, day ->

                val selectedCalendar = Calendar.getInstance()

                selectedCalendar.set(
                    year,
                    month,
                    day
                )

                val selectedDate = formatter.format(
                    selectedCalendar.time
                )

                Log.d(
                    "FollowupWidget",
                    "Selected date: $selectedDate"
                )

                // Save date to HomeWidget shared preferences.
                prefs.edit()
                    .putString(
                        "followup_selected_date",
                        selectedDate
                    )
                    .apply()

                // Trigger Flutter background callback.
                val uri = Uri.Builder()
                    .scheme("solufine")
                    .authority("followup")
                    .appendPath("refresh")
                    .appendQueryParameter(
                        "date",
                        selectedDate
                    )
                    .build()

                try {
                    val backgroundIntent =
                        HomeWidgetBackgroundIntent.getBroadcast(
                            this,
                            uri
                        )

                    backgroundIntent.send()

                    Log.d(
                        "FollowupWidget",
                        "Background refresh requested"
                    )
                } catch (e: Exception) {
                    Log.e(
                        "FollowupWidget",
                        "Failed to trigger background refresh",
                        e
                    )
                }

                // Close only the picker.
                // Do not launch MainActivity.
                finish()
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        )

        dialog.setOnCancelListener {
            finish()
        }

        dialog.show()
    }
}
