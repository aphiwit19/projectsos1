// lib/screens/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../services/profile_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String contactPhone;
  final String contactName;

  const ChatDetailScreen({
    Key? key,
    required this.contactPhone,
    required this.contactName,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  CollectionReference? _messagesRef;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupMessagesRef();
  }

  Future<void> _setupMessagesRef() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'กรุณาล็อกอินเพื่อดูแชท';
          _isLoading = false;
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
          _isLoading = false;
        });
        return;
      }

      final email = userDoc.docs.first.id;
      setState(() {
        _messagesRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .collection('chats');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _messagesRef == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) return;

      final senderEmail = userDoc.docs.first.id;
      final profileService = ProfileService();
      final userProfile = await profileService.getProfile(senderEmail);
      if (userProfile == null) return;

      // บันทึกข้อความในแชทของผู้ส่ง
      await _messagesRef!.add({
        'contactPhone': widget.contactPhone,
        'contactName': widget.contactName,
        'text': _messageController.text,
        'isMe': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ตรวจสอบว่าผู้รับมีบัญชีในแอปหรือไม่
      final recipientEmail = await profileService.findUserByPhone(widget.contactPhone);
      if (recipientEmail != null) {
        final recipientChatsRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(recipientEmail)
            .collection('chats');
        await recipientChatsRef.add({
          'contactPhone': userProfile.phone,
          'contactName': userProfile.fullName,
          'text': _messageController.text,
          'isMe': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งข้อความ: $e')),
      );
    }
  }

  // ฟังก์ชันสำหรับแปลง timestamp เป็นวันที่และเวลา
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ระบุเวลา';
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('d MMM yyyy HH:mm น.', 'th');
    return formatter.format(dateTime);
  }

  // ฟังก์ชันสำหรับเปิดลิงก์
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดลิงก์ได้: $url')),
      );
    }
  }

  // ฟังก์ชันสำหรับตรวจจับและแยกข้อความที่มีลิงก์
  Widget _buildMessageText(String text, bool isMe) {
    final urlRegExp = RegExp(r'https://maps\.google\.com/[^\s]+');
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      );
    }

    final parts = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // ข้อความก่อนลิงก์
      if (match.start > lastIndex) {
        parts.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ));
      }

      // ลิงก์
      final url = text.substring(match.start, match.end);
      parts.add(TextSpan(
        text: url,
        style: TextStyle(
          color: Colors.blue,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launchURL(url);
          },
      ));

      lastIndex = match.end;
    }

    // ข้อความหลังลิงก์
    if (lastIndex < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: parts),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                    _setupMessagesRef();
                  });
                },
                child: Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE64646),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black,size: 24,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.contactName,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef!
                  .where('contactPhone', isEqualTo: widget.contactPhone)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // รีเฟรชหน้า
                          },
                          child: Text('ลองใหม่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE64646),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                debugPrint('Messages for ${widget.contactPhone}: ${messages.length}');

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มแชทเลย!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['isMe'] as bool;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final formattedTime = _formatTimestamp(timestamp);

                    return Column(
                      crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Color(0xFFE64646) : Color(0xFF5D6066),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: _buildMessageText(message['text'], isMe),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "พิมพ์ข้อความ...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFE64646),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
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