import 'package:flutter/material.dart';
import 'package:projectappsos/features/auth/register_screen.dart';
import '../../screens/home_screen.dart'; // หน้าเป้าหมายหลังล็อกอิน
import 'forgot_password_screen.dart';
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // แก้ไข: เพิ่ม () ให้ GlobalKey
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // ตัวแปรควบคุมการซ่อน/แสดงรหัสผ่าน

  void signIn() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  void navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0), // พื้นหลังสีเทาอ่อน
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    "เบอร์โทรศัพท์",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // อนุญาตเฉพาะตัวเลข
                      LengthLimitingTextInputFormatter(10), // จำกัดความยาวสูงสุด 10 ตัว
                    ],
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกหมายเลขโทรศัพท์',
                      filled: true,
                      fillColor: Colors.white,
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกเบอร์มือถือ';
                      }
                      if (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    "รหัสผ่าน",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกรหัสผ่าน',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (value.length < 8) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: navigateToForgotPassword,
                        child: Text(
                          "ลืมรหัสผ่าน",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 100),
                  Center(
                    child: TextButton(
                      onPressed: navigateToRegister,
                      child: RichText(
                        text: TextSpan(
                          text: "ยังไม่ได้สมัครสมาชิก? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: "สมัครสมาชิก",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}