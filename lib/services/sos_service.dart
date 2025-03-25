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

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    } on Exception catch (e) { // เปลี่ยนจาก catch (Object e) เป็น on Exception catch (e)
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

      final profileService = ProfileService();
      final userProfile = await profileService.getProfile(senderEmail);
      if (userProfile == null) {
        throw Exception('ไม่พบข้อมูลโปรไฟล์ผู้ใช้');
      }

      final locationService = LocationService();
      final position = await locationService.getCurrentLocation(context: null);
      String mapLink;
      if (position != null) {
        mapLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      } else {
        mapLink = 'ไม่สามารถดึงตำแหน่งได้ กรุณาเปิด GPS หรือให้สิทธิ์การเข้าถึงตำแหน่ง';
      }

      final messageText = 'ช่วยด้วย! ฉันต้องการความช่วยเหลือ\n'
          'ตำแหน่ง: $mapLink\n'
          'ข้อมูลผู้ใช้: ชื่อ: ${userProfile.fullName ?? 'ไม่ระบุ'}, '
          'เบอร์: ${userProfile.phone ?? 'ไม่ระบุ'}, '
          'กรุ๊ปเลือด: ${userProfile.bloodType ?? 'ไม่ระบุ'}, '
          'อาการป่วย: ${userProfile.medicalConditions ?? 'ไม่ระบุ'}, '
          'ภูมิแพ้: ${userProfile.allergies ?? 'ไม่ระบุ'}';

      final contactService = EmergencyContactService();
      final contacts = await contactService.getEmergencyContacts(user.uid);
      if (contacts.isEmpty) {
        throw Exception('ไม่มีผู้ติดต่อฉุกเฉิน');
      }

      final recipients = <String>[];
      final timestamp = Timestamp.now();
      final formattedTimestamp = DateFormat('yyyyMMddTHHmmss').format(timestamp.toDate());

      final senderChatsRef = _firestore.collection('Users').doc(senderEmail).collection('chats');
      for (var contact in contacts) {
        recipients.add(contact.phone);
        debugPrint('Processing contact: ${contact.phone}');

        String sanitizedContactPhone = contact.phone.replaceAll(RegExp(r'[/#\[\]\$]'), '_');
        String chatId = 'chat_$sanitizedContactPhone';

        final message = {
          'text': messageText,
          'isMe': true,
          'timestamp': timestamp,
          'status': 'sent',
        };

        await _firestore.runTransaction((transaction) async {
          final chatDocRef = senderChatsRef.doc(chatId);
          final chatDoc = await transaction.get(chatDocRef);

          if (chatDoc.exists) {
            final messages = List<Map<String, dynamic>>.from(chatDoc['messages'] ?? []);
            bool messageExists = messages.any((msg) =>
            msg['text'] == messageText &&
                (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                    timestamp.millisecondsSinceEpoch);

            if (!messageExists) {
              transaction.update(chatDocRef, {
                'messages': FieldValue.arrayUnion([message]),
                'lastMessage': messageText,
                'lastTimestamp': timestamp,
                'lastReadTimestamp': chatDoc['lastReadTimestamp'] ?? null,
              });
            }
          } else {
            transaction.set(chatDocRef, {
              'contactPhone': contact.phone,
              'contactName': contact.name,
              'messages': [message],
              'lastMessage': messageText,
              'lastTimestamp': timestamp,
              'lastReadTimestamp': null,
            });
          }
        });

        debugPrint('SOS saved to sender\'s chat: $senderEmail for contact: ${contact.phone}');

        final recipientEmail = await profileService.findUserByPhone(contact.phone);
        if (recipientEmail != null) {
          debugPrint('Sending SOS to recipient: $recipientEmail');
          final recipientChatsRef = _firestore.collection('Users').doc(recipientEmail).collection('chats');

          String sanitizedSenderPhone = (userProfile.phone ?? '').replaceAll(RegExp(r'[/#\[\]\$]'), '_');
          String recipientChatId = 'chat_$sanitizedSenderPhone';

          final recipientMessage = {
            'text': messageText,
            'isMe': false,
            'timestamp': timestamp,
            'status': 'delivered',
          };

          await _firestore.runTransaction((transaction) async {
            final recipientChatDocRef = recipientChatsRef.doc(recipientChatId);
            final recipientChatDoc = await transaction.get(recipientChatDocRef);

            if (recipientChatDoc.exists) {
              final messages = List<Map<String, dynamic>>.from(recipientChatDoc['messages'] ?? []);
              bool messageExists = messages.any((msg) =>
              msg['text'] == messageText &&
                  (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                      timestamp.millisecondsSinceEpoch);

              if (!messageExists) {
                transaction.update(recipientChatDocRef, {
                  'messages': FieldValue.arrayUnion([recipientMessage]),
                  'lastMessage': messageText,
                  'lastTimestamp': timestamp,
                  'lastReadTimestamp': recipientChatDoc['lastReadTimestamp'] ?? null,
                });
              }
            } else {
              transaction.set(recipientChatDocRef, {
                'contactPhone': userProfile.phone ?? 'ไม่ระบุ',
                'contactName': userProfile.fullName ?? 'ไม่ระบุ',
                'messages': [recipientMessage],
                'lastMessage': messageText,
                'lastTimestamp': timestamp,
                'lastReadTimestamp': null,
              });
            }
          });

          await _firestore.runTransaction((transaction) async {
            final chatDocRef = senderChatsRef.doc(chatId);
            final chatDoc = await transaction.get(chatDocRef);

            if (chatDoc.exists) {
              final messages = List<Map<String, dynamic>>.from(chatDoc['messages'] ?? []);
              final updatedMessages = messages.map((msg) {
                if (msg['text'] == messageText &&
                    (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                        timestamp.millisecondsSinceEpoch &&
                    msg['status'] == 'sent') {
                  return {
                    'text': messageText,
                    'isMe': true,
                    'timestamp': timestamp,
                    'status': 'delivered',
                  };
                }
                return msg;
              }).toList();

              transaction.update(chatDocRef, {
                'messages': updatedMessages,
              });
            }
          });

          debugPrint('SOS sent to $recipientEmail');
        } else {
          debugPrint('No account found for ${contact.phone}, only saved to sender\'s chat');
        }
      }

      String sanitizedFullName = _sanitizeName(userProfile.fullName ?? 'unknown');
      String customSosId = 'sos_${sanitizedFullName}_$formattedTimestamp';
      int sosSequence = 0;
      final sosLogsRef = _firestore.collection('Users').doc(senderEmail).collection('sos_logs');
      while (true) {
        final existingSosDoc = await sosLogsRef.doc(customSosId).get();
        if (!existingSosDoc.exists) break;
        sosSequence++;
        customSosId = 'sos_${sanitizedFullName}_${formattedTimestamp}_$sosSequence';
      }

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
        'message': 'ช่วยด้วย! ฉันต้องการความช่วยเหลือ',
        'userInfo': {
          'fullName': userProfile.fullName ?? 'ไม่ระบุ',
          'phone': userProfile.phone ?? 'ไม่ระบุ',
          'bloodType': userProfile.bloodType ?? 'ไม่ระบุ',
          'medicalConditions': userProfile.medicalConditions ?? 'ไม่ระบุ',
          'allergies': userProfile.allergies ?? 'ไม่ระบุ',
        },
        'recipients': recipients,
      });
      debugPrint('SOS log saved for $senderEmail');
    } on Exception catch (e) { // เปลี่ยนจาก catch (Object e) เป็น on Exception catch (e)
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
    } on Exception catch (e) { // เปลี่ยนจาก catch (Object e) เป็น on Exception catch (e)
      debugPrint('Error loading SOS logs: $e');
      return [];
    }
  }
}