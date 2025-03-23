import 'package:flutter/material.dart';
import 'package:projectappsos/features/auth/login_screen.dart';
import 'package:projectappsos/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  String emailError = '';
  bool _isEmailSent = false;
  final AuthService _authService = AuthService();

  void sendPasswordResetEmail() async {
    setState(() {
      emailError = '';
    });

    String email = emailController.text.trim();
    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        emailError = 'กรุณากรอกอีเมล';
      });
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        emailError = 'กรุณากรอกอีเมลให้ถูกต้อง';
      });
      hasError = true;
    }

    if (!hasError) {
      try {
        await _authService.sendPasswordResetEmail(email);
        setState(() {
          _isEmailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งอีเมลรีเซ็ตรหัสผ่านไปที่ $email เรียบร้อยแล้ว')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งอีเมล: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 244, 244,1.0),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(244, 244, 244, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.only(left: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isEmailSent) ...[
              Text(
                "ลืมรหัสผ่าน",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "กรุณากรอกอีเมลเพื่อรับลิงก์รีเซ็ตรหัสผ่าน",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'กรุณากรอกอีเมล',
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
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (emailError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                  child: Text(
                    emailError,
                    style: TextStyle(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sendPasswordResetEmail,
                  child: Text(
                    "ส่งอีเมลรีเซ็ตรหัสผ่าน",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "ส่งอีเมลรีเซ็ตรหัสผ่านเรียบร้อยแล้ว!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "กรุณาตรวจสอบอีเมลของคุณ (${emailController.text}) และคลิกลิงก์เพื่อรีเซ็ตรหัสผ่าน",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text(
                            "กลับไปที่หน้าเข้าสู่ระบบ",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}