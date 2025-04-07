import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../main.dart' as main;
import 'package:geolocator/geolocator.dart';
import '../services/sos_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoSosTimer;
  int _remainingSeconds = 30; // เวลาถอยหลัง 30 วินาที (ค่าเริ่มต้น)
  
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
      
      // สร้าง background channel ที่มีความสำคัญต่ำสุด
      const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
        'appsos_foreground',  // ต้องตรงกับ notificationChannelId ใน background_service.dart
        'Background Services',
        description: 'Channel for background tracking services',
        importance: Importance.min,  // ตั้งค่าความสำคัญต่ำสุด
        showBadge: false,  // ไม่แสดง badge
        enableVibration: false,  // ไม่สั่น
        enableLights: false,  // ไม่มีไฟกระพริบ
      );
      
      // สร้างช่องแจ้งเตือน
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(backgroundChannel);

      // ลงทะเบียน callback การรับ notification actions
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // ตรวจสอบว่า notification จะถูกจัดการโดยแอปหลักหรือไม่
          if (_notificationHandledByMainApp) {
            print("NotificationService: Forwarding notification response to main app");
            // ส่งต่อการจัดการไปที่ handleActionFromNotification ใน main.dart
            try {
              if (details.actionId != null) {
                main.handleActionFromNotification(details.actionId!);
              } else {
                print("NotificationService: ActionId is null, cannot forward to main app");
              }
            } catch (e) {
              print("NotificationService: Error forwarding to main.dart: $e");
              // ถ้าเกิดข้อผิดพลาด ให้จัดการด้วย NotificationService
              _handleNotificationAction(details);
            }
            return;
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

  // จัดการการตอบสนองจากการแจ้งเตือน
  void _handleNotificationAction(NotificationResponse details) async {
    try {
      print("NotificationService: ทำการตอบสนองการแจ้งเตือน ${details.actionId}");
      
      // ตรวจสอบว่าได้รับการตอบสนองการแจ้งเตือนหรือไม่
      if (details.actionId != null) {
        String actionId = details.actionId!;
        
        if (actionId == 'CONFIRM_SOS') {
          // ตรวจสอบว่ามีการยืนยันแล้วหรือไม่ เพื่อป้องกันการทำซ้ำ
          if (_sosConfirmed) {
            print("NotificationService: SOS ถูกยืนยันแล้ว ไม่ทำอะไรเพิ่มเติม");
            return;
          }
          
          print("NotificationService: ได้รับการยืนยัน SOS");
          _sosConfirmed = true;
          _sosCancelled = false;
          
          // เรียกใช้ preventSosConfirmationScreen เพื่อป้องกันการเปิดหน้า SOS confirmation
          main.preventSosConfirmationScreen();
          
          // ยกเลิกการนับถอยหลังและหยุดเสียงเตือน
          _stopAutoSosCountdown();
          
          // ตรวจสอบว่าการแจ้งเตือนถูกจัดการโดยแอปหลักหรือไม่
          if (_notificationHandledByMainApp) {
            print("NotificationService: SOS confirmation จะถูกจัดการโดยแอปหลัก");
            return;
          }
          
          print("NotificationService: กำลังดำเนินการส่ง SOS โดยตรง");
          // ดำเนินการส่ง SOS โดยตรงจากการแจ้งเตือน
          _triggerSos();
        } else if (actionId == 'CANCEL') {
          // ตรวจสอบว่ามีการยกเลิกแล้วหรือไม่ เพื่อป้องกันการทำซ้ำ
          if (_sosCancelled) {
            print("NotificationService: SOS ถูกยกเลิกแล้ว ไม่ทำอะไรเพิ่มเติม");
            return;
          }
          
          print("NotificationService: ได้รับการยกเลิก SOS");
          _sosCancelled = true;
          _sosConfirmed = false;
          
          // เรียกใช้ preventSosConfirmationScreen เพื่อป้องกันการเปิดหน้า SOS confirmation
          main.preventSosConfirmationScreen();
          
          // ยกเลิกการนับถอยหลังและหยุดเสียงเตือน
          _stopAutoSosCountdown();
          _stopAlarmSound();
          
          // แสดงการแจ้งเตือนว่ายกเลิก SOS สำเร็จ
          print("NotificationService: กำลังแสดงการแจ้งเตือนว่ายกเลิก SOS");
          try {
            await showCancellationNotification();
            print("NotificationService: แสดงการแจ้งเตือนว่ายกเลิก SOS สำเร็จ");
          } catch (e) {
            print("NotificationService: เกิดข้อผิดพลาดในการแสดงการแจ้งเตือน: $e");
          }
        }
      }
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการจัดการการตอบสนองการแจ้งเตือน: $e");
    }
  }

  // เริ่มนับถอยหลังอัตโนมัติ
  void _startAutoSosCountdown() async {
    // ดึงค่าจาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _remainingSeconds = prefs.getInt('auto_fall_countdown_time') ?? 30;
    
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

  // ส่ง SOS จากการแจ้งเตือน
  Future<void> _triggerSos() async {
    try {
      // ตั้งค่าให้ไม่เปิดหน้าจอยืนยัน SOS
      main.preventSosConfirmationScreen();
      main.sosConfirmed = true;
      
      print("NotificationService: เริ่มกระบวนการส่ง SOS จากการแจ้งเตือน");
      
      // ตรวจสอบเครดิตก่อนดำเนินการต่อ
      /*bool hasCreditAvailable = await _checkCreditAvailable();
      if (!hasCreditAvailable) {
        print("NotificationService: ไม่สามารถส่ง SOS ได้เนื่องจากไม่มีเครดิตเหลือ");
        // แสดงการแจ้งเตือนว่าไม่มีเครดิตเหลือ
        await showNoCreditNotification();
        return;
      }*/
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        print("NotificationService: พบข้อมูลผู้ใช้ ${user.email}");
        
        // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
        await showSendingSosNotification();
        
        // ใช้ SosService เพื่อส่ง SOS และบันทึกข้อมูลในรูปแบบเดียวกัน
        final sosService = SosService();
        final result = await sosService.sendSos(
          user.uid,
          detectionSource: 'notification',
        );
        
        if (result['success']) {
          print("NotificationService: ส่ง SOS สำเร็จ: ${result['message']}");
          // แสดงการแจ้งเตือนว่าส่งสำเร็จ
          await showSosSuccessNotification();
        } else {
          print("NotificationService: ส่ง SOS ไม่สำเร็จ: ${result['message']}");
          await showSosFailedNotification(result['message'] ?? "การส่ง SOS ล้มเหลว");
        }
      } else {
        print("NotificationService: ไม่พบข้อมูลผู้ใช้ ไม่สามารถส่ง SOS ได้");
        await showSosFailedNotification("ไม่พบข้อมูลผู้ใช้");
      }
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการส่ง SOS: $e");
      await showSosFailedNotification("เกิดข้อผิดพลาด: $e");
    }
  }

  // ยกเลิก SOS
  Future<void> _cancelSos() async {
    print("NotificationService: _cancelSos() เริ่มทำงาน...");
    
    // ยกเลิก notification ทั้งหมด
    print("Cancelling all notifications for SOS cancellation");
    await flutterLocalNotificationsPlugin.cancelAll();
    
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
    print("NotificationService: กำลังแสดงการแจ้งเตือนว่ายกเลิก SOS");
    try {
      await showCancellationNotification();
      print("NotificationService: แสดงการแจ้งเตือนว่ายกเลิก SOS สำเร็จ");
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการแสดงการแจ้งเตือน: $e");
    }
  }

  // ขอสิทธิ์การแจ้งเตือน
  Future<bool> requestNotificationPermissions() async {
    // ไม่จำเป็นต้องใช้เมธอดนี้ เพราะเราขอสิทธิ์ผ่าน AndroidManifest.xml แล้ว
    return true;
  }
  
  // ฟังก์ชันสำหรับยกเลิกการแจ้งเตือนและตัวจับเวลาทั้งหมด (เรียกจาก Background Service)
  Future<void> cancelNotificationsAndTimers() async {
    print("NotificationService: Cancelling all notifications and timers");
    
    // ตั้งค่าสถานะยกเลิก
    _sosCancelled = true;
    _sosConfirmed = false;
    
    _stopAutoSosCountdown();
    _stopAlarmSound();
    await flutterLocalNotificationsPlugin.cancelAll();
    
    // แสดงการแจ้งเตือนว่ายกเลิกแล้ว
    print("NotificationService: กำลังแสดงการแจ้งเตือนว่ายกเลิก SOS");
    try {
      await showCancellationNotification();
      print("NotificationService: แสดงการแจ้งเตือนว่ายกเลิก SOS สำเร็จ");
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการแสดงการแจ้งเตือน: $e");
    }
    
    // รีเซ็ตสถานะหลัง 30 วินาที
    Timer(Duration(seconds: 30), () {
      _sosCancelled = false;
    });
  }
  
  // ฟังก์ชันแสดงการแจ้งเตือนยกเลิก (เรียกจาก Background Service)
  Future<void> showCancellationNotification() async {
    print("NotificationService: Showing cancellation notification");
    
    // ยกเลิกการแจ้งเตือนที่มีอยู่ก่อน
    await flutterLocalNotificationsPlugin.cancel(777);
    
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

    try {
      await flutterLocalNotificationsPlugin.show(
        777,
        'ยกเลิก SOS แล้ว',
        'คุณได้ยกเลิกการส่ง SOS แล้ว',
        notificationDetails,
      );
      print("NotificationService: แสดงการแจ้งเตือนยกเลิกสำเร็จ");
    } catch (e) {
      print("NotificationService: เกิดข้อผิดพลาดในการแสดงการแจ้งเตือนยกเลิก: $e");
    }
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

  // ฟังก์ชันดึงข้อมูลตำแหน่งปัจจุบัน
  Future<Map<String, dynamic>> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (e) {
      print("Error getting current location: $e");
      return {
        'error': 'location_unavailable',
        'error_details': e.toString(),
      };
    }
  }
} 