import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  // รายการของไอคอนและข้อความสำหรับแต่ละแถบ
  final List<Map<String, dynamic>> items = [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Chat'},
    {'icon': Icons.apps, 'label': 'Menu'},
    {'icon': Icons.add_circle, 'label': 'Add'},
    {'icon': Icons.person, 'label': 'User'},
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 8,
      items: items.map((item) {
        final int index = items.indexOf(item);
        return BottomNavigationBarItem(
          icon: Container(
            width: 80, // เพิ่มความกว้างเพื่อให้มีที่ว่างสำหรับข้อความ
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // ปรับ padding
            decoration: BoxDecoration(
              color: index == currentIndex
                  ? const Color.fromRGBO(230, 70, 70, 1.0)
                  : Colors.transparent,
              border: Border.all(
                color: index == currentIndex
                    ? const Color.fromRGBO(230, 70, 70, 1.0)
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่กึ่งกลาง
              children: [
                Icon(
                  item['icon'],
                  size: 20,
                  color: index == currentIndex ? Colors.white : Colors.grey,
                ),
                if (index == currentIndex) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9, // ลดขนาดตัวอักษรเล็กน้อย
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          label: '',
        );
      }).toList(),
      currentIndex: currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: onTap,
    );
  }
}