import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

// ฟังก์ชันเริ่มต้น background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // ตั้งค่าการแจ้งเตือนสำหรับ Foreground Service
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

  // เริ่ม service
  await service.startService();
}

// ฟังก์ชันทำงานในพื้นหลัง
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // ตั้งค่าการแจ้งเตือนเมื่อ service เริ่มทำงาน
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: "AppSOS is Running",
        content: "Monitoring for emergencies...",
      );
    }

    // เริ่มต้น Firebase ผ่าน FirebaseService
    try {
      await FirebaseService.initializeFirebase();
      FirebaseService.configureFirestore();
    } catch (e) {
      print('Failed to initialize Firebase in background service: $e');
      // ทำงานต่อไปแม้ว่า Firebase จะไม่สามารถเริ่มต้นได้
    }

    // สร้าง Stream สำหรับการติดตามตำแหน่ง
    StreamSubscription<Position>? positionStream;
    
    // ฟังก์ชันสำหรับอัพเดทตำแหน่งใน Firestore
    Future<void> updateLocation(Position position) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;
          final userEmail = user.email;
          
          if (userEmail != null) {
            // บันทึกตำแหน่งล่าสุดใน users collection
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
            });

            // บันทึกประวัติตำแหน่ง
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userEmail)
                .collection('location_history')
                .add({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
              'accuracy': position.accuracy,
              'speed': position.speed,
              'heading': position.heading,
              'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
            });

            // อัพเดทข้อมูลใน SOS logs ถ้ามีการแจ้งเหตุ
            final sosLogsRef = FirebaseFirestore.instance
                .collection('Users')
                .doc(userEmail)
                .collection('sos_logs');
            
            final activeSosQuery = await sosLogsRef
                .where('status', isEqualTo: 'active')
                .get();

            for (var doc in activeSosQuery.docs) {
              await doc.reference.update({
                'location': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                },
                'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
                'lastUpdated': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      } catch (e) {
        print('Error updating location: $e');
      }
    }

    // เริ่มการติดตามตำแหน่ง
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // อัพเดททุก 10 เมตร
      ),
    ).listen((Position position) {
      updateLocation(position);
    });

    // อัพเดทการแจ้งเตือนทุก 10 วินาที
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

    // จัดการเมื่อมีการสั่งหยุด service
    service.on('stopService').listen((event) {
      positionStream?.cancel();
      service.stopSelf();
    });
  } catch (e) {
    print('Error in background service: $e');
    // พยายามรักษา service ให้ทำงานต่อไปแม้จะมี error
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: "AppSOS Service",
        content: "Service is running with limited functionality",
      );
    }
  }
}

// สำหรับ iOS background (จำเป็นต้องมีแม้ว่าจะไม่ได้ใช้)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}