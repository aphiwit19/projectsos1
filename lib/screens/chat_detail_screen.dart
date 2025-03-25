// lib/screens/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../services/profile_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String contactName;
  final String contactPhone; // เพิ่ม contactPhone เพื่อใช้ในการส่งข้อความ

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.contactName,
    required this.contactPhone, // เพิ่มพารามิเตอร์
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  DocumentReference? _chatDocRef;
  bool _isLoading = true;
  String? _errorMessage;
  String? _contactPhone;

  @override
  void initState() {
    super.initState();
    _setupChatDocRef();
  }

  Future<void> _setupChatDocRef() async {
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
      final chatDocRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('chats')
          .doc(widget.chatId);

      final chatDoc = await chatDocRef.get();
      if (!chatDoc.exists) {
        setState(() {
          _errorMessage = 'ไม่พบแชทนี้';
          _isLoading = false;
        });
        return;
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final messages = List<Map<String, dynamic>>.from(chatData['messages'] ?? []);

      final currentTimestamp = Timestamp.now();
      await chatDocRef.update({
        'lastReadTimestamp': currentTimestamp,
      });

      final updatedMessages = messages.map((msg) {
        if (!msg['isMe'] && (msg['status'] == 'delivered' || msg['status'] == 'sent')) {
          return {
            ...msg,
            'status': 'read',
          };
        }
        return msg;
      }).toList();

      await chatDocRef.update({
        'messages': updatedMessages,
      });

      final profileService = ProfileService();
      final userProfile = await profileService.getProfile(email);
      if (userProfile != null) {
        final senderEmail = await profileService.findUserByPhone(chatData['contactPhone']);
        if (senderEmail != null) {
          final senderChatsRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(senderEmail)
              .collection('chats');
          String sanitizedRecipientPhone = userProfile.phone.replaceAll(RegExp(r'[/#\[\]\$]'), '_');
          String senderChatId = 'chat_$sanitizedRecipientPhone';

          final senderChatDoc = await senderChatsRef.doc(senderChatId).get();
          if (senderChatDoc.exists) {
            final senderMessages = List<Map<String, dynamic>>.from(senderChatDoc['messages'] ?? []);
            final updatedSenderMessages = senderMessages.map((msg) {
              final msgTimestamp = (msg['timestamp'] as Timestamp).toDate();
              if (msg['isMe'] &&
                  (msg['status'] == 'delivered' || msg['status'] == 'sent') &&
                  msgTimestamp.isBefore(currentTimestamp.toDate())) {
                return {
                  ...msg,
                  'status': 'read',
                };
              }
              return msg;
            }).toList();

            await senderChatsRef.doc(senderChatId).update({
              'messages': updatedSenderMessages,
              'lastReadTimestamp': currentTimestamp,
            });
          }
        }
      }

      setState(() {
        _chatDocRef = chatDocRef;
        _contactPhone = chatData['contactPhone'] as String?;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatDocRef == null || _contactPhone == null) return;

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

      final timestamp = Timestamp.now();
      final messageText = _messageController.text;
      final message = {
        'text': messageText,
        'isMe': true,
        'timestamp': timestamp,
        'status': 'sent',
      };

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final chatDoc = await transaction.get(_chatDocRef!);
        if (chatDoc.exists) {
          final messages = List<Map<String, dynamic>>.from(chatDoc['messages'] ?? []);
          bool messageExists = messages.any((msg) =>
          msg['text'] == messageText &&
              (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                  timestamp.millisecondsSinceEpoch);

          if (!messageExists) {
            transaction.update(_chatDocRef!, {
              'messages': FieldValue.arrayUnion([message]),
              'lastMessage': messageText,
              'lastTimestamp': timestamp,
            });
          }
        } else {
          transaction.set(_chatDocRef!, {
            'contactPhone': _contactPhone,
            'contactName': widget.contactName,
            'messages': [message],
            'lastMessage': messageText,
            'lastTimestamp': timestamp,
            'lastReadTimestamp': null,
          });
        }
      });

      final recipientEmail = await profileService.findUserByPhone(_contactPhone!);
      if (recipientEmail != null) {
        final recipientChatsRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(recipientEmail)
            .collection('chats');

        String sanitizedSenderPhone = userProfile.phone.replaceAll(RegExp(r'[/#\[\]\$]'), '_');
        String recipientChatId = 'chat_$sanitizedSenderPhone';

        final recipientChatDocRef = recipientChatsRef.doc(recipientChatId);
        final recipientMessage = {
          'text': messageText,
          'isMe': false,
          'timestamp': timestamp,
          'status': 'delivered',
        };

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final recipientChatSnapshot = await transaction.get(recipientChatDocRef);
          if (recipientChatSnapshot.exists) {
            final messages = List<Map<String, dynamic>>.from(recipientChatSnapshot['messages'] ?? []);
            bool messageExists = messages.any((msg) =>
            msg['text'] == messageText &&
                (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                    timestamp.millisecondsSinceEpoch);

            if (!messageExists) {
              transaction.update(recipientChatDocRef, {
                'messages': FieldValue.arrayUnion([recipientMessage]),
                'lastMessage': messageText,
                'lastTimestamp': timestamp,
              });
            }
          } else {
            transaction.set(recipientChatDocRef, {
              'contactPhone': userProfile.phone,
              'contactName': widget.contactName, // ใช้ชื่อที่ A ตั้งให้ B (เช่น "เมีย")
              'messages': [recipientMessage],
              'lastMessage': messageText,
              'lastTimestamp': timestamp,
              'lastReadTimestamp': null,
            });
          }
        });

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final chatDoc = await transaction.get(_chatDocRef!);
          if (chatDoc.exists) {
            final messages = List<Map<String, dynamic>>.from(chatDoc['messages'] ?? []);
            final updatedMessages = messages.map((msg) {
              if (msg['text'] == messageText &&
                  (msg['timestamp'] as Timestamp).millisecondsSinceEpoch ==
                      timestamp.millisecondsSinceEpoch &&
                  msg['status'] == 'sent') {
                return {
                  'text': messageText,
                  'isMe': true,
                  'timestamp': timestamp,
                  'status': 'delivered',
                };
              }
              return msg;
            }).toList();

            transaction.update(_chatDocRef!, {
              'messages': updatedMessages,
            });
          }
        });
      }

      _messageController.clear();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งข้อความ: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ระบุเวลา';
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('d MMM yyyy HH:mm น.', 'th');
    return formatter.format(dateTime);
  }

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
      if (match.start > lastIndex) {
        parts.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ));
      }

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
                    _setupChatDocRef();
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
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.contactName,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              _contactPhone ?? 'ไม่ระบุ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _chatDocRef!.snapshots(),
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
                            setState(() {});
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

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มแชทเลย!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final chatData = snapshot.data!.data() as Map<String, dynamic>;
                final messages = List<Map<String, dynamic>>.from(chatData['messages'] ?? []);

                messages.sort((a, b) {
                  final aTimestamp = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                  final bTimestamp = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                  return bTimestamp.compareTo(aTimestamp);
                });

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
                    final message = messages[index];
                    final isMe = message['isMe'] as bool;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final status = message['status'] as String? ?? 'sent';
                    final formattedTime = _formatTimestamp(timestamp);

                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (isMe && status != 'sent') ...[
                                SizedBox(width: 5),
                                Text(
                                  status == 'read' ? 'อ่านแล้ว' : 'ส่งถึงแล้ว',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == 'read' ? Colors.blue : Colors.green,
                                  ),
                                ),
                              ],
                            ],
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