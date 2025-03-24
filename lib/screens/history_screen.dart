// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/sos_service.dart';
import '../models/sos_log_model.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SosLog> _sosLogs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null).then((_) {
      _loadSosLogs();
    });
  }

  Future<void> _loadSosLogs() async {
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

      List<SosLog> logs = await SosService().getSosLogs(userId);
      setState(() {
        _sosLogs = logs;
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

  Future<void> _launchMap(double latitude, double longitude) async {
    final googleMapsUrl = 'googlemaps://?q=$latitude,$longitude';
    final geoUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude';
    final webUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final fallbackWebUrl = 'https://maps.google.com/?q=$latitude,$longitude';

    try {
      try {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      } catch (e) {
        print('Failed to launch Google Maps: $e');
      }

      try {
        await launchUrl(
          Uri.parse(geoUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      } catch (e) {
        print('Failed to launch geo URL: $e');
      }

      try {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      } catch (e) {
        print('Failed to launch web URL: $e');
      }

      try {
        await launchUrl(
          Uri.parse(fallbackWebUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      } catch (e) {
        print('Failed to launch fallback web URL: $e');
      }

      throw 'ไม่สามารถเปิด URL ได้ กรุณาคัดลอก URL และเปิดในเบราว์เซอร์';
    } catch (e) {
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
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
          child: Container(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              alignment: Alignment.center,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "ประวัติการแจ้งเหตุ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
            color: Colors.white,
            onPressed: _loadSosLogs,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color.fromRGBO(230, 70, 70, 1.0),
            ))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Color.fromRGBO(230, 70, 70, 1.0),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                            color: Color.fromRGBO(230, 70, 70, 1.0),
                            fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _sosLogs.isEmpty
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
                      itemCount: _sosLogs.length,
                      itemBuilder: (context, index) {
                        var log = _sosLogs[index];
                        String formattedDate =
                            DateFormat('dd MMM yyyy HH:mm', 'th_TH')
                                .format(log.timestamp.toDate());
                        formattedDate = formattedDate.replaceFirst(
                          RegExp(r'\d{4}'),
                          (int.parse(RegExp(r'\d{4}')
                                      .firstMatch(formattedDate)!
                                      .group(0)!) +
                                  543)
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
                                        Icons.warning,
                                        color: Color.fromRGBO(230, 70, 70, 1.0),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log.message,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color.fromRGBO(
                                                230, 70, 70, 1.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.group,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ส่งไปยัง: ${log.recipients.join(", ")}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ข้อมูลผู้ใช้: ชื่อ: ${log.userInfo['fullName']}, '
                                          'เบอร์: ${log.userInfo['phone']}, '
                                          'กรุ๊ปเลือด: ${log.userInfo['bloodType']}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54),
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
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54),
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
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.copy,
                                            size: 20, color: Colors.grey),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text:
                                                  '${log.location['latitude']}, ${log.location['longitude']}'));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'คัดลอกพิกัดเรียบร้อยแล้ว')),
                                          );
                                        },
                                        tooltip: 'คัดลอกพิกัด',
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _launchMap(
                                            log.location['latitude']!,
                                            log.location['longitude']!,
                                          );
                                        },
                                        icon: const Icon(Icons.map, size: 16),
                                        label: const Text('ดูบนแผนที่'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
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
