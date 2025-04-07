import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/material.dart';
import '../main.dart' as main;
import 'package:firebase_auth/firebase_auth.dart';

class FallDetectionService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // ปรับปรุง Thresholds ใหม่
  static const double accelerationThreshold = 23.0; // เพิ่มขึ้นเล็กน้อยเพื่อลดความไว
  static const double gyroscopeThreshold = 11.0; // เพิ่มขึ้นเล็กน้อยเพื่อลดความไว
  static const double stabilityThreshold = 2.0; // threshold สำหรับความนิ่งหลังจากการล้ม
  
  // เพิ่มตัวแปรสำหรับการตรวจสอบรูปแบบการล้ม
  bool _highAccelerationDetected = false;
  bool _highRotationDetected = false;
  DateTime? _accelerationTime;
  DateTime? _rotationTime;
  
  // ป้องกันการเรียกซ้ำ
  bool _processingFall = false;
  
  // ระยะเวลาที่ให้ตรวจสอบความนิ่งหลังการล้ม (ms)
  static const int stabilityCheckDelay = 500;
  
  // ระยะเวลาหลังจากตรวจพบการล้มแล้วจะไม่ตรวจอีก (ms)
  static const int cooldownPeriod = 20000; // เพิ่มเป็น 20 วินาที
  DateTime? _lastFallDetection;

  // Callback เมื่อตรวจจับการล้ม
  final Function() onFallDetected;

  // รายการข้อมูลความเร่งล่าสุด
  final List<double> _recentAccelerations = [];
  static const int _recentDataSize = 20; // เก็บข้อมูล 20 ค่าล่าสุด

  FallDetectionService({required this.onFallDetected});

  void startMonitoring() {
    // ตรวจสอบว่ามีการล็อกอินหรือไม่
    if (FirebaseAuth.instance.currentUser == null) {
      print("FallDetectionService: ไม่มีการล็อกอิน ไม่เริ่มการตรวจจับการล้ม");
      return;
    }
    
    print("FallDetectionService: เริ่มการตรวจจับการล้ม");
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // คำนวณขนาดของแรง (magnitude) จากแกน x, y, z
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // เก็บข้อมูลความเร่งล่าสุด
      _addRecentAcceleration(acceleration);

      // ตรวจสอบว่าเกิน threshold หรือไม่
      if (acceleration > accelerationThreshold) {
        print("Accelerometer detected: $acceleration G");
        _accelerationTime = DateTime.now();
        _highAccelerationDetected = true;
        _checkFallPattern();
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // คำนวณขนาดการหมุนจากแกน x, y, z
      double rotation = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // ตรวจสอบการหมุนที่อาจบ่งบอกการล้ม
      if (rotation > gyroscopeThreshold) {
        print("Gyroscope detected: $rotation rad/s");
        _rotationTime = DateTime.now();
        _highRotationDetected = true;
        _checkFallPattern();
      }
    });
  }

  void _addRecentAcceleration(double acceleration) {
    _recentAccelerations.add(acceleration);
    if (_recentAccelerations.length > _recentDataSize) {
      _recentAccelerations.removeAt(0);
    }
  }

  // ตรวจสอบความนิ่งหลังการล้ม
  Future<bool> _checkStabilityAfterFall() async {
    // รอให้เวลาผ่านไป 0.5 วินาที
    await Future.delayed(Duration(milliseconds: stabilityCheckDelay));
    
    // ถ้าไม่มีข้อมูลเพียงพอให้ถือว่าไม่นิ่ง
    if (_recentAccelerations.length < 5) return false;
    
    // ตรวจสอบ 5 ค่าล่าสุดว่ามีความนิ่งหรือไม่
    List<double> recentValues = _recentAccelerations.sublist(_recentAccelerations.length - 5);
    double avg = recentValues.reduce((a, b) => a + b) / recentValues.length;
    
    // คำนวณค่าความแปรปรวน
    double variance = 0;
    for (var value in recentValues) {
      variance += pow(value - avg, 2);
    }
    variance /= recentValues.length;
    
    print("Stability check - variance: $variance, avg: $avg");
    return variance < stabilityThreshold;
  }

  void _checkFallPattern() async {
    // ป้องกันการเรียกซ้ำและการเรียกเร็วเกิดไป
    if (_processingFall) return;
    
    // ตรวจสอบว่ามีการล็อกอินหรือไม่
    if (FirebaseAuth.instance.currentUser == null) {
      print("FallDetectionService: ไม่มีการล็อกอิน ไม่ทำการตรวจจับการล้ม");
      return;
    }
    
    // ตรวจสอบ cooldown period
    if (_lastFallDetection != null) {
      int timeSinceLastFall = DateTime.now().difference(_lastFallDetection!).inMilliseconds;
      if (timeSinceLastFall < cooldownPeriod) {
        print("Still in cooldown period: ${(cooldownPeriod - timeSinceLastFall) / 1000} seconds left");
        return;
      }
    }
    
    // ตรวจสอบว่ามีทั้งความเร่งสูงและการหมุนเร็ว ภายในช่วงเวลาที่กำหนด
    if (_highAccelerationDetected && _highRotationDetected) {
      // ตรวจสอบว่าเหตุการณ์ทั้งสองเกิดขึ้นภายใน 300ms หรือไม่
      if (_accelerationTime != null && _rotationTime != null) {
        int timeDifference = (_accelerationTime!.difference(_rotationTime!)).inMilliseconds.abs();
        
        if (timeDifference < 300) {
          _processingFall = true;
          print("Potential fall detected. Checking stability...");
          
          // ตรวจสอบความนิ่งหลังการล้ม
          bool isStable = await _checkStabilityAfterFall();
          
          if (isStable) {
            // ตรวจสอบว่ามีการป้องกันการเปิดหน้า SOS confirmation หรือไม่
            if (main.preventOpeningSosConfirmationScreen) {
              print("Fall confirmed but SOS process already in progress, ignoring fall detection");
              _resetDetectionState();
              return;
            }
            
            print("Fall confirmed: High acceleration, high rotation, followed by stability");
            _lastFallDetection = DateTime.now();
            onFallDetected();
          } else {
            print("Not a fall: No stability period detected after motion");
          }
          
          _resetDetectionState();
        }
      }
    }
  }

  void _resetDetectionState() {
    _highAccelerationDetected = false;
    _highRotationDetected = false;
    _accelerationTime = null;
    _rotationTime = null;
    _processingFall = false;
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _recentAccelerations.clear();
  }
}