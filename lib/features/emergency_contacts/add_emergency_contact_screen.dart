// lib/features/emergency_contacts/add_emergency_contact_screen.dart
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
  bool _isLoading = false;

  Future<void> _addContact() async {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    bool hasError = false;

    // ตรวจสอบการกรอกข้อมูล
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
    } else if (phone.length != 10 || !RegExp(r'^0\d{9}$').hasMatch(phone)) {
      setState(() {
        phoneError = 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก (เริ่มต้นด้วย 0)';
      });
      hasError = true;
    } else {
      setState(() {
        phoneError = '';
      });
    }

    if (hasError) {
      return;
    }

    // เริ่มการเพิ่มผู้ติดต่อ
    setState(() {
      _isLoading = true;
    });

    // เพิ่มผู้ติดต่อได้ทันที โดยไม่ต้องตรวจสอบว่ามีบัญชีในระบบหรือไม่
    try {
      widget.onContactAdded(name, phone);
      Navigator.pop(context);
      
      // แสดงข้อความเมื่อเพิ่มสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มผู้ติดต่อฉุกเฉินเรียบร้อยแล้ว'),
          backgroundColor: Color.fromRGBO(76, 175, 80, 1.0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
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
              alignment: Alignment.center,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "เพิ่มผู้ติดต่อฉุกเฉิน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "คุณสามารถเพิ่มผู้ติดต่อฉุกเฉินได้โดยไม่จำเป็นต้องเป็นผู้ใช้งานแอปพลิเคชัน เมื่อคุณกดปุ่ม SOS ระบบจะส่ง SMS แจ้งเตือนไปยังเบอร์โทรศัพท์นี้",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'ชื่อ',
                    errorText: nameError.isNotEmpty ? nameError : null,
                    errorStyle: const TextStyle(
                        color: Color.fromRGBO(230, 70, 70, 1.0)),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
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
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'เบอร์โทรศัพท์',
                    errorText: phoneError.isNotEmpty ? phoneError : null,
                    errorStyle: const TextStyle(
                        color: Color.fromRGBO(230, 70, 70, 1.0)),
                    prefixIcon: const Icon(Icons.phone, color: Colors.grey),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addContact,
                        child: const Text("เพิ่ม",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(230, 70, 70, 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 5,
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
