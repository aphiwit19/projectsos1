import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({Key? key}) : super(key: key);

  @override
  _SafetySettingsScreenState createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  bool _fallDetectionEnabled = true;
  int _sosCountdownTime = 5; // ค่าเริ่มต้น 5 วินาที
  int _autoFallCountdownTime = 30; // ค่าเริ่มต้น 30 วินาที

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // ดึงการตั้งค่าจาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      bool localFallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? true;
      int localSosCountdownTime = prefs.getInt('sos_countdown_time') ?? 5;
      int localAutoFallCountdownTime = prefs.getInt('auto_fall_countdown_time') ?? 30;
      
      // ดึงการตั้งค่าจาก Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.email)
              .get();
              
          if (userDoc.exists && userDoc.data()!.containsKey('settings')) {
            final settings = userDoc.data()!['settings'];
            if (settings != null) {
              // ตรวจสอบและปรับปรุงการตั้งค่าถ้าจำเป็น
              if (settings.containsKey('fall_detection_enabled')) {
                localFallDetectionEnabled = settings['fall_detection_enabled'] as bool;
                await prefs.setBool('fall_detection_enabled', localFallDetectionEnabled);
              }
              
              if (settings.containsKey('sos_countdown_time')) {
                localSosCountdownTime = settings['sos_countdown_time'] as int;
                await prefs.setInt('sos_countdown_time', localSosCountdownTime);
              }
              
              if (settings.containsKey('auto_fall_countdown_time')) {
                localAutoFallCountdownTime = settings['auto_fall_countdown_time'] as int;
                await prefs.setInt('auto_fall_countdown_time', localAutoFallCountdownTime);
              }
            }
          }
        } catch (e) {
          print('Error loading settings from Firestore: $e');
        }
      }
      
      setState(() {
        _fallDetectionEnabled = localFallDetectionEnabled;
        _sosCountdownTime = localSosCountdownTime;
        _autoFallCountdownTime = localAutoFallCountdownTime;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _fallDetectionEnabled = true; // ใช้ค่าเริ่มต้นหากเกิดข้อผิดพลาด
        _sosCountdownTime = 5; // ใช้ค่าเริ่มต้นหากเกิดข้อผิดพลาด
        _autoFallCountdownTime = 30; // ใช้ค่าเริ่มต้นหากเกิดข้อผิดพลาด
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fall_detection_enabled', _fallDetectionEnabled);
    await prefs.setInt('sos_countdown_time', _sosCountdownTime);
    await prefs.setInt('auto_fall_countdown_time', _autoFallCountdownTime);
    
    // บันทึกการตั้งค่าลงใน Firestore เพื่อให้ background service รับรู้การเปลี่ยนแปลงทันที
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .update({
            'settings': {
              'fall_detection_enabled': _fallDetectionEnabled,
              'sos_countdown_time': _sosCountdownTime,
              'auto_fall_countdown_time': _autoFallCountdownTime,
              'updated_at': FieldValue.serverTimestamp(),
            }
          });
        print('Settings saved to Firestore');
      }
    } catch (e) {
      print('Error saving settings to Firestore: $e');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกการตั้งค่าเรียบร้อยแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        title: const Text(
          "การตั้งค่าความปลอดภัย",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // ส่วนที่ 1: การตั้งค่าระบบตรวจจับการล้ม
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "การตั้งค่าระบบตรวจจับการล้ม",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "เปิดใช้ระบบตรวจจับการล้มอัตโนมัติ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        "เมื่อเปิดใช้งาน ระบบจะตรวจจับการล้มโดยอัตโนมัติและส่งการแจ้งเตือน",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      value: _fallDetectionEnabled,
                      activeColor: const Color.fromRGBO(230, 70, 70, 1.0),
                      onChanged: (value) {
                        setState(() {
                          _fallDetectionEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ส่วนที่ 2: การตั้งค่าการนับถอยหลังของ SOS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "การตั้งค่าการนับถอยหลัง",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "เวลานับถอยหลังเมื่อกดปุ่ม SOS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "$_sosCountdownTime วินาที",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_sosCountdownTime > 3) {
                                setState(() {
                                  _sosCountdownTime--;
                                });
                              }
                            },
                          ),
                          Text(
                            "$_sosCountdownTime",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (_sosCountdownTime < 10) {
                                setState(() {
                                  _sosCountdownTime++;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "เวลานับถอยหลังสำหรับการตรวจจับการล้มอัตโนมัติ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "$_autoFallCountdownTime วินาที",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_autoFallCountdownTime > 10) {
                                setState(() {
                                  _autoFallCountdownTime -= 5;
                                });
                              }
                            },
                          ),
                          Text(
                            "$_autoFallCountdownTime",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (_autoFallCountdownTime < 60) {
                                setState(() {
                                  _autoFallCountdownTime += 5;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // ปุ่มบันทึกการตั้งค่า
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text(
                  "บันทึกการตั้งค่า",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 