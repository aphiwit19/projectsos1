import 'package:flutter_sms/flutter_sms.dart';

class SmsService {
  Future<void> sendSms(List<String> recipients, String message) async {
    try {
      print('Sending SMS to $recipients with message: $message');
      String result = await sendSMS(
        message: message,
        recipients: recipients, // ต้องเป็น List<String>
        sendDirect: true,
      );
      print('SMS sent to $recipients: $result');
    } catch (e) {
      print('Failed to send SMS: $e');
      throw Exception('ไม่สามารถส่ง SMS ได้: $e');
    }
  }
}