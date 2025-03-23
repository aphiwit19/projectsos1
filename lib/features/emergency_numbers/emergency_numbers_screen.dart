import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // นำเข้าแพ็กเกจ Shimmer
import 'package:url_launcher/url_launcher.dart';
import '../../screens/home_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../emergency_contacts/emergency_contacts_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/emergency_number_service.dart';
import '../../models/emergency_number_model.dart';

class EmergencyNumbersScreen extends StatefulWidget {
  @override
  _EmergencyNumbersScreenState createState() => _EmergencyNumbersScreenState();
}

class _EmergencyNumbersScreenState extends State<EmergencyNumbersScreen> {
  final EmergencyNumberService _emergencyNumberService = EmergencyNumberService();
  List<EmergencyNumber> emergencyNumbers = [];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyNumbers(); // โหลดข้อมูลในพื้นหลัง
  }

  Future<void> _loadEmergencyNumbers() async {
    try {
      final numbers = await _emergencyNumberService.getEmergencyNumbers();
      setState(() {
        emergencyNumbers = numbers;
        // จัดกลุ่มตามหมวดหมู่ โดยรักษาลำดับดั้งเดิม
        for (var number in numbers) {
          if (!categories.contains(number.category)) {
            categories.add(number.category);
          }
        }
        print('Categories order: $categories'); // เพิ่มการ debug
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'เหตุด่วนเหตุร้าย':
        return Colors.red;
      case 'กรณีเจ็บป่วย':
        return Colors.orange;
      case 'แจ้งเหตุจราจร-ขอความช่วยเหลือ':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
        trailing: Text(
          number,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
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
            final Uri dialUri = Uri.parse('tel:$number');

            try {
              print('Attempting to open dialer: $dialUri');
              if (await canLaunchUrl(dialUri)) {
                await launchUrl(
                  dialUri,
                  mode: LaunchMode.externalApplication,
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

  Widget _buildEmergencyNumberList() {
    if (emergencyNumbers.isEmpty) {
      // ถ้ายังไม่มีข้อมูล (กำลังโหลด) ให้แสดง Shimmer สำหรับ 3 หมวดหมู่จำลอง
      return ListView(
        padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
        children: List.generate(3, (index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    width: 150,
                    height: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              ...List.generate(2, (i) { // จำลอง 2 รายการต่อหมวดหมู่
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
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
                      leading: Container(
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      title: Container(
                        width: 150,
                        height: 16,
                        color: Colors.white,
                      ),
                      trailing: Container(
                        width: 80,
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 10),
            ],
          );
        }),
      );
    }

    // ถ้ามีข้อมูลแล้ว ให้แสดงข้อมูลจริง
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      children: categories.map((category) {
        final numbersInCategory = emergencyNumbers.where((number) => number.category == category).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: _getCategoryColor(category),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...numbersInCategory.map((number) => _buildEmergencyTile(context, number.serviceName, number.phoneNumber)).toList(),
            SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _buildEmergencyNumberList(),
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
}