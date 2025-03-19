import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  final Function(String, String) onContactAdded;

  const AddEmergencyContactScreen({Key? key, required this.onContactAdded})
      : super(key: key);

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  String nameError = '';
  String phoneError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0), // ปรับสีพื้นหลัง
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "เพิ่มผู้ติดต่อฉุกเฉิน",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'ชื่อ',

                  errorText: nameError.isNotEmpty ? nameError : null,
                  filled: true,
                  fillColor: Colors.white, // ปรับพื้นหลังช่องเป็นสีขาว
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                  hintText: 'เบอร์โทรศัพท์',

                  errorText: phoneError.isNotEmpty ? phoneError : null,
                  filled: true,
                  fillColor: Colors.white, // ปรับพื้นหลังช่องเป็นสีขาว1
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                      widget.onContactAdded(name, phone);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("เพิ่ม",
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}