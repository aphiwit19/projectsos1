class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String gender;
  final String bloodType;
  final String medicalConditions;
  final String allergies;
  final String phone;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.bloodType,
    required this.medicalConditions,
    required this.allergies,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'phone': phone,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      gender: json['gender'] ?? '',
      bloodType: json['bloodType'] ?? '',
      medicalConditions: json['medicalConditions'] ?? '',
      allergies: json['allergies'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, fullName: $fullName, gender: $gender, bloodType: $bloodType, medicalConditions: $medicalConditions, allergies: $allergies, phone: $phone)';
  }
}