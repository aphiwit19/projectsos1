// lib/models/user_profile_model.dart
class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String gender;
  final String bloodType;
  final String medicalConditions;
  final String allergies;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.bloodType,
    required this.medicalConditions,
    required this.allergies,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      bloodType: json['bloodType'] ?? '',
      medicalConditions: json['medicalConditions'] ?? '',
      allergies: json['allergies'] ?? '',
    );
  }
}