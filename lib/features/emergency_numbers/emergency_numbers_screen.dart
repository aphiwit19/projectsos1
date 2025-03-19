import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/home_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../emergency_contacts/emergency_contacts_screen.dart';
import '../profile/profile_screen.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  final List<Map<String, String>> emergencyNumbers = [
    {'category': 'เหตุด่วนเหตุร้าย', 'service': 'ตำรวจ', 'number': '191'},
    {'category': 'เหตุด่วนเหตุร้าย', 'service': 'สายด่วน 199', 'number': '199'},
    {'category': 'เหตุด่วนเหตุร้าย', 'service': 'กู้ภัยมูลนิธิ', 'number': '1196'},
    {'category': 'กรณีเจ็บป่วย', 'service': 'โรงพยาบาล', 'number': '1154'},
    {'category': 'กรณีเจ็บป่วย', 'service': 'สายด่วนปฐมพยาบาล', 'number': '1669'},
    {'category': 'กรณีเจ็บป่วย', 'service': 'สายด่วนพิษภัย', 'number': '1646'},
    {'category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'service': 'สายด่วนจราจร', 'number': '1586'},
    {'category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'service': 'สายด่วนกรมทางหลวง', 'number': '1197'},
    {'category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'service': 'สายด่วนกรมทางด่วน', 'number': '1137'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "เหตุด่วนเหตุร้าย",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...emergencyNumbers
              .where((number) => number['category'] == 'เหตุด่วนเหตุร้าย')
              .map((number) => _buildEmergencyTile(context, number['service']!, number['number']!))
              .toList(),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "กรณีเจ็บป่วย",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...emergencyNumbers
              .where((number) => number['category'] == 'กรณีเจ็บป่วย')
              .map((number) => _buildEmergencyTile(context, number['service']!, number['number']!))
              .toList(),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "แจ้งเหตุจราจร-ขอความช่วยเหลือ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...emergencyNumbers
              .where((number) => number['category'] == 'แจ้งเหตุจราจร-ขอความช่วยเหลือ')
              .map((number) => _buildEmergencyTile(context, number['service']!, number['number']!))
              .toList(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmergencyTile(BuildContext context, String service, String number) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.phone, color: Colors.red),
        title: Text(service),
        trailing: Text(number, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () async {
          // แสดง dialog ยืนยัน
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('โทรไปที่ $service'),
              content: Text('คุณต้องการโทรไปที่ $number หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('โทร'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final Uri dialUri = Uri.parse('tel:$number'); // ใช้ tel: เพื่อเปิดแอพโทรศัพท์

            try {
              print('Attempting to open dialer: $dialUri');
              if (await canLaunchUrl(dialUri)) {
                await launchUrl(
                  dialUri,
                  mode: LaunchMode.externalApplication, // บังคับให้เปิดในแอพโทรศัพท์
                );
                print('Dialer opened successfully');
              } else {
                print('Cannot launch $dialUri');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ไม่สามารถเปิดแอพโทรศัพท์ได้')),
                );
              }
            } catch (e) {
              print('Error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
              );
            }
          }
        },
      ),
    );
  }
}