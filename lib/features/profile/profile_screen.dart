import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../screens/history_screen.dart';
import '../../screens/home_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../auth/login_screen.dart';
import '../emergency_numbers/emergency_numbers_screen.dart';
import '../emergency_contacts/emergency_contacts_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userProfile = {
    'fullName': 'สมชาย ใจดี',
    'gender': 'ชาย',
    'bloodType': 'O',
    'medicalConditions': 'ไม่มี',
    'allergies': 'ยาแก้ปวด',
  };
  String userPhone = 'ไม่ระบุ';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPhone();
  }

  Future<void> _loadProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        setState(() {
          userProfile = jsonDecode(profileJson);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลโปรไฟล์')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์: $e')),
      );
    }
  }

  Future<void> _loadPhone() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        userPhone = prefs.getString('userPhone') ?? 'ไม่ระบุ';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดเบอร์โทรศัพท์: $e')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        userProfile.clear();
        userProfile.addAll(arguments);
      });
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: userProfile),
      ),
    ).then((updatedProfile) async {
      if (updatedProfile != null && updatedProfile is Map<String, dynamic>) {
        setState(() {
          userProfile.clear();
          userProfile.addAll(updatedProfile);
        });
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userProfile', jsonEncode(userProfile));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูลที่แก้ไข: $e')),
          );
        }
      }
    });
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "ฉัน",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 40),
            Card(
              color: Color(0xFFD8DADC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _editProfile,
                          child: Text(
                            "แก้ไข",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ชื่อ-นามสกุล",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userProfile['fullName']?.isNotEmpty ?? false
                          ? userProfile['fullName']
                          : 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),

                    SizedBox(height: 20),
                    Text(
                      "เพศ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userProfile['gender']?.isNotEmpty ?? false
                          ? userProfile['gender']
                          : 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "หมู่เลือด",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userProfile['bloodType']?.isNotEmpty ?? false
                          ? userProfile['bloodType']
                          : 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "โรคประจำตัว",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userProfile['medicalConditions']?.isNotEmpty ?? false
                          ? userProfile['medicalConditions']
                          : 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "การแพ้ยา",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userProfile['allergies']?.isNotEmpty ?? false
                          ? userProfile['allergies']
                          : 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Color(0xFFD8DADC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _viewHistory,
                  child: Text(
                    "ประวัติการแจ้งเหตุ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: Text(
                  "ออกจากระบบ",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyNumbersScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              );
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }
}