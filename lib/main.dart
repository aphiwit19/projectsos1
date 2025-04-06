import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // เพิ่ม import สำหรับ intl
import 'package:intl/date_symbol_data_local.dart'; // เพิ่ม import สำหรับการเริ่มต้น locale
import 'screens/splash_screen.dart';
import 'scripts/seed_emergency_numbers.dart';
import 'scripts/seed_first_aid.dart'; // เพิ่ม import สำหรับ seed_first_aid
import 'scripts/seed_news.dart'; // เพิ่ม import สำหรับ seed_news
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  // await FirebaseAuth.instance.signOut(); // ล็อกเอาท์ผู้ใช้ทั้งหมด (เพื่อทดสอบ)

  // เพิ่มการ seed ข้อมูลเบอร์โทรฉุกเฉิน
  await seedEmergencyNumbers();
  
  // เพิ่มการ seed ข้อมูลการปฐมพยาบาล
  await seedFirstAidData();
  
  // เพิ่มการ seed ข้อมูลข่าวสาร
  await seedNewsData();

  // เริ่มต้น locale สำหรับ intl
  await initializeDateFormatting('th', null);

  await _requestPermissions();
  
  // เริ่มต้น background service
  await initializeService();

  runApp(MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.sms,
    Permission.phone,
    Permission.notification,
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