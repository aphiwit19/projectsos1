// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:projectappsos/features/auth/login_screen.dart';
import 'package:projectappsos/features/profile/edit_user_profile_screen.dart'; // ใช้ InitialProfileSetupScreen
import 'package:projectappsos/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String emailError = '';
  String passwordError = '';
  String confirmPasswordError = '';
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void register() async {
    setState(() {
      emailError = '';
      passwordError = '';
      confirmPasswordError = '';
      errorMessage = '';
      _isLoading = true;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    debugPrint('Register button pressed');
    debugPrint('Email: $email');
    debugPrint('Password: $password');
    debugPrint('Confirm Password: $confirmPassword');

    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        emailError = 'กรุณากรอกอีเมล';
      });
      hasError = true;
      debugPrint('Email error: $emailError');
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        emailError = 'กรุณากรอกอีเมลให้ถูกต้อง';
      });
      hasError = true;
      debugPrint('Email error: $emailError');
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = 'กรุณากรอกรหัสผ่าน';
      });
      hasError = true;
      debugPrint('Password error: $passwordError');
    } else if (password.length < 8) {
      setState(() {
        passwordError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
      });
      hasError = true;
      debugPrint('Password error: $passwordError');
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        confirmPasswordError = 'กรุณากรอกยืนยันรหัสผ่าน';
      });
      hasError = true;
      debugPrint('Confirm Password error: $confirmPasswordError');
    } else if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
      });
      hasError = true;
      debugPrint('Confirm Password error: $confirmPasswordError');
    }

    if (!hasError) {
      try {
        debugPrint('Attempting to register user...');
        var userCredential = await _authService.register(email, password);
        debugPrint('User registered with UID: ${userCredential.user?.uid}');

        debugPrint('Registration successful, navigating to InitialProfileSetupScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InitialProfileSetupScreen(
              userProfile: {
                'uid': userCredential.user?.uid ?? '',
                'email': email,
                'fullName': '',
                'phone': '',
                'gender': '',
                'bloodType': '',
                'medicalConditions': '',
                'allergies': '',
                'isNewUser': true, // เพิ่ม flag เพื่อระบุว่าเป็นผู้ใช้ใหม่
              },
            ),
          ),
        );
      } catch (e) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        debugPrint('Error during registration: $errorMessage');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 244, 244, 1.0),
      body: SingleChildScrollView(
        child: Container(
          color: Color.fromRGBO(244, 244, 244, 1.0),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text(
                "สมัครสมาชิก",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "อีเมล",
                style: TextStyle(fontSize: 14),
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
              SizedBox(height: 20),
              Text(
                "รหัสผ่าน",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'รหัสผ่าน',
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
              ),
              if (passwordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                  child: Text(
                    passwordError,
                    style: TextStyle(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Text(
                "ยืนยันรหัสผ่าน",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'ยืนยันรหัสผ่าน',
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
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    errorMessage,
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
                  onPressed: _isLoading ? null : register,
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text(
                    "ลงทะเบียน",
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
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "มีบัญชีอยู่แล้ว? ",
                    style: TextStyle(color: Color.fromRGBO(162, 162, 167, 1.0)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}