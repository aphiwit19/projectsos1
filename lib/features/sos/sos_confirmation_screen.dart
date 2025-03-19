import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';

class SosConfirmationScreen extends StatefulWidget {
  @override
  _SosConfirmationScreenState createState() => _SosConfirmationScreenState();
}

class _SosConfirmationScreenState extends State<SosConfirmationScreen> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  void _sendSos() {
    // จำลองการส่ง SOS และบันทึกข้อมูล
    print('Sending SOS...');
    // เมื่อเชื่อม Firebase:
    // 1. ดึงตำแหน่งจาก Geolocator
    // 2. บันทึก Current_Locations
    // 3. ส่ง SMS ด้วย url_launcher
    // 4. บันทึก SMS_Logs
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
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
      onWillPop: () async => false, // ป้องกันการกด Back
      child: Scaffold(
        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0), // พื้นหลังสีแดง
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SOS ฉุกเฉิน",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      "$_countdown",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(230, 70, 70, 1.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "ระบบจะส่งข้อมูลตำแหน่งที่อยู่ถึงผู้ติดต่อฉุกเฉิน เมื่อสิ้นสุดการนับถอยหลัง",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _cancelSOS,
                  child: Text(
                    "ยกเลิก",
                    style: TextStyle(fontSize: 18,color: Color.fromRGBO(230, 70, 70, 1.0)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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