import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../screens/history_screen.dart';
import '../../screens/home_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../auth/login_screen.dart';
import '../emergency_numbers/emergency_numbers_screen.dart';
import '../emergency_contacts/emergency_contacts_screen.dart';
import 'edit_profile_screen.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userProfile = {
    'fullName': '',
    'gender': '',
    'bloodType': '',
    'medicalConditions': '',
    'allergies': '',
    'phone': '',
  };
  String userEmail = 'ไม่ระบุ';
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfileAndEmail();
  }

  Future<void> _loadProfileAndEmail() async {
    try {
      String? email = await _authService.getEmail();
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      setState(() {
        userEmail = email;
      });

      UserProfile? profile = await _profileService.getProfile(email);
      if (profile != null) {
        setState(() {
          userProfile = profile.toJson();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลโปรไฟล์')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
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
          String? email = await _authService.getEmail();
          if (email == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
            return;
          }

          UserProfile updatedUserProfile = UserProfile(
            uid: await _authService.getUserId() ?? '',
            email: email,
            fullName: updatedProfile['fullName'] ?? '',
            gender: updatedProfile['gender'] ?? '',
            bloodType: updatedProfile['bloodType'] ?? '',
            medicalConditions: updatedProfile['medicalConditions'] ?? '',
            allergies: updatedProfile['allergies'] ?? '',
            phone: updatedProfile['phone'] ?? '',
          );
          await _profileService.saveProfile(updatedUserProfile);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
          );
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

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 244, 244, 1.0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Text(
              "ฉัน",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
                              color: Color.fromRGBO(230, 70, 70, 1.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.grey[600]),
                      title: Text(
                        "ชื่อ-นามสกุล",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['fullName']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['fullName'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.grey[600]),
                      title: Text(
                        "เบอร์โทรศัพท์",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['phone']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['phone'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.wc, color: Colors.grey[600]),
                      title: Text(
                        "เพศ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['gender']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['gender'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 60,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.bloodtype, color: Colors.grey[600]),
                      title: Text(
                        "หมู่เลือด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['bloodType']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['bloodType'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 40,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.medical_services, color: Colors.grey[600]),
                      title: Text(
                        "โรคประจำตัว",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['medicalConditions']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['medicalConditions'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.warning, color: Colors.grey[600]),
                      title: Text(
                        "การแพ้ยา",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: userProfile['allergies']?.isNotEmpty ?? false
                          ? Text(
                        userProfile['allergies'],
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                child: Text(
                  "ออกจากระบบ",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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