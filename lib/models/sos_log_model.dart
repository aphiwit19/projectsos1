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
  final Map<String, dynamic> extraData; // เพิ่มฟิลด์นี้เพื่อเก็บข้อมูลเพิ่มเติม เช่น สถานะการส่ง SMS

  SosLog({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.mapLink,
    required this.message,
    required this.userInfo,
    required this.recipients,
    this.extraData = const {}, // ค่าเริ่มต้นเป็น map ว่าง
  });

  factory SosLog.fromJson(Map<String, dynamic> json, String id) {
    // คัดแยกข้อมูลพื้นฐานและเก็บข้อมูลที่เหลือลงใน extraData
    Map<String, dynamic> extraData = Map.from(json);
    
    // ลบข้อมูลพื้นฐานออกจาก extraData
    ['timestamp', 'location', 'mapLink', 'message', 'userInfo', 'recipients'].forEach((key) {
      extraData.remove(key);
    });
    
    return SosLog(
      id: id,
      timestamp: json['timestamp'] ?? Timestamp.now(),
      location: Map<String, double>.from(json['location'] ?? {}),
      mapLink: json['mapLink'] ?? '',
      message: json['message'] ?? '',
      userInfo: Map<String, dynamic>.from(json['userInfo'] ?? {}),
      recipients: List<String>.from(json['recipients'] ?? []),
      extraData: extraData, // เก็บข้อมูลอื่นๆ ที่เหลือทั้งหมด
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> base = {
      'timestamp': timestamp,
      'location': location,
      'mapLink': mapLink,
      'message': message,
      'userInfo': userInfo,
      'recipients': recipients,
    };
    
    // รวมข้อมูลจาก extraData
    return {...base, ...extraData};
  }
}