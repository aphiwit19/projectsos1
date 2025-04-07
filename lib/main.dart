import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // เพิ่ม import สำหรับ intl
import 'package:intl/date_symbol_data_local.dart'; // เพิ่ม import สำหรับการเริ่มต้น locale
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // เพิ่ม import
import 'screens/splash_screen.dart';
import 'scripts/seed_emergency_numbers.dart';
import 'scripts/seed_first_aid.dart'; // เพิ่ม import สำหรับ seed_first_aid
import 'scripts/seed_news.dart'; // เพิ่ม import สำหรับ seed_news
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'features/sos/sos_confirmation_screen.dart';
import 'dart:async'; // เพิ่ม import สำหรับ StreamController
import 'package:cloud_firestore/cloud_firestore.dart'; // เพิ่ม import สำหรับ Firestore
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

// ตัวแปรควบคุมการทำงานระหว่าง background และ foreground
bool isProcessingFallDetection = false;
DateTime? lastGlobalFallDetection;
const int GLOBAL_COOLDOWN_PERIOD = 15000; // 15 วินาที cooldown ในระดับแอพ

// เพิ่มตัวแปรควบคุมสถานะการส่ง SOS
bool sosConfirmed = false;
bool sosCancelled = false;

// Stream controller สำหรับส่งข้อมูลจาก background service ไปยัง foreground
final StreamController<bool> fallDetectionStreamController = StreamController<bool>.broadcast();

// Service handler
final service = FlutterBackgroundService();

// การแก้ไขเพิ่มเติมสำหรับการรับการตอบสนองจากการแจ้งเตือน
// ควรใช้ในกรณีที่ NotificationService ไม่สามารถจัดการได้โดยตรง
void handleActionFromNotification(String actionId) async {
  print("Main: Handling notification action: $actionId");
  
  if (actionId == 'CANCEL') {
    if (sosCancelled) {
      print("Main: SOS already cancelled, ignoring duplicate action");
      return;
    }
    
    print("Main: Received CANCEL action");
    // ตั้งค่าสถานะการยกเลิก
    sosCancelled = true;
    sosConfirmed = false;
    
    // ยกเลิกการส่ง SOS จาก background service
    service.invoke("cancel_sos", {
      "timestamp": DateTime.now().toIso8601String(),
    });
    
    // รีเซ็ตสถานะหลัง 30 วินาที
    Timer(Duration(seconds: 30), () {
      sosCancelled = false;
    });
  } else if (actionId == 'CONFIRM_SOS') {
    if (sosConfirmed) {
      print("Main: SOS already confirmed, ignoring duplicate action");
      return;
    }
    
    /* คอมเมนต์ออกเพื่อทดสอบการแจ้งเตือน
    // ตรวจสอบเครดิตก่อนดำเนินการต่อ
    bool hasCreditAvailable = await _checkCreditAvailable();
    if (!hasCreditAvailable) {
      print("Main: ไม่สามารถส่ง SOS ได้เนื่องจากไม่มีเครดิตเหลือ");
      // แสดงการแจ้งเตือนว่าไม่มีเครดิตเหลือ
      await NotificationService().showNoCreditNotification();
      return;
    }
    */
    
    print("Main: Received CONFIRM_SOS action");
    // ตั้งค่าสถานะการยืนยัน
    sosConfirmed = true;
    sosCancelled = false;
    
    // แจ้ง background service ว่ามีการยืนยัน
    service.invoke("confirm_sos", {
      "timestamp": DateTime.now().toIso8601String(),
    });
    
    // แสดงการแจ้งเตือนว่ากำลังส่ง SOS
    NotificationService().showSendingSosNotification();
    
    // ส่ง SOS ทันที โดยไม่ต้องเปิดหน้าจอยืนยัน
    sendSosDirectly();
    
    // รีเซ็ตสถานะหลัง 30 วินาที
    Timer(Duration(seconds: 30), () {
      sosConfirmed = false;
    });
  }
}

// ฟังก์ชันสำหรับส่ง SOS โดยตรงจากการแจ้งเตือน
Future<void> sendSosDirectly() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      // บันทึกข้อมูลการส่ง SOS ไปยัง Firestore
      final sosRef = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection('sos_events')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'sending',
            'source': 'notification_direct',
            'location': await _getCurrentLocation(),
          });
      
      print("SOS record created with ID: ${sosRef.id}");
      
      // ดึงข้อมูลผู้ติดต่อฉุกเฉิน
      final userData = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();
      
      // อัพเดทสถานะเป็นส่งสำเร็จ
      await sosRef.update({'status': 'sent'});
      
      // ลดเครดิต (ถ้ามีการเช็คเครดิต)
      /*
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .update({
            'credit': FieldValue.increment(-1),
          });
      */
      
      // แสดงการแจ้งเตือนว่าส่งสำเร็จ
      NotificationService().showSosSuccessNotification();
      
    } else {
      print("User not logged in, cannot send SOS");
      NotificationService().showSosFailedNotification("ไม่พบข้อมูลผู้ใช้");
    }
  } catch (e) {
    print("Error sending SOS directly: $e");
    NotificationService().showSosFailedNotification("เกิดข้อผิดพลาด: $e");
  }
}

// ฟังก์ชันดึงข้อมูลตำแหน่งปัจจุบัน
Future<Map<String, dynamic>> _getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  } catch (e) {
    print("Error getting current location: $e");
    return {
      'error': 'location_unavailable',
      'error_details': e.toString(),
    };
  }
}

// ฟังก์ชันตรวจสอบเครดิต
Future<bool> _checkCreditAvailable() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      print("ไม่พบข้อมูลผู้ใช้ ไม่สามารถตรวจสอบเครดิตได้");
      return false;
    }
    
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();
    
    if (!userDoc.exists) {
      print("ไม่พบข้อมูลผู้ใช้ในฐานข้อมูล");
      return false;
    }
    
    final credit = userDoc.data()?['credit'] ?? 0;
    print("เครดิตคงเหลือ: $credit");
    
    return credit > 0;
  } catch (e) {
    print("เกิดข้อผิดพลาดในการตรวจสอบเครดิต: $e");
    return false;
  }
}

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

  // ขอสิทธิ์ที่จำเป็น
  await _requestPermissions();
  
  // เริ่มต้น background service
  await initializeService();
  
  // เริ่มต้น NotificationService
  await NotificationService().initialize();
  
  // สำรองการลงทะเบียนการตอบสนองการแจ้งเตือน
  try {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('notification_icon'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Main: Received notification response: ${response.actionId}");
        if (response.actionId != null) {
          handleActionFromNotification(response.actionId!);
        }
      },
    );
    
    print("Main: Flutter Local Notifications Plugin initialized successfully");
  } catch (e) {
    print("Main: Error initializing notification response handler: $e");
  }

  // ฟังก์ชันตรวจสอบ global cooldown
  bool canProcessFallDetection() {
    if (isProcessingFallDetection) return false;
    
    if (lastGlobalFallDetection != null) {
      int timeSinceLastDetection = DateTime.now().difference(lastGlobalFallDetection!).inMilliseconds;
      if (timeSinceLastDetection < GLOBAL_COOLDOWN_PERIOD) {
        print("Global cooldown still active: ${(GLOBAL_COOLDOWN_PERIOD - timeSinceLastDetection) / 1000} seconds left");
        return false;
      }
    }
    
    isProcessingFallDetection = true;
    lastGlobalFallDetection = DateTime.now();
    return true;
  }

  // ฟังก์ชันฟังเหตุการณ์จาก background service
  service.on('fall_detected').listen((event) {
    if (canProcessFallDetection()) {
      // ส่งสัญญาณ stream เพื่อให้ foreground ไม่ทำงานซ้ำซ้อน
      fallDetectionStreamController.add(true);
      
      // หลังจากประมวลผลเสร็จ 5 วินาที ให้รีเซ็ต flag
      Timer(Duration(seconds: 5), () {
        isProcessingFallDetection = false;
      });
    }
  });

  runApp(MyApp());
}

/// รับเหตุการณ์การคลิกการแจ้งเตือน (ไม่ถูกใช้แล้ว แต่เก็บไว้เป็น reference)
void _handleNotificationAction(NotificationResponse details) {
  print("Legacy notification handler called: ${details.actionId}");
  if (details.actionId == 'CONFIRM_SOS') {
    // เปิดแอพที่หน้า SOS confirmation screen
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => SosConfirmationScreen(detectionSource: 'notification')),
    );
  }
}

// ฟังก์ชันสำหรับตรวจสอบ cooldown ระดับแอป ที่สามารถเรียกใช้จากบริการอื่นๆ
bool checkGlobalFallDetectionCooldown() {
  if (isProcessingFallDetection) return false;
  
  if (lastGlobalFallDetection != null) {
    int timeSinceLastDetection = DateTime.now().difference(lastGlobalFallDetection!).inMilliseconds;
    if (timeSinceLastDetection < GLOBAL_COOLDOWN_PERIOD) {
      print("Global cooldown active: ${(GLOBAL_COOLDOWN_PERIOD - timeSinceLastDetection) / 1000} seconds left");
      return false;
    }
  }
  
  isProcessingFallDetection = true;
  lastGlobalFallDetection = DateTime.now();
  
  // หลังจากประมวลผลเสร็จ 5 วินาที ให้รีเซ็ต flag
  Timer(Duration(seconds: 5), () {
    isProcessingFallDetection = false;
  });
  
  return true;
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.sms,
    Permission.phone,
    Permission.notification,
  ].request();
}

// Global navigator key ที่จะใช้สำหรับ navigation จากภายนอก Widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Emergency App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SplashScreen(),
      navigatorKey: navigatorKey, // เพิ่ม navigator key
      debugShowCheckedModeBanner: false,
    );
  }
}