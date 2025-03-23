import 'package:flutter/material.dart';
import '../../models/emergency_contact_model.dart';
import 'add_emergency_contact_screen.dart';
import 'edit_emergency_contact_screen.dart';
import '../../screens/home_screen.dart';
import '../emergency_numbers/emergency_numbers_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> contacts = [];
  final EmergencyContactService _contactService = EmergencyContactService();
  final AuthService _authService = AuthService();
  String? userId;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndContacts();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาล็อกอินเพื่อดูรายชื่อผู้ติดต่อ')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึง userId ได้')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายชื่อ: $e')),
      );
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _addContact() {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาล็อกอินเพื่อเพิ่มผู้ติดต่อ')),
      );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มผู้ติดต่อ: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  void _editContact(String contactId, String currentName, String currentPhone) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาล็อกอินเพื่อแก้ไขผู้ติดต่อ')),
      );
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
              final updatedContact = EmergencyContact(
                contactId: contactId,
                userId: userId!,
                name: name,
                phone: phone,
              );
              await _contactService.updateContact(userId!, updatedContact);
              setState(() {
                int index = contacts.indexWhere((contact) => contact.contactId == contactId);
                if (index != -1) {
                  contacts[index] = updatedContact;
                }
              });
              print('Contact updated. Total contacts: ${contacts.length}');
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการแก้ไขผู้ติดต่อ: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  void _deleteContact(String contactId, String name) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบผู้ติดต่อ: $e')),
                        );
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

  @override
  Widget build(BuildContext context) {
    print('Building EmergencyContactsScreen. Contacts count: ${contacts.length}');
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
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
            Text(
              'เกิดข้อผิดพลาดในการโหลดข้อมูล',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadUserIdAndContacts,
              child: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
              ),
            ),
          ],
        ),
      )
          : contacts.isEmpty
          ? _buildEmptyState()
          : _buildContactList(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EmergencyNumbersScreen()),
              );
              break;
            case 2:
              break;
            case 3:
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

  Widget _buildEmptyState() {
    return Column(
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
                color: Colors.grey[300],
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
        const Text(
          "เพิ่มผู้ติดต่อฉุกเฉินโดยการใส่ชื่อ และเบอร์โทรศัพท์",
          style: TextStyle(fontSize: 14, color: Colors.black54),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: Text(
              "ผู้ติดต่อฉุกเฉิน",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _addContact,
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
                    size: 35,
                  ),
                ),
                const SizedBox(width: 30),
                const Text(
                  "เพิ่มผู้ติดต่อรายใหม่",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                color: Colors.white,
                elevation: 2,
                child: ListTile(
                  title: Text(contact.name, style: const TextStyle(fontSize: 16)),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Text(contact.phone,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _editContact(contact.contactId, contact.name, contact.phone);
                          } else if (value == 'delete') {
                            _deleteContact(contact.contactId, contact.name);
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