import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_number_model.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';

class EmergencyNumberService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ดึงข้อมูลหมายเลขฉุกเฉินทั้งหมด โดยเรียงตาม order
  Future<List<EmergencyNumber>> getEmergencyNumbers() async {
    try {
      debugPrint('Fetching emergency numbers from Firestore...');
      QuerySnapshot snapshot = await _firestore
          .collection('Emergency_Numbers')
          .orderBy('order') // เรียงตาม field order
          .get();
      debugPrint('Fetched ${snapshot.docs.length} emergency numbers');

      if (snapshot.docs.isEmpty) {
        debugPrint('No emergency numbers found in Firestore');
      }

      return snapshot.docs.map((doc) {
        debugPrint('Processing document: ${doc.id}');
        return EmergencyNumber.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Failed to load emergency numbers: $e');
      throw Exception('Failed to load emergency numbers: $e');
    }
  }
}