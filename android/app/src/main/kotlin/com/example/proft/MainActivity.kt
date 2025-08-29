package com.zamo.proft

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zamo.proft/screentime"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenTime" -> {
                    val screenTime = getScreenTime()
                    result.success(screenTime)
                }
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success("Opened Settings")
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * استرجاع إجمالي وقت استخدام الهاتف منذ الساعة 12:00 AM حتى الآن
     */
    private fun getScreenTime(): Int {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis

            val stats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)

            var totalTime = 0L
            for (entry in stats) {
                totalTime += entry.value.totalTimeInForeground
            }

            return (totalTime / 1000 / 60).toInt()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error fetching screen time: ${e.message}")
            return 0
        }
    }

    /**
     * فتح إعدادات `Usage Access Permission` للمستخدم لمنح الأذونات المطلوبة
     */
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }
}
