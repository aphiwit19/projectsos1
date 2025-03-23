class EmergencyNumber {
  final String numberId;
  final String serviceName;
  final String phoneNumber;
  final String category;
  final int order; // เพิ่ม field order

  EmergencyNumber({
    required this.numberId,
    required this.serviceName,
    required this.phoneNumber,
    required this.category,
    required this.order,
  });

  // แปลงจาก JSON (Firestore) เป็น Object
  factory EmergencyNumber.fromJson(String numberId, Map<String, dynamic> json) {
    return EmergencyNumber(
      numberId: numberId,
      serviceName: json['ServiceName'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      category: json['Category'] ?? '',
      order: json['order'] ?? 0, // เพิ่ม order
    );
  }

  // แปลงจาก Object เป็น JSON เพื่อบันทึกใน Firestore
  Map<String, dynamic> toJson() {
    return {
      'ServiceName': serviceName,
      'PhoneNumber': phoneNumber,
      'Category': category,
      'order': order,
    };
  }
}