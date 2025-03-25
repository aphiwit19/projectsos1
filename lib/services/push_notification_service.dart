// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class PushNotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//   Future<void> initialize(String userId) async {
//     try {
//       // ขอสิทธิ์การแจ้งเตือน
//       NotificationSettings settings = await _firebaseMessaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true,
//       );
//
//       print('User granted permission: ${settings.authorizationStatus}');
//
//       // ดึง FCM Token
//       String? token = await _firebaseMessaging.getToken();
//       if (token != null) {
//         print("FCM Token: $token");
//         // บันทึก FCM Token ลงใน Firestore
//         await _saveTokenToFirestore(userId, token);
//       } else {
//         print("Failed to get FCM token");
//       }
//
//       // ฟังการเปลี่ยนแปลงของ Token (เช่น ถ้า Token ถูกรีเฟรช)
//       _firebaseMessaging.onTokenRefresh.listen((newToken) {
//         print("FCM Token refreshed: $newToken");
//         _saveTokenToFirestore(userId, newToken);
//       });
//
//       // ตั้งค่าการจัดการเมื่อได้รับการแจ้งเตือน
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print('Got a message whilst in the foreground!');
//         print('Message data: ${message.data}');
//         if (message.notification != null) {
//           print('Message also contained a notification: ${message.notification}');
//         }
//       });
//
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         print('A new onMessageOpenedApp event was published!');
//         print('Message data: ${message.data}');
//       });
//     } catch (e) {
//       print("Error initializing push notifications: $e");
//     }
//   }
//
//   Future<void> _saveTokenToFirestore(String userId, String token) async {
//     try {
//       // ค้นหาเอกสารของผู้ใช้โดยใช้ userId
//       final userQuery = await FirebaseFirestore.instance
//           .collection('Users')
//           .where('uid', isEqualTo: userId)
//           .limit(1)
//           .get();
//
//       if (userQuery.docs.isNotEmpty) {
//         final userDoc = userQuery.docs.first;
//         await FirebaseFirestore.instance
//             .collection('Users')
//             .doc(userDoc.id)
//             .update({
//           'fcmToken': token,
//           'updatedAt': Timestamp.now(),
//         });
//         print("FCM Token saved to Firestore for user: ${userDoc.id}");
//       } else {
//         print("No user found with uid: $userId");
//       }
//     } catch (e) {
//       print("Error saving FCM token to Firestore: $e");
//     }
//   }
// }