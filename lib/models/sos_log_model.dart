// lib/models/sos_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SosLog {
  final String id;
  final Timestamp timestamp;
  final Map<String, double> location;
  final String mapLink;
  final String message;
  final Map<String, dynamic> userInfo;
  final List<String> recipients; // เพิ่มฟิลด์นี้

  SosLog({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.mapLink,
    required this.message,
    required this.userInfo,
    required this.recipients,
  });

  factory SosLog.fromJson(Map<String, dynamic> json, String id) {
    return SosLog(
      id: id,
      timestamp: json['timestamp'] ?? Timestamp.now(),
      location: Map<String, double>.from(json['location'] ?? {}),
      mapLink: json['mapLink'] ?? '',
      message: json['message'] ?? '',
      userInfo: Map<String, dynamic>.from(json['userInfo'] ?? {}),
      recipients: List<String>.from(json['recipients'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'location': location,
      'mapLink': mapLink,
      'message': message,
      'userInfo': userInfo,
      'recipients': recipients,
    };
  }
}