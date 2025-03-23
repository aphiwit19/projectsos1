import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/login_screen.dart';
import 'home_screen.dart';
import '../features/profile/edit_user_profile_screen.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ถ้ากำลังรอสถานะการล็อกอิน
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('SplashScreen: Waiting for auth state...');
            return _buildSplashContent(context);
          }

          // ถ้ามีข้อผิดพลาด
          if (snapshot.hasError) {
            debugPrint('SplashScreen: Error in auth state: ${snapshot.error}');
            return _buildErrorContent(context, 'เกิดข้อผิดพลาด: ${snapshot.error}');
          }

          // ถ้ามีผู้ใช้ล็อกอิน
          if (snapshot.hasData) {
            debugPrint('SplashScreen: User is logged in, UID: ${snapshot.data!.uid}');
            String? email = snapshot.data!.email;
            debugPrint('SplashScreen: email = $email');

            if (email != null && email.isNotEmpty) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseService.firestore.collection('Users').doc(email).get(),
                builder: (context, userDocSnapshot) {
                  // ถ้ากำลังรอข้อมูลผู้ใช้จาก Firestore
                  if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                    debugPrint('SplashScreen: Waiting for user profile data...');
                    return _buildSplashContent(context);
                  }

                  // ถ้ามีข้อผิดพลาดในการดึงข้อมูลผู้ใช้
                  if (userDocSnapshot.hasError) {
                    debugPrint('SplashScreen: Error fetching user profile: ${userDocSnapshot.error}');
                    return _buildErrorContent(context, 'เกิดข้อผิดพลาด: ${userDocSnapshot.error}');
                  }

                  // ถ้าดึงข้อมูลสำเร็จ
                  if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                    debugPrint('SplashScreen: User has profile, navigating to HomeScreen');
                    // รอ 2 วินาทีแล้วนำทางไป HomeScreen
                    _navigateAfterDelay(context, HomeScreen());
                  } else {
                    debugPrint('SplashScreen: User has no profile, navigating to EditUserProfileScreen');
                    // รอ 2 วินาทีแล้วนำทางไป EditUserProfileScreen
                    _navigateAfterDelay(
                      context,
                      EditUserProfileScreen(),
                      arguments: {'email': email},
                    );
                  }
                  return _buildSplashContent(context);
                },
              );
            } else {
              debugPrint('SplashScreen: email is null or empty, navigating to LoginScreen');
              _authService.logout();
              _navigateAfterDelay(context, LoginScreen());
            }
          } else {
            // ถ้าไม่มีผู้ใช้ล็อกอิน
            debugPrint('SplashScreen: User not logged in, navigating to LoginScreen');
            _navigateAfterDelay(context, LoginScreen());
          }

          return _buildSplashContent(context);
        },
      ),
    );
  }

  // ฟังก์ชันสำหรับหน่วงเวลาและนำทาง
  Future<void> _navigateAfterDelay(BuildContext context, Widget destination, {Map<String, dynamic>? arguments}) async {
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => destination,
          settings: arguments != null ? RouteSettings(arguments: arguments) : null,
        ),
      );
    }
  }

  // ฟังก์ชันสำหรับสร้าง UI ของ Splash Screen
  Widget _buildSplashContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(255, 216, 215, 1.0),
                  ),
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(246, 135, 133, 1.0),
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                  ),
                ),
                Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        SizedBox(height: 40),
        Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: Text(
            'ยินดีต้อนรับเข้าสู่ My SOS',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันสำหรับแสดงข้อผิดพลาด
  Widget _buildErrorContent(BuildContext context, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // ลองโหลดใหม่
            setState(() {});
          },
          child: Text('ลองใหม่'),
        ),
      ],
    );
  }
}