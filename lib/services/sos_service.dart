// lib/services/sos_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../models/sos_log_model.dart';
import '../models/emergency_contact_model.dart';
import 'emergency_contact_service.dart';
import 'location_service.dart';
import 'profile_service.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    } catch (e) {
      throw Exception('Error getting email: $e');
    }
  }

  Future<void> sendSos() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }

      final senderEmail = await _getEmailFromUserId(user.uid);
      if (senderEmail == null) {
        throw Exception('ไม่พบอีเมลผู้ใช้');
      }

      // ดึงข้อมูลผู้ใช้ (ผู้ส่ง)
      final profileService = ProfileService();
      final userProfile = await profileService.getProfile(senderEmail);
      if (userProfile == null) {
        throw Exception('ไม่พบข้อมูลโปรไฟล์ผู้ใช้');
      }

      // ดึงตำแหน่งปัจจุบัน
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final mapLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      // สร้างข้อความ SOS
      final message = 'ช่วยด้วย! ฉันต้องการความช่วยเหลือ\n'
          'ตำแหน่ง: $mapLink\n'
          'ข้อมูลผู้ใช้: ชื่อ: ${userProfile.fullName}, '
          'เบอร์: ${userProfile.phone}, '
          'กรุ๊ปเลือด: ${userProfile.bloodType}, '
          'อาการป่วย: ${userProfile.medicalConditions}, '
          'ภูมิแพ้: ${userProfile.allergies}';

      // ดึงรายชื่อผู้ติดต่อฉุกเฉิน
      final contactService = EmergencyContactService();
      final contacts = await contactService.getEmergencyContacts(user.uid);
      if (contacts.isEmpty) {
        throw Exception('ไม่มีผู้ติดต่อฉุกเฉิน');
      }

      // เก็บรายชื่อผู้ติดต่อที่ได้รับการแจ้งเหตุ
      final recipients = <String>[];

      // ส่งข้อความไปยังแชทของผู้ติดต่อแต่ละคน
      final senderChatsRef = _firestore.collection('Users').doc(senderEmail).collection('chats');
      for (var contact in contacts) {
        recipients.add(contact.name);
        debugPrint('Processing contact: ${contact.name}, phone: ${contact.phone}');

        // บันทึกข้อความในแชทของผู้ส่ง (บัญชี A)
        await senderChatsRef.add({
          'contactPhone': contact.phone, // ใช้เบอร์โทรเป็นตัวระบุ
          'contactName': contact.name,  // เก็บชื่อเพื่อแสดงผล
          'text': message,
          'isMe': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint('SOS saved to sender\'s chat: $senderEmail for contact: ${contact.name}');

        // ตรวจสอบว่าผู้ติดต่อมีบัญชีในแอปหรือไม่
        final recipientEmail = await profileService.findUserByPhone(contact.phone);
        if (recipientEmail != null) {
          // ถ้ามีบัญชี ส่งข้อความไปยังแชทของผู้รับ
          debugPrint('Sending SOS to recipient: $recipientEmail');
          final recipientChatsRef = _firestore.collection('Users').doc(recipientEmail).collection('chats');
          await recipientChatsRef.add({
            'contactPhone': userProfile.phone, // ใช้เบอร์โทรของผู้ส่ง
            'contactName': userProfile.fullName, // ใช้ชื่อผู้ส่ง
            'text': message,
            'isMe': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint('SOS sent to $recipientEmail');
        } else {
          debugPrint('No account found for ${contact.phone}, only saved to sender\'s chat');
        }
      }

      // บันทึกประวัติการแจ้งเหตุ SOS
      debugPrint('Saving SOS log for $senderEmail');
      final sosLogsRef = _firestore.collection('Users').doc(senderEmail).collection('sos_logs');
      await sosLogsRef.add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'mapLink': mapLink,
        'message': 'ช่วยด้วย! ฉันต้องการความช่วยเหลือ',
        'userInfo': {
          'fullName': userProfile.fullName,
          'phone': userProfile.phone,
          'bloodType': userProfile.bloodType,
          'medicalConditions': userProfile.medicalConditions,
          'allergies': userProfile.allergies,
        },
        'recipients': recipients,
      });
      debugPrint('SOS log saved for $senderEmail');
    } catch (e) {
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
    } catch (e) {
      print('Error loading SOS logs: $e');
      return [];
    }
  }
}