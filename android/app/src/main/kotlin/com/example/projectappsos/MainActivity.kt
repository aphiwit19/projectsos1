package com.example.projectappsos

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.os.Bundle
import android.app.NotificationManager
import android.app.NotificationChannel
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // สร้างช่องทางการแจ้งเตือนสำหรับ Android 8.0 (API level 26) ขึ้นไป
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "appsos_foreground", // ต้องตรงกับ notificationChannelId ใน background_service.dart
                "AppSOS Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "AppSOS service notifications"
            channel.enableVibration(true)
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
