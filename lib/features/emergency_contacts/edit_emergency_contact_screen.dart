import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditEmergencyContactScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final Function(String, String) onContactUpdated;

  const EditEmergencyContactScreen({
    Key? key,
    required this.currentName,
    required this.currentPhone,
    required this.onContactUpdated,
  }) : super(key: key);

  @override
  State<EditEmergencyContactScreen> createState() =>
      _EditEmergencyContactScreenState();
}

class _EditEmergencyContactScreenState extends State<EditEmergencyContactScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  String nameError = '';
  String phoneError = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0), // ปรับพื้นหลังให้อ่อนลง
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0), // ใช้สีแดงตามธีม
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
              alignment: Alignment.center,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "แก้ไขผู้ติดต่อฉุกเฉิน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "แก้ไขผู้ติดต่อฉุกเฉิน",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "กรุณากรอกข้อมูลผู้ติดต่อฉุกเฉิน",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // ช่องกรอกชื่อ
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
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    hintText: 'ชื่อ',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: nameError.isNotEmpty ? nameError : null,
                    errorStyle: const TextStyle(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      fontSize: 14,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ช่องกรอกเบอร์โทรศัพท์
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
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                    hintText: 'เบอร์โทรศัพท์',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: phoneError.isNotEmpty ? phoneError : null,
                    errorStyle: const TextStyle(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      fontSize: 14,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String name = nameController.text.trim();
                    String phone = phoneController.text.trim();
                    bool hasError = false;

                    if (name.isEmpty) {
                      setState(() {
                        nameError = 'กรุณากรอกชื่อ';
                      });
                      hasError = true;
                    } else {
                      setState(() {
                        nameError = '';
                      });
                    }
                    if (phone.isEmpty) {
                      setState(() {
                        phoneError = 'กรุณากรอกเบอร์โทรศัพท์';
                      });
                      hasError = true;
                    } else if (phone.length != 10 ||
                        !RegExp(r'^0\d{9}$').hasMatch(phone)) {
                      setState(() {
                        phoneError = 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก (เริ่มต้นด้วย 0)';
                      });
                      hasError = true;
                    } else {
                      setState(() {
                        phoneError = '';
                      });
                    }

                    if (!hasError) {
                      widget.onContactUpdated(name, phone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5, // เพิ่มเงาให้ปุ่ม
                    shadowColor: Colors.black26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}