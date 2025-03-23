import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_contact_model.dart';
import 'firebase_service.dart';

class EmergencyContactService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  Future<String?> _getEmailFromUserId(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('Users')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        print('User not found for userId: $userId');
        return null;
      }
      return query.docs.first.id; // คืนค่า email ซึ่งเป็น Document ID
    } catch (e) {
      print('Error getting email from userId: $e');
      return null;
    }
  }

  Future<List<EmergencyContact>> getEmergencyContacts(String userId) async {
    try {
      String? email = await _getEmailFromUserId(userId);
      if (email == null) {
        print('No email found for userId: $userId, returning empty list');
        return [];
      }
      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(email)
          .collection('EmergencyContacts')
          .get();
      return snapshot.docs
          .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading emergency contacts: $e');
      return [];
    }
  }

  Future<void> addContact(String userId, EmergencyContact contact) async {
    try {
      String? email = await _getEmailFromUserId(userId);
      if (email == null) {
        throw Exception('User not found');
      }
      CollectionReference contactsRef =
      _firestore.collection('Users').doc(email).collection('EmergencyContacts');
      print('Adding contact: ${contact.toJson()}');
      await contactsRef.doc(contact.contactId).set(contact.toJson());
      print('Contact added successfully');
    } catch (e) {
      print('Error adding contact: $e');
      throw Exception('Failed to add contact: $e');
    }
  }

  Future<void> updateContact(String userId, EmergencyContact contact) async {
    try {
      String? email = await _getEmailFromUserId(userId);
      if (email == null) {
        throw Exception('User not found');
      }
      CollectionReference contactsRef =
      _firestore.collection('Users').doc(email).collection('EmergencyContacts');
      print('Updating contact: ${contact.toJson()}');
      await contactsRef.doc(contact.contactId).update(contact.toJson());
      print('Contact updated successfully');
    } catch (e) {
      print('Error updating contact: $e');
      throw Exception('Failed to update contact: $e');
    }
  }

  Future<void> deleteContact(String userId, String contactId) async {
    try {
      String? email = await _getEmailFromUserId(userId);
      if (email == null) {
        throw Exception('User not found');
      }
      CollectionReference contactsRef =
      _firestore.collection('Users').doc(email).collection('EmergencyContacts');
      print('Deleting contact: $contactId');
      await contactsRef.doc(contactId).delete();
      print('Contact deleted successfully');
    } catch (e) {
      print('Error deleting contact: $e');
      throw Exception('Failed to delete contact: $e');
    }
  }
}