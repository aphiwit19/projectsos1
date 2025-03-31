import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  // ดึงตำแหน่งแบบ real-time จาก current_location ที่ background service บันทึกไว้
  Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return null;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection('current_location')
          .doc('latest')
          .get();

      if (docSnapshot.exists) {
        // ถ้ามีข้อมูลตำแหน่งล่าสุดจาก background service
        return docSnapshot.data();
      }
      
      // ถ้าไม่มีข้อมูล ให้คืนค่า null
      return null;
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  // ดึงตำแหน่งแบบ one-time ใช้เมื่อไม่มีข้อมูลจาก background service
  Future<Position> getCurrentLocation({required context}) async {
    try {
      // ตรวจสอบว่า GPS เปิดอยู่หรือไม่
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('กรุณาเปิด GPS เพื่อใช้งาน');
      }

      // ขออนุญาตตำแหน่ง
      PermissionStatus permission = await Permission.locationWhenInUse.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('กรุณาอนุญาตการเข้าถึงตำแหน่ง');
      }

      // ดึงตำแหน่ง
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e');
    }
  }
  
  // ฟังก์ชันสำหรับเรียกใช้จากที่อื่นๆ ในแอพ - จะพยายามใช้ตำแหน่งล่าสุดก่อน
  // ถ้าไม่มีหรือนานเกินไป จะเรียกดึงตำแหน่งใหม่
  Future<Position?> getBestLocation({required context}) async {
    try {
      // ลองดึงตำแหน่งล่าสุดจาก background service ก่อน
      final lastLocation = await getLastKnownLocation();
      
      if (lastLocation != null) {
        // ตรวจสอบเวลาที่บันทึก ถ้าไม่เกิน 2 นาที ใช้ตำแหน่งนี้ได้
        final timestamp = lastLocation['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final now = DateTime.now();
          final diff = now.difference(timestamp.toDate());
          
          if (diff.inMinutes < 2) {
            // ตำแหน่งยังใหม่พอ สร้าง Position object จากข้อมูลใน Firestore
            return Position.fromMap({
              'latitude': lastLocation['latitude'],
              'longitude': lastLocation['longitude'],
              'accuracy': lastLocation['accuracy'] ?? 0.0,
              'altitude': 0.0,
              'speed': lastLocation['speed'] ?? 0.0,
              'speedAccuracy': 0.0,
              'heading': lastLocation['heading'] ?? 0.0,
              'timestamp': timestamp.toDate().millisecondsSinceEpoch,
            });
          }
        }
      }
      
      // ถ้าไม่มีตำแหน่งล่าสุดหรือนานเกินไป ดึงตำแหน่งใหม่
      return await getCurrentLocation(context: context);
    } catch (e) {
      print('Error getting best location: $e');
      return null;
    }
  }
}