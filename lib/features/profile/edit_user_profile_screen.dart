// lib/features/profile/edit_user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectappsos/models/user_profile_model.dart';
import 'package:projectappsos/services/profile_service.dart';
import '../../screens/home_screen.dart';

class InitialProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const InitialProfileSetupScreen({required this.userProfile});

  @override
  _InitialProfileSetupScreenState createState() => _InitialProfileSetupScreenState();
}

class _InitialProfileSetupScreenState extends State<InitialProfileSetupScreen> {
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
  final _formKey = GlobalKey<FormState>();

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

    // แสดง Dialog เพื่อยืนยันการบันทึก
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
      // ตรวจสอบว่าเบอร์โทรซ้ำกับที่มีอยู่ในระบบหรือไม่
      final userEmail = await _profileService.findUserByPhone(phone);
      if (userEmail != null && userEmail != widget.userProfile['email']) {
        setState(() {
          _isLoading = false;
          _phoneError = 'เบอร์โทรนี้ถูกใช้งานแล้ว';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เบอร์โทรนี้ถูกใช้งานแล้ว')),
        );
        return;
      }

      // สร้างข้อมูลโปรไฟล์ที่อัปเดต
      final updatedProfile = UserProfile(
        uid: widget.userProfile['uid'] ?? '',
        email: widget.userProfile['email'] ?? '',
        fullName: _fullNameController.text.trim(),
        phone: phone,
        gender: _selectedGender ?? '',
        bloodType: _selectedBloodType ?? '',
        medicalConditions: _medicalConditionsController.text.trim(),
        allergies: _allergiesController.text.trim(),
      );

      debugPrint('Saving updated profile: ${updatedProfile.toJson()}');

      // บันทึกข้อมูลลง Firestore
      await _profileService.saveProfile(updatedProfile);

      // ตรวจสอบว่าเป็นผู้ใช้ใหม่หรือไม่
      bool isNewUser = widget.userProfile['isNewUser'] ?? false;
      if (isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pop(context, updatedProfile.toJson());
      }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFE64646),
        elevation: 0,
        title: const Text(
          "บันทึกโปร์ไฟล์ส่วนตัว",
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แสดงภาพประกอบ

                  SizedBox(height: 18),
                  _buildSectionHeader('ข้อมูลส่วนตัว'),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _fullNameController,
                    label: "ชื่อ-นามสกุล",
                    hintText: "กรุณากรอกชื่อ-นามสกุล",
                    errorText: _fullNameError,
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "เบอร์โทรศัพท์",
                    hintText: "กรุณากรอกเบอร์โทรศัพท์",
                    errorText: _phoneError,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildDropdownField(
                    label: "เพศ",
                    hint: "เลือกเพศ",
                    value: _selectedGender,
                    errorText: _genderError,
                    items: genderOptions,
                    icon: Icons.person_outline,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildDropdownField(
                    label: "หมู่เลือด",
                    hint: "เลือกหมู่เลือด",
                    value: _selectedBloodType,
                    errorText: _bloodTypeError,
                    items: bloodTypeOptions,
                    icon: Icons.bloodtype_outlined,
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodType = value;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  _buildSectionHeader('ข้อมูลทางการแพทย์'),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _medicalConditionsController,
                    label: "โรคประจำตัว",
                    hintText: "กรุณากรอกโรคประจำตัว (หากไม่มีให้ระบุ 'ไม่มี')",
                    errorText: _medicalConditionsError,
                    icon: Icons.medical_services_outlined,
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _allergiesController,
                    label: "การแพ้ยา",
                    hintText: "กรุณากรอกการแพ้ยา (หากไม่มีให้ระบุ 'ไม่มี')",
                    errorText: _allergiesError,
                    icon: Icons.medication_outlined,
                    maxLines: 3,
                  ),
                  SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE64646).withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE64646),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "บันทึกข้อมูล",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: Color(0xFFE64646),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? errorText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black38),
              prefixIcon: Icon(icon, color: Color(0xFFE64646)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFE64646), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Color(0xFFE64646),
                ),
                SizedBox(width: 4),
                Text(
                  errorText,
                  style: TextStyle(
                    color: Color(0xFFE64646),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    String? errorText,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black38),
              prefixIcon: Icon(icon, color: Color(0xFFE64646)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFE64646), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Color(0xFFE64646),
                ),
                SizedBox(width: 4),
                Text(
                  errorText,
                  style: TextStyle(
                    color: Color(0xFFE64646),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}