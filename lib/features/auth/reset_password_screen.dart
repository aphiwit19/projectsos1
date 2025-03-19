import 'package:flutter/material.dart';
import 'login_screen.dart'; // เชื่อมต่อกับ Login

class ResetPasswordScreen extends StatefulWidget {
  final String phone;

  ResetPasswordScreen({required this.phone});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();
  String newPasswordError = ''; // ข้อความแจ้งเตือนสำหรับรหัสผ่านใหม่
  String confirmPasswordError = ''; // ข้อความแจ้งเตือนสำหรับยืนยันรหัสผ่าน
  bool _obscureNewPassword = true; // ตัวแปรควบคุมการซ่อน/แสดงรหัสผ่านใหม่
  bool _obscureConfirmPassword = true; // ตัวแปรควบคุมการซ่อน/แสดงยืนยันรหัสผ่าน

  void resetPassword() {
    // ล้างข้อความแจ้งเตือนก่อนตรวจสอบใหม่
    setState(() {
      newPasswordError = '';
      confirmPasswordError = '';
    });

    String newPassword = newPasswordController.text.trim();
    String confirmNewPassword = confirmNewPasswordController.text.trim();

    // ตรวจสอบข้อมูลทั้งหมด โดยไม่หยุดทันที
    bool hasError = false;

    if (newPassword.isEmpty) {
      setState(() {
        newPasswordError = 'กรุณากรอกรหัสผ่าน';
      });
      hasError = true;
    } else if (newPassword.length < 8) {
      setState(() {
        newPasswordError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
      });
      hasError = true;
    }

    if (confirmNewPassword.isEmpty) {
      setState(() {
        confirmPasswordError = 'กรุณากรอกยืนยันรหัสผ่าน';
      });
      hasError = true;
    } else if (newPassword != confirmNewPassword) {
      setState(() {
        confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
      });
      hasError = true;
    }

    // หากไม่มีข้อผิดพลาดให้ดำเนินการรีเซ็ตรหัสผ่าน
    if (!hasError) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, // เปลี่ยนเป็นชิดซ้าย
          children: [
            Text(
              "เปลี่ยนรหัสผ่าน",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text("รหัสผ่าน", style: TextStyle(fontSize: 14)),
            SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                hintText: 'รหัสผ่าน',
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
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: _toggleNewPasswordVisibility,
                ),
              ),
            ),
            if (newPasswordError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                child: Text(
                  newPasswordError,
                  style: TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Text("ยืนยันรหัสผ่าน", style: TextStyle(fontSize: 14)),
            SizedBox(height: 10),
            TextField(
              controller: confirmNewPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: 'ยืนยันรหัสผ่าน',
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
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: _toggleConfirmPasswordVisibility,
                ),
              ),
            ),
            if (confirmPasswordError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                child: Text(
                  confirmPasswordError,
                  style: TextStyle(
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: double.infinity, // ปุ่มกว้างเต็มหน้าจอ
                child: ElevatedButton(
                  onPressed: resetPassword,
                  child: Text(
                    "เปลี่ยนรหัสผ่าน",
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