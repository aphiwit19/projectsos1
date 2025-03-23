import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/user_profile_model.dart';
import 'firebase_service.dart';

class ProfileService {
  Future<void> saveProfile(UserProfile userProfile) async {
    try {
      if (userProfile.uid.isEmpty) {
        throw Exception('UserProfile must have a valid uid');
      }
      await FirebaseService.firestore.collection('Users').doc(userProfile.email).set(
        userProfile.toJson(),
        SetOptions(merge: true),
      );
      debugPrint('Profile saved successfully for email: ${userProfile.email}');
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<UserProfile?> getProfile(String email) async {
    try {
      DocumentSnapshot doc = await FirebaseService.firestore.collection('Users').doc(email).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> updateEmail(String oldEmail, String newEmail) async {
    try {
      DocumentSnapshot doc = await FirebaseService.firestore.collection('Users').doc(oldEmail).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['email'] = newEmail;
        await FirebaseService.firestore.collection('Users').doc(newEmail).set(data);
        await FirebaseService.firestore.collection('Users').doc(oldEmail).delete();
      }
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }
}