package com.dvtechventures.shubhmilan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channel = NotificationChannel(
                channelId,
                "High importance notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Messages, matches, and alerts"
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
