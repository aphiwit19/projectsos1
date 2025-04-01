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

  Future<Map<String, dynamic>> sendSos(String userId) async {
    try {
      // 1. ตรวจสอบว่ามีการล็อกอินหรือไม่
      if (userId.isEmpty) {
        debugPrint('User not logged in');
        return {
          'success': false,
          'message': 'กรุณาล็อกอินก่อนใช้งาน',
        };
      }

      // 2. ค้นหา email ของผู้ใช้
      String? senderEmail = await _getEmailFromUserId(userId);
      if (senderEmail == null) {
        debugPrint('Email not found for userId: $userId');
        return {
          'success': false,
          'message': 'ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่',
        };
      }
      debugPrint('Sender email: $senderEmail');

      // 3. ดึงข้อมูลผู้ใช้
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(senderEmail).get();
      if (!userDoc.exists) {
        debugPrint('User profile not found for email: $senderEmail');
        return {
          'success': false,
          'message': 'ไม่พบข้อมูลโปรไฟล์ผู้ใช้',
        };
      }

      UserProfile userProfile = UserProfile.fromJson(userDoc.data() as Map<String, dynamic>);
      debugPrint('User profile loaded: ${userProfile.fullName}');

      // 4. ดึงตำแหน่งปัจจุบัน
      Position? position;
      String mapLink = "ไม่สามารถระบุตำแหน่งได้";
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );
          debugPrint('Position: ${position.latitude}, ${position.longitude}');
          mapLink = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
        } else {
          debugPrint('Location permission denied');
        }
      } catch (e) {
        debugPrint('Error getting position: $e');
      }

      // 5. ดึงรายชื่อผู้ติดต่อฉุกเฉิน
      QuerySnapshot contactsSnapshot = await _firestore
          .collection('Users')
          .doc(senderEmail)
          .collection('EmergencyContacts')
          .get();

      List<EmergencyContact> contacts = contactsSnapshot.docs
          .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      if (contacts.isEmpty) {
        debugPrint('No emergency contacts found for email: $senderEmail');
        return {
          'success': false,
          'message': 'ไม่พบผู้ติดต่อฉุกเฉิน กรุณาเพิ่มผู้ติดต่อก่อนส่ง SOS',
        };
      }
      debugPrint('Found ${contacts.length} emergency contacts');

      // 6. เตรียมข้อมูลสำหรับส่ง SMS
      final timestamp = Timestamp.now();
      final formattedTimestamp = DateFormat('yyyyMMddTHHmmss').format(timestamp.toDate());
      
      final recipients = <String>[];
      final phoneNumbers = <String>[];
      for (var contact in contacts) {
        recipients.add(contact.phone);
        phoneNumbers.add(contact.phone);
        debugPrint('Processing contact: ${contact.phone}');
      }

      // 7. ส่ง SMS
      bool anySmsSent = false;
      Map<String, dynamic> smsStatuses = {};
      try {
        // เปลี่ยนจาก bool เป็น SmsResult ที่มีข้อมูลละเอียดมากขึ้น
        final smsResult = await _smsService.sendSosMessage(userProfile, mapLink, phoneNumbers);
        debugPrint('SMS send result: $smsResult');
        
        // ตรวจสอบว่ามีการส่ง SMS สำเร็จอย่างน้อย 1 เบอร์หรือไม่
        anySmsSent = smsResult.statuses.values.any((status) => status == SmsStatus.success);
        
        // บันทึกสถานะการส่งของแต่ละเบอร์เพื่อเก็บในฐานข้อมูล
        smsResult.statuses.forEach((phone, status) {
          smsStatuses[phone] = status.toString().split('.').last; // แปลง enum เป็น string (success, failed, pending)
        });
        
        debugPrint('Any SMS sent successfully: $anySmsSent');
        
        // ถ้าไม่มีการส่ง SMS สำเร็จเลย
        if (!anySmsSent) {
          debugPrint('No SMS was sent successfully');
          
          // ตรวจสอบว่ามีการส่งที่อยู่ระหว่างดำเนินการ (pending) หรือไม่
          bool hasPending = smsResult.statuses.values.any((status) => status == SmsStatus.pending);
          if (hasPending) {
            debugPrint('Some SMS are still pending');
          }
        }
      } catch (smsError) {
        debugPrint('Failed to send SMS: $smsError');
        // ไม่ throw Exception ที่นี่เพื่อให้โค้ดทำงานต่อไปได้
      }

      // 8. บันทึกประวัติการส่ง SOS - บันทึกเฉพาะเมื่อส่ง SMS สำเร็จอย่างน้อย 1 เบอร์
      if (anySmsSent) {
        String sanitizedFullName = _sanitizeName(userProfile.fullName ?? 'unknown');
        String customSosId = 'sos_${sanitizedFullName}_$formattedTimestamp';
        int sosSequence = 0;
        final sosLogsRef = _firestore.collection('Users').doc(senderEmail).collection('sos_logs');
        
        // ตรวจสอบว่ามีไอดีซ้ำหรือไม่
        while (true) {
          final existingSosDoc = await sosLogsRef.doc(customSosId).get();
          if (!existingSosDoc.exists) break;
          sosSequence++;
          customSosId = 'sos_${sanitizedFullName}_${formattedTimestamp}_$sosSequence';
        }

        // สร้างข้อความ SOS ด้วย SMS Service
        final sosMessage = _smsService.createSosMessage(userProfile, mapLink);
        
        // บันทึกข้อมูล SOS
        debugPrint('Saving SOS log for $senderEmail');
        await sosLogsRef.doc(customSosId).set({
          'timestamp': timestamp,
          'location': position != null
              ? {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
              : {
            'latitude': null,
            'longitude': null,
          },
          'mapLink': mapLink,
          'message': sosMessage,
          'userInfo': {
            'fullName': userProfile.fullName ?? 'ไม่ระบุ',
            'phone': userProfile.phone ?? 'ไม่ระบุ',
            'bloodType': userProfile.bloodType ?? 'ไม่ระบุ',
            'medicalConditions': userProfile.medicalConditions ?? 'ไม่ระบุ',
            'allergies': userProfile.allergies ?? 'ไม่ระบุ',
          },
          'recipients': recipients,
          'smsStatuses': smsStatuses, // เก็บสถานะการส่งของแต่ละเบอร์
          'anySmsSent': anySmsSent, // แทนที่ smsSent เดิม
          'smsTimestamp': timestamp, // เวลาที่ส่ง SMS
        });
        debugPrint('SOS log saved for $senderEmail');
        
        // ส่งคืนข้อมูลผลการบันทึก
        return {
          'success': true,
          'message': 'ส่ง SOS เรียบร้อยแล้ว',
          'logId': customSosId,
        };
      } else {
        // ไม่บันทึกประวัติเมื่อส่ง SMS ไม่สำเร็จ
        debugPrint('Not saving SOS log because no SMS was sent successfully');
        
        // ส่งคืนข้อมูลที่ระบุว่าไม่บันทึกประวัติ
        return {
          'success': false,
          'message': 'ไม่สามารถส่ง SMS ได้ กรุณาลองอีกครั้ง',
          'logId': null,
        };
      }
    } on Exception catch (e) {
      debugPrint('Error in sendSos: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการส่ง SOS: $e',
      };
    }
  }

  Future<List<SosLog>> getSosLogs(String userId) async {
    try {
      final email = await _getEmailFromUserId(userId);
      if (email == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(email)
          .collection('sos_logs')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
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

      // ลบเอกสารจาก Firestore
      await _firestore
          .collection('Users')
          .doc(email)
          .collection('sos_logs')
          .doc(sosLogId)
          .delete();
      
      debugPrint('SOS log deleted successfully: $sosLogId');
      return true;
    } on Exception catch (e) {
      debugPrint('Error deleting SOS log: $e');
      return false;
    }
  }
}