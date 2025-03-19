import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  Future<void> saveProfile(UserProfile userProfile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', jsonEncode(userProfile.toJson()));
      await prefs.setBool('hasProfile', true);
      // เมื่อเชื่อม Firebase: ใช้ Firestore เช่น db.collection('users').doc(userProfile.userId).set(...)
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        return UserProfile.fromJson(jsonDecode(profileJson));
      }
      return null;
      // เมื่อเชื่อม Firebase: return db.collection('users').doc(userId).get()
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}