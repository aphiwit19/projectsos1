import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  EditProfileScreen({required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  String? _selectedGender;
  String? _selectedBloodType;

  final List<String> genderOptions = ['ชาย', 'หญิง', 'อื่นๆ'];
  final List<String> bloodTypeOptions = ['A', 'B', 'AB', 'O'];

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.userProfile['fullName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userProfile['phone'] ?? '');
    _medicalConditionsController =
        TextEditingController(text: widget.userProfile['medicalConditions'] ?? '');
    _allergiesController =
        TextEditingController(text: widget.userProfile['allergies'] ?? '');
    _selectedGender = widget.userProfile['gender']?.isNotEmpty == true
        ? widget.userProfile['gender']
        : 'ชาย';
    _selectedBloodType = widget.userProfile['bloodType']?.isNotEmpty == true
        ? widget.userProfile['bloodType']
        : 'O';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // ตรวจสอบข้อมูลที่จำเป็น
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
        SnackBar(content: Text('เบอร์โทรศัพท์ต้องเริ่มด้วย 0 และเป็นตัวเลข 10 หลัก')),
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
      // สร้างข้อมูลโปรไฟล์ที่อัปเดต
      Map<String, dynamic> updatedProfile = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'bloodType': _selectedBloodType ?? '',
        'medicalConditions': _medicalConditionsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
      };

      debugPrint('Saving updated profile: $updatedProfile');

      // ส่งข้อมูลกลับไปยังหน้าที่เรียก (ProfileScreen)
      Navigator.pop(context, updatedProfile);

      // แสดงข้อความแจ้งว่าบันทึกสำเร็จ (จะแสดงใน ProfileScreen)
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.only(left: 16),
        ),
        title: const Text(
          "แก้ไขข้อมูลส่วนตัว",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "ข้อมูลพื้นฐาน",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 20),
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
                    counterText: '',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                        child: Text(gender, style: const TextStyle(color: Colors.black)),
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
            const SizedBox(height: 20),
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
                        child: Text(bloodType, style: const TextStyle(color: Colors.black)),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text(
                  "บันทึก",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}