import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/edit_user_profile_screen.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String phoneError = '';
  String passwordError = '';
  String confirmPasswordError = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> registerWithMockData() async {
    setState(() {
      phoneError = '';
      passwordError = '';
      confirmPasswordError = '';
    });

    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    bool hasError = false;

    if (phone.isEmpty) {
      setState(() {
        phoneError = 'กรุณากรอกเบอร์มือถือ';
      });
      hasError = true;
    } else if (phone.length != 10 || !RegExp(r'^0\d{9}$').hasMatch(phone)) {
      setState(() {
        phoneError = 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก (เริ่มต้นด้วย 0)';
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = 'กรุณากรอกรหัสผ่าน';
      });
      hasError = true;
    } else if (password.length < 8) {
      setState(() {
        passwordError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
      });
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        confirmPasswordError = 'กรุณากรอกยืนยันรหัสผ่าน';
      });
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
      });
      hasError = true;
    }

    if (!hasError) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('phone', phone);
      await prefs.setBool('hasProfile', false);

      print("สมัครสมาชิกสำเร็จ: $phone");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditUserProfileScreen(),
          // ส่งข้อมูลเบื้องต้นไปยัง EditUserProfileScreen
          settings: RouteSettings(arguments: {'phone': phone}),
        ),
      );
    }
  }

  void navigateToLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

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

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1.0),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "ลงทะเบียน",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text("เบอร์โทรศัพท์", style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
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
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                if (phoneError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                    child: Text(
                      phoneError,
                      style: TextStyle(
                        color: Color.fromRGBO(230, 70, 70, 1.0),
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Text("รหัสผ่าน", style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'กรุณากรอกรหัสผ่าน',
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
                Text("ยืนยันรหัสผ่าน", style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'กรุณากรอกยืนยันรหัสผ่าน',
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
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerWithMockData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "ลงทะเบียน",
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
                    onPressed: navigateToLoginScreen,
                    child: RichText(
                      text: TextSpan(
                        text: "มีบัญชีอยู่แล้ว? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "เข้าสู่ระบบตอนนี้",
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
    );
  }
}