import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_log_model.dart'; // ปรับตามโครงสร้างโฟลเดอร์จริง

class HistoryScreen extends StatelessWidget {
  // ข้อมูลจำลอง (จะเปลี่ยนเป็น Firebase ในภายหลัง)
  final List<SMSLog> historyData = [
    SMSLog(
      smsId: '1',
      userId: 'user1',
      locationId: 'loc1',
      contactId: 'cont1',
      recipientNumber: '0991234567',
      messageContent: 'Help me!',
      sentTime: DateTime.now().toString(),
      latitude: 13.7563,
      longitude: 100.5018,
    ),
  ];

  void _sendSMS(String phone, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print('Could not launch SMS');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              alignment: Alignment.center,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "ประวัติการแจ้งเหตุ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ListView.builder(
              shrinkWrap: true, // ป้องกัน Overflow ใน SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // ปิดการเลื่อนซ้ำ
              itemCount: historyData.length,
              itemBuilder: (context, index) {
                final data = historyData[index];
                return Column(
                  children: [
                    Card(
                      elevation: 0,
                      color: const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.phone,
                          color: Color(0xFFE64646),
                          size: 20,
                        ),
                        title: Text(
                          data.recipientNumber, // แทน name ด้วย recipientNumber
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'ข้อความ: ${data.messageContent}\nเวลา: ${data.sentTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          _sendSMS(data.recipientNumber, data.messageContent);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}