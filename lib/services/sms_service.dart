import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';
import 'package:intl/intl.dart';

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
  
  // แปลง SmsStatus เป็น String สำหรับแสดงผล
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
  
  // แปลง SmsResult เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toJson() {
    return {
      'allSuccess': allSuccess,
      'errorMessage': errorMessage,
      'statuses': statuses.map((phone, status) => 
          MapEntry(phone, statusToString(status))),
    };
  }
}

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;

  // API Key ของแอพ
  final String _username = 'YOUR_SMS_USERNAME'; // ใส่ Username ของ SMS Gateway
  final String _password = 'YOUR_SMS_PASSWORD'; // ใส่ Password ของ SMS Gateway
  final String _sender = 'YOUR_SENDER_NAME'; // ใส่ชื่อผู้ส่ง
  final String _apiUrl = 'https://api.thsms.com/v1/send';

  SmsService._internal();

  // เมธอดสำหรับตรวจสอบเครดิต
  Future<Map<String, dynamic>> checkCredit() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.thsms.com/v1/credit'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'credit': data['credit'] ?? 0,
        };
      }

      return {
        'success': false,
        'error': 'ไม่สามารถตรวจสอบเครดิตได้ (${response.statusCode})',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'เกิดข้อผิดพลาดในการตรวจสอบเครดิต: $e',
      };
    }
  }

  // สร้างข้อความ SOS หลัก (แบบสั้นสำหรับทดสอบ)
  String createSosMessage(UserProfile user, String positionLink) {
    return "เหตุฉุกเฉิน";
  }

  // สร้างข้อความที่มีข้อมูลทางการแพทย์ (แบบสั้นสำหรับทดสอบ)
  String createMedicalInfoMessage(UserProfile user) {
    return "เหตุฉุกเฉิน";
  }
  
  // ส่งข้อความ SOS ไปยังผู้ติดต่อฉุกเฉินทั้งหมด
  Future<SmsResult> sendSosMessage(UserProfile userProfile, String mapLink, List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) {
        throw Exception('ไม่มีเบอร์โทรศัพท์ผู้ติดต่อฉุกเฉิน');
      }
      
      // ข้อความหลักที่สั้นและสำคัญที่สุด
      String primaryMessage = createSosMessage(userProfile, mapLink);
      
      // ข้อความเสริมสำหรับข้อมูลทางการแพทย์
      String medicalMessage = createMedicalInfoMessage(userProfile);
      
      // ส่งข้อความหลักที่สำคัญก่อน
      SmsResult mainResult = await sendBulkSms(phoneNumbers, primaryMessage);
      bool hasSentSecondary = false;
      
      // หากการส่งข้อความหลักสำเร็จ ให้ส่งข้อความเพิ่มเติม
      if (mainResult.allSuccess || mainResult.statuses.values.contains(SmsStatus.success)) {
        await Future.delayed(Duration(seconds: 2)); // รอสักครู่ก่อนส่งข้อความถัดไป
        SmsResult medicalResult = await sendBulkSms(
          phoneNumbers.where((phone) => 
            mainResult.statuses[phone] == SmsStatus.success).toList(), 
          medicalMessage
        );
        hasSentSecondary = true;
        
        // รวมผลลัพธ์
        Map<String, SmsStatus> combinedStatuses = Map.from(mainResult.statuses);
        medicalResult.statuses.forEach((phone, status) {
          if (combinedStatuses[phone] == SmsStatus.success && status != SmsStatus.success) {
            combinedStatuses[phone] = SmsStatus.pending; // ถ้าส่งข้อความแรกได้แต่ข้อความที่สองไม่ได้
          }
        });
        
        return SmsResult(
          allSuccess: mainResult.allSuccess && medicalResult.allSuccess,
          statuses: combinedStatuses,
          errorMessage: mainResult.errorMessage.isNotEmpty ? mainResult.errorMessage : medicalResult.errorMessage,
        );
      }
      
      return mainResult;
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

  // เมธอดสำหรับส่ง SMS ไปยังหมายเลขเดียว
  Future<SmsResult> sendSms(String phoneNumber, String message) async {
    try {
      debugPrint('กำลังส่ง SMS ไปยัง $phoneNumber');
      debugPrint('ข้อความ: $message');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
        },
        body: json.encode({
          'sender': _sender,
          'message': message,
          'to': phoneNumber,
        }),
      );
      
      debugPrint('ผลการส่ง SMS: ${response.statusCode}');
      debugPrint('ข้อความตอบกลับ: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return SmsResult(
            allSuccess: true,
            statuses: Map.fromIterable(
              [phoneNumber],
              key: (phone) => phone,
              value: (_) => SmsStatus.success
            ),
            errorMessage: 'ส่ง SMS สำเร็จ',
          );
        } else {
          return SmsResult(
            allSuccess: false,
            statuses: Map.fromIterable(
              [phoneNumber],
              key: (phone) => phone,
              value: (_) => SmsStatus.failed
            ),
            errorMessage: data['message'] ?? 'ไม่ทราบสาเหตุ',
          );
        }
      }
      
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          [phoneNumber],
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'การเชื่อมต่อล้มเหลว (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          [phoneNumber],
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาดในการส่ง SMS: $e',
      );
    }
  }

  // ตรวจสอบว่าข้อความยาวเกินไปหรือไม่
  bool _isMessageTooLong(String message) {
    // ตรวจสอบว่ามีภาษาไทยหรือไม่
    bool containsThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(message);
    
    // ตรวจสอบตามเงื่อนไข
    if (containsThai) {
      return message.length > 70; // ภาษาไทยรวมกับภาษาอังกฤษ ไม่เกิน 70 ตัวอักษร
    } else {
      return message.length > 160; // ภาษาอังกฤษล้วน ไม่เกิน 160 ตัวอักษร
    }
  }
  
  // แบ่งข้อความยาวเป็นส่วนๆ
  List<String> _splitMessage(String message) {
    List<String> parts = [];
    bool containsThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(message);
    int maxLength = containsThai ? 70 : 160;
    int maxParts = 5; // จำกัดจำนวนข้อความที่จะส่งไม่เกิน 5 ข้อความ
    
    // หากข้อความยาวมาก ให้ตัดเนื้อหาบางส่วนออก
    if (message.length > maxLength * maxParts) {
      message = message.substring(0, maxLength * maxParts - 3) + '...';
    }
    
    // แบ่งข้อความ
    for (int i = 0; i < message.length; i += maxLength) {
      int end = i + maxLength;
      if (end > message.length) end = message.length;
      
      String part = message.substring(i, end);
      
      // เพิ่มส่วนต่อของข้อความ (ถ้าไม่ใช่ข้อความสุดท้าย)
      if (end < message.length && parts.length < maxParts - 1) {
        parts.add('(${parts.length + 1}/${(message.length / maxLength).ceil()}) $part');
      } else if (parts.isNotEmpty) {
        // ข้อความสุดท้าย
        parts.add('(${parts.length + 1}/${parts.length + 1}) $part');
      } else {
        // มีเพียงข้อความเดียว
        parts.add(part);
      }
      
      // ถ้าแบ่งครบจำนวนข้อความสูงสุดแล้วให้หยุด
      if (parts.length >= maxParts) break;
    }
    
    return parts;
  }

  // เมธอดสำหรับส่ง SMS แบบกลุ่ม
  Future<SmsResult> sendBulkSms(List<String> phoneNumbers, String message) async {
    try {
      if (phoneNumbers.isEmpty) {
        return SmsResult(
          allSuccess: false,
          statuses: {},
          errorMessage: 'ไม่มีเบอร์โทรศัพท์ที่ต้องการส่ง',
        );
      }

      // ตรวจสอบเครดิตก่อนส่ง
      final creditCheck = await checkCredit();
      debugPrint('ผลการตรวจสอบเครดิต: $creditCheck');
      
      if (!creditCheck['hasCredit']) {
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.failed
          ),
          errorMessage: 'เครดิตไม่เพียงพอ: ${creditCheck['credit']} เครดิต',
        );
      }

      // จัดรูปแบบเบอร์โทรศัพท์
      List<String> formattedPhones = phoneNumbers.map((phone) {
        String formatted = phone.replaceAll('-', '').replaceAll(' ', '');
        if (formatted.startsWith('0')) {
          return formatted.substring(1); // ตัด 0 ออก
        }
        return formatted;
      }).toList();

      debugPrint('กำลังส่ง SMS ไปยังเบอร์: $formattedPhones');
      debugPrint('ข้อความที่ส่ง: $message');
      debugPrint('ใช้ Sender Name: $_sender');

      Map<String, SmsStatus> statuses = {};
      bool allSuccess = true;
      String errorMessage = '';

      // ส่ง SMS ทีละเบอร์
      for (String phone in formattedPhones) {
        try {
          debugPrint('กำลังส่ง SMS ไปยังเบอร์: $phone');
          
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'sender': _sender,
              'message': message,
              'to': phone,
            }),
          );

          debugPrint('ผลการส่ง SMS: ${response.statusCode}');
          debugPrint('ข้อความตอบกลับ: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData['status'] == 'success') {
              statuses[phoneNumbers[formattedPhones.indexOf(phone)]] = SmsStatus.success;
              debugPrint('ส่ง SMS สำเร็จ: $phone');
            } else {
              statuses[phoneNumbers[formattedPhones.indexOf(phone)]] = SmsStatus.failed;
              allSuccess = false;
              errorMessage = 'ส่ง SMS ไม่สำเร็จ: ${responseData['message']}';
              debugPrint('ส่ง SMS ไม่สำเร็จ: $phone - ${responseData['message']}');
            }
          } else {
            statuses[phoneNumbers[formattedPhones.indexOf(phone)]] = SmsStatus.failed;
            allSuccess = false;
            errorMessage = 'ส่ง SMS ไม่สำเร็จ (${response.statusCode}): ${response.body}';
            debugPrint('ส่ง SMS ไม่สำเร็จ: $phone - $errorMessage');
          }
        } catch (e) {
          statuses[phoneNumbers[formattedPhones.indexOf(phone)]] = SmsStatus.failed;
          allSuccess = false;
          errorMessage = 'เกิดข้อผิดพลาดในการส่ง SMS: $e';
          debugPrint('เกิดข้อผิดพลาด: $phone - $e');
        }
      }

      return SmsResult(
        allSuccess: allSuccess,
        statuses: statuses,
        errorMessage: errorMessage,
      );
    } catch (e) {
      debugPrint('Error sending bulk SMS: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          phoneNumbers,
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาดในการส่งข้อความ: $e',
      );
    }
  }
  
  // เมธอดสำหรับส่งข้อความยาว โดยแบ่งเป็นส่วนๆ
  Future<SmsResult> _sendLongMessage(List<String> phoneNumbers, String message) async {
    List<String> messageParts = _splitMessage(message);
    
    bool allSuccess = true;
    String errorMessage = '';
    Map<String, SmsStatus> combinedStatuses = {};
    
    // เริ่มต้นด้วยการกำหนดให้ทุกเบอร์มีสถานะสำเร็จ
    for (String phone in phoneNumbers) {
      combinedStatuses[phone] = SmsStatus.success;
    }
    
    // ส่งทีละส่วน
    for (String part in messageParts) {
      // รอเวลาเล็กน้อยระหว่างการส่งแต่ละข้อความ
      if (messageParts.indexOf(part) > 0) {
        await Future.delayed(Duration(seconds: 2));
      }
      
      SmsResult result = await _sendSimpleBulkSms(phoneNumbers, part);
      
      // อัปเดตสถานะ
      if (!result.allSuccess) {
        allSuccess = false;
        if (result.errorMessage.isNotEmpty) {
          errorMessage = result.errorMessage;
        }
      }
      
      // อัปเดตสถานะของแต่ละเบอร์
      result.statuses.forEach((phone, status) {
        // ถ้าเบอร์ใดเบอร์หนึ่งล้มเหลว ให้ถือว่าทั้งหมดล้มเหลว
        if (status != SmsStatus.success && combinedStatuses[phone] == SmsStatus.success) {
          combinedStatuses[phone] = status;
        }
      });
      
      // ถ้ามีเบอร์ใดเบอร์หนึ่งที่เครดิตหมด ให้หยุดการส่งทันที
      if (result.statuses.values.contains(SmsStatus.noCredit)) {
        break;
      }
    }
    
    return SmsResult(
      allSuccess: allSuccess,
      statuses: combinedStatuses,
      errorMessage: errorMessage,
    );
  }
  
  // เมธอดสำหรับส่ง SMS จำนวนมาก (เกิน 500 เบอร์)
  Future<SmsResult> _sendLargeBulkMessage(List<String> phoneNumbers, String message) async {
    bool allSuccess = true;
    String errorMessage = '';
    Map<String, SmsStatus> combinedStatuses = {};
    
    // แบ่งรายการเบอร์โทรเป็นชุดๆ ละไม่เกิน 500 เบอร์
    List<List<String>> batches = [];
    
    for (int i = 0; i < phoneNumbers.length; i += 500) {
      int end = i + 500;
      if (end > phoneNumbers.length) end = phoneNumbers.length;
      batches.add(phoneNumbers.sublist(i, end));
    }
    
    // ส่งแต่ละชุด
    for (List<String> batch in batches) {
      // ถ้าเป็นชุดแรก ส่งทันที
      if (batches.indexOf(batch) == 0) {
        SmsResult result = await _sendSimpleBulkSms(batch, message);
        
        // อัปเดตสถานะ
        result.statuses.forEach((phone, status) {
          combinedStatuses[phone] = status;
        });
        
        if (!result.allSuccess) {
          allSuccess = false;
          if (result.errorMessage.isNotEmpty) {
            errorMessage = result.errorMessage;
          }
        }
        
        // หากเครดิตหมด ให้หยุดการส่งทันที
        if (result.statuses.values.contains(SmsStatus.noCredit)) {
          // กำหนดสถานะเครดิตหมดให้กับเบอร์ที่เหลือ
          for (int i = 1; i < batches.length; i++) {
            for (String phone in batches[i]) {
              combinedStatuses[phone] = SmsStatus.noCredit;
            }
          }
          break;
        }
      } else {
        // ชุดถัดไปใช้การส่งแบบตั้งเวลา (อย่างน้อย 15 นาทีหลังจากเวลาปัจจุบัน)
        DateTime now = DateTime.now();
        DateTime scheduledTime = now.add(Duration(minutes: 15 + batches.indexOf(batch)));
        
        SmsResult result = await _sendScheduledBulkSms(batch, message, scheduledTime);
        
        // อัปเดตสถานะ
        result.statuses.forEach((phone, status) {
          combinedStatuses[phone] = status;
        });
        
        if (!result.allSuccess) {
          allSuccess = false;
          if (result.errorMessage.isNotEmpty && errorMessage.isEmpty) {
            errorMessage = result.errorMessage;
          }
        }
      }
    }
    
    return SmsResult(
      allSuccess: allSuccess,
      statuses: combinedStatuses,
      errorMessage: errorMessage,
    );
  }
  
  // ส่ง SMS แบบกลุ่มโดยไม่มีการแบ่งข้อความหรือการตรวจสอบพิเศษ
  Future<SmsResult> _sendSimpleBulkSms(List<String> phoneNumbers, String message) async {
    try {
      if (phoneNumbers.isEmpty) {
        throw Exception('ไม่มีหมายเลขโทรศัพท์ที่จะส่ง');
      }

      // ตรวจสอบเครดิตก่อนการส่ง
      final creditInfo = await checkCredit();
      
      if (!creditInfo['hasCredit']) {
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.noCredit
          ),
          errorMessage: 'ไม่สามารถส่ง SMS ได้เนื่องจากเครดิตหมด',
        );
      }

      List<String> formattedPhones = phoneNumbers.map((phone) {
        String formatted = phone.replaceAll('-', '').replaceAll(' ', '');
        if (formatted.startsWith('0')) {
          return formatted.substring(1); // ตัด 0 ออก
        }
        return formatted;
      }).toList();
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender': _sender,
          'message': message,
          'to': formattedPhones.join(','),
        }),
      );
      
      if (response.statusCode == 200) {
        return SmsResult(
          allSuccess: true,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.success
          ),
        );
      } else {
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.failed
          ),
          errorMessage: 'ส่ง SMS ไม่สำเร็จ: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          phoneNumbers, 
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาด: $e',
      );
    }
  }
  
  // ส่ง SMS แบบตั้งเวลา สำหรับการส่งเบอร์จำนวนมาก
  Future<SmsResult> _sendScheduledBulkSms(List<String> phoneNumbers, String message, DateTime scheduledTime) async {
    try {
      if (phoneNumbers.isEmpty) {
        throw Exception('ไม่มีหมายเลขโทรศัพท์ที่จะส่ง');
      }

      // ตรวจสอบเครดิตก่อนการส่ง
      final creditInfo = await checkCredit();
      
      if (!creditInfo['hasCredit']) {
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.noCredit
          ),
          errorMessage: 'ไม่สามารถส่ง SMS ได้เนื่องจากเครดิตหมด',
        );
      }

      List<String> formattedPhones = phoneNumbers.map((phone) {
        String formatted = phone.replaceAll('-', '').replaceAll(' ', '');
        if (formatted.startsWith('0')) {
          return formatted.substring(1); // ตัด 0 ออก
        }
        return formatted;
      }).toList();
      
      // แปลงวันที่เวลาให้อยู่ในรูปแบบที่ API ต้องการ
      String formattedDateTime = "${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')} ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00";
      
      debugPrint('ตั้งเวลาส่ง SMS: $formattedDateTime');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender': _sender,
          'message': message,
          'to': formattedPhones.join(','),
          'scheduled_delivery': formattedDateTime,
        }),
      );
      
      if (response.statusCode == 200) {
        return SmsResult(
          allSuccess: true,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.pending // ข้อความตั้งเวลาจะอยู่ในสถานะรอดำเนินการ
          ),
        );
      } else {
        return SmsResult(
          allSuccess: false,
          statuses: Map.fromIterable(
            phoneNumbers,
            key: (phone) => phone,
            value: (_) => SmsStatus.failed
          ),
          errorMessage: 'ส่ง SMS ไม่สำเร็จ: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending scheduled SMS: $e');
      return SmsResult(
        allSuccess: false,
        statuses: Map.fromIterable(
          phoneNumbers, 
          key: (phone) => phone,
          value: (_) => SmsStatus.failed
        ),
        errorMessage: 'เกิดข้อผิดพลาด: $e',
      );
    }
  }

  // คำนวณจำนวนเครดิตที่จะใช้ในการส่ง SMS
  int calculateCreditUsage(String message, int recipientCount) {
    // ตรวจสอบว่ามีภาษาไทยหรือไม่
    bool containsThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(message);
    
    // คำนวณจำนวนข้อความที่ต้องส่ง
    int messageCount = 1;
    if (containsThai) {
      messageCount = (message.length / 70).ceil();
    } else {
      messageCount = (message.length / 160).ceil();
    }
    
    // จำกัดไม่เกิน 5 ข้อความต่อการส่ง
    if (messageCount > 5) messageCount = 5;
    
    // คำนวณเครดิตที่ใช้ (1 ข้อความ x จำนวนเบอร์)
    return messageCount * recipientCount;
  }
  
  // คำนวณเครดิตที่ใช้สำหรับข้อความ SOS
  Future<Map<String, dynamic>> calculateSosCreditUsage(UserProfile userProfile, String mapLink, List<String> phoneNumbers) {
    String primaryMessage = createSosMessage(userProfile, mapLink);
    String medicalMessage = createMedicalInfoMessage(userProfile);
    
    int primaryCredit = calculateCreditUsage(primaryMessage, phoneNumbers.length);
    int medicalCredit = calculateCreditUsage(medicalMessage, phoneNumbers.length);
    
    return Future.value({
      'primaryMessage': primaryMessage,
      'medicalMessage': medicalMessage,
      'primaryCreditUsage': primaryCredit,
      'medicalCreditUsage': medicalCredit,
      'totalCreditUsage': primaryCredit + medicalCredit,
      'recipientCount': phoneNumbers.length,
    });
  }
} 