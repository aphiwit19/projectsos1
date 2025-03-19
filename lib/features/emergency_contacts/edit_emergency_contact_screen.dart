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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.black),
                  hintText: 'ชื่อ',
                  hintStyle: const TextStyle(color: Colors.grey),
                  errorText: nameError.isNotEmpty ? nameError : null,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Colors.black),
                  hintText: 'เบอร์โทรศัพท์',
                  hintStyle: const TextStyle(color: Colors.grey),
                  errorText: phoneError.isNotEmpty ? phoneError : null,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
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
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("บันทึก",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
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