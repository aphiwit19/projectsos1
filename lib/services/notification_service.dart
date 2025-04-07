import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../main.dart' as main;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoSosTimer;
  int _remainingSeconds = 30; // เวลาถอยหลัง 30 วินาที
  
  // เพิ่มตัวแปรสำหรับป้องกันการแจ้งเตือนซ้ำ
  DateTime? _lastFallNotificationTime;
  static const int NOTIFICATION_COOLDOWN_PERIOD = 15000; // 15 วินาที cooldown

  // ตรวจสอบว่ามีการตั้งค่า initialize แล้วหรือไม่
  bool _isInitialized = false;
  
  // ตัวแปรสถานะการยืนยันและยกเลิก
  bool _sosConfirmed = false;
  bool _sosCancelled = false;

  // เพิ่มตัวแปรเพื่อตรวจสอบว่าการแจ้งเตือนถูกเรียกจากที่ไหน
  bool _notificationHandledByMainApp = false;
  
  // ระบุว่าการแจ้งเตือนจะถูกจัดการโดยแอปหลัก (เรียกจาก main.dart)
  void markNotificationHandledByMainApp() {
    _notificationHandledByMainApp = true;
    print("NotificationService: Notifications will be handled by main app");
  }

  // ระบุว่าการแจ้งเตือนจะถูกจัดการโดย NotificationService (default)
  void markNotificationHandledByService() {
    _notificationHandledByMainApp = false;
    print("NotificationService: Notifications will be handled by service");
  }

  // สร้าง Singleton instance
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // เริ่มต้นระบบการแจ้งเตือน
  Future<void> initialize() async {
    // ป้องกันการ initialize ซ้ำ
    if (_isInitialized) {
      print("NotificationService already initialized");
      return;
    }
    
    print("Initializing NotificationService...");
    
    try {
      // ตั้งค่า Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('notification_icon');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // ลงทะเบียน callback การรับ notification actions
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // ตรวจสอบว่า notification จะถูกจัดการโดยแอปหลักหรือไม่
          if (_notificationHandledByMainApp) {
            print("NotificationService: Forwarding notification response to main app");
            return; // ไม่ทำอะไรเพิ่มเติม เพราะการจัดการจะถูกทำที่ main.dart
          }
          
          print("Received notification response: ${details.actionId}");
          _handleNotificationAction(details);
        },
      );
      
      print("NotificationService initialized successfully");

      // ตรวจสอบการลงทะเบียน notification actions
      await _checkNotificationSetup();

      // เตรียม audio player
      try {
        await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
        await _audioPlayer.setLoopMode(LoopMode.one); // เล่นวนซ้ำ
        print("Audio player set up successfully");
      } catch (e) {
        print('Error setting up audio player: $e');
      }
      
      _isInitialized = true;
    } catch (e) {
      print("Error initializing NotificationService: $e");
    }
  }

  // ตรวจสอบการตั้งค่า notification
  Future<void> _checkNotificationSetup() async {
    try {
      List<ActiveNotification>? activeNotifications = 
          await flutterLocalNotificationsPlugin.getActiveNotifications();
      
      print("Active notifications count: ${activeNotifications?.length ?? 0}");
      
      var androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        print("Android plugin resolved successfully");
      } else {
        print("Failed to resolve Android plugin");
      }
    } catch (e) {
      print("Error checking notification setup: $e");
    }
  }

  // เพิ่มฟังก์ชันตรวจสอบเครดิต
  Future<bool> _checkCreditAvailable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print("ไม่พบข้อมูลผู้ใช้ ไม่สามารถตรวจสอบเครดิตได้");
        return false;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();
      
      if (!userDoc.exists) {
        print("ไม่พบข้อมูลผู้ใช้ในฐานข้อมูล");
        return false;
      }
      
      final credit = userDoc.data()?['credit'] ?? 0;
      print("เครดิตคงเหลือ: $credit");
      
      return credit > 0;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการตรวจสอบเครดิต: $e");
      return false;
    }
  }

  // แสดงการแจ้งเตือนเมื่อตรวจพบการล้ม - ปรับปรุงเพื่อตรวจสอบเครดิต
  Future<void> showFallDetectionAlert({
    required int notificationId,
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    // ตรวจสอบสถานะการยืนยันและยกเลิก
    if (_sosConfirmed || _sosCancelled) {
      print("NotificationService: SOS already confirmed or cancelled, ignoring alert");
      return;
    }
    
    // ตรวจสอบ cooldown period เพื่อป้องกันการแจ้งเตือนซ้ำ
    if (_lastFallNotificationTime != null) {
      int timeSinceLastNotification = DateTime.now().difference(_lastFallNotificationTime!).inMilliseconds;
      if (timeSinceLastNotification < NOTIFICATION_COOLDOWN_PERIOD) {
        print("Notification in cooldown period: ${(NOTIFICATION_COOLDOWN_PERIOD - timeSinceLastNotification) / 1000} seconds left");
        return; // ไม่แสดงการแจ้งเตือนซ้ำในช่วง cooldown
      }
    }
    
    /* คอมเมนต์ออกเพื่อทดสอบการแจ้งเตือน
    // ตรวจสอบเครดิตคงเหลือ
    bool hasCreditAvailable = await _checkCreditAvailable();
    if (!hasCreditAvailable) {
      // แสดงการแจ้งเตือนว่าไม่มีเครดิตเหลือ
      await showNoCreditNotification();
      return;
    }
    */
    
    // บันทึกเวลาแจ้งเตือนล่าสุด
    _lastFallNotificationTime = DateTime.now();
    
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

  // ฟังก์ชันแสดงการแจ้งเตือนเมื่อไม่มีเครดิตเหลือ
  Future<void> showNoCreditNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'credit_warning_channel',
      'Credit Warning Notifications',
      channelDescription: 'Notifications for credit warnings',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      555,
      'ไม่สามารถส่ง SOS ได้',
      'เครดิตของคุณหมด กรุณาเติมเครดิตเพื่อใช้บริการส่ง SOS',
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
    print("NotificationService: _handleNotificationAction ได้รับการตอบสนอง: ${details.actionId}");
    
    // ถ้าการแจ้งเตือนถูกจัดการโดยแอปหลัก ควรข้ามไป
    if (_notificationHandledByMainApp) {
      print("NotificationService: การแจ้งเตือนถูกจัดการโดยแอปหลัก ไม่ทำงานใน _handleNotificationAction");
      return;
    }
    
    if (details.actionId == 'CONFIRM_SOS') {
      // ป้องกันการทำงานซ้ำซ้อน
      if (_sosConfirmed) {
        print("NotificationService: SOS already confirmed, ignoring action");
        return;
      }
      
      // ตั้งค่าสถานะยืนยัน
      _sosConfirmed = true;
      _sosCancelled = false;
      
      // ตั้งค่าตัวแปรป้องกันการเปิดหน้า SOS confirmation
      main.sosConfirmed = true;
      main.preventSosConfirmationScreen();
      
      print("NotificationService: CONFIRM_SOS action received - stopping countdown and triggering SOS");
      _stopAutoSosCountdown();
      _stopAlarmSound();
      _triggerSos();
      
      // รีเซ็ตสถานะหลัง 30 วินาที
      Timer(Duration(seconds: 30), () {
        _sosConfirmed = false;
      });
    } else if (details.actionId == 'CANCEL') {
      // ป้องกันการทำงานซ้ำซ้อน
      if (_sosCancelled) {
        print("NotificationService: SOS already cancelled, ignoring action");
        return;
      }
      
      // ตั้งค่าสถานะยกเลิก
      _sosCancelled = true;
      _sosConfirmed = false;
      
      // ตั้งค่าตัวแปรป้องกันการเปิดหน้า SOS confirmation เมื่อกดยกเลิกด้วย
      main.preventSosConfirmationScreen();
      
      print("NotificationService: CANCEL action received - stopping countdown and canceling SOS");
      _stopAutoSosCountdown();
      _stopAlarmSound();
      _cancelSos();
      
      // รีเซ็ตสถานะหลัง 30 วินาที
      Timer(Duration(seconds: 30), () {
        _sosCancelled = false;
      });
    }
  }

  // เริ่มนับถอยหลังอัตโนมัติ
  void _startAutoSosCountdown() {
    _remainingSeconds = 30;
    print("Starting auto SOS countdown: $_remainingSeconds seconds");
    
    // ยกเลิกตัวจับเวลาเดิมถ้ามี
    if (_autoSosTimer != null) {
      print("Cancelling existing timer");
      _autoSosTimer!.cancel();
      _autoSosTimer = null;
    }
    
    // สร้างตัวจับเวลาใหม่
    _autoSosTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      
      // อัปเดตการแจ้งเตือนทุก 5 วินาที
      if (_remainingSeconds % 5 == 0 || _remainingSeconds <= 5) {
        print("Updating countdown notification: $_remainingSeconds seconds remaining");
        updateCountdownNotification(
          notificationId: 888,
          remainingSeconds: _remainingSeconds,
        );
      }
      
      // เมื่อนับถอยหลังถึงศูนย์
      if (_remainingSeconds <= 0) {
        print("Countdown reached zero - triggering SOS");
        _stopAutoSosCountdown();
        _stopAlarmSound();
        _triggerSos();
      }
    });
    
    print("Auto SOS countdown timer started");
  }

  // หยุดการนับถอยหลังอัตโนมัติ
  void _stopAutoSosCountdown() {
    print("Stopping auto SOS countdown");
    if (_autoSosTimer != null) {
      _autoSosTimer!.cancel();
      _autoSosTimer = null;
      print("Auto SOS countdown timer cancelled");
    } else {
      print("No active timer to cancel");
    }
  }

  // หยุดเสียงเตือน
  void _stopAlarmSound() {
    try {
      print("Stopping alarm sound");
      _audioPlayer.stop();
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  // ส่ง SOS - ปรับปรุงเพื่อตรวจสอบเครดิตอีกครั้ง
  void _triggerSos() async {
    print("NotificationService: _triggerSos() เริ่มทำงาน...");
    
    // ป้องกันการเปิดหน้า SOS confirmation ถ้ายังไม่ได้ตั้งค่าจาก _handleNotificationAction
    if (!main.preventOpeningSosConfirmationScreen) {
      main.preventSosConfirmationScreen();
    }
    
    /* คอมเมนต์ออกเพื่อทดสอบการแจ้งเตือน
    // ตรวจสอบเครดิตอีกครั้งก่อนส่ง SOS
    bool hasCreditAvailable = await _checkCreditAvailable();
    if (!hasCreditAvailable) {
      // แสดงการแจ้งเตือนว่าไม่มีเครดิตเหลือ
      await showNoCreditNotification();
      return;
    }
    */
    
    // ยกเลิก notification ทั้งหมด
    print("NotificationService: กำลังยกเลิกการแจ้งเตือนทั้งหมดก่อนส่ง SOS");
    flutterLocalNotificationsPlugin.cancelAll();
    
    // ตรวจสอบว่าการแจ้งเตือนถูกจัดการโดยแอปหลักหรือไม่
    if (_notificationHandledByMainApp) {
      print("NotificationService: การแจ้งเตือนถูกจัดการโดยแอปหลัก ไม่ส่ง SOS จาก service");
      return;
    }
    
    // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
    print("NotificationService: กำลังแสดงการแจ้งเตือนว่ากำลังส่ง SOS");
    await showSendingSosNotification();
    
    // ส่งคำสั่งไปยัง background service ให้ส่ง SOS
    try {
      print("NotificationService: กำลังส่งคำสั่งไปยัง background service");
      final service = FlutterBackgroundService();
      service.invoke("confirm_sos", {
        "timestamp": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการเรียกใช้ background service: $e");
      showSosFailedNotification("ไม่สามารถเชื่อมต่อกับบริการพื้นหลังได้");
    }
  }

  // ยกเลิก SOS
  void _cancelSos() {
    print("NotificationService: _cancelSos() เริ่มทำงาน...");
    
    // ยกเลิก notification ทั้งหมด
    print("Cancelling all notifications for SOS cancellation");
    flutterLocalNotificationsPlugin.cancelAll();
    
    // ส่งคำสั่งไปยัง background service ให้ยกเลิก SOS
    try {
      print("NotificationService: กำลังส่งคำสั่ง cancel_sos ไปยัง background service");
      final service = FlutterBackgroundService();
      service.invoke("cancel_sos", {
        "timestamp": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการเรียกใช้ background service สำหรับยกเลิก SOS: $e");
    }
    
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

    print("Showing SOS cancellation notification");
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
  
  // ฟังก์ชันสำหรับยกเลิกการแจ้งเตือนและตัวจับเวลาทั้งหมด (เรียกจาก Background Service)
  void cancelNotificationsAndTimers() {
    print("NotificationService: Cancelling all notifications and timers");
    
    // ตั้งค่าสถานะยกเลิก
    _sosCancelled = true;
    _sosConfirmed = false;
    
    _stopAutoSosCountdown();
    _stopAlarmSound();
    flutterLocalNotificationsPlugin.cancelAll();
    
    // รีเซ็ตสถานะหลัง 30 วินาที
    Timer(Duration(seconds: 30), () {
      _sosCancelled = false;
    });
  }
  
  // ฟังก์ชันแสดงการแจ้งเตือนยกเลิก (เรียกจาก Background Service)
  void showCancellationNotification() {
    print("NotificationService: Showing cancellation notification");
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

  // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
  Future<void> showSendingSosNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_status_channel',
      'SOS Status Notifications',
      channelDescription: 'Notifications for SOS status updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      888, // ใช้ ID ที่ไม่ซ้ำกับการแจ้งเตือนอื่น
      'กำลังส่ง SOS',
      'กำลังส่งข้อความแจ้งเตือนไปยังผู้ติดต่อฉุกเฉินของคุณ',
      notificationDetails,
    );
  }
  
  // แสดงการแจ้งเตือนเมื่อส่ง SOS สำเร็จ
  Future<void> showSosSuccessNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_status_channel',
      'SOS Status Notifications',
      channelDescription: 'Notifications for SOS status updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999, // ใช้ ID ที่ไม่ซ้ำกับการแจ้งเตือนอื่น
      'ส่ง SOS สำเร็จ ✓',
      'ส่งข้อความแจ้งเตือนไปยังผู้ติดต่อฉุกเฉินของคุณเรียบร้อยแล้ว',
      notificationDetails,
    );
  }
  
  // แสดงการแจ้งเตือนเมื่อส่ง SOS ไม่สำเร็จ
  Future<void> showSosFailedNotification(String errorMessage) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_status_channel',
      'SOS Status Notifications',
      channelDescription: 'Notifications for SOS status updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      777, // ใช้ ID ที่ไม่ซ้ำกับการแจ้งเตือนอื่น
      'ส่ง SOS ไม่สำเร็จ',
      'ไม่สามารถส่งข้อความแจ้งเตือนได้: $errorMessage',
      notificationDetails,
    );
  }
} 