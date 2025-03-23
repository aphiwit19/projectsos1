import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/emergency_contact_model.dart';
import '../../screens/home_screen.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/location_service.dart';
import '../../services/sms_service.dart';
import '../../services/sos_service.dart';
import '../../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class SosConfirmationScreen extends StatefulWidget {
  const SosConfirmationScreen({Key? key}) : super(key: key);

  @override
  _SosConfirmationScreenState createState() => _SosConfirmationScreenState();
}

class _SosConfirmationScreenState extends State<SosConfirmationScreen> {
  int _countdown = 5;
  Timer? _timer;
  bool _isSending = false;

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
    });

    try {
      // ตรวจสอบ permission SMS
      var smsStatus = await Permission.sms.status;
      if (!smsStatus.isGranted) {
        smsStatus = await Permission.sms.request();
        if (!smsStatus.isGranted) {
          throw Exception('SMS permission not granted');
        }
      }

      // ตรวจสอบ permission location
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
      String? userId = await AuthService().getUserId();
      if (userId == null) {
        throw Exception('ไม่สามารถดึง userId ได้ กรุณาล็อกอินใหม่');
      }

      // ดึงตำแหน่ง
      Position position = await LocationService().getCurrentLocation();

      // ดึงข้อมูลผู้ใช้
      Map<String, dynamic>? userInfo = await SosService().getUserInfo();
      if (userInfo == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }
      String fullName = userInfo['FullName']?.toString() ?? 'ผู้ใช้';
      String phoneNumber = userInfo['PhoneNumber']?.toString() ?? 'ไม่ระบุ';

      // ดึงผู้ติดต่อฉุกเฉิน
      List<EmergencyContact> contacts = await EmergencyContactService().getEmergencyContacts(userId);
      if (contacts.isEmpty) {
        throw Exception('ไม่พบผู้ติดต่อฉุกเฉิน');
      }

      // สร้าง List<String> สำหรับ recipients
      List<String> recipients = contacts
          .where((contact) => contact.phone != null && contact.phone!.isNotEmpty)
          .map((contact) => contact.phone!)
          .toList();

      if (recipients.isEmpty) {
        throw Exception('ไม่พบเบอร์โทรศัพท์ที่ถูกต้องในผู้ติดต่อฉุกเฉิน');
      }

      // สร้างข้อความ SMS
      String message =
          'ช่วยด้วย! ฉัน $fullName ต้องการความช่วยเหลือฉุกเฉิน ตำแหน่งของฉัน: https://maps.google.com/?q=${position.latitude},${position.longitude} เบอร์โทรของฉัน: $phoneNumber';

      // บันทึกตำแหน่งใน Firestore
      var location = await SosService().saveLocation(position);

      // ส่ง SMS อัตโนมัติ
      print('Sending SOS to $recipients');
      await SmsService().sendSms(recipients, message);
      print('SOS sent successfully');

      // บันทึก SMS Logs
      await SosService().logSms(
        location,
        contacts.map((contact) => contact.toJson()).toList(),
        message,
      );

      // แสดงข้อความแจ้งเตือน
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่ง SOS ไปยัง ${recipients.length} ผู้ติดต่อเรียบร้อยแล้ว')),
        );
      }

      // กลับไปหน้า HomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Failed to send SOS: $errorMessage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $errorMessage')),
        );
        if (errorMessage.contains('SMS service not available')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อุปกรณ์นี้ไม่รองรับการส่ง SMS อัตโนมัติ')),
          );
        }
        // กลับไปหน้า HomeScreen แม้จะเกิดข้อผิดพลาด
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _cancelSOS() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
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
                ? const CircularProgressIndicator(
              color: Colors.white,
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
                  "ระบบจะส่งข้อมูลตำแหน่งที่อยู่ถึงผู้ติดต่อฉุกเฉิน เมื่อสิ้นสุดการนับถอยหลัง",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _cancelSOS,
                  child: const Text(
                    "ยกเลิก",
                    style: TextStyle(fontSize: 18, color: Color.fromRGBO(230, 70, 70, 1.0)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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