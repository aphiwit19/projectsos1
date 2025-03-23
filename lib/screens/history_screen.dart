import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // สำหรับ Clipboard

import '../services/auth_service.dart';
import '../services/sos_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _smsLogs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize Thai locale for date formatting
    initializeDateFormatting('th_TH', null).then((_) {
      _loadSmsLogs();
    });
  }

  Future<void> _loadSmsLogs() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = '';
    });

    try {
      String? userId = await AuthService().getUserId();
      if (userId == null) {
        throw Exception('ไม่พบรหัสผู้ใช้');
      }

      List<Map<String, dynamic>> logs = await SosService().getSmsLogs(userId);
      setState(() {
        _smsLogs = logs;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดประวัติ: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // ฟังก์ชันเปิด Google Maps
  Future<void> _launchMap(double latitude, double longitude) async {
    // รูปแบบ URL สำหรับ Google Maps
    final googleMapsUrl = 'googlemaps://?q=$latitude,$longitude';
    final geoUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude';
    final webUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final fallbackWebUrl = 'https://maps.google.com/?q=$latitude,$longitude';

    try {
      // ลองใช้ Google Maps URL Scheme
      print('Step 1: Attempting to launch Google Maps URL: $googleMapsUrl');
      try {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.platformDefault,
        );
        print('Step 2: Google Maps launched successfully');
        return;
      } catch (e) {
        print('Step 2: Failed to launch Google Maps: $e');
      }

      // ลองใช้ geo: URL Scheme
      print('Step 3: Attempting to launch geo URL: $geoUrl');
      try {
        await launchUrl(
          Uri.parse(geoUrl),
          mode: LaunchMode.platformDefault,
        );
        print('Step 4: Geo URL launched successfully');
        return;
      } catch (e) {
        print('Step 4: Failed to launch geo URL: $e');
      }

      // ลองใช้ web URL
      print('Step 5: Attempting to launch web URL: $webUrl');
      try {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.platformDefault,
        );
        print('Step 6: Web URL launched successfully');
        return;
      } catch (e) {
        print('Step 6: Failed to launch web URL: $e');
      }

      // ลองใช้ fallback web URL
      print('Step 7: Attempting to launch fallback web URL: $fallbackWebUrl');
      try {
        await launchUrl(
          Uri.parse(fallbackWebUrl),
          mode: LaunchMode.platformDefault,
        );
        print('Step 8: Fallback web URL launched successfully');
        return;
      } catch (e) {
        print('Step 8: Failed to launch fallback web URL: $e');
      }

      // ถ้าทั้งหมดไม่ทำงาน แจ้งเตือนผู้ใช้
      throw 'ไม่สามารถเปิด URL ได้ กรุณาคัดลอก URL และเปิดในเบราว์เซอร์';
    } catch (e) {
      print('Error launching map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          action: SnackBarAction(
            label: 'คัดลอก URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: webUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('คัดลอก URL เรียบร้อยแล้ว')),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการแจ้งเหตุ'),
        backgroundColor: Colors.redAccent,
        elevation: 4,
        actions: [
          _isRefreshing
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSmsLogs,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : _smsLogs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่มีประวัติการแจ้งเหตุ',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'คุณยังไม่ได้ส่ง SOS ใดๆ',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _smsLogs.length,
        itemBuilder: (context, index) {
          var log = _smsLogs[index];
          // จัดรูปแบบวันที่เป็นภาษาไทย
          String formattedDate = DateFormat('dd MMM yyyy HH:mm', 'th_TH')
              .format(DateTime.parse(log['sentTime']));
          // แปลงปี ค.ศ. เป็น พ.ศ.
          formattedDate = formattedDate.replaceFirst(
            RegExp(r'\d{4}'),
            (int.parse(RegExp(r'\d{4}').firstMatch(formattedDate)!.group(0)!) + 543)
                .toString(),
          );

          return AnimatedSlide(
            offset: Offset(0, 0),
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ส่งไปยัง: ${log['recipientNumber']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.message,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ข้อความ: ${log['messageContent']}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'วันที่และเวลา: $formattedDate',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ตำแหน่งที่ส่ง SOS',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: '${log['latitude']}, ${log['longitude']}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('คัดลอกพิกัดเรียบร้อยแล้ว')),
                            );
                          },
                          tooltip: 'คัดลอกพิกัด',
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _launchMap(
                              double.parse(log['latitude'].toString()),
                              double.parse(log['longitude'].toString()),
                            );
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('ดูบนแผนที่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}