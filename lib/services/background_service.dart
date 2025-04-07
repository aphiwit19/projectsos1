import 'dart:async';
import 'dart:math'; // เพิ่ม import สำหรับใช้ฟังก์ชัน sqrt และ pow
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart'; // เพิ่ม import สำหรับเซนเซอร์
import 'firebase_service.dart';
import 'notification_service.dart'; // เพิ่ม import สำหรับ notification service
import 'package:flutter/material.dart'; // นำเข้า Material package เพื่อใช้ enum ของ Android
import 'sos_service.dart'; // เพิ่ม import สำหรับ SosService
import 'package:shared_preferences/shared_preferences.dart';

// เพิ่มค่าคงที่สำหรับการตรวจจับการล้ม
const double ACCELERATION_THRESHOLD = 23.0; // เพิ่มขึ้นเล็กน้อยเพื่อลดความไว
const double GYROSCOPE_THRESHOLD = 11.0; // เพิ่มขึ้นเล็กน้อยเพื่อลดความไว
const double STABILITY_THRESHOLD = 2.0;
const int STABILITY_CHECK_DELAY = 500; // ms
const int COOLDOWN_PERIOD = 20000; // เพิ่มเป็น 20 วินาที
const int RECENT_DATA_SIZE = 20; // จำนวนข้อมูลเซนเซอร์ที่เก็บไว้

// ฟังก์ชันอัพเดทตำแหน่ง - ย้ายมาไว้ด้านนอกเพื่อให้ใช้ได้ในทุกส่วน
Future<void> updateLocation(Position position) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .update({
        'last_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
      print('=== LOCATION UPDATED: ${position.latitude}, ${position.longitude} ===');
    }
  } catch (e) {
    print('=== ERROR UPDATING LOCATION: $e ===');
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // ขอสิทธิ์แจ้งเตือนสำหรับ Android 13 ขึ้นไป
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  
  // เริ่มต้น NotificationService
  await NotificationService().initialize();
  await NotificationService().requestNotificationPermissions();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'appsos_foreground',
      initialNotificationTitle: 'AppSOS บริการช่วยเหลือฉุกเฉิน',
      initialNotificationContent: 'กำลังเริ่มต้นระบบติดตาม...',
      foregroundServiceNotificationId: 555, // เปลี่ยนจาก 888 เป็น 555 เพื่อไม่ให้ซ้ำกับ notification อื่น
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // ตรวจสอบการตั้งค่าระบบตรวจจับการล้ม
  try {
    final prefs = await SharedPreferences.getInstance();
    final fallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? true;
    print("iOS background: Fall detection ${fallDetectionEnabled ? 'enabled' : 'disabled'}");
  } catch (e) {
    print("iOS background: Error checking fall detection settings: $e");
  }
  
  final FlutterBackgroundService service = FlutterBackgroundService();
  return await service.isRunning();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // ตัวแปรที่ใช้ร่วมกันในทั้งฟังก์ชัน
    bool fallDetectionEnabled = true; // ค่าเริ่มต้นเป็น true เพื่อความปลอดภัย
    
    print('=== BACKGROUND SERVICE STARTED ===');
    print('Background service started at ${DateTime.now()}');
    
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      // ปรับปรุงข้อความในการแจ้งเตือนให้ชัดเจนว่าเป็นการแจ้งเตือนถาวร
      await service.setForegroundNotificationInfo(
        title: "AppSOS - ระบบติดตามกำลังทำงาน",
        content: "ระบบติดตามตำแหน่ง" + (fallDetectionEnabled ? " และตรวจจับการล้มทำงานอยู่" : " ทำงานอยู่ (ปิดระบบตรวจจับการล้ม)"),
      );
      print('=== FOREGROUND SERVICE SET ===');
    }

    try {
      await FirebaseService.initializeFirebase();
      FirebaseService.configureFirestore();
      print('=== FIREBASE INITIALIZED IN BACKGROUND ===');
    } catch (e) {
      print('Failed to initialize Firebase in background service: $e');
    }

    // ตัวแปรสำหรับระบบตรวจจับการล้ม
    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
    StreamSubscription<Position>? positionStream;
    
    // ตัวแปรสำหรับการตรวจจับการล้ม
    bool highAccelerationDetected = false;
    bool highRotationDetected = false;
    DateTime? accelerationTime;
    DateTime? rotationTime;
    bool processingFall = false;
    DateTime? lastFallDetection;
    List<double> recentAccelerations = [];
    
    // ฟังก์ชันอัพเดทการตั้งค่า
    Future<void> updateSettings() async {
      try {
        // ดึงการตั้งค่าจาก SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        fallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? true;
        
        // ตรวจสอบการตั้งค่าจาก Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.email)
                .get();
                
            if (userDoc.exists && userDoc.data()!.containsKey('settings')) {
              final settings = userDoc.data()!['settings'];
              if (settings != null && settings.containsKey('fall_detection_enabled')) {
                // อัพเดทการตั้งค่าใน SharedPreferences จาก Firestore
                final firebaseSettingEnabled = settings['fall_detection_enabled'] as bool;
                if (firebaseSettingEnabled != fallDetectionEnabled) {
                  print("Updating fall detection setting from Firestore: ${firebaseSettingEnabled ? 'enabled' : 'disabled'}");
                  await prefs.setBool('fall_detection_enabled', firebaseSettingEnabled);
                  fallDetectionEnabled = firebaseSettingEnabled;
                }
              }
            }
          } catch (e) {
            print("Error checking Firestore settings: $e");
          }
        }
        
        print("Fall detection setting updated: ${fallDetectionEnabled ? 'enabled' : 'disabled'}");
        
        // อัพเดทข้อความแจ้งเตือนเพื่อแสดงสถานะปัจจุบัน
        if (service is AndroidServiceInstance) {
          await service.setForegroundNotificationInfo(
            title: "AppSOS - ระบบติดตามกำลังทำงาน",
            content: "ระบบติดตามตำแหน่ง" + (fallDetectionEnabled ? " และตรวจจับการล้มทำงานอยู่" : " ทำงานอยู่ (ปิดระบบตรวจจับการล้ม)"),
          );
        }
      } catch (e) {
        print("Error updating fall detection settings: $e");
        // ถ้าเกิดข้อผิดพลาด ให้ตั้งค่าเป็น enabled เพื่อความปลอดภัย
        fallDetectionEnabled = true;
      }
    }
    
    // เรียกเพื่ออัพเดทการตั้งค่าเมื่อเริ่มต้น
    await updateSettings();
    
    // ตั้งเวลาให้ตรวจสอบการตั้งค่าทุก 60 วินาที
    Timer.periodic(Duration(seconds: 60), (_) async {
      await updateSettings();
    });
    
    // ฟังการเปลี่ยนแปลงการตั้งค่าใน Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .snapshots()
          .listen((snapshot) async {
        print("User document updated in Firestore");
        if (snapshot.exists && snapshot.data()!.containsKey('settings')) {
          print("Settings found in Firestore, updating local settings");
          await updateSettings();
        }
      }, onError: (error) {
        print("Error listening to Firestore changes: $error");
      });
    }
    
    // ฟังก์ชันสำหรับตรวจสอบระยะทางระหว่างตำแหน่ง - ยังคงต้องการสำหรับการคำนวณระยะทาง
    double calculateDistance(Position pos1, Position pos2) {
      return Geolocator.distanceBetween(
        pos1.latitude, pos1.longitude,
        pos2.latitude, pos2.longitude
      );
    }
    
    // ฟังก์ชันเพิ่มค่าความเร่งล่าสุด
    void addRecentAcceleration(double acceleration) {
      recentAccelerations.add(acceleration);
      if (recentAccelerations.length > RECENT_DATA_SIZE) {
        recentAccelerations.removeAt(0);
      }
    }
    
    // ฟังก์ชันรีเซ็ตสถานะการตรวจจับการล้ม
    void resetDetectionState() {
      highAccelerationDetected = false;
      highRotationDetected = false;
      accelerationTime = null;
      rotationTime = null;
      processingFall = false;
    }
    
    // ฟังก์ชันตรวจสอบความนิ่งหลังการล้ม
    Future<bool> checkStabilityAfterFall() async {
      // รอให้เวลาผ่านไป 0.5 วินาที
      await Future.delayed(Duration(milliseconds: STABILITY_CHECK_DELAY));
      
      // ถ้าไม่มีข้อมูลเพียงพอให้ถือว่าไม่นิ่ง
      if (recentAccelerations.length < 5) return false;
      
      // ตรวจสอบ 5 ค่าล่าสุดว่ามีความนิ่งหรือไม่
      List<double> recentValues = recentAccelerations.sublist(recentAccelerations.length - 5);
      double avg = recentValues.reduce((a, b) => a + b) / recentValues.length;
      
      // คำนวณค่าความแปรปรวน
      double variance = 0;
      for (var value in recentValues) {
        variance += pow(value - avg, 2);
      }
      variance /= recentValues.length;
      
      print("Stability check - variance: $variance, avg: $avg");
      return variance < STABILITY_THRESHOLD;
    }
    
    // ฟังก์ชันตรวจสอบเครดิต
    Future<bool> checkCreditAvailable() async {
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
    
    // ฟังก์ชันแสดงการแจ้งเตือนและเปิดหน้า SOS
    void handleFallDetection() async {
      print("Fall detected in background service!");
      
      try {
        // ตรวจสอบว่ามีการล็อกอินหรือไม่
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.email == null) {
          print("BackgroundService: ไม่มีการล็อกอิน ไม่แสดงการแจ้งเตือนการล้ม");
          return;
        }
        
        /* คอมเมนต์ออกเพื่อทดสอบการแจ้งเตือน
        // ตรวจสอบเครดิตก่อนแสดงการแจ้งเตือน
        bool hasCreditAvailable = await checkCreditAvailable();
        if (!hasCreditAvailable) {
          print("ไม่สามารถส่ง SOS ได้เนื่องจากไม่มีเครดิตเหลือ");
          // แสดงการแจ้งเตือนว่าไม่มีเครดิตเหลือ
          await NotificationService().showNoCreditNotification();
          return;
        }
        */
        
        // ดึงการตั้งค่าเวลานับถอยหลังจาก SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final autoFallCountdownTime = prefs.getInt('auto_fall_countdown_time') ?? 30;
        
        // เรียกใช้ NotificationService เพื่อแสดงการแจ้งเตือนพร้อมเสียงและตัวนับเวลา
        await NotificationService().showFallDetectionAlert(
          notificationId: 888,
          title: '⚠️ ตรวจพบการล้ม!',
          body: 'จะส่ง SOS อัตโนมัติใน $autoFallCountdownTime วินาที\nกดยืนยันเพื่อส่ง SOS หรือยกเลิกหากไม่ต้องการความช่วยเหลือ',
          playSound: true,
        );
        
        // ลบส่วนนี้ออกเพื่อป้องกันการเปิดหน้า SOS confirmation screen
        // service.invoke("fall_detected", {
        //   "timestamp": DateTime.now().toIso8601String(),
        // });
      } catch (e) {
        print("Error in handleFallDetection: $e");
      }
    }
    
    // ฟังก์ชันตรวจสอบรูปแบบการล้ม
    void checkFallPattern() async {
      // ถ้ามีการประมวลผลอยู่แล้ว หรืออยู่ในช่วง cooldown ให้ข้าม
      if (processingFall) return;
      
      // ตรวจสอบว่าระบบตรวจจับการล้มเปิดอยู่หรือไม่
      if (!fallDetectionEnabled) {
        print("Fall detection is disabled in settings");
        return;
      }
      
      // ตรวจสอบ cooldown
      if (lastFallDetection != null) {
        int timeSinceLast = DateTime.now().difference(lastFallDetection!).inMilliseconds;
        if (timeSinceLast < COOLDOWN_PERIOD) {
          print("In cooldown period: ${(COOLDOWN_PERIOD - timeSinceLast) / 1000} seconds left");
          return;
        }
      }
      
      // ตรวจสอบรูปแบบการล้ม: ความเร่งสูงตามด้วยการหมุนในช่วงเวลาที่ใกล้เคียงกัน
      if (highAccelerationDetected && highRotationDetected && 
          accelerationTime != null && rotationTime != null) {
        
        // ตรวจสอบว่าเวลาระหว่างสองเหตุการณ์ห่างกันไม่เกิน 500 ms
        int timeDifference = accelerationTime!.difference(rotationTime!).inMilliseconds.abs();
        if (timeDifference < 500) {
          processingFall = true;
          
          print("Fall pattern detected! Checking stability...");
          
          // ตรวจสอบความนิ่งหลังการล้ม
          bool isStable = await checkStabilityAfterFall();
          if (isStable) {
            print("Person seems stable after fall - likely false positive");
            processingFall = false;
            resetDetectionState();
            return;
          }
          
          // บันทึกเวลาล่าสุดที่ตรวจพบการล้ม
          lastFallDetection = DateTime.now();
          
          // แจ้งเตือนการตรวจพบการล้ม
          handleFallDetection();
          
          // รีเซ็ตสถานะการตรวจจับ
          resetDetectionState();
        }
      }
    }
    
    // เริ่มการติดตามเซนเซอร์ accelerometer
    accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // ไม่ตรวจจับการล้มถ้าระบบถูกปิดใช้งาน
      if (!fallDetectionEnabled) {
        return;
      }
      
      // คำนวณขนาดของแรง (magnitude) จากแกน x, y, z
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // เก็บข้อมูลความเร่งล่าสุด
      addRecentAcceleration(acceleration);

      // ตรวจสอบว่าเกิน threshold หรือไม่
      if (acceleration > ACCELERATION_THRESHOLD) {
        print("Accelerometer detected in background: $acceleration G");
        accelerationTime = DateTime.now();
        highAccelerationDetected = true;
        checkFallPattern();
      }
    });

    // เริ่มการติดตามเซนเซอร์ gyroscope
    gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // ไม่ตรวจจับการล้มถ้าระบบถูกปิดใช้งาน
      if (!fallDetectionEnabled) {
        return;
      }
      
      // คำนวณขนาดการหมุนจากแกน x, y, z
      double rotation = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // ตรวจสอบการหมุนที่อาจบ่งบอกการล้ม
      if (rotation > GYROSCOPE_THRESHOLD) {
        print("Gyroscope detected in background: $rotation rad/s");
        rotationTime = DateTime.now();
        highRotationDetected = true;
        checkFallPattern();
      }
    });
    
    // เพิ่มการติดตามการล็อกอินและอัพเดทตำแหน่งทันที
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print('=== AUTH STATE CHANGED: ${user?.email} ===');
      if (user != null) {
        // อัพเดทตำแหน่งทันทีเมื่อล็อกอิน
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
          );
          await updateLocation(position);
          print('=== INITIAL LOCATION UPDATED AFTER LOGIN ===');
        } catch (e) {
          print('=== ERROR GETTING INITIAL POSITION: $e ===');
        }
      }
    });

    // ลดเวลาในการอัพเดทตำแหน่งเป็นทุก 10 วินาที
    Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
          );
          await updateLocation(position);
        }
      } catch (e) {
        print('=== ERROR GETTING POSITION: $e ===');
      }
    });

    // ลดระยะทางในการอัพเดทเป็น 5 เมตร
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // ลดจาก 10 เมตร เป็น 5 เมตร
      ),
    ).listen((Position position) async {
      print('=== POSITION STREAM UPDATE ===');
      print('Position update received: ${position.latitude}, ${position.longitude}');
      await updateLocation(position);
    });

    // ตัวแปรเพื่อป้องกันการทำงานซ้ำซ้อนของ SOS
    bool isSosConfirmed = false;
    bool isSosCancelled = false;

    service.on('stopService').listen((event) {
      accelerometerSubscription?.cancel();
      gyroscopeSubscription?.cancel();
      positionStream?.cancel();
      service.stopSelf();
    });

    // ฟังก์ชันส่ง SOS จาก background service
    Future<void> _sendSosFromBackground() async {
      try {
        // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
        NotificationService().showSendingSosNotification();
        
        // ใช้ SosService เพื่อส่ง SOS ในรูปแบบเดียวกับทุกการแจ้งเหตุ
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid != null) {
          // นำเข้า SosService ในบริเวณนี้เพื่อป้องกันปัญหา circular dependency
          // import SosService นอกฟังก์ชันนี้เพื่อป้องกันปัญหา circular dependency
          final sosService = SosService();
          
          // เรียกใช้ SosService เพื่อส่ง SOS (ตั้งค่าแหล่งที่มาเป็น background_service)
          final result = await sosService.sendSos(
            user.uid,
            detectionSource: 'automatic',
          );
          
          if (result['success']) {
            print('=== SOS SENT SUCCESSFULLY: ${result['message']} ===');
            // แสดงการแจ้งเตือนว่าส่งสำเร็จ
            NotificationService().showSosSuccessNotification();
          } else {
            print('=== FAILED TO SEND SOS: ${result['message']} ===');
            
            // ตรวจสอบว่าเป็นกรณีเครดิตหมดหรือไม่
            final bool isCreditEmpty = result['isCreditEmpty'] ?? false;
            if (isCreditEmpty) {
              NotificationService().showSosFailedNotification('ไม่สามารถส่ง SMS เนื่องจากเครดิตหมด กรุณาติดต่อผู้ดูแลระบบ');
            } else {
              NotificationService().showSosFailedNotification(result['message'] ?? "การส่ง SOS ล้มเหลว");
            }
          }
        } else {
          print('=== USER NOT LOGGED IN, CANNOT SEND SOS ===');
          NotificationService().showSosFailedNotification("ไม่พบข้อมูลผู้ใช้ โปรดล็อกอินใหม่");
        }
      } catch (e) {
        print('=== ERROR SENDING SOS: $e ===');
        NotificationService().showSosFailedNotification("เกิดข้อผิดพลาด: $e");
      }
    }

    // รับคำสั่ง confirm_sos
    service.on('confirm_sos').listen((event) async {
      print('=== RECEIVED CONFIRM_SOS COMMAND ===');
      if (isSosConfirmed) {
        print('=== SOS ALREADY CONFIRMED, IGNORING DUPLICATE COMMAND ===');
        return;
      }
      
      isSosConfirmed = true;
      isSosCancelled = false;
      
      // ยกเลิกการนับถอยหลังที่อาจมีอยู่ก่อนหน้านี้ใน NotificationService
      NotificationService().cancelNotificationsAndTimers();
      
      // ส่ง SOS
      await _sendSosFromBackground();
      
      // รีเซ็ตสถานะหลังจากเวลาที่กำหนด
      final prefs = await SharedPreferences.getInstance();
      final resetTime = prefs.getInt('auto_fall_countdown_time') ?? 30;
      Timer(Duration(seconds: resetTime), () {
        isSosConfirmed = false;
      });
    });
    
    // รับคำสั่ง cancel_sos
    service.on('cancel_sos').listen((event) async {
      print('=== RECEIVED CANCEL_SOS COMMAND ===');
      if (isSosCancelled) {
        print('=== SOS ALREADY CANCELLED, IGNORING DUPLICATE COMMAND ===');
        return;
      }
      
      isSosCancelled = true;
      isSosConfirmed = false;
      
      // ยกเลิกการนับถอยหลังที่อาจมีอยู่ก่อนหน้านี้ใน NotificationService
      NotificationService().cancelNotificationsAndTimers();
      
      // รีเซ็ตสถานะหลังจากเวลาที่กำหนด
      final prefs = await SharedPreferences.getInstance();
      final resetTime = prefs.getInt('auto_fall_countdown_time') ?? 30;
      Timer(Duration(seconds: resetTime), () {
        isSosCancelled = false;
      });
    });
    
  } catch (e) {
    print('=== ERROR IN BACKGROUND SERVICE: $e ===');
  }
}