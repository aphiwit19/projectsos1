// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../screens/chat_screen.dart';
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
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
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
          const SnackBar(content: Text('ไม่พบข้อมูลโปรไฟล์')),
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
              const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
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
            const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
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
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color.fromRGBO(230, 70, 70, 1.0),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ยืนยันการออกจากระบบ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'คุณต้องการออกจากระบบหรือไม่?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "ฉัน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _editProfile,
                          child: const Text(
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
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.wc, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.bloodtype, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.medical_services, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        child: Icon(Icons.warning, color: Colors.white, size: 20),
                      ),
                      title: const Text(
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _viewHistory,
                  child: const Text(
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                child: const Text(
                  "ออกจากระบบ",
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 4,
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
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyNumbersScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              );
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }
}