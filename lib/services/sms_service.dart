import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

// เพิ่ม enum เพื่อแสดงสถานะการส่ง SMS ที่ละเอียดมากขึ้น
enum SmsStatus {
  success,   // ส่งสำเร็จ
  failed,    // ส่งไม่สำเร็จ
  pending,   // อยู่ระหว่างการส่ง/ไม่ทราบสถานะ
  noCredit   // เครดิตหมด
}

// สร้าง class เพื่อเก็บผลลัพธ์การส่ง SMS ที่มีรายละเอียดมากขึ้น
class SmsResult {
  final bool allSuccess;
  final Map<String, SmsStatus> statuses; // เก็บสถานะของแต่ละเบอร์
  final String errorMessage;

  SmsResult({
    required this.allSuccess,
    required this.statuses,
    this.errorMessage = '',
  });

  @override
  String toString() {
    return 'SmsResult(allSuccess: $allSuccess, statuses: $statuses, errorMessage: $errorMessage)';
  }
}

class SmsService {
  // ข้อมูลสำหรับเชื่อมต่อกับ API THSMS (V1)
  final String _apiUsername = 'apirebmp';
  final String _apiPassword = 'Aphiwit@2546';
  final String _apiUrl = 'https://thsms.com/api/rest';
  final String _sender = 'DirectSMS'; // ชื่อผู้ส่งที่ลงทะเบียนกับ THSMS

  // Token สำหรับ API V2 (เก็บไว้เผื่อต้องการใช้ในอนาคต)
  final String _apiTokenV2 = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC90aHNtcy5jb21cL21hbmFnZVwvYXBpLWtleSIsImlhdCI6MTc0MzQyNDM5MSwibmJmIjoxNzQzNDI1OTY4LCJqdGkiOiJrZ1htbmJVZFljR3J5YkY0Iiwic3ViIjoxMTE3MjYsInBydiI6IjIzYmQ1Yzg5NDlmNjAwYWRiMzllNzAxYzQwMDg3MmRiN2E1OTc2ZjcifQ.v3gfImvvTC3-A7sHaoXaHUXmkyElmZI8S4UYF_EiYzM';

  // เมธอดสำหรับเช็คเครดิต
  Future<Map<String, dynamic>> checkCredit() async {
    try {
      // ใช้ API V1 สำหรับตรวจสอบเครดิต
      final String creditUrl = '$_apiUrl?username=$_apiUsername&password=$_apiPassword&method=credit';
      
      debugPrint('ทดสอบการเชื่อมต่อ API: $creditUrl');
      
      final response = await http.get(Uri.parse(creditUrl));
      
      debugPrint('รหัสการตอบกลับ: ${response.statusCode}');
      debugPrint('ข้อมูลการตอบกลับ: ${response.body}');
      
      if (response.statusCode == 200) {
        // ตรวจสอบว่าการตอบกลับเป็น XML และมีสถานะ success หรือไม่
        if (response.body.contains('<status>success</status>')) {
          // แยกค่าเครดิตจาก XML
          final RegExp creditRegex = RegExp(r'<amount>(.*?)</amount>');
          final match = creditRegex.firstMatch(response.body);
          
          String credit = '0';
          if (match != null && match.groupCount >= 1) {
            credit = match.group(1) ?? '0';
          }
          
          return {
            'status': 'success',
            'credit': credit,
            'balance': credit,
            'hasCredit': double.tryParse(credit) != null && double.parse(credit) > 0,
          };
        } else {
          return {
            'status': 'error',
            'credit': '0',
            'balance': '0',
            'hasCredit': false,
            'message': 'การเชื่อมต่อล้มเหลว: ${response.body}'
          };
        }
      } else {
        return {
          'status': 'error',
          'credit': '0',
          'balance': '0',
          'hasCredit': false,
          'message': 'การเชื่อมต่อล้มเหลว (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      debugPrint('Error checking credit: $e');
      return {
        'status': 'error',
        'credit': '0',
        'balance': '0',
        'hasCredit': false,
        'message': 'เกิดข้อผิดพลาดในการตรวจสอบเครดิต: $e'
      };
    }
  }

  // สร้างข้อความ SOS จากข้อมูลผู้ใช้และตำแหน่ง
  String createSosMessage(UserProfile userProfile, String mapLink) {
    return '🚨 SOS! ฉุกเฉิน! ${userProfile.fullName ?? 'ผู้ใช้'} ต้องการความช่วยเหลือด่วน!\n\n'
        '👤 ข้อมูลผู้ใช้:\n'
        '- ชื่อ: ${userProfile.fullName ?? 'ไม่ระบุ'}\n'
        '- เบอร์โทร: ${userProfile.phone ?? 'ไม่ระบุ'}\n'
        '- กรุ๊ปเลือด: ${userProfile.bloodType ?? 'ไม่ระบุ'}\n'
        '- อาการป่วย: ${userProfile.medicalConditions ?? 'ไม่ระบุ'}\n'
        '- ภูมิแพ้: ${userProfile.allergies ?? 'ไม่ระบุ'}\n\n'
        '📍 พิกัดปัจจุบัน: $mapLink\n\n'
        'กดลิงก์ด้านบนเพื่อดูตำแหน่งบน Google Maps';
  }
  
  // ส่งข้อความ SOS ไปยังผู้ติดต่อฉุกเฉินทั้งหมด (แก้ไขให้ส่งคืน SmsResult)
  Future<SmsResult> sendSosMessage(UserProfile userProfile, String mapLink, List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) {
        throw Exception('ไม่มีเบอร์โทรศัพท์ผู้ติดต่อฉุกเฉิน');
      }
      
      String messageText = createSosMessage(userProfile, mapLink);
      return await sendBulkSms(phoneNumbers, messageText);
    } catch (e) {
      debugPrint('Error sending SOS message: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          phoneNumbers,
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาดในการส่งข้อความ SOS: $e',
      );
    }
  }

  // เมธอดสำหรับส่ง SMS ไปยังหมายเลขเดียว (แก้ไขให้ส่งคืน SmsResult)
  Future<SmsResult> sendSms(String phoneNumber, String message) async {
    return sendBulkSms([phoneNumber], message);
  }

  // เมธอดสำหรับส่ง SMS แบบกลุ่ม (API V1) (แก้ไขให้ส่งคืน SmsResult)
  Future<SmsResult> sendBulkSms(List<String> phoneNumbers, String message) async {
    try {
      if (phoneNumbers.isEmpty) {
        throw Exception('ไม่มีหมายเลขโทรศัพท์ที่จะส่ง');
      }

      // ตรวจสอบเครดิตก่อนการส่ง
      final creditInfo = await checkCredit();
      debugPrint('ข้อมูลเครดิต: $creditInfo');
      
      // ถ้าไม่มีเครดิต ให้ return ทันทีว่าไม่สามารถส่งได้
      if (!creditInfo['hasCredit']) {
        debugPrint('ไม่สามารถส่ง SMS ได้เนื่องจากเครดิตหมด');
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.noCredit
          ),
          errorMessage: 'ไม่สามารถส่ง SMS ได้เนื่องจากเครดิตหมด (คงเหลือ: ${creditInfo['credit']})',
        );
      }

      bool allSuccess = true;
      String errorMessage = '';
      Map<String, SmsStatus> statuses = {};
      
      for (final recipient in phoneNumbers) {
        // ตรวจสอบและแก้ไขรูปแบบเบอร์โทรศัพท์
        String formattedPhone = recipient.replaceAll('-', '').replaceAll(' ', '');
        if (formattedPhone.startsWith('+')) {
          formattedPhone = formattedPhone.substring(1);
        } else if (formattedPhone.startsWith('0')) {
          formattedPhone = '66${formattedPhone.substring(1)}';
        }
        
        debugPrint('กำลังส่ง SMS ไปยัง: $formattedPhone');
        debugPrint('ข้อความ: $message');
        debugPrint('ผู้ส่ง: $_sender');
        
        // สร้าง URL สำหรับส่ง SMS ตามเอกสาร V1
        final String encodedMessage = Uri.encodeComponent(message);
        final String sendUrl = '$_apiUrl?username=$_apiUsername&password=$_apiPassword&method=send&from=$_sender&to=$formattedPhone&message=$encodedMessage';
        
        debugPrint('URL การส่ง: $sendUrl');
        
        // ส่งคำขอไปยัง API
        final response = await http.get(Uri.parse(sendUrl));
        
        // พิมพ์รายละเอียดการตอบกลับจาก API
        debugPrint('รหัสการตอบกลับ: ${response.statusCode}');
        debugPrint('ข้อมูลการตอบกลับ: ${response.body}');
        
        if (response.statusCode == 200) {
          // THSMS ตอบกลับเป็น XML - ตรวจสอบกรณีต่างๆ
          if (response.body.contains('<status>success</status>')) {
            debugPrint('ส่ง SMS ไปยัง $formattedPhone สำเร็จ!');
            statuses[recipient] = SmsStatus.success;
          } else if (response.body.contains('not enough credit')) {
            // กรณีเครดิตไม่พอ
            debugPrint('เครดิตไม่เพียงพอในการส่ง SMS ไปยัง $formattedPhone');
            allSuccess = false;
            errorMessage = 'เครดิต SMS ไม่เพียงพอ';
            statuses[recipient] = SmsStatus.noCredit;
          } else {
            debugPrint('ส่ง SMS ไปยัง $formattedPhone ล้มเหลว: ${response.body}');
            allSuccess = false;
            errorMessage = response.body;
            
            // ตรวจสอบว่าเป็นสถานะกำลังส่งหรือล้มเหลว
            if (response.body.contains('queue') || response.body.contains('pending')) {
              statuses[recipient] = SmsStatus.pending;
            } else {
              statuses[recipient] = SmsStatus.failed;
            }
          }
        } else {
          debugPrint('เกิดข้อผิดพลาดในการส่ง SMS ไปยัง $formattedPhone - รหัสสถานะ: ${response.statusCode}');
          allSuccess = false;
          errorMessage = 'รหัสสถานะ: ${response.statusCode}, ข้อมูล: ${response.body}';
          statuses[recipient] = SmsStatus.failed;
        }
      }
      
      if (!allSuccess) {
        debugPrint('บางข้อความส่งไม่สำเร็จ: $errorMessage');
      }
      
      return SmsResult(
        allSuccess: allSuccess,
        statuses: statuses,
        errorMessage: errorMessage,
      );
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          phoneNumbers, 
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาดในการส่ง SMS: $e',
      );
    }
  }
} 