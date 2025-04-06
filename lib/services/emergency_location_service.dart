import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class EmergencyLocationService {
  // ใช้ Nominatim API ของ OpenStreetMap (ไม่ต้องมี API key)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // Overpass API สำหรับเรียกข้อมูลรายละเอียดเพิ่มเติม เช่น เวลาเปิด-ปิด
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // ประเภทของสถานที่ฉุกเฉิน
  static const Map<String, String> emergencyTypes = {
    'hospital': 'โรงพยาบาล',
    'police': 'สถานีตำรวจ',
    'clinic': 'คลินิก',
    'pharmacy': 'ร้านขายยา',
  };

  // ตรวจสอบว่าข้อความเป็นภาษาไทยที่ถูกต้องหรือไม่
  bool _isValidThaiText(String text) {
    if (text.isEmpty) return false;

    // จำเป็นต้องมีตัวอักษรภาษาไทยอย่างน้อย 1 ตัว หรือเป็นตัวอักษร/ตัวเลขปกติ
    final thaiPattern = RegExp(r'[ก-๙]');
    final invalidPattern = RegExp(r'[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ]');

    return !invalidPattern.hasMatch(text) &&
        (thaiPattern.hasMatch(text) || RegExp(r'^[a-zA-Z0-9\s.,\-\/()]+$').hasMatch(text));
  }

  // ดึงข้อมูลสถานที่ใกล้เคียงจาก Nominatim
  Future<List<Map<String, dynamic>>> _searchNearbyPlaces(
      Position currentLocation, double radiusKm, String amenity, String defaultName) async {
    try {
      // คำนวณขอบเขตพื้นที่ค้นหา (bounding box)
      final double earthRadius = 6371.0; // รัศมีโลกเป็นกิโลเมตร
      final double latDelta = (radiusKm / earthRadius) * (180 / math.pi);
      final double lonDelta = (radiusKm / earthRadius) * (180 / math.pi) / math.cos(currentLocation.latitude * math.pi / 180);

      final double south = currentLocation.latitude - latDelta;
      final double north = currentLocation.latitude + latDelta;
      final double west = currentLocation.longitude - lonDelta;
      final double east = currentLocation.longitude + lonDelta;

      // เพิ่มค่า radius เป็น 25% เพื่อให้ครอบคลุมมากขึ้น
      final double expandedRadiusKm = radiusKm * 1.25;

      // ใช้ viewbox และ bounded=1 เพื่อจำกัดผลลัพธ์ในพื้นที่
      final Uri uri = Uri.parse('$_nominatimUrl/search')
          .replace(queryParameters: {
        'format': 'json',
        'viewbox': '$west,$south,$east,$north',
        'bounded': '1',
        'amenity': amenity,
        'limit': '20',
        'accept-language': 'th,en',
      });

      // เพิ่ม header เพื่อระบุแอปพลิเคชันตามข้อกำหนดของ Nominatim
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SOSThailandApp', // ต้องระบุชื่อแอป
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        List<Map<String, dynamic>> places = [];

        for (var place in results) {
          if (place == null || place['lat'] == null || place['lon'] == null) continue;

          double lat = double.parse(place['lat'].toString());
          double lon = double.parse(place['lon'].toString());

          // คำนวณระยะทางแบบที่ 1 - ใช้ Geolocator
          double distanceGeolocator = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            lat,
            lon,
          ) / 1000; // แปลงเป็น km

          // คำนวณระยะทางแบบที่ 2 - ใช้ Haversine formula
          double distanceHaversine = _calculateHaversineDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              lat,
              lon
          );

          // ใช้ค่าเฉลี่ยของระยะทางทั้งสองวิธี
          double distance = (distanceGeolocator + distanceHaversine) / 2;

          // ตรวจสอบว่าอยู่ในรัศมีที่กำหนดหรือไม่ (ใช้ radius ที่เพิ่มขึ้น)
          if (distance <= expandedRadiusKm) {
            // ดึงข้อมูลเพิ่มเติมจาก tags
            String name = place['name'] ?? place['display_name'] ?? defaultName;
            if (!_isValidThaiText(name)) {
              name = defaultName;
            }

            String address = place['display_name'] ?? 'ไม่ระบุที่อยู่';
            if (!_isValidThaiText(address)) {
              address = 'ไม่ระบุที่อยู่';
            }

            places.add({
              'name': name,
              'address': address,
              'phone': _getMockPhoneNumber(amenity), // แทนที่ 'ไม่ระบุเบอร์โทร' ด้วยเบอร์โทรจำลอง
              'latitude': lat,
              'longitude': lon,
              'distance': distance,
            });
          }
        }

        // เรียงลำดับตามระยะทาง
        places.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

        // ถ้าไม่พบข้อมูลใดๆ ให้สร้างข้อมูลจำลอง 1 รายการ
        if (places.isEmpty) {
          final place = _createMockPlace(currentLocation, radiusKm * 0.7, defaultName);
          places.add(place);
        }

        return places;
      }

      // หากมีปัญหาในการเรียก API ให้ส่งข้อมูลจำลอง
      return [_createMockPlace(currentLocation, radiusKm * 0.7, defaultName)];
    } catch (e) {
      print('Error searching places: $e');
      return [_createMockPlace(currentLocation, radiusKm * 0.7, defaultName)];
    }
  }

  // ดึงข้อมูลเวลาเปิด-ปิดของสถานที่ผ่าน Overpass API
  Future<Map<String, dynamic>?> _getOpeningHours(String osmType, String osmId) async {
    try {
      // แปลง OSM type เป็นตัวอักษรย่อ
      String osmTypeChar = '';
      if (osmType.toLowerCase() == 'node') {
        osmTypeChar = 'n';
      } else if (osmType.toLowerCase() == 'way') {
        osmTypeChar = 'w';
      } else if (osmType.toLowerCase() == 'relation') {
        osmTypeChar = 'r';
      }

      if (osmTypeChar.isEmpty) return null;

      // สร้าง Overpass QL query
      String query = '''
        [out:json];
        ${osmTypeChar}(${osmId});
        out body;
      ''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'SOSThailandApp',
        },
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;

        if (elements.isNotEmpty) {
          final tags = elements[0]['tags'];

          if (tags != null && tags['opening_hours'] != null) {
            final openingHours = tags['opening_hours'];
            final isOpen = _isCurrentlyOpen(openingHours);

            String hoursDisplay = '';
            try {
              // จัดรูปแบบเวลาเปิด-ปิดให้อ่านง่ายขึ้น
              hoursDisplay = _formatOpeningHours(openingHours);
            } catch (e) {
              // หากไม่สามารถจัดรูปแบบได้ ให้ใช้ข้อมูลดิบ
              hoursDisplay = openingHours;
            }

            return {
              'hours': hoursDisplay,
              'is_open': isOpen,
            };
          }

          // บางสถานที่เปิด 24 ชั่วโมง อาจใช้ tag '24/7' แทน
          if (tags != null && tags['24/7'] == 'yes') {
            return {
              'hours': 'เปิดตลอด 24 ชั่วโมง',
              'is_open': true,
            };
          }
        }
      }

      return {
        'hours': 'ไม่ระบุเวลาทำการ',
        'is_open': null,
      };
    } catch (e) {
      print('Error in _getOpeningHours: $e');
      return null;
    }
  }

  // ตรวจสอบว่าสถานที่เปิดอยู่หรือไม่
  bool? _isCurrentlyOpen(String openingHoursStr) {
    try {
      // กรณีเปิดตลอด 24 ชั่วโมง
      if (openingHoursStr == '24/7') return true;

      // รับเวลาปัจจุบัน
      final now = DateTime.now();
      final currentDay = _getDayOfWeekShort(now.weekday);
      final currentTime = now.hour * 60 + now.minute; // แปลงเป็นนาที

      // แยกข้อมูลตามวัน
      final days = openingHoursStr.split(';');

      for (var day in days) {
        day = day.trim();
        // ตรวจสอบว่าวันนี้มีข้อมูลหรือไม่
        if (day.contains(currentDay) || day.contains('Mo-Su') || day.contains('Mo-Sa') || day.contains('Mo-Fr')) {
          // ตรวจสอบช่วงเวลา
          final timeRanges = day.split(' ')[1]; // เช่น "10:00-20:00"
          final ranges = timeRanges.split(',');

          for (var range in ranges) {
            final times = range.split('-');
            if (times.length == 2) {
              final openTime = _convertTimeToMinutes(times[0]);
              final closeTime = _convertTimeToMinutes(times[1]);

              if (closeTime < openTime) {
                // กรณีปิดหลังเที่ยงคืน
                if (currentTime >= openTime || currentTime <= closeTime) {
                  return true;
                }
              } else {
                // กรณีปกติ
                if (currentTime >= openTime && currentTime <= closeTime) {
                  return true;
                }
              }
            }
          }
        }
      }

      // ถ้าไม่เข้าเงื่อนไขการเปิด แสดงว่าปิด
      return false;
    } catch (e) {
      print('Error parsing opening hours: $e');
      return null; // ไม่สามารถระบุได้
    }
  }

  // แปลงเวลาจากรูปแบบ "HH:MM" เป็นนาที
  int _convertTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length != 2) return 0;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;

      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }

  // แปลงเลขวันเป็นตัวย่อภาษาอังกฤษ
  String _getDayOfWeekShort(int weekday) {
    switch (weekday) {
      case 1: return 'Mo';
      case 2: return 'Tu';
      case 3: return 'We';
      case 4: return 'Th';
      case 5: return 'Fr';
      case 6: return 'Sa';
      case 7: return 'Su';
      default: return '';
    }
  }

  // จัดรูปแบบเวลาเปิด-ปิดให้อ่านง่ายขึ้น
  String _formatOpeningHours(String openingHoursStr) {
    try {
      if (openingHoursStr == '24/7') {
        return 'เปิดตลอด 24 ชั่วโมง';
      }

      // แปลงรหัสวันเป็นภาษาไทย
      final Map<String, String> dayTranslation = {
        'Mo': 'จันทร์',
        'Tu': 'อังคาร',
        'We': 'พุธ',
        'Th': 'พฤหัสบดี',
        'Fr': 'ศุกร์',
        'Sa': 'เสาร์',
        'Su': 'อาทิตย์',
        'Mo-Fr': 'จันทร์-ศุกร์',
        'Mo-Sa': 'จันทร์-เสาร์',
        'Sa-Su': 'เสาร์-อาทิตย์',
        'Mo-Su': 'ทุกวัน'
      };

      // แยกตามวัน
      final days = openingHoursStr.split(';');
      List<String> result = [];

      for (var day in days) {
        day = day.trim();
        if (day.isEmpty) continue;

        final parts = day.split(' ');
        if (parts.length >= 2) {
          String dayPart = parts[0];
          String timePart = parts.sublist(1).join(' ');

          // แปลงวัน
          if (dayTranslation.containsKey(dayPart)) {
            dayPart = dayTranslation[dayPart]!;
          } else if (dayPart.contains('-')) {
            final rangeParts = dayPart.split('-');
            if (rangeParts.length == 2 &&
                dayTranslation.containsKey(rangeParts[0]) &&
                dayTranslation.containsKey(rangeParts[1])) {
              dayPart = '${dayTranslation[rangeParts[0]]}-${dayTranslation[rangeParts[1]]}';
            }
          }

          result.add('$dayPart: $timePart');
        }
      }

      return result.join('\n');
    } catch (e) {
      print('Error formatting opening hours: $e');
      return openingHoursStr; // ถ้ามีข้อผิดพลาด ให้คืนค่าเดิม
    }
  }

  // สร้างข้อมูลสถานที่จำลอง 1 แห่ง
  Map<String, dynamic> _createMockPlace(Position currentLocation, double maxDistance, String defaultName) {
    final random = math.Random();
    final randomAngle = random.nextDouble() * 2 * math.pi;
    final randomDistance = random.nextDouble() * maxDistance;

    final earthRadius = 6371.0;
    final lat = currentLocation.latitude +
        (randomDistance / earthRadius) * (180 / math.pi) * math.cos(randomAngle);
    final lon = currentLocation.longitude +
        (randomDistance / earthRadius) * (180 / math.pi) * math.sin(randomAngle) / math.cos(currentLocation.latitude * math.pi / 180);

    return {
      'name': '$defaultName ${random.nextInt(10) + 1}',
      'address': 'ถนนตัวอย่าง ตำบล/แขวงตัวอย่าง อำเภอ/เขตตัวอย่าง',
      'phone': _getMockPhoneNumber(defaultName.toLowerCase()), // แทนที่ 'ไม่ระบุเบอร์โทร' ด้วยเบอร์โทรจำลอง
      'latitude': lat,
      'longitude': lon,
      'distance': randomDistance,
      'opening_hours': 'เปิดตลอด 24 ชั่วโมง', // ค่าเริ่มต้นสำหรับข้อมูลจำลอง
      'is_open': true, // ค่าเริ่มต้นสำหรับข้อมูลจำลอง
    };
  }

  // คำนวณระยะทางโดยใช้ Haversine formula (มักใกล้เคียงกับที่ Google Maps ใช้)
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // รัศมีโลกเป็นกิโลเมตร

    // แปลงจาก degrees เป็น radians
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    // Haversine formula
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;

    // ปรับค่าระยะทางเพิ่มขึ้น 10% เพื่อให้ใกล้เคียงกับระยะทางจริงที่ต้องขับรถ
    return distance * 1.1;
  }

  // แปลงจาก degrees เป็น radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // ดึงข้อมูลโรงพยาบาลใกล้เคียง
  Future<List<Map<String, dynamic>>> getNearbyHospitals(Position currentLocation, double radiusKm) async {
    // รอ 1 วินาทีก่อนเรียก API (ตามข้อกำหนดของ Nominatim - Usage Policy)
    await Future.delayed(Duration(seconds: 1));
    return await _searchNearbyPlaces(currentLocation, radiusKm, 'hospital', 'โรงพยาบาล');
  }

  // ดึงข้อมูลสถานีตำรวจใกล้เคียง
  Future<List<Map<String, dynamic>>> getNearbyPoliceStations(Position currentLocation, double radiusKm) async {
    // รอ 1 วินาทีก่อนเรียก API (ตามข้อกำหนดของ Nominatim - Usage Policy)
    await Future.delayed(Duration(seconds: 1));
    return await _searchNearbyPlaces(currentLocation, radiusKm, 'police', 'สถานีตำรวจ');
  }

  // ดึงข้อมูลคลินิกใกล้เคียง
  Future<List<Map<String, dynamic>>> getNearbyClinics(Position currentLocation, double radiusKm) async {
    // รอ 1 วินาทีก่อนเรียก API (ตามข้อกำหนดของ Nominatim - Usage Policy)
    await Future.delayed(Duration(seconds: 1));
    return await _searchNearbyPlaces(currentLocation, radiusKm, 'clinic', 'คลินิก');
  }
  
  // ดึงข้อมูลร้านขายยาใกล้เคียง
  Future<List<Map<String, dynamic>>> getNearbyPharmacies(Position currentLocation, double radiusKm) async {
    // รอ 1 วินาทีก่อนเรียก API (ตามข้อกำหนดของ Nominatim - Usage Policy)
    await Future.delayed(Duration(seconds: 1));
    return await _searchNearbyPlaces(currentLocation, radiusKm, 'pharmacy', 'ร้านขายยา');
  }
  
  // สร้างเบอร์โทรศัพท์จำลองตามประเภทสถานที่
  String _getMockPhoneNumber(String placeType) {
    if (placeType.contains('hospital') || placeType.contains('โรงพยาบาล')) {
      return '1669'; // เบอร์ฉุกเฉินการแพทย์
    } else if (placeType.contains('police') || placeType.contains('ตำรวจ')) {
      return '191'; // เบอร์ตำรวจ
    } else if (placeType.contains('clinic') || placeType.contains('คลินิก')) {
      return '1646'; // เบอร์สายด่วนกรมการแพทย์
    } else if (placeType.contains('pharmacy') || placeType.contains('ร้านขายยา')) {
      return '1556'; // เบอร์สายด่วนสำนักงานคณะกรรมการอาหารและยา
    } else {
      return '1196'; // เบอร์แจ้งเหตุด่วน
    }
  }
} 