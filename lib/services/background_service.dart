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

// เพิ่มค่าคงที่สำหรับการตรวจจับการล้ม
const double ACCELERATION_THRESHOLD = 22.0;
const double GYROSCOPE_THRESHOLD = 10.0;
const double STABILITY_THRESHOLD = 2.0;
const int STABILITY_CHECK_DELAY = 500; // ms
const int COOLDOWN_PERIOD = 10000; // 10 วินาที
const int RECENT_DATA_SIZE = 20; // จำนวนข้อมูลเซนเซอร์ที่เก็บไว้

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // ขอสิทธิ์แจ้งเตือนสำหรับ Android 13 ขึ้นไป
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'appsos_foreground',
      initialNotificationTitle: 'AppSOS บริการช่วยเหลือฉุกเฉิน',
      initialNotificationContent: 'กำลังเริ่มต้นระบบติดตาม...',
      foregroundServiceNotificationId: 888,
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
void onStart(ServiceInstance service) async {
  try {
    print('=== BACKGROUND SERVICE STARTED ===');
    print('Background service started at ${DateTime.now()}');
    
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: "AppSOS กำลังทำงาน",
        content: "ระบบติดตามตำแหน่งกำลังทำงาน",
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
    
    // ฟังก์ชันแสดงการแจ้งเตือนและเปิดหน้า SOS
    void handleFallDetection() async {
      print("Fall detected in background service!");
      
      if (service is AndroidServiceInstance) {
        // อัพเดตการแจ้งเตือนเพื่อบอกว่าตรวจพบการล้ม
        await service.setForegroundNotificationInfo(
          title: "⚠️ ตรวจพบการล้ม!",
          content: "กำลังรอยืนยันการส่ง SOS...",
        );
      }
      
      // ส่งข้อมูลไปยังแอปหลัก (ถ้าแอปเปิดอยู่)
      service.invoke("fall_detected", {
        "timestamp": DateTime.now().toIso8601String(),
      });
      
      // บันทึกการตรวจพบการล้มลง Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.email)
              .collection('fall_events')
              .add({
                'timestamp': FieldValue.serverTimestamp(),
                'confirmed': false,
                'action_taken': 'notification_shown',
              });
        }
      } catch (e) {
        print('=== ERROR LOGGING FALL EVENT: $e ===');
      }
    }
    
    // ฟังก์ชันตรวจสอบรูปแบบการล้ม
    void checkFallPattern() async {
      // ป้องกันการเรียกซ้ำและการเรียกเร็วเกินไป
      if (processingFall) return;
      
      // ตรวจสอบ cooldown period
      if (lastFallDetection != null) {
        int timeSinceLastFall = DateTime.now().difference(lastFallDetection!).inMilliseconds;
        if (timeSinceLastFall < COOLDOWN_PERIOD) {
          print("Still in cooldown period: ${(COOLDOWN_PERIOD - timeSinceLastFall) / 1000} seconds left");
          return;
        }
      }
      
      // ตรวจสอบว่ามีทั้งความเร่งสูงและการหมุนเร็ว ภายในช่วงเวลาที่กำหนด
      if (highAccelerationDetected && highRotationDetected) {
        // ตรวจสอบว่าเหตุการณ์ทั้งสองเกิดขึ้นภายใน 300ms หรือไม่
        if (accelerationTime != null && rotationTime != null) {
          int timeDifference = (accelerationTime!.difference(rotationTime!)).inMilliseconds.abs();
          
          if (timeDifference < 300) {
            processingFall = true;
            print("Potential fall detected in background. Checking stability...");
            
            // ตรวจสอบความนิ่งหลังการล้ม
            bool isStable = await checkStabilityAfterFall();
            
            if (isStable) {
              print("Fall confirmed in background: High acceleration, high rotation, followed by stability");
              lastFallDetection = DateTime.now();
              handleFallDetection();
            } else {
              print("Not a fall: No stability period detected after motion");
            }
            
            resetDetectionState();
          }
        }
      }
    }
    
    // เริ่มการติดตามเซนเซอร์ accelerometer
    accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
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

    // อัพเดทการแจ้งเตือน
    Timer.periodic(Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await service.setForegroundNotificationInfo(
            title: "AppSOS กำลังทำงาน",
            content: "ระบบติดตามกำลังทำงาน",
          );
        }
      }
    });

    service.on('stopService').listen((event) {
      accelerometerSubscription?.cancel();
      gyroscopeSubscription?.cancel();
      positionStream?.cancel();
      service.stopSelf();
    });

  } catch (e) {
    print('=== MAIN ERROR IN BACKGROUND SERVICE: $e ===');
    print('=== STACK TRACE: ${StackTrace.current} ===');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

Future<bool> isServiceRunning() async {
  final service = FlutterBackgroundService();
  return await service.isRunning();
}

// ปรับปรุงฟังก์ชัน updateLocation ให้ทำงานเร็วขึ้น
Future<void> updateLocation(Position position) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userEmail = user.email;
      final userId = user.uid;
      
      if (userEmail != null) {
        // บันทึกตำแหน่งโดยตรงไม่ต้องตรวจสอบ document
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userEmail)
            .collection('current_location')
            .doc('latest')
            .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
              'accuracy': position.accuracy,
              'speed': position.speed,
              'heading': position.heading,
              'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
              'userId': userId,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        
        print('=== LOCATION UPDATED FOR USER: ${userEmail} ===');
      }
    }
  } catch (e) {
    print('=== ERROR IN UPDATE LOCATION: $e ===');
  }
}