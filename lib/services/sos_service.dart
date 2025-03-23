import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/current_location_model.dart';
import '../models/sms_log_model.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CurrentLocation> saveLocation(Position position) async {
    try {
      String? email = _auth.currentUser?.email;
      if (email == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }

      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('ไม่พบรหัสผู้ใช้');
      }

      // ใช้ userId เป็น ID ของเอกสาร
      DocumentReference docRef = _firestore.collection('Current_Locations').doc(userId);
      CurrentLocation location = CurrentLocation(
        locationId: userId,
        userId: userId,
        email: email,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await docRef.set({
        'locationId': location.locationId,
        'userId': location.userId,
        'email': location.email,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return location;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการบันทึกตำแหน่ง: $e');
    }
  }

  Future<void> logSms(
      CurrentLocation location,
      List<Map<String, dynamic>> contacts,
      String message,
      ) async {
    try {
      String? email = _auth.currentUser?.email;
      if (email == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }

      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('ไม่พบรหัสผู้ใช้');
      }

      for (var contact in contacts) {
        String customId = '${contact['contactId']}_${DateTime.now().millisecondsSinceEpoch}';
        DocumentReference docRef = _firestore
            .collection('Users')
            .doc(userId)
            .collection('SMS_Logs')
            .doc(customId);

        SMSLog smsLog = SMSLog(
          smsId: customId,
          userId: userId,
          email: email,
          locationId: location.locationId,
          contactId: contact['contactId'],
          recipientNumber: contact['phone'],
          messageContent: message,
          sentTime: DateTime.now(),
          latitude: location.latitude,
          longitude: location.longitude,
        );

        await docRef.set({
          'smsId': smsLog.smsId,
          'userId': smsLog.userId,
          'email': smsLog.email,
          'locationId': smsLog.locationId,
          'contactId': smsLog.contactId,
          'recipientNumber': smsLog.recipientNumber,
          'messageContent': smsLog.messageContent,
          'sentTime': FieldValue.serverTimestamp(),
          'latitude': smsLog.latitude,
          'longitude': smsLog.longitude,
        });
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการบันทึก SMS Logs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSmsLogs(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('SMS_Logs')
          .orderBy('sentTime', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['sentTime'] is Timestamp) {
          data['sentTime'] = (data['sentTime'] as Timestamp).toDate().toString();
        }
        return data;
      }).toList();
    } catch (e) {
      print('Error loading SMS logs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      String? email = _auth.currentUser?.email;
      if (email == null) {
        throw Exception('ไม่พบผู้ใช้ที่ล็อกอิน');
      }

      // เปลี่ยนจากใช้ uid เป็น email เพื่อให้สอดคล้องกับโครงสร้างปัจจุบันใน Firestore
      DocumentSnapshot doc = await _firestore.collection('Users').doc(email).get();
      if (!doc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้: $e');
    }
  }
}