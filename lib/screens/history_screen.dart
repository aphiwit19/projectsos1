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

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<SosLog> _sosLogs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    initializeDateFormatting('th_TH', null).then((_) {
      _loadSosLogs();
    });
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      
      // เริ่มแอนิเมชั่นใหม่เมื่อโหลดข้อมูลเสร็จ
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดประวัติ: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // เพิ่มฟังก์ชันสำหรับลบประวัติการแจ้งเหตุ
  Future<void> _deleteSosLog(String sosLogId) async {
    try {
      String? userId = await AuthService().getUserId();
      if (userId == null) {
        throw Exception('ไม่พบรหัสผู้ใช้');
      }

      // แสดงกล่องยืนยันการลบ
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'ยืนยันการลบ',
            style: TextStyle(
              color: Color.fromRGBO(230, 70, 70, 1.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'คุณต้องการลบประวัติการแจ้งเหตุนี้ใช่หรือไม่? การดำเนินการนี้ไม่สามารถยกเลิกได้',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ลบ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ?? false;

      if (confirmDelete) {
        // ดำเนินการลบ
        bool success = await SosService().deleteSosLog(userId, sosLogId);
        
        if (success) {
          // อัปเดตรายการโดยลบรายการที่ต้องการออก
          setState(() {
            _sosLogs.removeWhere((log) => log.id == sosLogId);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบประวัติการแจ้งเหตุเรียบร้อยแล้ว'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถลบประวัติการแจ้งเหตุได้'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _launchMap(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเปิดแผนที่ได้: ไม่มีข้อมูลพิกัด'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final googleMapsUrl = 'googlemaps://?q=$latitude,$longitude';
    final geoUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude';
    final webUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final fallbackWebUrl = 'https://maps.google.com/?q=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      }

      if (await canLaunchUrl(Uri.parse(geoUrl))) {
        await launchUrl(
          Uri.parse(geoUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      }

      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      }

      if (await canLaunchUrl(Uri.parse(fallbackWebUrl))) {
        await launchUrl(
          Uri.parse(fallbackWebUrl),
          mode: LaunchMode.platformDefault,
        );
        return;
      }

      throw 'ไม่สามารถเปิด URL ได้ กรุณาคัดลอก URL และเปิดในเบราว์เซอร์';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'คัดลอก URL',
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: webUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('คัดลอก URL เรียบร้อยแล้ว'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  String _getTimeAgo(DateTime date) {
    Duration difference = DateTime.now().difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy HH:mm', 'th_TH').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
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
          "ประวัติการแจ้งเหตุ SOS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 10.0),
            child: Container(
              width: 40,
              height: 40,
              child: _isRefreshing
                ? const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.white,
                  onPressed: _loadSosLogs,
                  tooltip: 'รีเฟรช',
                ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(230, 70, 70, 1.0),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(230, 70, 70, 0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Color.fromRGBO(230, 70, 70, 1.0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Color.fromRGBO(230, 70, 70, 1.0),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadSosLogs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('ลองใหม่'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _sosLogs.isEmpty
                  ? FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_toggle_off,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'ไม่มีประวัติการแจ้งเหตุ',
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'คุณยังไม่เคยส่ง SOS มาก่อน ประวัติจะแสดงที่นี่เมื่อคุณใช้ปุ่ม SOS',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              width: 180,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color.fromRGBO(230, 70, 70, 1.0)),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(25),
                                child: const Center(
                                  child: Text(
                                    'กลับสู่หน้าหลัก',
                                    style: TextStyle(
                                      color: Color.fromRGBO(230, 70, 70, 1.0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: RefreshIndicator(
                        onRefresh: _loadSosLogs,
                        color: const Color.fromRGBO(230, 70, 70, 1.0),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _sosLogs.length,
                          itemBuilder: (context, index) {
                            var log = _sosLogs[index];
                            String timeAgo = _getTimeAgo(log.timestamp.toDate());
                            String formattedDate = DateFormat('dd MMM yyyy HH:mm', 'th_TH').format(log.timestamp.toDate());
                            formattedDate = formattedDate.replaceFirst(
                              RegExp(r'\d{4}'),
                              (int.parse(RegExp(r'\d{4}').firstMatch(formattedDate)!.group(0)!) + 543).toString(),
                            );

                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.5, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.1 > 0.9 ? 0.9 : index * 0.1,
                                      (index * 0.1 + 0.6) > 1.0 ? 1.0 : (index * 0.1 + 0.6),
                                      curve: Curves.easeOutQuad,
                                    ),
                                  ),
                                ),
                                child: Card(
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ส่วนหัวของการ์ด
                                        Container(
                                          color: const Color.fromRGBO(230, 70, 70, 0.1),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(230, 70, 70, 1.0),
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                child: const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'การแจ้งเหตุฉุกเฉิน',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Color.fromRGBO(230, 70, 70, 1.0),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      timeAgo,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  color: Colors.grey,
                                                ),
                                                onSelected: (String value) {
                                                  if (value == 'copy') {
                                                    final latitude = log.location['latitude']?.toString() ?? 'ไม่ระบุ';
                                                    final longitude = log.location['longitude']?.toString() ?? 'ไม่ระบุ';
                                                    Clipboard.setData(ClipboardData(text: '$latitude, $longitude'));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('คัดลอกพิกัดเรียบร้อยแล้ว'),
                                                        behavior: SnackBarBehavior.floating,
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  } else if (value == 'delete') {
                                                    _deleteSosLog(log.id);
                                                  }
                                                },
                                                itemBuilder: (BuildContext context) => [
                                                  const PopupMenuItem<String>(
                                                    value: 'copy',
                                                    child: ListTile(
                                                      leading: Icon(Icons.copy, color: Colors.grey),
                                                      title: Text('คัดลอกพิกัด'),
                                                      dense: true,
                                                    ),
                                                  ),
                                                  const PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: ListTile(
                                                      leading: Icon(Icons.delete, color: Colors.redAccent),
                                                      title: Text('ลบประวัติ'),
                                                      dense: true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // เนื้อหาของการ์ด
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // ข้อความ
                                              Text(
                                                log.message,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              
                                              // ข้อมูลผู้ใช้
                                              _buildInfoRow(
                                                Icons.person_outline,
                                                'ข้อมูลผู้ใช้',
                                                'ชื่อ: ${log.userInfo['fullName'] ?? 'ไม่ระบุ'}, '
                                                'เบอร์: ${log.userInfo['phone'] ?? 'ไม่ระบุ'}, '
                                                'กรุ๊ปเลือด: ${log.userInfo['bloodType'] ?? 'ไม่ระบุ'}'
                                              ),
                                              
                                              // ผู้รับ
                                              if (log.recipients.isNotEmpty)
                                                _buildInfoRow(
                                                  Icons.people_outline,
                                                  'ส่งไปยัง',
                                                  log.recipients.join(", ")
                                                ),
                                              
                                              // เวลา
                                              _buildInfoRow(
                                                Icons.access_time,
                                                'วันและเวลา',
                                                formattedDate
                                              ),
                                              
                                              // แผนที่
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(25),
                                                  gradient: const LinearGradient(
                                                    colors: [Colors.green, Color(0xFF43A047)],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(25),
                                                    onTap: () {
                                                      _launchMap(
                                                        log.location['latitude'] as double?,
                                                        log.location['longitude'] as double?,
                                                      );
                                                    },
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: const [
                                                          Icon(
                                                            Icons.map,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'ดูตำแหน่งบนแผนที่',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}