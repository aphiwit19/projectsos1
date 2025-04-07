// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async'; // เพิ่ม import สำหรับ StreamSubscription
import '../services/fall_detection_service.dart';
import '../features/sos/sos_confirmation_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/emergency_contacts/emergency_contacts_screen.dart';
import '../features/profile/profile_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../main.dart'; // import main.dart เพื่อใช้ตัวแปรและฟังก์ชันจากไฟล์หลัก
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FallDetectionService _fallDetectionService;
  int _currentIndex = 0;
  StreamSubscription? _fallDetectionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fallDetectionService = FallDetectionService(
      onFallDetected: _handleFallDetection,
    );
    _fallDetectionService.startMonitoring();

    // รับเหตุการณ์การตรวจพบการล้มจาก Background Service
    _fallDetectionStreamSubscription = fallDetectionStreamController.stream.listen((event) {
      print("Fall detection event received from background service");
      // ไม่ต้องดำเนินการเพิ่มเติม เพราะ background service จะจัดการการแจ้งเตือนเอง
    });
  }

  void _handleFallDetection() {
    print("Fall detected in foreground! Checking global cooldown...");
    
    // ตรวจสอบว่า SOS ถูกยืนยันแล้วหรือไม่ หรือมีการตั้งค่าไม่ให้เปิดหน้าจอ
    if (sosConfirmed || preventOpeningSosConfirmationScreen) {
      print("SOS already confirmed or screen opening prevented, not showing confirmation screen");
      return;
    }
    
    // ตรวจสอบว่าอยู่ในช่วง cooldown ระดับแอพหรือไม่
    if (checkGlobalFallDetectionCooldown()) {
      print("Global cooldown passed, triggering SOS confirmation screen...");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SosConfirmationScreen(detectionSource: 'automatic')),
      ).then((value) {
        print("Returned to HomeScreen from SosConfirmationScreen");
      });
    } else {
      print("Fall detected but global cooldown is active, ignoring...");
    }
  }

  @override
  void dispose() {
    _fallDetectionService.stopMonitoring();
    _fallDetectionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              "ต้องการขอความช่วยเหลือ หรือไม่?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // ตรวจสอบว่ามีการป้องกันการเปิดหน้าจอหรือไม่
                if (preventOpeningSosConfirmationScreen) {
                  print("SOS button pressed but screen opening prevented, not showing confirmation screen");
                  // แสดงข้อความแจ้งว่ากำลังส่ง SOS อยู่
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('กำลังส่ง SOS อยู่ กรุณารอสักครู่...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SosConfirmationScreen(detectionSource: 'manual')),
                ).then((value) {
                  print("Returned to HomeScreen from SosConfirmationScreen");
                });
              },
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE64646).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFFD8D7).withOpacity(0.7),
                              Color(0xFFFFD8D7),
                            ],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFF68785).withOpacity(0.7),
                              Color(0xFFF68785),
                            ],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFE64646).withOpacity(0.8),
                              Color(0xFFE64646),
                            ],
                            stops: [0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE64646).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "กดปุ่มSOS เพื่อขอความช่วยเหลือ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}