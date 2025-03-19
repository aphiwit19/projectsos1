import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ยังไม่ต้องใส่จนกว่าจะตั้งค่า Firebase

class AuthService {
  // FirebaseAuth instance (จะใช้เมื่อเชื่อม Firebase)
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', phoneNumber);
      await prefs.setBool('isLoggedIn', true);
      // เมื่อเชื่อม Firebase: ใช้ _auth.signInWithPhoneNumber หรือ credential
    } catch (e) {
      throw Exception('Failed to save phone number: $e');
    }
  }

  Future<String?> getPhoneNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('userPhone');
      // เมื่อเชื่อม Firebase: return _auth.currentUser?.phoneNumber;
    } catch (e) {
      throw Exception('Failed to load phone number: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
      // เมื่อเชื่อม Firebase: return _auth.currentUser != null;
    } catch (e) {
      throw Exception('Failed to check login status: $e');
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userPhone');
      await prefs.remove('isLoggedIn');
      await prefs.remove('userProfile');
      await prefs.remove('hasProfile');
      await prefs.remove('emergencyContacts');
      // เมื่อเชื่อม Firebase: await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

// เพิ่มเมธอดสำหรับ Firebase Authentication (ยังไม่ใช้งานจนกว่าจะเชื่อม)
/*
  Future<String> signInWithPhone(String phone, String otp) async {
    // ตัวอย่างสำหรับ Firebase Phone Auth
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: '', // จะได้จาก OTP Verification
        smsCode: otp,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user!.uid;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }
  */
}