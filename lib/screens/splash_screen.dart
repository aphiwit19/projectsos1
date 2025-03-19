import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/login_screen.dart';
import 'home_screen.dart';
import '../features/profile/edit_user_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn'); // ใช้ ? เพื่อจัดการ null
    bool? hasProfile = prefs.getBool('hasProfile'); // ใช้ ? เพื่อจัดการ null

    if (mounted) {
      if (isLoggedIn == true && hasProfile == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (isLoggedIn == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EditUserProfileScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
      body: Column(
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
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(bottom: 50),
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
      ),
    );
  }
}