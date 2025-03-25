import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
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
}