// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/login_screen.dart';
import 'home_screen.dart';
import '../features/profile/edit_user_profile_screen.dart'; // ใช้ InitialProfileSetupScreen
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    debugPrint('SplashScreen: User has no profile, navigating to InitialProfileSetupScreen');
                    // รอ 2 วินาทีแล้วนำทางไป InitialProfileSetupScreen
                    _navigateAfterDelay(
                      context,
                      InitialProfileSetupScreen(
                        userProfile: {
                          'uid': snapshot.data!.uid,
                          'email': email,
                          'fullName': '',
                          'phone': '',
                          'gender': '',
                          'bloodType': '',
                          'medicalConditions': '',
                          'allergies': '',
                          'isNewUser': true,
                        },
                      ),
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF73B3B),
            Color(0xFFBD2A2A),
          ],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // วงกลม SOS
                  Container(
                    width: screenWidth * 0.72,
                    height: screenWidth * 0.72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // เงาด้านหลัง
                        Container(
                          margin: EdgeInsets.only(top: 15),
                          width: screenWidth * 0.68,
                          height: screenWidth * 0.68,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 25,
                                spreadRadius: 1,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                        
                        // วงกลมชั้นนอก
                        Container(
                          width: screenWidth * 0.65,
                          height: screenWidth * 0.65,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: screenWidth * 0.55,
                              height: screenWidth * 0.55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF5252),
                                    Color(0xFFE64646),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFE64646).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // แสงวาวในวงกลม
                                  Positioned(
                                    top: screenWidth * 0.12,
                                    left: screenWidth * 0.12,
                                    child: Container(
                                      width: screenWidth * 0.12,
                                      height: screenWidth * 0.08,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.25),
                                      ),
                                    ),
                                  ),
                                  
                                  // ตัวอักษร SOS และเส้นขีดใต้
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "SOS",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.14,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                            height: 1,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black38,
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        // เส้นขีดใต้ข้อความ
                                        Container(
                                          width: screenWidth * 0.25,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 3,
                                                spreadRadius: 0,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // กากบาท (เครื่องหมายการแพทย์) อยู่ด้านบนสุด
                        Positioned(
                          top: 0,
                          child: Container(
                            width: screenWidth * 0.16,
                            height: screenWidth * 0.16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFFE64646), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: Color(0xFFE64646),
                                size: screenWidth * 0.09,
                                weight: 700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.05),
                  
                  // Loading Indicator และข้อความ
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // ชื่อแอป
                        Text(
                          'My SOS',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // คำอธิบาย
                        Text(
                          'แอปพลิเคชันช่วยเหลือฉุกเฉิน',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับแสดงข้อผิดพลาด
  Widget _buildErrorContent(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE64646),
            Color(0xFFCD3F3F),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 80,
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  // ลองโหลดใหม่
                  setState(() {});
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  child: Text(
                    'ลองใหม่',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE64646),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}