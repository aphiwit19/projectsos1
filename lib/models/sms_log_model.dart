import 'dart:convert';

class SMSLog {
  final String smsId;
  final String userId;
  final String locationId;
  final String contactId;
  final String recipientNumber;
  final String messageContent;
  final String sentTime; // ใช้ String ชั่วคราว (จะเปลี่ยนเป็น DateTime เมื่อใช้ Firebase)
  final double latitude;
  final double longitude;

  SMSLog({
    required this.smsId,
    required this.userId,
    required this.locationId,
    required this.contactId,
    required this.recipientNumber,
    required this.messageContent,
    required this.sentTime,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'smsId': smsId,
      'userId': userId,
      'locationId': locationId,
      'contactId': contactId,
      'recipientNumber': recipientNumber,
      'messageContent': messageContent,
      'sentTime': sentTime,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory SMSLog.fromJson(Map<String, dynamic> json) {
    return SMSLog(
      smsId: json['smsId'] ?? '',
      userId: json['userId'] ?? '',
      locationId: json['locationId'] ?? '',
      contactId: json['contactId'] ?? '',
      recipientNumber: json['recipientNumber'] ?? '',
      messageContent: json['messageContent'] ?? '',
      sentTime: json['sentTime'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'SMSLog(smsId: $smsId, userId: $userId, locationId: $locationId, contactId: $contactId, recipientNumber: $recipientNumber, messageContent: $messageContent, sentTime: $sentTime, latitude: $latitude, longitude: $longitude)';
  }
}