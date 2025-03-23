// import 'package:flutter/material.dart';
// import 'login_screen.dart';
// import '../../services/auth_service.dart';
//
// class ResetPasswordScreen extends StatefulWidget {
//   final String email;
//
//   ResetPasswordScreen({required this.email});
//
//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }
//
// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final AuthService _authService = AuthService();
//   bool _isEmailSent = false; // เพิ่มตัวแปรเพื่อตรวจสอบว่าส่งอีเมลแล้วหรือไม่
//
//   void sendPasswordResetEmail() async {
//     try {
//       await _authService.sendPasswordResetEmail(widget.email);
//       setState(() {
//         _isEmailSent = true; // เปลี่ยนสถานะเมื่อส่งอีเมลสำเร็จ
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งอีเมลรีเซ็ตรหัสผ่าน: $e')),
//       );
//     }
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
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "รีเซ็ตรหัสผ่าน",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 20),
//             if (!_isEmailSent) ...[
//               Text(
//                 "เราจะส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณ: ${widget.email}",
//                 style: TextStyle(fontSize: 14),
//               ),
//               SizedBox(height: 40),
//               Center(
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: sendPasswordResetEmail,
//                     child: Text(
//                       "ส่งอีเมลรีเซ็ตรหัสผ่าน",
//                       style: TextStyle(fontSize: 18, color: Colors.white),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
//                       padding: EdgeInsets.symmetric(vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ] else ...[
//               Text(
//                 "ส่งอีเมลรีเซ็ตรหัสผ่านเรียบร้อยแล้ว!",
//                 style: TextStyle(fontSize: 16, color: Colors.green),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 "กรุณาตรวจสอบอีเมลของคุณ (${widget.email}) และคลิกลิงก์เพื่อรีเซ็ตรหัสผ่าน",
//                 style: TextStyle(fontSize: 14),
//               ),
//               SizedBox(height: 40),
//               Center(
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => LoginScreen()),
//                       );
//                     },
//                     child: Text(
//                       "กลับไปที่หน้าเข้าสู่ระบบ",
//                       style: TextStyle(fontSize: 18, color: Colors.white),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
//                       padding: EdgeInsets.symmetric(vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }