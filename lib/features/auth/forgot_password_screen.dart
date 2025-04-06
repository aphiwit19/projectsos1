import 'package:flutter/material.dart';
import 'package:projectappsos/features/auth/login_screen.dart';
import 'package:projectappsos/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  String emailError = '';
  bool _isEmailSent = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        emailError = '';
        _isLoading = true;
      });

      String email = emailController.text.trim();

      try {
        await _authService.sendPasswordResetEmail(email);
        setState(() {
          _isEmailSent = true;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          emailError = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการส่งอีเมล: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Color(0xFFE64646),
          ),
        );
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
              child: !_isEmailSent
                ? _buildRequestPasswordResetForm()
                : _buildSuccessScreen(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRequestPasswordResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        // รูปภาพด้านบน
        Center(
          child: Container(
            height: 240,
            width: 280,
            child: Image.asset(
              'assets/images/forgotpassword_image.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 24),
        // หัวข้อ
        Center(
          child: Text(
            "ลืมรหัสผ่าน",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            "กรุณากรอกอีเมลเพื่อรับลิงก์รีเซ็ตรหัสผ่าน",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 40),
        // ฟอร์มอีเมล
        _buildInputField(
          controller: emailController,
          label: "อีเมล",
          hintText: "กรุณากรอกอีเมล",
          icon: Icons.email_outlined,
          errorText: emailError,
        ),
        SizedBox(height: 40),
        // ปุ่มส่งอีเมลรีเซ็ตรหัสผ่าน
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
            onPressed: _isLoading ? null : sendPasswordResetEmail,
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
                  "ส่งลิงก์รีเซ็ตรหัสผ่าน",
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
              "จำรหัสผ่านได้แล้ว? ",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
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
    );
  }
  
  Widget _buildSuccessScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40),
        // ไอคอนสำเร็จ
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: 100,
              color: Color(0xFFE64646),
            ),
          ),
        ),
        SizedBox(height: 30),
        Text(
          "ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "เราได้ส่งลิงก์สำหรับรีเซ็ตรหัสผ่านไปที่\n${emailController.text}\nกรุณาตรวจสอบอีเมลและทำตามคำแนะนำ",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 40),
        // กลับไปหน้าเข้าสู่ระบบ
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE64646),
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              "กลับไปหน้าเข้าสู่ระบบ",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String errorText,
    TextInputType keyboardType = TextInputType.emailAddress,
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
                return 'กรุณากรอกอีเมล';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
}