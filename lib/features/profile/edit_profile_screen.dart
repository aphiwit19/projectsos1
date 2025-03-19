import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  EditProfileScreen({required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
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
    _medicalConditionsController =
        TextEditingController(text: widget.userProfile['medicalConditions'] ?? '');
    _allergiesController =
        TextEditingController(text: widget.userProfile['allergies'] ?? '');
    _selectedGender = widget.userProfile['gender'] ?? 'ชาย';
    _selectedBloodType = widget.userProfile['bloodType'] ?? 'O';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    Map<String, dynamic> updatedProfile = {
      'fullName': _fullNameController.text,
      'gender': _selectedGender,
      'bloodType': _selectedBloodType,
      'medicalConditions': _medicalConditionsController.text,
      'allergies': _allergiesController.text,
    };
    Navigator.pop(context, updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
          child: Container(
            width: 40, // กำหนดขนาดของกรอบให้สมส่วน
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black, // เปลี่ยนสีไอคอนเป็นสีแดงตามภาพ
                size: 20, // ปรับขนาดไอคอนให้เหมาะสม
              ),
              alignment: Alignment.center, // จัดไอคอนให้อยู่กึ่งกลาง
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFF4F4F4), // พื้นหลังสี #F4F4F4
      body: SingleChildScrollView( // เพิ่ม SingleChildScrollView เพื่อให้เลื่อนได้
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "ข้อมูลพื้นฐาน",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            // ช่องชื่อ-นามสกุล
            Card(
              elevation: 0,
              color: Color(0xFFFFFFFF), // พื้นหลังกรอบสี #FFFFFF
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFE0E0E0)), // ขอบสีเทา #E0E0E0
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: "ชื่อ-นามสกุล",
                    labelStyle: TextStyle(color: Colors.grey[700]), // สีเทาเข้ม
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // ช่องเพศ
            Card(
              elevation: 0,
              color: Color(0xFFFFFFFF), // พื้นหลังกรอบสี #FFFFFF
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFE0E0E0)), // ขอบสีเทา #E0E0E0
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(
                    "เพศ",
                    style: TextStyle(color: Colors.grey[700]), // สีเทาเข้ม
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedGender,
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: TextStyle(color: Colors.grey[500]), // สีเทาอ่อน
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    underline: SizedBox(), // ลบเส้นใต้ Dropdown
                    icon: Icon(Icons.arrow_forward_ios, size: 16), // ลูกศรตามภาพ
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // ช่องหมู่เลือด
            Card(
              elevation: 0,
              color: Color(0xFFFFFFFF), // พื้นหลังกรอบสี #FFFFFF
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFE0E0E0)), // ขอบสีเทา #E0E0E0
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(
                    "หมู่เลือด",
                    style: TextStyle(color: Colors.grey[700]), // สีเทาเข้ม
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedBloodType,
                    items: bloodTypeOptions.map((String bloodType) {
                      return DropdownMenuItem<String>(
                        value: bloodType,
                        child: Text(
                          bloodType,
                          style: TextStyle(color: Colors.grey[500]), // สีเทาอ่อน
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBloodType = newValue;
                      });
                    },
                    underline: SizedBox(), // ลบเส้นใต้ Dropdown
                    icon: Icon(Icons.arrow_forward_ios, size: 16), // ลูกศรตามภาพ
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // ช่องโรคประจำตัว
            Card(
              elevation: 0,
              color: Color(0xFFFFFFFF), // พื้นหลังกรอบสี #FFFFFF
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFE0E0E0)), // ขอบสีเทา #E0E0E0
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _medicalConditionsController,
                  decoration: InputDecoration(
                    labelText: "โรคประจำตัว",
                    labelStyle: TextStyle(color: Colors.grey[700]), // สีเทาเข้ม
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // ช่องการแพ้ยา
            Card(
              elevation: 0,
              color: Color(0xFFFFFFFF), // พื้นหลังกรอบสี #FFFFFF
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFE0E0E0)), // ขอบสีเทา #E0E0E0
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    labelText: "การแพ้ยา",
                    labelStyle: TextStyle(color: Colors.grey[700]), // สีเทาเข้ม
                    border: InputBorder.none,
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
                  backgroundColor: Color(0xFFE64646), // สีแดง #E64646
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}