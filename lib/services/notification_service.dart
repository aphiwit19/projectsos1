import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoSosTimer;
  int _remainingSeconds = 30; // เวลาถอยหลัง 30 วินาที

  // สร้าง Singleton instance
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // เริ่มต้นระบบการแจ้งเตือน
  Future<void> initialize() async {
    // ตั้งค่า Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationAction(details);
      },
    );

    // เตรียม audio player
    try {
      await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one); // เล่นวนซ้ำ
    } catch (e) {
      print('Error setting up audio player: $e');
    }
  }

  // แสดงการแจ้งเตือนเมื่อตรวจพบการล้ม
  Future<void> showFallDetectionAlert({
    required int notificationId,
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    // เริ่มนับถอยหลังอัตโนมัติ
    _startAutoSosCountdown();

    // เล่นเสียงเตือน
    if (playSound) {
      try {
        _audioPlayer.setVolume(1.0);
        _audioPlayer.play();
      } catch (e) {
        print('Error playing alert sound: $e');
      }
    }

    // แสดงการแจ้งเตือนแบบมีปุ่มกด
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fall_detection_channel',
      'Fall Detection Notifications',
      channelDescription: 'Notifications for fall detection',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'CONFIRM_SOS',
          'ยืนยันและส่ง SOS',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'CANCEL',
          'ยกเลิก',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  // อัปเดตการแจ้งเตือนเพื่อแสดงเวลาถอยหลัง
  Future<void> updateCountdownNotification({
    required int notificationId,
    required int remainingSeconds,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fall_detection_channel',
      'Fall Detection Notifications',
      channelDescription: 'Notifications for fall detection',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'CONFIRM_SOS',
          'ยืนยันและส่ง SOS',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'CANCEL',
          'ยกเลิก',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      '⚠️ ตรวจพบการล้ม!',
      'จะส่ง SOS อัตโนมัติใน $remainingSeconds วินาที\nกดยืนยันเพื่อส่ง SOS หรือยกเลิกหากไม่ต้องการความช่วยเหลือ',
      notificationDetails,
    );
  }

  // จัดการกับการกดปุ่มใน notification
  void _handleNotificationAction(NotificationResponse details) {
    if (details.actionId == 'CONFIRM_SOS') {
      _stopAutoSosCountdown();
      _stopAlarmSound();
      _triggerSos();
    } else if (details.actionId == 'CANCEL') {
      _stopAutoSosCountdown();
      _stopAlarmSound();
      _cancelSos();
    }
  }

  // เริ่มนับถอยหลังอัตโนมัติ
  void _startAutoSosCountdown() {
    _remainingSeconds = 30;
    
    // ยกเลิกตัวจับเวลาเดิมถ้ามี
    _autoSosTimer?.cancel();
    
    // สร้างตัวจับเวลาใหม่
    _autoSosTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      
      // อัปเดตการแจ้งเตือนทุก 5 วินาที
      if (_remainingSeconds % 5 == 0 || _remainingSeconds <= 5) {
        updateCountdownNotification(
          notificationId: 888,
          remainingSeconds: _remainingSeconds,
        );
      }
      
      // เมื่อนับถอยหลังถึงศูนย์
      if (_remainingSeconds <= 0) {
        _stopAutoSosCountdown();
        _stopAlarmSound();
        _triggerSos();
      }
    });
  }

  // หยุดการนับถอยหลังอัตโนมัติ
  void _stopAutoSosCountdown() {
    _autoSosTimer?.cancel();
    _autoSosTimer = null;
  }

  // หยุดเสียงเตือน
  void _stopAlarmSound() {
    try {
      _audioPlayer.stop();
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  // ส่ง SOS
  void _triggerSos() {
    // ยกเลิก notification ทั้งหมด
    flutterLocalNotificationsPlugin.cancelAll();
    
    // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS Notifications',
      channelDescription: 'Notifications for SOS',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    flutterLocalNotificationsPlugin.show(
      999,
      'กำลังส่ง SOS',
      'กำลังเปิดแอพพลิเคชันเพื่อส่ง SOS',
      notificationDetails,
    );
  }

  // ยกเลิก SOS
  void _cancelSos() {
    // ยกเลิก notification ทั้งหมด
    flutterLocalNotificationsPlugin.cancelAll();
    
    // แสดง notification ยกเลิก
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS Notifications',
      channelDescription: 'Notifications for SOS',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    flutterLocalNotificationsPlugin.show(
      777,
      'ยกเลิก SOS แล้ว',
      'คุณได้ยกเลิกการส่ง SOS แล้ว',
      notificationDetails,
    );
  }

  // ขอสิทธิ์การแจ้งเตือน
  Future<bool> requestNotificationPermissions() async {
    // ไม่จำเป็นต้องใช้เมธอดนี้ เพราะเราขอสิทธิ์ผ่าน AndroidManifest.xml แล้ว
    return true;
  }
} 