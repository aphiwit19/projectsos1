// lib/features/sos/sos_confirmation_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/sos_service.dart';

class SosConfirmationScreen extends StatefulWidget {
  const SosConfirmationScreen({Key? key}) : super(key: key);

  @override
  _SosConfirmationScreenState createState() => _SosConfirmationScreenState();
}

class _SosConfirmationScreenState extends State<SosConfirmationScreen> {
  int _countdown = 5;
  Timer? _timer;
  bool _isSending = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
            _sendSos();
          }
        });
      }
    });
  }

  Future<void> _sendSos() async {
    setState(() {
      _isSending = true;
      _statusMessage = 'กำลังเตรียมข้อมูล...';
    });

    try {
      // ตรวจสอบ permission location
      setState(() {
        _statusMessage = 'กำลังตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง...';
      });
      
      var locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          throw Exception('Location permission not granted');
        }
      }

      // ตรวจสอบว่า location service เปิดอยู่หรือไม่
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // ดึง userId
      setState(() {
        _statusMessage = 'กำลังตรวจสอบข้อมูลผู้ใช้...';
      });
      
      String? userId = await AuthService().getUserId();
      if (userId == null) {
        throw Exception('ไม่สามารถดึง userId ได้ กรุณาล็อกอินใหม่');
      }

      // เรียกใช้ SosService เพื่อส่ง SOS
      setState(() {
        _statusMessage = 'กำลังส่ง SMS ไปยังผู้ติดต่อฉุกเฉิน...';
      });
      
      await SosService().sendSos();

      // แสดงข้อความแจ้งเตือน
      if (mounted) {
        setState(() {
          _statusMessage = 'ส่ง SMS และบันทึกข้อมูล SOS เรียบร้อยแล้ว';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่ง SOS และ SMS เรียบร้อยแล้ว')),
        );
        
        // รอให้ผู้ใช้ได้เห็นข้อความสักครู่ก่อนกลับไปหน้าหลัก
        await Future.delayed(const Duration(seconds: 2));
      }

      // กลับไปหน้า HomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Failed to send SOS: $errorMessage');
      if (mounted) {
        setState(() {
          _statusMessage = 'เกิดข้อผิดพลาด: $errorMessage';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $errorMessage')),
        );
        
        // รอให้ผู้ใช้ได้เห็นข้อความสักครู่ก่อนกลับไปหน้าหลัก
        await Future.delayed(const Duration(seconds: 2));
        
        // กลับไปหน้า HomeScreen แม้จะเกิดข้อผิดพลาด
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _cancelSOS() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        body: SafeArea(
          child: Center(
            child: _isSending
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "SOS ฉุกเฉิน",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            "$_countdown",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(230, 70, 70, 1.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "ระบบจะส่ง SMS ข้อมูลตำแหน่งที่อยู่ถึงผู้ติดต่อฉุกเฉิน เมื่อสิ้นสุดการนับถอยหลัง",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: _cancelSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(fontSize: 18, color: Color.fromRGBO(230, 70, 70, 1.0)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}