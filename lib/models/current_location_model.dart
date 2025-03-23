import 'dart:convert';

class CurrentLocation {
  final String locationId;
  final String userId;
  final String email; // เพิ่ม email
  final double latitude;
  final double longitude;
  final DateTime timestamp; // เปลี่ยนเป็น DateTime

  CurrentLocation({
    required this.locationId,
    required this.userId,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'userId': userId,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      locationId: json['locationId'] ?? '',
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'CurrentLocation(locationId: $locationId, userId: $userId, email: $email, latitude: $latitude, longitude: $longitude, timestamp: $timestamp)';
  }
}