import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> seedEmergencyNumbers() async {
  final firestore = FirebaseFirestore.instance;

  final emergencyNumbers = [
    // หมวด: เหตุด่วนเหตุร้าย
    {'NumberID': 'number_001', 'ServiceName': 'แจ้งเหตุด่วนเหตุร้ายกับเจ้าหน้าที่ตำรวจ', 'PhoneNumber': '191', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 1},
    {'NumberID': 'number_002', 'ServiceName': 'แจ้งเหตุไฟไหม้/ดับเพลิง', 'PhoneNumber': '199', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 2},
    {'NumberID': 'number_003', 'ServiceName': 'ศูนย์ปราบปรามการโจรกรรมรถ (แจ้งรถหาย)', 'PhoneNumber': '1192', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 3},
    {'NumberID': 'number_004', 'ServiceName': 'กองปราบ (สายด่วนแจ้งเหตุอาชญากรรม คดีร้ายแรง)', 'PhoneNumber': '1195', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 4},
    {'NumberID': 'number_005', 'ServiceName': 'แจ้งคนหาย', 'PhoneNumber': '1300', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 5},
    {'NumberID': 'number_006', 'ServiceName': 'ร่วมด้วยช่วยกัน', 'PhoneNumber': '1677', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 6},
    {'NumberID': 'number_007', 'ServiceName': 'ศูนย์เตือนภัยพิบัติแห่งชาติ', 'PhoneNumber': '192', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 7},
    {'NumberID': 'number_008', 'ServiceName': 'แจ้งอุบัติเหตุทางน้ำ', 'PhoneNumber': '1196', 'Category': 'เหตุด่วนเหตุร้าย', 'order': 8},

    // หมวด: การแพทย์และโรงพยาบาล
    {'NumberID': 'number_009', 'ServiceName': 'สถาบันการแพทย์ฉุกเฉินแห่งชาติ (ทั่วประเทศ)', 'PhoneNumber': '1669', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 9},
    {'NumberID': 'number_010', 'ServiceName': 'หน่วยแพทย์ฉุกเฉิน (กทม.)', 'PhoneNumber': '1646', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 10},
    {'NumberID': 'number_011', 'ServiceName': 'หน่วยแพทย์กู้ชีวิต วชิรพยาบาล', 'PhoneNumber': '1554', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 11},
    {'NumberID': 'number_012', 'ServiceName': 'โรงพยาบาลตำรวจ', 'PhoneNumber': '1691', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 12},
    {'NumberID': 'number_013', 'ServiceName': 'สายด่วนกรมสุขภาพจิต', 'PhoneNumber': '1667', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 13},
    {'NumberID': 'number_014', 'ServiceName': 'กรมป้องกันและบรรเทาสาธารณภัย', 'PhoneNumber': '1784', 'Category': 'การแพทย์และโรงพยาบาล', 'order': 14},

    // หมวด: สาธารณูปโภค
    {'NumberID': 'number_015', 'ServiceName': 'การไฟฟ้าส่วนภูมิภาค', 'PhoneNumber': '1129', 'Category': 'สาธารณูปโภค', 'order': 15},
    {'NumberID': 'number_016', 'ServiceName': 'การไฟฟ้านครหลวง', 'PhoneNumber': '1130', 'Category': 'สาธารณูปโภค', 'order': 16},
    {'NumberID': 'number_017', 'ServiceName': 'การประปานครหลวง', 'PhoneNumber': '1125', 'Category': 'สาธารณูปโภค', 'order': 17},
    {'NumberID': 'number_018', 'ServiceName': 'การประปาส่วนภูมิภาค', 'PhoneNumber': '1162', 'Category': 'สาธารณูปโภค', 'order': 18},
    {'NumberID': 'number_019', 'ServiceName': 'สำนักงานประกันสังคม', 'PhoneNumber': '1506', 'Category': 'สาธารณูปโภค', 'order': 19},
    {'NumberID': 'number_020', 'ServiceName': 'สายด่วนประกันภัย', 'PhoneNumber': '1186', 'Category': 'สาธารณูปโภค', 'order': 20},

    // หมวด: ระหว่างเดินทาง
    {'NumberID': 'number_021', 'ServiceName': 'กรมทางพิเศษแห่งประเทศไทย', 'PhoneNumber': '1543', 'Category': 'ระหว่างเดินทาง', 'order': 21},
    {'NumberID': 'number_022', 'ServiceName': 'ตำรวจทางหลวง', 'PhoneNumber': '1193', 'Category': 'ระหว่างเดินทาง', 'order': 22},
    {'NumberID': 'number_023', 'ServiceName': 'ตำรวจท่องเที่ยว', 'PhoneNumber': '1155', 'Category': 'ระหว่างเดินทาง', 'order': 23},
    {'NumberID': 'number_024', 'ServiceName': 'สวพ. FM91 สถานีวิทยุเพื่อความปลอดภัยและจราจร', 'PhoneNumber': '1644', 'Category': 'ระหว่างเดินทาง', 'order': 24},
    {'NumberID': 'number_025', 'ServiceName': 'การรถไฟแห่งประเทศไทย', 'PhoneNumber': '1690', 'Category': 'ระหว่างเดินทาง', 'order': 25},
    {'NumberID': 'number_026', 'ServiceName': 'กรมทางหลวงชนบท', 'PhoneNumber': '1146', 'Category': 'ระหว่างเดินทาง', 'order': 26},
    {'NumberID': 'number_027', 'ServiceName': 'ศูนย์ช่วยเหลือนักท่องเที่ยว (TAC)', 'PhoneNumber': '02-134-4077', 'Category': 'ระหว่างเดินทาง', 'order': 27},
  ];

  try {
    for (var number in emergencyNumbers) {
      await firestore.collection('Emergency_Numbers').doc(number['NumberID'] as String?).set({
        'ServiceName': number['ServiceName'],
        'PhoneNumber': number['PhoneNumber'],
        'Category': number['Category'],
        'order': number['order'],
      });
      print('Added ${number['ServiceName']} to Firestore with order ${number['order']}');
    }
    print('Seeding completed.');
  } catch (e) {
    print('Error during seeding: $e');
  }
}