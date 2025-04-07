// lib/services/sos_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/sos_log_model.dart';
import '../models/emergency_contact_model.dart';
import 'emergency_contact_service.dart';
import 'location_service.dart';
import 'profile_service.dart';
import 'sms_service.dart';
import '../models/user_profile_model.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';
import '../services/sms_service.dart';
import '../services/location_service.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SmsService _smsService = SmsService();

  String _sanitizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<String?> _getEmailFromUserId(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('Users')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        debugPrint('User not found for userId: $userId');
        return null;
      }
      return query.docs.first.id;
    } catch (e) {
      debugPrint('Error getting email from userId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> sendSos(
    String userId, {
    String detectionSource = 'manual',
  }) async {
    try {
      print('SOS Service: เริ่มต้นกระบวนการส่ง SOS สำหรับผู้ใช้ $userId');
      
      // ดึงข้อมูลผู้ใช้
      final user = await _getUserData(userId);
      if (user == null) {
        return {
          'success': false,
          'message': 'ไม่พบข้อมูลผู้ใช้',
          'userId': userId,
        };
      }

      // ดึงตำแหน่งปัจจุบัน
      print('SOS Service: กำลังดึงข้อมูลตำแหน่ง...');
      final position = await LocationService().getCurrentPosition();
      print('SOS Service: ได้ตำแหน่งแล้ว - ${position.latitude}, ${position.longitude}');

      // สร้างลิงก์ตำแหน่ง
      final positionLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      
      // ดึงรายชื่อผู้ติดต่อฉุกเฉิน
      print('SOS Service: กำลังดึงรายชื่อผู้ติดต่อฉุกเฉิน...');
      final contacts = await _getEmergencyContacts(userId);
      
      if (contacts.isEmpty) {
        return {
          'success': false,
          'message': 'ไม่พบรายชื่อผู้ติดต่อฉุกเฉิน กรุณาเพิ่มผู้ติดต่อฉุกเฉินก่อน',
        };
      }
      
      print('SOS Service: พบผู้ติดต่อฉุกเฉิน ${contacts.length} คน');

      // สร้างข้อความ SOS
      final userName = user['name'] ?? 'ผู้ใช้';
      final currentTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      
      final messagePrefix = detectionSource == 'automatic' 
          ? '[ระบบตรวจพบการล้ม]' 
          : detectionSource == 'notification'
              ? '[ยืนยันจากการแจ้งเตือน]'
              : '[แจ้งเหตุฉุกเฉิน]';
      
      final message = '''
$messagePrefix ฉุกเฉิน! $userName ต้องการความช่วยเหลือ
เวลา: $currentTime
ตำแหน่ง: $positionLink
''';

      // ส่ง SMS ไปยังผู้ติดต่อทั้งหมด
      print('SOS Service: กำลังส่ง SMS...');
      
      List<String> sentNumbers = [];
      List<String> failedNumbers = [];
      
      for (final contact in contacts) {
        final phoneNumber = contact['phone'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          final success = await SmsService().sendSms(
            phoneNumber,
            message,
          );
          
          if (success) {
            sentNumbers.add(phoneNumber);
          } else {
            failedNumbers.add(phoneNumber);
          }
        }
      }
      
      print('SOS Service: ส่ง SMS สำเร็จ ${sentNumbers.length} เบอร์, ล้มเหลว ${failedNumbers.length} เบอร์');

      // บันทึกประวัติการส่ง SOS
      print('SOS Service: กำลังบันทึกประวัติการส่ง SOS...');
      
      final sosId = await _saveSosHistory(
        userId,
        position,
        sentNumbers,
        failedNumbers,
        detectionSource,
      );
      
      print('SOS Service: บันทึกประวัติ SOS เรียบร้อย ID: $sosId');

      // คืนค่าผลลัพธ์
      if (sentNumbers.isNotEmpty) {
        return {
          'success': true,
          'message': 'ส่ง SOS สำเร็จ ${sentNumbers.length} เบอร์',
          'sentCount': sentNumbers.length,
          'failedCount': failedNumbers.length,
          'sosId': sosId,
        };
      } else {
        return {
          'success': false,
          'message': 'ไม่สามารถส่ง SMS ไปยังผู้ติดต่อฉุกเฉินได้',
          'sentCount': 0,
          'failedCount': failedNumbers.length,
        };
      }
    } catch (e) {
      print('SOS Service ERROR: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการส่ง SOS: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // ค้นหาทั้งจาก userId และ uid
      QuerySnapshot usersQueryByUserId = await _firestore
          .collection('Users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (usersQueryByUserId.docs.isNotEmpty) {
        return usersQueryByUserId.docs.first.data() as Map<String, dynamic>;
      }

      // ถ้าไม่พบจาก userId ให้ลองหาจาก uid
      QuerySnapshot usersQueryByUid = await _firestore
          .collection('Users')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (usersQueryByUid.docs.isNotEmpty) {
        return usersQueryByUid.docs.first.data() as Map<String, dynamic>;
      }

      // ลองดึงจาก email โดยตรง (ถ้า userId เป็น email)
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      
      print('ไม่พบข้อมูลผู้ใช้สำหรับ userId: $userId');
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getEmergencyContacts(String userId) async {
    try {
      // ลองหาข้อมูลผู้ใช้ด้วยวิธีต่างๆ
      
      // 1. ค้นหาโดยใช้ userId
      QuerySnapshot usersQueryByUserId = await _firestore
          .collection('Users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (usersQueryByUserId.docs.isNotEmpty) {
        final userDoc = usersQueryByUserId.docs.first;
        
        // ดึงรายชื่อผู้ติดต่อฉุกเฉินจาก Firestore
        final contactsSnapshot = await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('EmergencyContacts')
            .get();
        
        return contactsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }
      
      // 2. ค้นหาโดยใช้ uid
      QuerySnapshot usersQueryByUid = await _firestore
          .collection('Users')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (usersQueryByUid.docs.isNotEmpty) {
        final userDoc = usersQueryByUid.docs.first;
        
        // ดึงรายชื่อผู้ติดต่อฉุกเฉินจาก Firestore
        final contactsSnapshot = await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('EmergencyContacts')
            .get();
        
        return contactsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }
      
      // 3. ค้นหาโดยตรงจาก document ID (ถ้า userId เป็น email)
      try {
        final contactsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('EmergencyContacts')
            .get();
        
        return contactsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      } catch (e) {
        print('Error getting emergency contacts directly: $e');
      }
      
      print('ไม่พบข้อมูลผู้ติดต่อฉุกเฉินสำหรับ userId: $userId');
      return [];
    } catch (e) {
      print('Error getting emergency contacts: $e');
      return [];
    }
  }

  Future<String> _saveSosHistory(
    String userId,
    Position position,
    List<String> sentNumbers,
    List<String> failedNumbers,
    String detectionSource,
  ) async {
    try {
      // สร้างข้อมูล SOS
      final sosData = {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
        'sentTo': sentNumbers,
        'failedTo': failedNumbers,
        'status': sentNumbers.isNotEmpty ? 'success' : 'failed',
        'detectionSource': detectionSource,
        'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
        'message': 'SOS ส่งเมื่อ ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        'recipients': sentNumbers,
        'userInfo': {
          'userId': userId,
        },
      };
      
      // บันทึกลงฐานข้อมูล
      final docRef = await _firestore.collection('sos_history').add(sosData);

      try {
        // ค้นหา document ID ของผู้ใช้ (email)
        String? email = await _getEmailFromUserId(userId);
        
        if (email != null) {
          // บันทึกลง user document ด้วย email
          await _firestore.collection('Users').doc(email).collection('sos_history').doc(docRef.id).set(sosData);
          print('บันทึกประวัติ SOS ใน Users/$email/sos_history เรียบร้อย');
        } else {
          // พยายามบันทึกโดยตรงด้วย userId
          await _firestore.collection('Users').doc(userId).collection('sos_history').doc(docRef.id).set(sosData);
          print('บันทึกประวัติ SOS ใน Users/$userId/sos_history เรียบร้อย');
        }
      } catch (e) {
        print('ไม่สามารถบันทึกประวัติ SOS ใน Users collection: $e');
        // ไม่ throw exception เพื่อให้ฟังก์ชันยังทำงานต่อได้ แม้จะไม่สามารถบันทึกลง user document
      }
      
      return docRef.id;
    } catch (e) {
      print('Error saving SOS history: $e');
      rethrow; // ส่งต่อ error
    }
  }

  Future<List<SosLog>> getSosLogs(String userId) async {
    try {
      final email = await _getEmailFromUserId(userId);
      if (email == null) {
        return [];
      }

      // ลองดึงข้อมูลจากคอลเลกชัน sos_events ก่อน
      QuerySnapshot eventsSnapshot = await _firestore
          .collection('Users')
          .doc(email)
          .collection('sos_events')
          .orderBy('timestamp', descending: true)
          .get();

      if (eventsSnapshot.docs.isNotEmpty) {
        print('พบข้อมูลประวัติ SOS จำนวน ${eventsSnapshot.docs.length} รายการในคอลเลกชัน sos_events');
        return eventsSnapshot.docs
            .map((doc) => SosLog.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      }

      // ถ้าไม่พบข้อมูลใน sos_events ให้ลองดึงจาก sos_logs (เผื่อเป็นข้อมูลเก่า)
      QuerySnapshot logsSnapshot = await _firestore
          .collection('Users')
          .doc(email)
          .collection('sos_logs')
          .orderBy('timestamp', descending: true)
          .get();

      print('พบข้อมูลประวัติ SOS จำนวน ${logsSnapshot.docs.length} รายการในคอลเลกชัน sos_logs');
      return logsSnapshot.docs
          .map((doc) => SosLog.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } on Exception catch (e) {
      debugPrint('Error loading SOS logs: $e');
      return [];
    }
  }

  // เพิ่มฟังก์ชันสำหรับลบประวัติการแจ้งเหตุ
  Future<bool> deleteSosLog(String userId, String sosLogId) async {
    try {
      final email = await _getEmailFromUserId(userId);
      if (email == null) {
        debugPrint('Cannot delete SOS log: User email not found for userId: $userId');
        return false;
      }

      bool success = false;

      try {
        // ลองลบจากคอลเลกชัน sos_events ก่อน
        await _firestore
            .collection('Users')
            .doc(email)
            .collection('sos_events')
            .doc(sosLogId)
            .delete();
        
        debugPrint('SOS log deleted successfully from sos_events: $sosLogId');
        success = true;
      } catch (e) {
        debugPrint('Error or not found when deleting from sos_events: $e');
      }

      try {
        // ลองลบจากคอลเลกชัน sos_logs (เผื่อเป็นข้อมูลเก่า)
        await _firestore
            .collection('Users')
            .doc(email)
            .collection('sos_logs')
            .doc(sosLogId)
            .delete();
        
        debugPrint('SOS log deleted successfully from sos_logs: $sosLogId');
        success = true;
      } catch (e) {
        debugPrint('Error or not found when deleting from sos_logs: $e');
      }
      
      return success;
    } on Exception catch (e) {
      debugPrint('Error deleting SOS log: $e');
      return false;
    }
  }
}