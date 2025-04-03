// lib/features/emergency_contacts/emergency_contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/emergency_contact_model.dart';
import 'add_emergency_contact_screen.dart';
import 'edit_emergency_contact_screen.dart';
import '../../screens/home_screen.dart';
import '../menu/menu_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> contacts = [];
  final EmergencyContactService _contactService = EmergencyContactService();
  final AuthService _authService = AuthService();
  String? userId;
  bool isLoading = true;
  bool hasError = false;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndContacts();
    _updateEmergencyContactIds();
  }

  Future<String> _getContactFullName(String contactPhone) async {
    return contactPhone;
  }

  Future<void> _loadUserIdAndContacts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      bool isLoggedIn = await _authService.isLoggedIn();
      print('Is user logged in: $isLoggedIn');
      if (!isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      userId = await _authService.getUserId();
      print('User ID: $userId');
      if (userId == null) {
        print('Failed to get userId');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final loadedContacts = await _contactService.getEmergencyContacts(userId!);
      print('Loaded contacts: $loadedContacts');
      setState(() {
        contacts = loadedContacts;
        isLoading = false;
      });
      if (loadedContacts.isEmpty) {
        print('No contacts found for userId: $userId');
      } else {
        print('Contacts found: ${loadedContacts.length} contacts');
      }
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _updateEmergencyContactIds() async {
    // ฟังก์ชันนี้ไม่จำเป็นต้องทำงานอีกต่อไปเนื่องจากเราไม่ได้อัพเดต contactId ตามฐานข้อมูลอีกแล้ว
    // แต่เราจะเก็บไว้เพื่อความเข้ากันได้กับโค้ดเดิม
    return;
  }

  void _addContact() {
    if (userId == null) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEmergencyContactScreen(
          onContactAdded: (name, phone) async {
            try {
              String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
              String contactId = 'contact_${name.toLowerCase().replaceAll(' ', '_')}_$timestamp';
              final newContact = EmergencyContact(
                contactId: contactId,
                userId: userId!,
                name: name,
                phone: phone,
              );

              await _contactService.addContact(userId!, newContact);

              setState(() {
                contacts.add(newContact);
              });
              print('Contact added. Total contacts: ${contacts.length}');
            } catch (e) {
              print('Error adding contact: $e');
            }
          },
        ),
      ),
    );
  }

  void _editContact(String contactId, String currentName, String currentPhone) {
    if (userId == null) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmergencyContactScreen(
          currentName: currentName,
          currentPhone: currentPhone,
          onContactUpdated: (name, phone) async {
            try {
              String newContactId = contactId;
              if (name != currentName || phone != currentPhone) {
                String timestamp = contactId.split('_').last;
                newContactId = 'contact_${name.toLowerCase().replaceAll(' ', '_')}_$timestamp';
              }

              final updatedContact = EmergencyContact(
                contactId: newContactId,
                userId: userId!,
                name: name,
                phone: phone,
              );

              if (newContactId != contactId) {
                final user = await FirebaseFirestore.instance
                    .collection('Users')
                    .where('uid', isEqualTo: userId)
                    .limit(1)
                    .get();
                final email = user.docs.first.id;

                final oldDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(email)
                    .collection('EmergencyContacts')
                    .doc(contactId)
                    .get();

                if (oldDoc.exists) {
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(email)
                      .collection('EmergencyContacts')
                      .doc(newContactId)
                      .set({
                    'contactId': newContactId,
                    'userId': userId,
                    'name': name,
                    'phone': phone,
                  });

                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(email)
                      .collection('EmergencyContacts')
                      .doc(contactId)
                      .delete();
                }
              } else {
                await _contactService.updateContact(userId!, updatedContact);
              }

              setState(() {
                int index = contacts.indexWhere((contact) => contact.contactId == contactId);
                if (index != -1) {
                  contacts[index] = updatedContact;
                }
              });
              print('Contact updated. Total contacts: ${contacts.length}');
            } catch (e) {
              print('Error updating contact: $e');
            }
          },
        ),
      ),
    );
  }

  void _deleteContact(String contactId, String name, String phone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                "คุณแน่ใจหรือไม่?",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "คุณต้องการลบ \"$name\" ออกจากรายการผู้ติดต่อฉุกเฉิน?",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ยกเลิก",
                        style: TextStyle(fontSize: 16, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _contactService.deleteContact(userId!, contactId);

                        setState(() {
                          contacts.removeWhere((contact) => contact.contactId == contactId);
                        });
                        print('Contact deleted. Total contacts: ${contacts.length}');
                        Navigator.pop(context);
                      } catch (e) {
                        print('Error deleting contact: $e');
                      }
                    },
                    child: const Text("ยืนยัน",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building EmergencyContactsScreen. Contacts count: ${contacts.length}');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 244, 244, 1.0),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(230, 70, 70, 1.0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "ผู้ติดต่อฉุกเฉิน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(230, 70, 70, 1.0),
        ),
      )
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              'เกิดข้อผิดพลาดในการโหลดข้อมูล',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadUserIdAndContacts,
              child: const Text('ลองใหม่', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      )
          : contacts.isEmpty
          ? _buildEmptyState()
          : _buildContactList(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(230, 70, 70, 1.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.group,
                      size: 50,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: 15,
                      bottom: 15,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(230, 70, 70, 1.0),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "เพิ่มผู้ติดต่อกรณีฉุกเฉิน",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            "เพิ่มผู้ติดต่อฉุกเฉินได้ทันทีโดยระบบจะส่ง SMS ไปยังเบอร์โทรศัพท์นี้เมื่อคุณกดปุ่ม SOS",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addContact,
              child: const Text("เพิ่มผู้ติดต่อ",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _addContact,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "เพิ่มผู้ติดต่อรายใหม่",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(230, 70, 70, 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          contact.phone,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (String value) {
                      if (value == 'edit') {
                        _editContact(contact.contactId, contact.name, contact.phone);
                      } else if (value == 'delete') {
                        _deleteContact(contact.contactId, contact.name, contact.phone);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.grey),
                          title: Text('แก้ไข'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                              Icons.delete, color: Color.fromRGBO(230, 70, 70, 1.0)),
                          title: Text('ลบ'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}