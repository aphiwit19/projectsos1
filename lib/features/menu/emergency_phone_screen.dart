import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/emergency_number_service.dart';
import '../../models/emergency_number_model.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../profile/profile_screen.dart';
import '../emergency_contacts/emergency_contacts_screen.dart';
import '../../screens/home_screen.dart';
import 'menu_screen.dart';

class EmergencyPhoneScreen extends StatefulWidget {
  const EmergencyPhoneScreen({Key? key}) : super(key: key);

  @override
  EmergencyPhoneScreenState createState() => EmergencyPhoneScreenState();
}

class EmergencyPhoneScreenState extends State<EmergencyPhoneScreen> {
  final EmergencyNumberService _emergencyNumberService = EmergencyNumberService();
  List<EmergencyNumber> emergencyNumbers = [];
  List<String> categories = [];
  bool isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadEmergencyNumbers();
  }

  Future<void> _loadEmergencyNumbers() async {
    try {
      setState(() {
        isLoading = true;
      });
      final numbers = await _emergencyNumberService.getEmergencyNumbers();
      setState(() {
        emergencyNumbers = numbers.where((number) =>
        number.category != "แจ้งเหตุจราจร-ขอความช่วยเหลือ").toList();

        categories = [];
        for (var number in emergencyNumbers) {
          if (!categories.contains(number.category)) {
            categories.add(number.category);
          }
        }
        isLoading = false;
        print('Categories order: $categories');
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'เหตุด่วนเหตุร้าย':
        return Colors.red;
      case 'การแพทย์และโรงพยาบาล':
        return Colors.orange;
      case 'สาธารณูปโภค':
        return Colors.green;
      case 'ระหว่างเดินทาง':
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
    if (isLoading) {
      return ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
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
              ...List.generate(3, (i) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.06),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 150,
                                  height: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 20,
                            color: Colors.white,
                          ),
                        ],
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

    if (emergencyNumbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'ไม่พบข้อมูลเบอร์โทรฉุกเฉิน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadEmergencyNumbers,
              child: Text('ลองใหม่อีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE64646),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
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
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
      appBar: AppBar(
        backgroundColor: Color(0xFFE64646),
        elevation: 0,
        title: const Text(
          "เบอร์โทรฉุกเฉิน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildEmergencyNumberList(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 