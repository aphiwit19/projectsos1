import 'package:flutter/material.dart';
import 'otp_verification_screen.dart'; // เชื่อมต่อกับ OTP Verification
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  String errorMessage = '';

  void sendOTP() {
    setState(() {
      errorMessage = ''; // ล้างข้อความแจ้งเตือนก่อนตรวจสอบใหม่
    });

    String phone = phoneController.text.trim();

    // ตรวจสอบว่าเบอร์ไม่ว่าง
    if (phone.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกเบอร์โทรศัพท์';
      });
      return;
    }

    // ตรวจสอบเบอร์โทรศัพท์ 10 หลัก เริ่มต้นด้วย 0
    if (phone.length != 10 || !RegExp(r'^0\d{9}$').hasMatch(phone)) {
      setState(() {
        errorMessage = 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก (เริ่มต้นด้วย 0)';
      });
      return;
    }

    // ไปหน้า OTP Verification ถ้าผ่านการตรวจสอบ
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OTPVerificationScreen(phone: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 244, 244, 1.0), // ตั้งพื้นหลังทั้งหน้า
      appBar: AppBar(
        backgroundColor: Colors.white, // ตั้ง AppBar เป็นสีขาว
        elevation: 0, // ลบเงา AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Container(
        color: Color.fromRGBO(244, 244, 244, 1.0), // ตั้ง Container
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // จัดชิดซ้าย
          children: [
            Text(
              "ลืมรหัสผ่าน?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "เบอร์โทรศัพท์",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10), // เพิ่มระยะห่างระหว่างข้อความและช่องกรอก
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // อนุญาตเฉพาะตัวเลข
                LengthLimitingTextInputFormatter(10), // จำกัดความยาวสูงสุด 10 ตัว
              ],
              decoration: InputDecoration(
                hintText: 'กรุณากรอกหมายเลขโทรศัพท์',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey), // ลบ borderSide ที่ซ้ำออก
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white, // พื้นหลังสีขาวคงที่
              ),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Text(
              "คุณอาจจะได้รับการแจ้งเตือนทางSMSจากเราเพื่อวัตถุประสงค์ด้านความปลอดภัยและการเข้าสู่ระบบ",
              style: TextStyle(color: Color.fromRGBO(162, 162, 167, 1.0), fontSize: 12),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // ทำให้ปุ่มกว้างเต็มหน้าจอ
              child: ElevatedButton(
                onPressed: sendOTP,
                child: Text(
                  "ดำเนินการต่อ",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(230, 70, 70, 1.0), // ปุ่มสีแดง
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // ทำให้ปุ่มโค้ง
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