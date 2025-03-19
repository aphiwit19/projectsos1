import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactService {
  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> contactList = contacts.map((contact) => contact.toJson()).toList();
      await prefs.setString('emergencyContacts', jsonEncode(contactList));
    } catch (e) {
      throw Exception('Failed to save contacts: $e');
    }
  }

  Future<List<EmergencyContact>> getContacts(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? contactsJson = prefs.getString('emergencyContacts');
      if (contactsJson != null) {
        List<dynamic> contactList = jsonDecode(contactsJson);
        return contactList.map((json) => EmergencyContact.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load contacts: $e');
    }
  }
}