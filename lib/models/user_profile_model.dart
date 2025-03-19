import 'dart:convert';

class UserProfile {
  final String userId; // เพิ่มฟิลด์ userId สำหรับ Primary Key
  final String phone;
  final String fullName;
  final String gender;
  final String bloodType;
  final String medicalConditions;
  final String allergies;

  UserProfile({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.bloodType,
    required this.medicalConditions,
    required this.allergies,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phone': phone,
      'fullName': fullName,
      'gender': gender,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      gender: json['gender'] ?? '',
      bloodType: json['bloodType'] ?? '',
      medicalConditions: json['medicalConditions'] ?? '',
      allergies: json['allergies'] ?? '',
    );
  }

  // เพิ่ม method เพื่อแปลงเป็น String สำหรับการ debug
  @override
  String toString() {
    return 'UserProfile(userId: $userId, phone: $phone, fullName: $fullName, gender: $gender, bloodType: $bloodType, medicalConditions: $medicalConditions, allergies: $allergies)';
  }
}