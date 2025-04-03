import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'appsos_foreground',
      initialNotificationTitle: 'AppSOS Service',
      initialNotificationContent: 'Service is starting...',
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
        title: "AppSOS is Running",
        content: "Monitoring for emergencies...",
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

    StreamSubscription<Position>? positionStream;
    
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
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await service.setForegroundNotificationInfo(
            title: "AppSOS Service",
            content: "Service is running ${DateTime.now()}",
          );
        }
      }
    });

    service.on('stopService').listen((event) {
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