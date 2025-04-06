import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../services/emergency_location_service.dart';

class EmergencyLocationsScreen extends StatefulWidget {
  const EmergencyLocationsScreen({Key? key}) : super(key: key);

  @override
  EmergencyLocationsScreenState createState() => EmergencyLocationsScreenState();
}

class EmergencyLocationsScreenState extends State<EmergencyLocationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();
  final EmergencyLocationService _emergencyLocationService = EmergencyLocationService();

  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';

  // ข้อมูลสถานที่แต่ละประเภท
  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _policeStations = [];
  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _pharmacies = [];
  
  // รัศมีการค้นหา (กิโลเมตร)
  double _searchRadius = 10.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  // ดึงตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final position = await _locationService.getBestLocation(context: context);

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });

        // เมื่อได้ตำแหน่งแล้ว ดึงข้อมูลสถานที่
        await _fetchAllEmergencyLocations();
      } else {
        setState(() {
          _errorMessage = 'ไม่สามารถรับตำแหน่งได้ กรุณาตรวจสอบการเปิดใช้งาน GPS';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการรับตำแหน่ง: $e';
        _isLoading = false;
      });
    }
  }

  // ดึงข้อมูลสถานที่ทั้งหมด
  Future<void> _fetchAllEmergencyLocations() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ดึงข้อมูลแต่ละประเภทพร้อมกัน
      await Future.wait([
        _fetchHospitals(),
        _fetchPoliceStations(),
        _fetchClinics(),
        _fetchPharmacies(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลสถานที่: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ดึงข้อมูลโรงพยาบาล
  Future<void> _fetchHospitals() async {
    if (_currentPosition == null) return;

    try {
      final hospitals = await _emergencyLocationService.getNearbyHospitals(
        _currentPosition!,
        _searchRadius,
      );

      setState(() {
        _hospitals = hospitals;
      });
    } catch (e) {
      print('Error fetching hospitals: $e');
    }
  }

  // ดึงข้อมูลสถานีตำรวจ
  Future<void> _fetchPoliceStations() async {
    if (_currentPosition == null) return;

    try {
      final stations = await _emergencyLocationService.getNearbyPoliceStations(
        _currentPosition!,
        _searchRadius,
      );

      setState(() {
        _policeStations = stations;
      });
    } catch (e) {
      print('Error fetching police stations: $e');
    }
  }

  // ดึงข้อมูลคลินิก
  Future<void> _fetchClinics() async {
    if (_currentPosition == null) return;

    try {
      final clinics = await _emergencyLocationService.getNearbyClinics(
        _currentPosition!,
        _searchRadius,
      );

      setState(() {
        _clinics = clinics;
      });
    } catch (e) {
      print('Error fetching clinics: $e');
    }
  }

  // ดึงข้อมูลร้านขายยา
  Future<void> _fetchPharmacies() async {
    if (_currentPosition == null) return;

    try {
      final pharmacies = await _emergencyLocationService.getNearbyPharmacies(
        _currentPosition!,
        _searchRadius,
      );

      setState(() {
        _pharmacies = pharmacies;
      });
    } catch (e) {
      print('Error fetching pharmacies: $e');
    }
  }

  // เปิดแผนที่เพื่อนำทาง
  Future<void> _openMap(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดแผนที่ได้')),
      );
    }
  }

  // สร้าง widget แสดงรายการสถานที่
  Widget _buildLocationList(List<Map<String, dynamic>> locations) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(230, 70, 70, 1.0),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color.fromRGBO(230, 70, 70, 1.0),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบสถานที่ในรัศมี $_searchRadius กิโลเมตร',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchRadius += 5;
                });
                _fetchAllEmergencyLocations();
              },
              icon: const Icon(Icons.search),
              label: Text('ขยายการค้นหาเป็น ${_searchRadius + 5} กม.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllEmergencyLocations,
      color: Colors.blue.shade700,
      child: ListView.builder(
        itemCount: locations.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemBuilder: (context, index) {
          final location = locations[index];
          final distance = location['distance'] as double;
          final distanceText = distance < 1
              ? '${(distance * 1000).toStringAsFixed(0)} เมตร'
              : '${distance.toStringAsFixed(1)} กม.';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade700.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.blue.shade700.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade700.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                location['name'].toString().contains('โรงพยาบาล') || location['name'].toString().contains('รพ.')
                                    ? Icons.local_hospital
                                    : location['name'].toString().contains('ตำรวจ') || location['name'].toString().contains('สภ.')
                                    ? Icons.local_police
                                    : location['name'].toString().contains('ร้านขายยา') || location['name'].toString().contains('ขายยา') || location['name'].toString().contains('เภสัช')
                                    ? Icons.local_pharmacy
                                    : Icons.medical_services,
                                color: Colors.blue.shade700,
                                size: 26,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                location['name'] ?? 'ไม่ระบุชื่อ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Color.fromRGBO(230, 70, 70, 1.0),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  location['address'] ?? 'ไม่ระบุที่อยู่',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ระยะทาง: $distanceText',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openMap(
                            location['latitude'] as double,
                            location['longitude'] as double,
                          );
                        },
                        icon: const Icon(Icons.directions,color: Colors.green,),
                        label: const Text(
                          'นำทาง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1.0),
      appBar: AppBar(
        backgroundColor:  Colors.blue.shade700,
        elevation: 0,
        title: const Text(
          "สถานบริการฉุกเฉินใกล้ฉัน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          isScrollable: false,
          labelPadding: EdgeInsets.symmetric(horizontal: 4),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              height: 40,
              child: Text(
                'โรงพยาบาล',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
            Tab(
              height: 40,
              child: Text(
                'ตำรวจ',
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              height: 40,
              child: Text(
                'คลินิก',
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              height: 40,
              child: Text(
                'ร้านขายยา',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // แสดงข้อมูลรัศมีการค้นหา
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รัศมีการค้นหา: $_searchRadius กม.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                Row(
                  children: [
                    // ปุ่มสำหรับลดรัศมี
                    IconButton(
                      onPressed: _searchRadius <= 5 ? null : () {
                        setState(() {
                          _searchRadius = _searchRadius - 5;
                        });
                        _fetchAllEmergencyLocations();
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red.shade700,
                      tooltip: 'ลดรัศมี',
                    ),
                    // ปุ่มสำหรับเพิ่มรัศมี
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _searchRadius = _searchRadius + 5;
                        });
                        _fetchAllEmergencyLocations();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.green.shade700,
                      tooltip: 'เพิ่มรัศมี',
                    ),
                    // ปุ่มรีเฟรช
                    IconButton(
                      onPressed: _fetchAllEmergencyLocations,
                      icon: const Icon(Icons.refresh),
                      color: Colors.blue.shade700,
                      tooltip: 'รีเฟรช',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // แสดงข้อมูลแต่ละแท็บ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLocationList(_hospitals),
                _buildLocationList(_policeStations),
                _buildLocationList(_clinics),
                _buildLocationList(_pharmacies),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 