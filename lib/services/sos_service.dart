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

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SmsService _smsService = SmsService();

  String _sanitizeName(String name) {
    return name
        .replaceAll(RegExp(r'[/#\[\]\$]'), '_')
        .replaceAll(' ', '_');
  }

  Future<String?> _getEmailFromUserId(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('Users')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return null;
      }
      return query.docs.first.id;
    } on Exception catch (e) {
      throw Exception('Error getting email: $e');
    }
  }

  Future<void> sendSos() async {
    try {
      // 1. ตรวจสอบการล็อกอิน
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }

      // 2. ดึงข้อมูลอีเมลผู้ใช้
      final senderEmail = await _getEmailFromUserId(user.uid);
      if (senderEmail == null) {
        throw Exception('ไม่พบอีเมลผู้ใช้');
      }

      // 3. ดึงข้อมูลโปรไฟล์
      final profileService = ProfileService();
      final userProfile = await profileService.getProfile(senderEmail);
      if (userProfile == null) {
        throw Exception('ไม่พบข้อมูลโปรไฟล์ผู้ใช้');
      }

      // 4. ดึงข้อมูลตำแหน่ง
      final locationService = LocationService();
      final position = await locationService.getBestLocation(context: null);
      String mapLink;
      if (position != null) {
        mapLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      } else {
        mapLink = 'ไม่สามารถดึงตำแหน่งได้ กรุณาเปิด GPS หรือให้สิทธิ์การเข้าถึงตำแหน่ง';
      }

      // 5. ดึงรายชื่อผู้ติดต่อฉุกเฉิน
      final contactService = EmergencyContactService();
      final contacts = await contactService.getEmergencyContacts(user.uid);
      if (contacts.isEmpty) {
        throw Exception('ไม่มีผู้ติดต่อฉุกเฉิน');
      }

      // 6. เตรียมข้อมูลสำหรับการส่ง SMS และบันทึก
      final recipients = <String>[];
      final phoneNumbers = <String>[];
      for (var contact in contacts) {
        recipients.add(contact.phone);
        phoneNumbers.add(contact.phone);
        debugPrint('Processing contact: ${contact.phone}');
      }

      final timestamp = Timestamp.now();
      final formattedTimestamp = DateFormat('yyyyMMddTHHmmss').format(timestamp.toDate());
      
      // 7. ส่ง SMS
      bool smsSent = false;
      try {
        smsSent = await _smsService.sendSosMessage(userProfile, mapLink, phoneNumbers);
        debugPrint('SMS sent to all emergency contacts: $smsSent');
      } catch (smsError) {
        debugPrint('Failed to send SMS: $smsError');
        // ไม่ throw Exception ที่นี่เพื่อให้โค้ดทำงานต่อไปได้
      }

      // 8. บันทึกประวัติการส่ง SOS
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
        'smsSent': smsSent,
      });
      debugPrint('SOS log saved for $senderEmail');
    } on Exception catch (e) {
      debugPrint('Error in sendSos: $e');
      throw Exception('เกิดข้อผิดพลาดในการส่ง SOS: $e');
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
}