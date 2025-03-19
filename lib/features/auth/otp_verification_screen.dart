import 'package:flutter/material.dart';
import 'reset_password_screen.dart'; // เชื่อมต่อกับ Reset Password

class OTPVerificationScreen extends StatefulWidget {
  final String phone;

  OTPVerificationScreen({required this.phone});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(4, (_) => TextEditingController());
  String errorMessage = '';

  void verifyOTP() {
    String otp = otpControllers.map((controller) => controller.text.trim()).join();

    // ตรวจสอบ OTP ทดสอบ (สมมติว่า OTP เป็น "5555")
    if (otp.length != 4 || otp != "5555") {
      setState(() {
        errorMessage = 'รหัส OTP ไม่ถูกต้อง';
      });
      return;
    }

    // ไปหน้า Reset Password
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResetPasswordScreen(phone: widget.phone)),
    );
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังทั้งหน้าเป็นสีขาว
      appBar: AppBar(
        backgroundColor: Colors.white, // ตั้ง AppBar เป็นสีขาว
        elevation: 0, // ลบเงา AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Container(
        color: Colors.white, // ตั้ง Container เป็นสีขาว
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start, // จัดกึ่งกลาง
          children: [
            Text(
              "กรุณาตรวจสอบหมายเลขOTP ที่โทรศัพท์ของคุณ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              "เราได้ส่งรหัสยืนยัน ไปที่หมายเลขโทรศัพท์ของคุณ",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 50,
                  height: 50, // ทำให้เป็นสี่เหลี่ยมจัตุรัส
                  margin: EdgeInsets.symmetric(horizontal: 10), // เพิ่มระยะห่างระหว่างช่อง
                  child: TextField(
                    controller: otpControllers[index],
                    decoration: InputDecoration(
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
                      fillColor: Colors.white, // พื้นหลังสีขาว
                      counterText: "", // ซ่อน counter
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            Text(
              errorMessage,
              style: TextStyle(color: Color.fromRGBO(230, 70, 70, 1.0)),
            ),
            SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity, // ปุ่มกว้างเต็มหน้าจอ
                child: ElevatedButton(
                  onPressed: verifyOTP,
                  child: Text(
                    "ตรวจสอบ",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(230, 70, 70, 1.0), // ปุ่มสีแดง
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // มุมโค้ง
                    ),
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