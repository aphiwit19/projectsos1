import 'dart:convert';

class CurrentLocation {
  final String locationId;
  final String userId;
  final double latitude;
  final double longitude;
  final String timestamp; // ใช้ String ชั่วคราว (จะเปลี่ยนเป็น DateTime เมื่อใช้ Firebase)

  CurrentLocation({
    required this.locationId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      locationId: json['locationId'] ?? '',
      userId: json['userId'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] ?? '',
    );
  }

  @override
  String toString() {
    return 'CurrentLocation(locationId: $locationId, userId: $userId, latitude: $latitude, longitude: $longitude, timestamp: $timestamp)';
  }
}