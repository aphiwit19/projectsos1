// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  CollectionReference? _contactsRef;
  String? _errorMessage;
  Map<String, String> _contactNames = {};

  @override
  void initState() {
    super.initState();
    _setupChatsRef();
    _setupContactsRef();
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
    print('User email: $email');
    setState(() {
      _chatsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('chats');
    });
  }

  Future<void> _setupContactsRef() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) return;

    final email = userDoc.docs.first.id;
    setState(() {
      _contactsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('EmergencyContacts');
    });

    // ดึงข้อมูลจาก EmergencyContacts เพื่อเก็บ contactName
    final contactsSnapshot = await _contactsRef!.get();
    final Map<String, String> contactNames = {};
    for (var doc in contactsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final phone = data['phone'] as String? ?? '';
      final name = data['name'] as String? ?? phone;
      if (phone.isNotEmpty) {
        contactNames[phone] = name;
      }
    }
    setState(() {
      _contactNames = contactNames;
    });
  }

  String _getContactName(String phone) {
    return _contactNames[phone] ?? phone; // ใช้ชื่อจาก EmergencyContacts ถ้าไม่มีใช้เบอร์โทร
  }

  // ฟังก์ชันสำหรับแปลง timestamp เป็นวันที่และเวลา
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('HH:mm', 'th');
    return formatter.format(dateTime);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFFE64646),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "แชท",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "ค้นหาเบอร์โทรหรือชื่อ...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFFE64646),
                    size: 24,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Color(0xFFE64646),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    color: Colors.grey[400],
                    size: 50,
                  ),
                  SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _setupChatsRef();
                      });
                    },
                    child: Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE64646),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )
                  : CircularProgressIndicator(
                color: Color(0xFFE64646),
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _chatsRef!.orderBy('lastTimestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: Text('ลองใหม่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE64646),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE64646),
                    ),
                  );
                }

                final chats = snapshot.data!.docs;
                print('Number of chats: ${chats.length}');

                // กรองตามคำค้นหา (ใช้เบอร์โทรหรือชื่อ)
                var chatList = chats;
                if (_searchQuery.isNotEmpty) {
                  chatList = chatList.where((chat) {
                    final data = chat.data() as Map<String, dynamic>;
                    final contactPhone = (data['contactPhone'] ?? '').toString().toLowerCase();
                    final contactName = _getContactName(contactPhone).toLowerCase();
                    return contactPhone.contains(_searchQuery) || contactName.contains(_searchQuery);
                  }).toList();

                  // เรียงลำดับตามความใกล้เคียงของคำค้นหา
                  chatList.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aPhone = (aData['contactPhone'] ?? '').toString().toLowerCase();
                    final aName = _getContactName(aPhone).toLowerCase();
                    final bPhone = (bData['contactPhone'] ?? '').toString().toLowerCase();
                    final bName = _getContactName(bPhone).toLowerCase();

                    final aMatch = aPhone.startsWith(_searchQuery) || aName.startsWith(_searchQuery) ? 2 : (aPhone.contains(_searchQuery) || aName.contains(_searchQuery) ? 1 : 0);
                    final bMatch = bPhone.startsWith(_searchQuery) || bName.startsWith(_searchQuery) ? 2 : (bPhone.contains(_searchQuery) || bName.contains(_searchQuery) ? 1 : 0);

                    return bMatch.compareTo(aMatch);
                  });
                }

                if (chatList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[400],
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'ยังไม่มีแชท เริ่มแชทกับผู้ติดต่อฉุกเฉินของคุณ!'
                              : 'ไม่พบแชทที่ตรงกับคำค้นหา',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: chatList.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey[200],
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    final data = chat.data() as Map<String, dynamic>;
                    final contactPhone = data['contactPhone'] as String? ?? 'ไม่ระบุ';
                    final contactName = _getContactName(contactPhone);
                    final lastMessage = data['lastMessage'] as String? ?? 'ไม่มีข้อความ';
                    final lastTimestamp = data['lastTimestamp'] as Timestamp?;
                    final lastReadTimestamp = data['lastReadTimestamp'] as Timestamp?;
                    final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

                    // ตรวจสอบว่ามีข้อความใหม่ที่ยังไม่ได้อ่านจากฝั่งคนอื่นหรือไม่
                    bool hasUnreadMessage = false;
                    if (lastTimestamp != null && messages.isNotEmpty) {
                      messages.sort((a, b) {
                        final aTimestamp = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                        final bTimestamp = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                        return bTimestamp.compareTo(aTimestamp);
                      });

                      final latestMessage = messages.first;
                      final isFromOther = !(latestMessage['isMe'] as bool? ?? true);

                      print('Chat ${chat.id}: lastTimestamp=${lastTimestamp.toDate()}, lastReadTimestamp=${lastReadTimestamp?.toDate()}, isFromOther=$isFromOther');

                      if (isFromOther) {
                        if (lastReadTimestamp == null ||
                            lastTimestamp.toDate().isAfter(lastReadTimestamp.toDate())) {
                          hasUnreadMessage = true;
                          print('Chat ${chat.id} has unread message');
                        }
                      }
                    } else {
                      print('Chat ${chat.id}: lastTimestamp or messages is null/empty');
                    }

                    // สร้าง chatId โดยใช้ contactPhone
                    final chatId = 'chat_${contactPhone.replaceAll(RegExp(r'[/#\[\]\$]'), '_')}';

                    // ตรวจสอบว่าตรงกับคำค้นหาหรือไม่
                    final contactPhoneLower = contactPhone.toLowerCase();
                    final contactNameLower = contactName.toLowerCase();
                    final isMatch = _searchQuery.isNotEmpty &&
                        (contactPhoneLower.contains(_searchQuery) || contactNameLower.contains(_searchQuery));

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMatch ? Colors.yellow[100] : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFE64646).withOpacity(0.8),
                          child: Text(
                            contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contactName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: hasUnreadMessage ? FontWeight.bold : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    contactPhone,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (hasUnreadMessage) ...[
                              SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontWeight: hasUnreadMessage ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTimestamp(lastTimestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnreadMessage ? Color(0xFFE64646) : Colors.grey[500],
                                fontWeight: hasUnreadMessage ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // อัปเดต lastReadTimestamp เมื่อเปิดแชท
                          if (hasUnreadMessage) {
                            FirebaseFirestore.instance
                                .collection('Users')
                                .doc(FirebaseAuth.instance.currentUser!.email)
                                .collection('chats')
                                .doc(chatId)
                                .update({
                              'lastReadTimestamp': Timestamp.now(),
                            });
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chatId,
                                contactName: contactName,
                                contactPhone: contactPhone,
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