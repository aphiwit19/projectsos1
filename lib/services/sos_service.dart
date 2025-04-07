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
      print('SOS Service: เริ่มต้นกระบวนการส่ง SOS สำหรับผู้ใช้ $userId (source: $detectionSource)');
      
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

      // สร้างข้อความ SOS แบบเดียวกันทุกประเภทการแจ้งเหตุ
      final userName = user['name'] ?? 'ผู้ใช้';
      final currentTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      
      // สร้างข้อความที่มีข้อมูลเพิ่มเติม
      final message = '''
🚨 SOS! ฉุกเฉิน! $userName ต้องการความช่วยเหลือด่วน!
เวลา: $currentTime
👤 ข้อมูลผู้ใช้:
- ชื่อ: ${user['name'] ?? 'ไม่ระบุ'}
- เบอร์โทร: ${user['phone'] ?? 'ไม่ระบุ'}
- กรุ๊ปเลือด: ${user['bloodType'] ?? 'ไม่ระบุ'}
- อาการป่วย: ${user['medicalConditions'] ?? 'ไม่ระบุ'}
- ภูมิแพ้: ${user['allergies'] ?? 'ไม่ระบุ'}
📍 พิกัดปัจจุบัน: $positionLink
${detectionSource == 'automatic' ? '[ระบบตรวจพบการล้ม]' : detectionSource == 'notification' ? '[ยืนยันจากการแจ้งเตือน]' : '[ผู้ใช้แจ้งเหตุฉุกเฉิน]'}
''';

      // รวบรวมเบอร์โทรจากผู้ติดต่อฉุกเฉิน
      List<String> phoneNumbers = [];
      for (final contact in contacts) {
        final phoneNumber = contact['phone'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          phoneNumbers.add(phoneNumber);
        }
      }
      
      if (phoneNumbers.isEmpty) {
        return {
          'success': false,
          'message': 'ไม่พบเบอร์โทรศัพท์ของผู้ติดต่อฉุกเฉิน',
        };
      }
      
      // ส่ง SMS โดยใช้ SMS Gateway API (sendBulkSms)
      print('SOS Service: กำลังส่ง SMS ผ่าน Gateway API...');
      final smsResult = await SmsService().sendBulkSms(phoneNumbers, message);
      
      // แยกเบอร์ที่ส่งสำเร็จและล้มเหลว
      List<String> sentNumbers = [];
      List<String> failedNumbers = [];
      
      smsResult.statuses.forEach((phone, status) {
        if (status == SmsStatus.success || status == SmsStatus.pending) {
          sentNumbers.add(phone);
        } else {
          failedNumbers.add(phone);
        }
      });
      
      print('SOS Service: ส่ง SMS สำเร็จ ${sentNumbers.length} เบอร์, ล้มเหลว ${failedNumbers.length} เบอร์');

      String sosId = "not_saved";
      
      // บันทึกประวัติการส่ง SOS เฉพาะเมื่อส่งสำเร็จอย่างน้อย 1 เบอร์ และไม่มีปัญหาเครดิตหมด
      if (sentNumbers.isNotEmpty && !smsResult.statuses.values.any((status) => status == SmsStatus.noCredit)) {
        print('SOS Service: กำลังบันทึกประวัติการส่ง SOS...');
        
        sosId = await _saveSosHistory(
          userId,
          position,
          sentNumbers,
          failedNumbers,
          detectionSource,
          smsResult,
        );
        
        print('SOS Service: บันทึกประวัติ SOS เรียบร้อย ID: $sosId');
      } else if (smsResult.statuses.values.any((status) => status == SmsStatus.noCredit)) {
        print('SOS Service: ไม่มีการบันทึกประวัติ SOS เนื่องจากเครดิต SMS Gateway หมด');
      } else {
        print('SOS Service: ไม่มีการบันทึกประวัติ SOS เนื่องจากส่ง SMS ไม่สำเร็จ');
      }
      
      // คืนค่าผลลัพธ์
      if (smsResult.statuses.values.any((status) => status == SmsStatus.noCredit)) {
        return {
          'success': false,
          'message': 'ไม่สามารถส่ง SMS เนื่องจากเครดิตหมด',
          'sentCount': 0,
          'failedCount': failedNumbers.length,
          'isCreditEmpty': true,
          'sosId': "not_saved",
        };
      } else if (sentNumbers.isNotEmpty || smsResult.statuses.values.any((status) => status == SmsStatus.pending)) {
        return {
          'success': true,
          'message': 'ส่ง SOS สำเร็จ ${sentNumbers.length} เบอร์',
          'sentCount': sentNumbers.length,
          'failedCount': failedNumbers.length,
          'sosId': sosId,
          'isCreditEmpty': false,
        };
      } else {
        return {
          'success': false,
          'message': 'ไม่สามารถส่ง SMS ไปยังผู้ติดต่อฉุกเฉินได้: ${smsResult.errorMessage}',
          'sentCount': 0,
          'failedCount': failedNumbers.length,
          'sosId': "not_saved",
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
    SmsResult smsResult,
  ) async {
    try {
      // บันทึกข้อมูลเฉพาะกรณีที่มีการส่ง SMS สำเร็จอย่างน้อย 1 เบอร์เท่านั้น
      if (sentNumbers.isEmpty) {
        // สร้าง ID ชั่วคราวแต่ไม่บันทึกข้อมูล เพราะส่ง SMS ไม่สำเร็จ
        return "not_saved_${DateTime.now().millisecondsSinceEpoch}";
      }
      
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
        'status': 'success', // ถ้ามาถึงตรงนี้แสดงว่าส่งสำเร็จแล้วอย่างน้อย 1 เบอร์
        'detectionSource': detectionSource,
        'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
        'message': 'SOS ส่งเมื่อ ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        'recipients': sentNumbers,
        'userInfo': {
          'userId': userId,
        },
        'smsGatewayResult': {
          'allSuccess': smsResult.allSuccess,
          'errorMessage': smsResult.errorMessage,
          'statuses': smsResult.statuses.map((phone, status) => MapEntry(phone, statusToString(status))),
        },
      };
      
      // บันทึกลงฐานข้อมูลกลาง (เป็นสำรองในกรณีที่ไม่สามารถบันทึกในระดับผู้ใช้ได้)
      final docRef = await _firestore.collection('sos_logs').add(sosData);

      try {
        // ค้นหา document ID ของผู้ใช้ (email)
        String? email = await _getEmailFromUserId(userId);
        
        if (email != null) {
          // บันทึกลง user document ด้วย email ในคอลเลกชัน sos_logs เท่านั้น
          await _firestore.collection('Users').doc(email).collection('sos_logs').doc(docRef.id).set(sosData);
          print('บันทึกประวัติ SOS ใน Users/$email/sos_logs เรียบร้อย');
        } else {
          // พยายามบันทึกโดยตรงด้วย userId ในคอลเลกชัน sos_logs เท่านั้น
          await _firestore.collection('Users').doc(userId).collection('sos_logs').doc(docRef.id).set(sosData);
          print('บันทึกประวัติ SOS ใน Users/$userId/sos_logs เรียบร้อย');
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
  
  // เพิ่มฟังก์ชันช่วยแปลง SmsStatus เป็น String
  String statusToString(SmsStatus status) {
    switch (status) {
      case SmsStatus.success:
        return 'success';
      case SmsStatus.failed:
        return 'failed';
      case SmsStatus.pending:
        return 'pending';
      case SmsStatus.noCredit:
        return 'no_credit';
      default:
        return 'unknown';
    }
  }

  Future<List<SosLog>> getSosLogs(String userId) async {
    try {
      final email = await _getEmailFromUserId(userId);
      if (email == null) {
        return [];
      }

      // ดึงข้อมูลจากคอลเลกชัน sos_logs เท่านั้น
      QuerySnapshot logsSnapshot = await _firestore
          .collection('Users')
          .doc(email)
          .collection('sos_logs')
          .orderBy('timestamp', descending: true)
          .get();

      if (logsSnapshot.docs.isEmpty) {
        print('ไม่พบข้อมูลประวัติ SOS ในคอลเลกชัน sos_logs');
        return [];
      }
      
      print('พบข้อมูลประวัติ SOS จำนวน ${logsSnapshot.docs.length} รายการในคอลเลกชัน sos_logs');
      
      // แปลงข้อมูลเป็น SosLog
      List<SosLog> allLogs = logsSnapshot.docs
          .map((doc) => SosLog.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // กรองเฉพาะข้อมูลที่ส่ง SMS สำเร็จ ไม่รวมกรณีเครดิตหมด
      allLogs = allLogs.where((log) {
        // กรณีเป็น UI event หรือ การเปิดหน้าจอยืนยัน
        if (log.extraData.containsKey('action')) {
          String action = log.extraData['action'].toString();
          if (action == 'sos_confirmation_opened' ||
              action.startsWith('ui_') ||
              action.contains('_screen')) {
            return false;
          }
        }
      
        // ตรวจสอบกรณีเครดิตหมด
        if (log.id.startsWith('not_saved_')) {
          return false;
        }
        
        // ตรวจสอบจากข้อมูล SMS Gateway
        if (log.extraData.containsKey('smsGatewayResult')) {
          var smsResult = log.extraData['smsGatewayResult'];
          if (smsResult is Map) {
            if (smsResult.containsKey('allSuccess') && smsResult['allSuccess'] == false) {
              // ถ้ามีข้อความเกี่ยวกับเครดิตหมด
              if (smsResult.containsKey('errorMessage') && 
                  smsResult['errorMessage'] is String && 
                  smsResult['errorMessage'].toString().toLowerCase().contains('credit')) {
                return false;
              }
              
              // ตรวจสอบว่ามีเบอร์ที่ส่งสำเร็จบ้างหรือไม่
              if (smsResult.containsKey('statuses') && 
                  smsResult['statuses'] is Map &&
                  !smsResult['statuses'].values.any((status) => status == 'success')) {
                return false;
              }
            }
          }
        }
        
        // ตรวจสอบจากฟิลด์ sentTo หรือ recipients
        bool hasSentNumbers = false;
        
        if (log.extraData.containsKey('sentTo') && log.extraData['sentTo'] is List) {
          hasSentNumbers = (log.extraData['sentTo'] as List).isNotEmpty;
        }
        
        if (!hasSentNumbers && log.recipients.isNotEmpty) {
          hasSentNumbers = true;
        }
        
        if (!hasSentNumbers) {
          return false;
        }
        
        // ตรวจสอบจากฟิลด์สถานะ
        if (log.extraData.containsKey('status')) {
          String status = log.extraData['status'].toString();
          if (status != 'success' && status != 'sent') {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      print('กรองแล้วพบประวัติ SOS ที่ส่งสำเร็จจำนวน ${allLogs.length} รายการ');
      return allLogs;
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
        // ลบจากคอลเลกชัน sos_logs (หลัก) ในระดับผู้ใช้
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
      
      // ลบจากคอลเลกชันกลาง sos_logs ด้วย (ถ้ามี)
      try {
        await _firestore
            .collection('sos_logs')
            .doc(sosLogId)
            .delete();
            
        debugPrint('SOS log deleted successfully from global sos_logs: $sosLogId');
        success = true;
      } catch (e) {
        debugPrint('Error or not found when deleting from global sos_logs: $e');
      }
      
      return success;
    } on Exception catch (e) {
      debugPrint('Error deleting SOS log: $e');
      return false;
    }
  }
}