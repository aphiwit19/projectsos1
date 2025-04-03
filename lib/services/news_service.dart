import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ดึงข่าวทั้งหมด
  Future<List<News>> getAllNews() async {
    try {
      debugPrint('Fetching all news from Firestore...');
      QuerySnapshot snapshot = await _firestore
          .collection('news')
          .get();
      
      debugPrint('Fetched ${snapshot.docs.length} news items');

      if (snapshot.docs.isEmpty) {
        debugPrint('No news found in Firestore');
      }

      List<News> allNews = snapshot.docs.map((doc) {
        debugPrint('Processing news document: ${doc.id}');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return News.fromJson(data);
      }).toList();

      return allNews;
    } catch (e) {
      debugPrint('Failed to load news: $e');
      throw Exception('Failed to load news: $e');
    }
  }
} 