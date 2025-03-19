import 'package:flutter/material.dart';
import 'package:projectappsos/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../screens/home_screen.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';

class EditUserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<EditUserProfileScreen> {
  late TextEditingController _fullNameController;
  String? _selectedGender;
  String? _selectedBloodType;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  final ProfileService _profileService = ProfileService();

  final List<String> genderOptions = ['ชาย', 'หญิง', 'อื่นๆ'];
  final List<String> bloodTypeOptions = ['A', 'B', 'AB', 'O'];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: '');
    _medicalConditionsController = TextEditingController(text: '');
    _allergiesController = TextEditingController(text: '');
    _selectedGender = genderOptions[0];
    _selectedBloodType = bloodTypeOptions[0];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['phone'] != null) {
      _savePhoneToPreferences(arguments['phone']);
    }
  }

  Future<void> _savePhoneToPreferences(String? phone) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', phone ?? '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกเบอร์โทรศัพท์: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกเพศ')),
      );
      return;
    }

    final user = UserProfile(
      fullName: _fullNameController.text.trim(),
      phone: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['phone'] ?? '',
      gender: _selectedGender!,
      bloodType: _selectedBloodType ?? '',
      medicalConditions: _medicalConditionsController.text.trim(),
      allergies: _allergiesController.text.trim(), userId: '',
    );

    try {
      await _profileService.saveProfile(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
          settings: RouteSettings(arguments: user.toJson()),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ข้อมูลผู้ใช้"),
      ),
      backgroundColor: Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "ข้อมูลผู้ใช้",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Card(
              elevation: 0,
              color: Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: "ชื่อ-นามสกุล *",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ListTile(
                  title: Text(
                    "เพศ *",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedGender,
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender, style: TextStyle(color: Colors.grey[500])),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ListTile(
                  title: Text(
                    "หมู่เลือด",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedBloodType,
                    items: bloodTypeOptions.map((String bloodType) {
                      return DropdownMenuItem<String>(
                        value: bloodType,
                        child: Text(bloodType, style: TextStyle(color: Colors.grey[500])),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBloodType = newValue;
                      });
                    },
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _medicalConditionsController,
                  decoration: InputDecoration(
                    labelText: "โรคประจำตัว",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    labelText: "การแพ้ยา",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: Text(
                  "บันทึก",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE64646),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}