// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:projectappsos/features/auth/login_screen.dart';
import 'package:projectappsos/features/profile/edit_user_profile_screen.dart'; // ใช้ InitialProfileSetupScreen
import 'package:projectappsos/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (_formKey.currentState!.validate()) {
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

      if (password != confirmPassword) {
        setState(() {
          confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
          _isLoading = false;
        });
        return;
      }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Container(
                      height: 200,
                      width: 280,
                      child: Image.asset(
                        'assets/images/register_image.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      "สมัครสมาชิก",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "สมัครสมาชิกเพื่อเริ่มการใช้งาน",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildInputField(
                    controller: emailController,
                    label: "อีเมล",
                    hintText: "กรุณากรอกอีเมล",
                    errorText: emailError,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  _buildPasswordField(
                    controller: passwordController,
                    label: "รหัสผ่าน",
                    hintText: "กรุณากรอกรหัสผ่าน",
                    errorText: passwordError,
                    obscureText: _obscurePassword,
                    toggleVisibility: _togglePasswordVisibility,
                  ),
                  SizedBox(height: 20),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: "ยืนยันรหัสผ่าน",
                    hintText: "กรุณายืนยันรหัสผ่าน",
                    errorText: confirmPasswordError,
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility: _toggleConfirmPasswordVisibility,
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, 
                            size: 16, 
                            color: Color(0xFFE64646),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: Color(0xFFE64646),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE64646).withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE64646),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "สมัครสมาชิก",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "มีบัญชีอยู่แล้ว? ",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
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
                            color: Color(0xFFE64646),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String errorText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black38),
              prefixIcon: Icon(icon, color: Color(0xFFE64646)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFE64646), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอก${label.toLowerCase()}';
              }
              if (label == "อีเมล" && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'กรุณากรอกอีเมลให้ถูกต้อง';
              }
              return null;
            },
          ),
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 8.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Color(0xFFE64646),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String errorText,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black38),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFE64646)),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleVisibility,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFE64646), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอก${label.toLowerCase()}';
              }
              if (value.length < 8 && label == "รหัสผ่าน") {
                return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
              }
              if (label == "ยืนยันรหัสผ่าน" && value != passwordController.text) {
                return 'รหัสผ่านไม่ตรงกัน';
              }
              return null;
            },
          ),
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 8.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Color(0xFFE64646),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}