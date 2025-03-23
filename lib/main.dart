import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'scripts/seed_emergency_numbers.dart'; // เพิ่มการ import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  // await FirebaseAuth.instance.signOut(); // ล็อกเอาท์ผู้ใช้ทั้งหมด (เพื่อทดสอบ)

  // เพิ่มการ seed ข้อมูลเบอร์โทรฉุกเฉิน
  await seedEmergencyNumbers();

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
      debugShowCheckedModeBanner: false,
    );
  }
}