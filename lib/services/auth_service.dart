import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'profile_service.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final ProfileService _profileService = ProfileService();

  Future<UserCredential> register(String email, String password) async {
    try {
      debugPrint('Starting registration for email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userId = userCredential.user!.uid;
      // ใช้ email เป็น Document ID
      await _firestore.collection('Users').doc(email).set({
        'uid': userId,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // ตรวจสอบว่า Document ถูกสร้างสำเร็จ
      DocumentSnapshot doc = await _firestore.collection('Users').doc(email).get();
      if (!doc.exists) {
        throw Exception('Failed to create user document in Firestore');
      }
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('uid')) {
        throw Exception('User document created but missing "uid" field');
      }
      debugPrint('User registered successfully: $userId');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'invalid-email':
          errorMessage = 'อีเมลไม่ถูกต้อง';
          break;
        case 'weak-password':
          errorMessage = 'รหัสผ่านอ่อนแอเกินไป';
          break;
        default:
          errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      debugPrint('Registration failed: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Registration failed: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      debugPrint('Starting login for email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // ตรวจสอบและสร้าง Document ใน Users collection ถ้ายังไม่มี
      DocumentSnapshot doc = await _firestore.collection('Users').doc(email).get();
      if (!doc.exists) {
        debugPrint('User document not found for email: $email, creating new document');
        await _firestore.collection('Users').doc(email).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('User logged in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'ไม่พบผู้ใช้ด้วยอีเมลนี้';
          break;
        case 'wrong-password':
          errorMessage = 'รหัสผ่านไม่ถูกต้อง';
          break;
        case 'invalid-email':
          errorMessage = 'อีเมลไม่ถูกต้อง';
          break;
        default:
          errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      debugPrint('Login failed: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Login failed: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<String?> getUserId() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in');
        return null; // คืนค่า null แทนการ throw exception
      }
      String? userId = currentUser.uid;
      debugPrint('Current user ID: $userId');
      return userId;
    } catch (e) {
      debugPrint('Failed to load user ID: $e');
      return null;
    }
  }

  Future<String?> getEmail() async {
    try {
      String? email = _auth.currentUser?.email;
      debugPrint('Current user email: $email');
      return email;
    } catch (e) {
      debugPrint('Failed to load email: $e');
      return null;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }
      String? oldEmail = currentUser.email;
      if (oldEmail == null) {
        throw Exception('ไม่พบอีเมลของผู้ใช้');
      }
      debugPrint('Updating email from $oldEmail to $newEmail');
      await currentUser.updateEmail(newEmail);
      await _profileService.updateEmail(oldEmail, newEmail);
      // รีเฟรชข้อมูลผู้ใช้หลังจากอัปเดตอีเมล
      await currentUser.reload();
      debugPrint('Email updated successfully');
    } catch (e) {
      debugPrint('Failed to update email: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      bool loggedIn = _auth.currentUser != null;
      debugPrint('User logged in: $loggedIn');
      return loggedIn;
    } catch (e) {
      debugPrint('Failed to check login status: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Logging out user');
      await _auth.signOut();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Failed to logout: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<String> generateOTP(String email) async {
    try {
      debugPrint('Generating OTP for email: $email');
      String otp = (1000 + Random().nextInt(9000)).toString();
      await _firestore.collection('PasswordResetOTPs').doc(email).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('OTP generated: $otp');
      return otp;
    } catch (e) {
      debugPrint('Failed to generate OTP: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    try {
      debugPrint('Verifying OTP for email: $email, OTP: $otp');
      DocumentSnapshot doc = await _firestore.collection('PasswordResetOTPs').doc(email).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data == null || !data.containsKey('createdAt') || data['createdAt'] == null) {
          throw Exception('ไม่พบข้อมูลการสร้าง OTP');
        }
        Timestamp createdAt = data['createdAt'];
        DateTime createdTime = createdAt.toDate();
        DateTime now = DateTime.now();
        if (now.difference(createdTime).inMinutes > 5) {
          debugPrint('OTP expired');
          throw Exception('OTP หมดอายุแล้ว');
        }
        if (data['otp'] == otp) {
          debugPrint('OTP verified successfully');
          return true;
        }
      }
      debugPrint('OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('Failed to verify OTP: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      await _firestore.collection('PasswordResetOTPs').doc(email).delete();
      debugPrint('Password reset email sent successfully');
    } catch (e) {
      debugPrint('Failed to send password reset email: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}