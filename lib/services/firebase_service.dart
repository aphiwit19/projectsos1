// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // static final FirebaseAuth _auth = FirebaseAuth.instance;
  // static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เริ่มต้น Firebase (จะใช้ใน main.dart)
  static Future<void> initializeFirebase() async {
    // await Firebase.initializeApp();
    print('Firebase initialized (placeholder)');
  }

  // ดึง UserID ปัจจุบัน
  static String? getCurrentUserId() {
    // return _auth.currentUser?.uid;
    return null; // Placeholder
  }

// ดึง Firestore instance (สำหรับใช้งานใน service อื่น ๆ)
// static FirebaseFirestore get firestore => _firestore;
}