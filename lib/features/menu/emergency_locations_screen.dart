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
  List<Map<String, dynamic>> _fireStations = [];
  List<Map<String, dynamic>> _clinics = [];
  
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
        _fetchFireStations(),
        _fetchClinics(),
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

  // ดึงข้อมูลสถานีดับเพลิง
  Future<void> _fetchFireStations() async {
    if (_currentPosition == null) return;
    
    try {
      final stations = await _emergencyLocationService.getNearbyFireStations(
        _currentPosition!,
        _searchRadius,
      );
      
      setState(() {
        _fireStations = stations;
      });
    } catch (e) {
      print('Error fetching fire stations: $e');
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
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              style: const TextStyle(fontSize: 18),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchAllEmergencyLocations,
      child: ListView.builder(
        itemCount: locations.length,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemBuilder: (context, index) {
          final location = locations[index];
          final distance = location['distance'] as double;
          final distanceText = distance < 1 
              ? '${(distance * 1000).toStringAsFixed(0)} เมตร' 
              : '${distance.toStringAsFixed(1)} กม.';
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    location['name'] ?? 'ไม่ระบุชื่อ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location['address'] ?? 'ไม่ระบุที่อยู่',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ระยะทาง: $distanceText',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                      icon: const Icon(Icons.directions),
                      label: const Text('นำทาง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
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
        backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        title: const Text(
          "สถานบริการฉุกเฉินใกล้ฉัน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
            fontSize: 14,
          ),
          isScrollable: false,
          labelPadding: EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('โรงพยาบาล'),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('ตำรวจ'),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('ดับเพลิง'),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('คลินิก'),
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
                      color: Colors.red,
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
                      color: Colors.green,
                      tooltip: 'เพิ่มรัศมี',
                    ),
                    // ปุ่มรีเฟรช
                    IconButton(
                      onPressed: _fetchAllEmergencyLocations,
                      icon: const Icon(Icons.refresh),
                      color: Colors.blue,
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
                _buildLocationList(_fireStations),
                _buildLocationList(_clinics),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 