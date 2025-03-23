// import 'package:flutter/material.dart';
// import 'reset_password_screen.dart';
// import '../../services/auth_service.dart';
//
// class OTPVerificationScreen extends StatefulWidget {
//   final String email;
//
//   OTPVerificationScreen({required this.email});
//
//   @override
//   _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
// }
//
// class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
//   final List<TextEditingController> otpControllers = List.generate(4, (_) => TextEditingController());
//   String errorMessage = '';
//   final AuthService _authService = AuthService();
//
//   void verifyOTP() async {
//     String otp = otpControllers.map((controller) => controller.text.trim()).join();
//
//     if (otp.length != 4) {
//       setState(() {
//         errorMessage = 'กรุณากรอก OTP ให้ครบ 4 ตัว';
//       });
//       return;
//     }
//
//     try {
//       bool isValid = await _authService.verifyOTP(widget.email, otp);
//       if (isValid) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => ResetPasswordScreen(email: widget.email)),
//         );
//       } else {
//         setState(() {
//           errorMessage = 'รหัส OTP ไม่ถูกต้อง';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'เกิดข้อผิดพลาด: $e';
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     for (var controller in otpControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         color: Colors.white,
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "กรุณาตรวจสอบรหัส OTP ที่อีเมลของคุณ",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             Text(
//               "เราได้ส่งรหัสยืนยันไปที่อีเมลของคุณ (ใช้ 5555 เพื่อทดสอบ)",
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(4, (index) {
//                 return Container(
//                   width: 50,
//                   height: 50,
//                   margin: EdgeInsets.symmetric(horizontal: 10),
//                   child: TextField(
//                     controller: otpControllers[index],
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       counterText: "",
//                     ),
//                     keyboardType: TextInputType.number,
//                     maxLength: 1,
//                     textAlign: TextAlign.center,
//                     onChanged: (value) {
//                       if (value.length == 1 && index < 3) {
//                         FocusScope.of(context).nextFocus();
//                       }
//                     },
//                   ),
//                 );
//               }),
//             ),
//             SizedBox(height: 20),
//             Text(
//               errorMessage,
//               style: TextStyle(color: Color.fromRGBO(230, 70, 70, 1.0)),
//             ),
//             SizedBox(height: 20),
//             Center(
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: verifyOTP,
//                   child: Text(
//                     "ตรวจสอบ",
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
//                     padding: EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }