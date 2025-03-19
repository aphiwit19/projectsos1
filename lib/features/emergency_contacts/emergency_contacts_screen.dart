import 'package:flutter/material.dart';
import 'add_emergency_contact_screen.dart';
import 'edit_emergency_contact_screen.dart';
import '../../screens/home_screen.dart';
import '../emergency_numbers/emergency_numbers_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/auth_service.dart'; // เพิ่มเพื่อดึง userId

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> contacts = [];
  final EmergencyContactService _contactService = EmergencyContactService();
  final AuthService _authService = AuthService();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndContacts();
  }

  Future<void> _loadUserIdAndContacts() async {
    try {
      userId = await _authService.getPhoneNumber(); // ใช้ phone เป็น userId ชั่วคราว
      if (userId != null) {
        final loadedContacts = await _contactService.getContacts(userId!);
        setState(() {
          contacts = loadedContacts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายชื่อ: $e')),
      );
    }
  }

  void _addContact() {
    if (userId == null) return; // ป้องกันกรณี userId ยังไม่โหลด
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEmergencyContactScreen(
          onContactAdded: (name, phone) async {
            setState(() {
              contacts.add(EmergencyContact(
                contactId: DateTime.now().millisecondsSinceEpoch.toString(), // ID ชั่วคราว
                userId: userId!,
                name: name,
                phone: phone,
              ));
            });
            await _contactService.saveContacts(contacts);
          },
        ),
      ),
    );
  }

  void _editContact(String currentName, String currentPhone) {
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmergencyContactScreen(
          currentName: currentName,
          currentPhone: currentPhone,
          onContactUpdated: (name, phone) async {
            setState(() {
              int index = contacts.indexWhere((contact) => contact.name == currentName);
              if (index != -1) {
                contacts[index] = EmergencyContact(
                  contactId: contacts[index].contactId, // รักษา contactId เดิม
                  userId: userId!,
                  name: name,
                  phone: phone,
                );
              }
            });
            await _contactService.saveContacts(contacts);
          },
        ),
      ),
    );
  }

  void _deleteContact(String name) {
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        contacts.removeWhere((contact) => contact.name == name);
                      });
                      await _contactService.saveContacts(contacts);
                      Navigator.pop(context);
                    },
                    child: const Text("ยืนยัน",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: contacts.isEmpty ? _buildEmptyState() : _buildContactList(),
      ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(230, 70, 70, 1.0),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.group, size: 50, color: Colors.white),
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          "เพิ่มผู้ติดต่อกรณีฉุกเฉิน",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "เพิ่มผู้ติดต่อฉุกเฉินโดยการใส่ชื่อ และเบอร์โทรศัพท์",
          style: TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addContact,
            child: const Text("เพิ่มผู้ติดต่อ",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(230, 70, 70, 1.0),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30))),
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
            padding: EdgeInsets.only(top: 20.0), // แก้ custom เป็น top
            child: Text(
              "ผู้ติดต่อฉุกเฉิน",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          GestureDetector(
            onTap: _addContact,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(230, 70, 70, 1.0),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
                const SizedBox(width: 20),
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
          const SizedBox(height: 40),
          ListView.builder(
            shrinkWrap: true, // ป้องกัน Overflow
            physics: const NeverScrollableScrollPhysics(), // ปิดการเลื่อนซ้ำ
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                color: Colors.white,
                child: ListTile(
                  title: Text(contact.name, style: const TextStyle(fontSize: 16)),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.grey, size: 16),
                          const SizedBox(width: 5),
                          Text(contact.phone,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _editContact(contact.name, contact.phone);
                          } else if (value == 'delete') {
                            _deleteContact(contact.name);
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