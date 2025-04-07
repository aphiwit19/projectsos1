// lib/features/sos/sos_confirmation_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/sos_service.dart';
import '../../main.dart' as main;

class SosConfirmationScreen extends StatefulWidget {
  final String detectionSource; // เพิ่มพารามิเตอร์เพื่อระบุที่มาของการเปิดหน้าจอ

  const SosConfirmationScreen({
    Key? key, 
    this.detectionSource = 'manual',  // ค่าเริ่มต้นคือการกดด้วยตัวเอง
  }) : super(key: key);

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
    
    // ตรวจสอบว่ามีการป้องกันการเปิดหน้านี้หรือไม่
    if (main.preventOpeningSosConfirmationScreen) {
      print("SosConfirmationScreen: มีการป้องกันการเปิดหน้า SOS confirmation ตรวจพบ กำลังปิดหน้าจอ");
      // ปิดหน้า SOS confirmation และกลับไปหน้า HomeScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
      return;
    }
    
    _startCountdown();
    
    // บันทึกข้อมูลการตรวจพบการล้มลง Firestore ตามแหล่งที่มา
    _logSOSRequest();
  }
  
  // บันทึกข้อมูลการเรียกใช้ SOS
  Future<void> _logSOSRequest() async {
    try {
      final authService = AuthService();
      String? userId = await authService.getUserId();
      if (userId != null) {
        await authService.addSosLog(
          'sos_confirmation_opened',
          'ผู้ใช้เปิดหน้าจอยืนยัน SOS',
          {
            'detection_source': widget.detectionSource,
            'timestamp': DateTime.now().toString(),
          },
        );
      }
    } catch (e) {
      print('ไม่สามารถบันทึกข้อมูล SOS log: $e');
    }
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
      
      // เพิ่มข้อมูลแหล่งที่มาของ SOS
      final result = await SosService().sendSos(
        userId, 
        detectionSource: widget.detectionSource
      );

      // แสดงข้อความแจ้งเตือนตามผลลัพธ์ที่ได้รับ
      if (mounted) {
        if (result['success']) {
          setState(() {
            _statusMessage = 'ส่ง SMS และบันทึกข้อมูล SOS เรียบร้อยแล้ว';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ส่ง SOS และ SMS เรียบร้อยแล้ว')),
          );
        } else {
          // กรณีส่งไม่สำเร็จ
          setState(() {
            _statusMessage = result['message'] ?? 'เกิดข้อผิดพลาดในการส่ง SOS';
          });
          
          // ตรวจสอบว่าเป็นกรณีเครดิตหมดหรือไม่
          final bool isCreditEmpty = result['isCreditEmpty'] ?? false;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'เกิดข้อผิดพลาดในการส่ง SOS'),
              backgroundColor: isCreditEmpty ? Colors.orange : Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // รอให้ผู้ใช้ได้เห็นข้อความสักครู่ก่อนกลับไปหน้าหลัก
        await Future.delayed(const Duration(seconds: 3));
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
                      Text(
                        widget.detectionSource == 'manual' 
                        ? "SOS ฉุกเฉิน" 
                        : widget.detectionSource == 'notification' 
                          ? "ยืนยันการส่ง SOS" 
                          : "ตรวจพบการล้ม",
                        style: const TextStyle(
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
                      Text(
                        widget.detectionSource == 'notification'
                        ? "ระบบกำลังจะส่ง SMS แจ้งเหตุฉุกเฉินตามที่คุณยืนยัน"
                        : widget.detectionSource == 'automatic'
                          ? "ระบบตรวจพบการล้ม และจะส่ง SMS แจ้งเหตุฉุกเฉิน"
                          : "ระบบจะส่ง SMS แจ้งเหตุฉุกเฉิน เมื่อสิ้นสุดการนับถอยหลัง",
                        style: const TextStyle(
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