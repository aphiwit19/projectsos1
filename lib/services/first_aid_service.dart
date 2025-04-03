import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/first_aid.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';

class FirstAidService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ดึงข้อมูลการปฐมพยาบาลทั้งหมด
  Future<List<FirstAid>> getFirstAidItems() async {
    try {
      debugPrint('Fetching first aid items from Firestore...');
      QuerySnapshot snapshot = await _firestore
          .collection('firstAid')
          .get();
      debugPrint('Fetched ${snapshot.docs.length} first aid items');

      if (snapshot.docs.isEmpty) {
        debugPrint('No first aid items found in Firestore');
      }

      List<FirstAid> allItems = snapshot.docs.map((doc) {
        debugPrint('Processing document: ${doc.id}');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FirstAid.fromJson(data);
      }).toList();

      return allItems;
    } catch (e) {
      debugPrint('Failed to load first aid items: $e');
      throw Exception('Failed to load first aid items: $e');
    }
  }
} 