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
            // สร้างช่องทางสำหรับ background service
            val backgroundChannel = NotificationChannel(
                "appsos_foreground", // ต้องตรงกับ notificationChannelId ใน background_service.dart
                "AppSOS Background Service",
                NotificationManager.IMPORTANCE_HIGH
            )
            backgroundChannel.description = "AppSOS service notifications"
            backgroundChannel.enableVibration(true)
            
            // สร้างช่องทางสำหรับการตรวจจับการล้ม
            val fallDetectionChannel = NotificationChannel(
                "fall_detection_channel", // ต้องตรงกับ channelId ใน notification_service.dart
                "Fall Detection Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            fallDetectionChannel.description = "Notifications for fall detection"
            fallDetectionChannel.enableVibration(true)
            fallDetectionChannel.setShowBadge(true)
            
            // สร้างช่องทางสำหรับ SOS
            val sosChannel = NotificationChannel(
                "sos_channel", // ต้องตรงกับ channelId ใน notification_service.dart
                "SOS Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            sosChannel.description = "Notifications for SOS"
            sosChannel.enableVibration(true)
            sosChannel.setShowBadge(true)
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(backgroundChannel)
            notificationManager.createNotificationChannel(fallDetectionChannel)
            notificationManager.createNotificationChannel(sosChannel)
        }
    }
}
