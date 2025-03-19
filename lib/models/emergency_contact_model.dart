import 'dart:convert';

class EmergencyContact {
  final String contactId; // เพิ่มฟิลด์ contactId
  final String userId; // เพิ่มฟิลด์ userId เพื่อเชื่อมโยงกับผู้ใช้
  final String name;
  final String phone;

  EmergencyContact({
    required this.contactId,
    required this.userId,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'userId': userId,
      'name': name,
      'phone': phone,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      contactId: json['contactId'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  @override
  String toString() {
    return 'EmergencyContact(contactId: $contactId, userId: $userId, name: $name, phone: $phone)';
  }
}