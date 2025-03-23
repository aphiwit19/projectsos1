import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class EditUserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<EditUserProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  String? _selectedGender;
  String? _selectedBloodType;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  String? email;

  final List<String> genderOptions = ['ชาย', 'หญิง', 'อื่นๆ'];
  final List<String> bloodTypeOptions = ['A', 'B', 'AB', 'O'];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _medicalConditionsController = TextEditingController(text: '');
    _allergiesController = TextEditingController(text: '');
    _selectedGender = genderOptions[0];
    _selectedBloodType = bloodTypeOptions[0];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['email'] != null) {
      email = arguments['email'];
    }
    if (email == null || email!.isEmpty) {
      _authService.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบอีเมลผู้ใช้ กรุณาล็อกอิน')),
      );
      _authService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์')),
      );
      return;
    }
    String phone = _phoneController.text.trim();
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก และเริ่มต้นด้วย 0')),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกเพศ')),
      );
      return;
    }

    try {
      String? userId = await _authService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอิน')),
        );
        _authService.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      final user = UserProfile(
        uid: userId,
        email: email!,
        fullName: _fullNameController.text.trim(),
        gender: _selectedGender!,
        bloodType: _selectedBloodType ?? '',
        medicalConditions: _medicalConditionsController.text.trim(),
        allergies: _allergiesController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await _profileService.saveProfile(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
          settings: RouteSettings(arguments: user.toJson()),
        ),
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
        backgroundColor: Color.fromRGBO(244, 244, 244, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.only(left: 16),
        ),
        title: Text(
          "ข้อมูลผู้ใช้",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Color.fromRGBO(244, 244, 244, 1.0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
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
                    prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: "เบอร์โทรศัพท์ *",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ListTile(
                  leading: Icon(Icons.wc, color: Colors.grey[600]),
                  title: Text(
                    "เพศ *",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedGender,
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    underline: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ListTile(
                  leading: Icon(Icons.bloodtype, color: Colors.grey[600]),
                  title: Text(
                    "หมู่เลือด",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedBloodType,
                    items: bloodTypeOptions.map((String bloodType) {
                      return DropdownMenuItem<String>(
                        value: bloodType,
                        child: Text(bloodType, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBloodType = newValue;
                      });
                    },
                    underline: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
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
                    prefixIcon: Icon(Icons.medical_services, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white,
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
                    prefixIcon: Icon(Icons.warning, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: Text(
                  "บันทึก",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}