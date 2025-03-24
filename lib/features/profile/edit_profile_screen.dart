// lib/features/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectappsos/models/user_profile_model.dart';
import 'package:projectappsos/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({required this.userProfile});

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
  String? _fullNameError;
  String? _phoneError;
  String? _genderError;
  String? _bloodTypeError;
  String? _medicalConditionsError;
  String? _allergiesError;
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

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
        : null;
    _selectedBloodType = widget.userProfile['bloodType']?.isNotEmpty == true
        ? widget.userProfile['bloodType']
        : null;
  }

  Future<void> _saveProfile() async {
    // รีเซ็ตข้อความ error
    setState(() {
      _fullNameError = null;
      _phoneError = null;
      _genderError = null;
      _bloodTypeError = null;
      _medicalConditionsError = null;
      _allergiesError = null;
    });

    bool hasError = false;

    // ตรวจสอบข้อมูลที่จำเป็น
    if (_fullNameController.text.trim().isEmpty) {
      setState(() {
        _fullNameError = 'กรุณากรอกชื่อ-นามสกุล';
      });
      hasError = true;
    }

    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneError = 'กรุณากรอกเบอร์โทรศัพท์';
      });
      hasError = true;
    } else if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      setState(() {
        _phoneError = 'เบอร์โทรศัพท์ต้องเริ่มด้วย 0 และเป็นตัวเลข 10 หลัก';
      });
      hasError = true;
    }

    if (_selectedGender == null) {
      setState(() {
        _genderError = 'กรุณาเลือกเพศ';
      });
      hasError = true;
    }

    if (_selectedBloodType == null) {
      setState(() {
        _bloodTypeError = 'กรุณาเลือกหมู่เลือด';
      });
      hasError = true;
    }

    if (_medicalConditionsController.text.trim().isEmpty) {
      setState(() {
        _medicalConditionsError = 'กรุณากรอกโรคประจำตัว';
      });
      hasError = true;
    }

    if (_allergiesController.text.trim().isEmpty) {
      setState(() {
        _allergiesError = 'กรุณากรอกการแพ้ยา';
      });
      hasError = true;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.save,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ยืนยันการบันทึก',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'คุณต้องการบันทึกข้อมูลโปรไฟล์นี้หรือไม่?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = UserProfile(
        uid: widget.userProfile['uid'] ?? '',
        email: widget.userProfile['email'] ?? '',
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender ?? '',
        bloodType: _selectedBloodType ?? '',
        medicalConditions: _medicalConditionsController.text.trim(),
        allergies: _allergiesController.text.trim(),
      );

      debugPrint('Saving updated profile: ${updatedProfile.toJson()}');

      await _profileService.saveProfile(updatedProfile);

      Navigator.pop(context, updatedProfile.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
          child: Container(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "แก้ไขข้อมูลส่วนตัว",
          style: TextStyle(
            color: Colors.white,
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: "ชื่อ-นามสกุล",
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  errorText: _fullNameError,
                  errorStyle: const TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "เบอร์โทรศัพท์",
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                  errorText: _phoneError,
                  errorStyle: const TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: const Icon(Icons.wc, color: Colors.grey),
                    title: Text(
                      "เพศ",
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
                          _genderError = null; // รีเซ็ต error เมื่อเลือก
                        });
                      },
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ),
                  ),
                  if (_genderError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                      child: Text(
                        _genderError!,
                        style: const TextStyle(
                          color: Color.fromRGBO(230, 70, 70, 1.0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: const Icon(Icons.bloodtype, color: Colors.grey),
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
                          _bloodTypeError = null; // รีเซ็ต error เมื่อเลือก
                        });
                      },
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ),
                  ),
                  if (_bloodTypeError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                      child: Text(
                        _bloodTypeError!,
                        style: const TextStyle(
                          color: Color.fromRGBO(230, 70, 70, 1.0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _medicalConditionsController,
                decoration: InputDecoration(
                  labelText: "โรคประจำตัว",
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.medical_services, color: Colors.grey),
                  errorText: _medicalConditionsError,
                  errorStyle: const TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: "การแพ้ยา",
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.warning, color: Colors.grey),
                  errorText: _allergiesError,
                  errorStyle: const TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(230, 70, 70, 1.0),
                strokeWidth: 5,
              ),
            )
                : SizedBox(
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
                  elevation: 5,
                  shadowColor: Colors.black26,
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