import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> seedEmergencyNumbers() async {
  final firestore = FirebaseFirestore.instance;

  final emergencyNumbers = [
    {'NumberID': 'number_001', 'ServiceName': 'ตำรวจ', 'PhoneNumber': '191', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 1},
    {'NumberID': 'number_002', 'ServiceName': 'สายด่วน 199', 'PhoneNumber': '199', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 2},
    {'NumberID': 'number_003', 'ServiceName': 'กู้ภัยมูลนิธิ', 'PhoneNumber': '1196', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 3},
    {'NumberID': 'number_004', 'ServiceName': 'โรงพยาบาล', 'PhoneNumber': '1154', 'Category': 'กรณีเจ็บป่วย', 'order': 4},
    {'NumberID': 'number_005', 'ServiceName': 'สายด่วนปฐมพยาบาล', 'PhoneNumber': '1669', 'Category': 'กรณีเจ็บป่วย', 'order': 5},
    {'NumberID': 'number_006', 'ServiceName': 'สายด่วนพิษภัย', 'PhoneNumber': '1646', 'Category': 'กรณีเจ็บป่วย', 'order': 6},
    {'NumberID': 'number_007', 'ServiceName': 'สายด่วนจราจร', 'PhoneNumber': '1586', 'Category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'order': 7},
    {'NumberID': 'number_008', 'ServiceName': 'สายด่วนกรมทางหลวง', 'PhoneNumber': '1197', 'Category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'order': 8},
    {'NumberID': 'number_009', 'ServiceName': 'สายด่วนกรมทางด่วน', 'PhoneNumber': '1137', 'Category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'order': 9},
    {'NumberID': 'number_0010', 'ServiceName': 'สายด่วนกรมทางเหนือ', 'PhoneNumber': '1138', 'Category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'order': 10},
    {'NumberID': 'number_0011', 'ServiceName': 'สายด่วนกรมทางอีสาน', 'PhoneNumber': '1139', 'Category': 'แจ้งเหตุจราจร-ขอความช่วยเหลือ', 'order': 11},
  ];

  try {
    for (var number in emergencyNumbers) {
      await firestore.collection('Emergency_Numbers').doc(number['NumberID'] as String?).set({
        'ServiceName': number['ServiceName'],
        'PhoneNumber': number['PhoneNumber'],
        'Category': number['Category'],
        'order': number['order'], // เพิ่ม field order
      });
      print('Added ${number['ServiceName']} to Firestore with order ${number['order']}');
    }
    print('Seeding completed.');
  } catch (e) {
    print('Error during seeding: $e');
  }
}

void main() async {
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA4XFPXbrH7uF0HBIAfNOpobR3w_A84qvl",
        appId: "1:743149788728:android:e08214bebf7148189050cd",
        messagingSenderId: "743149788728",
        projectId: "projectappsos",
      ),
    );
    print('Firebase initialized successfully.');

    print('Starting seeding...');
    await seedEmergencyNumbers();
    print('Seeding completed.');
  } catch (e) {
    print('Error during initialization or seeding: $e');
  }
}