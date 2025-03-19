import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FirebaseService.initializeFirebase(); // เปิดใช้งานเมื่อตั้งค่า Firebase
  await _requestPermissions();
  runApp(MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.sms,
  ].request();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Emergency App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SplashScreen(),
    );
  }
}