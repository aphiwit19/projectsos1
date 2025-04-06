import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class FallDetectionService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Thresholds สำหรับการตรวจจับการล้ม (ปรับได้ตามการทดสอบ)
  static const double accelerationThreshold = 25.0; // แรง G ที่บ่งบอกการล้ม
  static const double gyroscopeThreshold = 12.0; // ความเร็วการหมุน (rad/s)

  // Callback เมื่อตรวจจับการล้ม
  final Function() onFallDetected;

  FallDetectionService({required this.onFallDetected});

  void startMonitoring() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // คำนวณขนาดของแรง (magnitude) จากแกน x, y, z
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // ตรวจสอบว่าเกิน threshold หรือไม่
      if (acceleration > accelerationThreshold) {
        print("Accelerometer detected: $acceleration G");
        _checkFallCondition();
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // คำนวณขนาดการหมุนจากแกน x, y, z
      double rotation = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // ตรวจสอบการหมุนที่อาจบ่งบอกการล้ม
      if (rotation > gyroscopeThreshold) {
        print("Gyroscope detected: $rotation rad/s");
        _checkFallCondition();
      }
    });
  }

  void _checkFallCondition() {
    // เงื่อนไขการล้ม: ถ้ามีทั้งแรงกระแทกและการหมุน อาจเป็นการล้ม
    // ในตัวอย่างนี้ ถ้าเกิน threshold อย่างใดอย่างหนึ่งก็เรียก callback
    onFallDetected();
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }
}