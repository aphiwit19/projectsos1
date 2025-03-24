// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // สำหรับจัดรูปแบบวันที่
import '../screens/home_screen.dart';
import '../features/emergency_contacts/emergency_contacts_screen.dart';
import '../features/emergency_numbers/emergency_numbers_screen.dart';
import '../features/profile/profile_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CollectionReference? _chatsRef;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupChatsRef();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _setupChatsRef() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'กรุณาล็อกอินเพื่อดูรายการแชท';
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) {
      setState(() {
        _errorMessage = 'ไม่พบข้อมูลผู้ใช้';
      });
      return;
    }

    final email = userDoc.docs.first.id;
    setState(() {
      _chatsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('chats');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 244, 244, 1.0), // ปรับสีพื้นหลังให้เข้ากับแอป
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0), // สีแดงตามธีม
        elevation: 0,
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับอัตโนมัติ
        title: Text(
          "แชท",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "ค้นหาแชท...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.transparent, // ใช้สีจาก Container
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          // รายการแชท
          Expanded(
            child: _chatsRef == null
                ? Center(
              child: _errorMessage != null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _setupChatsRef();
                      });
                    },
                    child: Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
                  : CircularProgressIndicator(
                color: Color.fromRGBO(230, 70, 70, 1.0),
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _chatsRef!.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: Text('ลองใหม่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // กลุ่มข้อความตาม contactPhone และหา timestamp ล่าสุด
                final Map<String, Map<String, dynamic>> latestMessages = {};
                for (var doc in messages) {
                  final data = doc.data() as Map<String, dynamic>;
                  final contactPhone = data['contactPhone'] as String;
                  final timestamp = data['timestamp'] as Timestamp?;

                  if (!latestMessages.containsKey(contactPhone) ||
                      (timestamp != null &&
                          (latestMessages[contactPhone]!['timestamp'] == null ||
                              timestamp.compareTo(latestMessages[contactPhone]!['timestamp']) > 0))) {
                    latestMessages[contactPhone] = {
                      'contactPhone': contactPhone,
                      'contactName': data['contactName'] as String,
                      'timestamp': timestamp,
                      'latestText': data['text'] as String,
                    };
                  }
                }

                // แปลงเป็นรายการและเรียงลำดับตาม timestamp
                var chatList = latestMessages.values.toList()
                  ..sort((a, b) {
                    final aTimestamp = a['timestamp'] as Timestamp?;
                    final bTimestamp = b['timestamp'] as Timestamp?;
                    if (aTimestamp == null && bTimestamp == null) return 0;
                    if (aTimestamp == null) return 1;
                    if (bTimestamp == null) return -1;
                    return bTimestamp.compareTo(aTimestamp);
                  });

                // กรองตามคำค้นหา (ชื่อหรือเบอร์)
                if (_searchQuery.isNotEmpty) {
                  chatList = chatList.where((chat) {
                    final contactName = chat['contactName'].toString().toLowerCase();
                    final contactPhone = chat['contactPhone'].toString().toLowerCase();
                    return contactName.contains(_searchQuery) || contactPhone.contains(_searchQuery);
                  }).toList();

                  // เรียงลำดับตามความใกล้เคียงของคำค้นหา
                  chatList.sort((a, b) {
                    final aName = a['contactName'].toString().toLowerCase();
                    final bName = b['contactName'].toString().toLowerCase();
                    final aPhone = a['contactPhone'].toString().toLowerCase();
                    final bPhone = b['contactPhone'].toString().toLowerCase();

                    final aNameMatch = aName.startsWith(_searchQuery) ? 2 : (aName.contains(_searchQuery) ? 1 : 0);
                    final bNameMatch = bName.startsWith(_searchQuery) ? 2 : (bName.contains(_searchQuery) ? 1 : 0);
                    final aPhoneMatch = aPhone.startsWith(_searchQuery) ? 2 : (aPhone.contains(_searchQuery) ? 1 : 0);
                    final bPhoneMatch = bPhone.startsWith(_searchQuery) ? 2 : (bPhone.contains(_searchQuery) ? 1 : 0);

                    final aScore = aNameMatch + aPhoneMatch;
                    final bScore = bNameMatch + bPhoneMatch;

                    return bScore.compareTo(aScore);
                  });
                }

                if (chatList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty
                              ? 'ยังไม่มีแชท เริ่มแชทกับผู้ติดต่อฉุกเฉินของคุณ!'
                              : 'ไม่พบแชทที่ตรงกับคำค้นหา',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    final contactPhone = chat['contactPhone'] as String;
                    final contactName = chat['contactName'] as String;
                    final latestText = chat['latestText'] as String;
                    final timestamp = chat['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    // ตรวจสอบว่าตรงกับคำค้นหาหรือไม่
                    final contactNameLower = contactName.toLowerCase();
                    final contactPhoneLower = contactPhone.toLowerCase();
                    final isMatch = _searchQuery.isNotEmpty &&
                        (contactNameLower.contains(_searchQuery) || contactPhoneLower.contains(_searchQuery));

                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isMatch ? Colors.yellow[100] : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        leading: CircleAvatar(
                          backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
                          child: Text(
                            contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                contactName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            latestText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                contactPhone: contactPhone,
                                contactName: contactName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyNumbersScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}