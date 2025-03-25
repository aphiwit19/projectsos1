// lib/widgets/custom_bottom_navigation_bar.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // ฟังก์ชันเพื่อดึง CollectionReference ของแชท
  Future<CollectionReference?> _getChatsRef() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in');
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) {
      print('User document not found');
      return null;
    }

    final email = userDoc.docs.first.id;
    print('User email: $email');
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(email)
        .collection('chats');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollectionReference?>(
      future: _getChatsRef(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print('No chatsRef data available');
          return _buildBottomNavigationBar(context, 0);
        }

        final chatsRef = snapshot.data;
        if (chatsRef == null) {
          print('chatsRef is null');
          return _buildBottomNavigationBar(context, 0);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: chatsRef.snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasError) {
              print('Stream error: ${snapshot.error}');
              return _buildBottomNavigationBar(context, 0);
            }

            if (!snapshot.hasData) {
              print('No snapshot data');
              return _buildBottomNavigationBar(context, 0);
            }

            final chats = snapshot.data!.docs;
            print('Number of chats: ${chats.length}');

            for (var chat in chats) {
              final data = chat.data() as Map<String, dynamic>;
              final lastTimestamp = data['lastTimestamp'] as Timestamp?;
              final lastReadTimestamp = data['lastReadTimestamp'] as Timestamp?;
              final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

              if (lastTimestamp == null || messages.isEmpty) {
                print('Chat ${chat.id}: lastTimestamp or messages is null/empty');
                continue;
              }

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
                  unreadCount++;
                  print('Chat ${chat.id} has unread message');
                }
              }
            }

            print('Total unreadCount: $unreadCount');
            return _buildBottomNavigationBar(context, unreadCount);
          },
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int unreadCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFE64646),
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: 26,
            ),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  Icons.chat_bubble,
                  size: 26,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Color(0xFFE64646),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'แชท',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.phone,
              size: 26,
            ),
            label: 'เบอร์ฉุกเฉิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.contacts,
              size: 26,
            ),
            label: 'ผู้ติดต่อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              size: 26,
            ),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}