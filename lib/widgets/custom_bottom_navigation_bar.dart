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
    {'icon': Icons.apps, 'label': 'Menu'},
    {'icon': Icons.add_circle, 'label': 'Add'},
    {'icon': Icons.person, 'label': 'User'},
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFFFFF), // กำหนดสีพื้นหลังเป็นสีขาว
      elevation: 8, // เพิ่มเงาเล็กน้อยเพื่อให้แถบดูเด่นขึ้น
      items: items.map((item) {
        final int index = items.indexOf(item);
        return BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'],
                  size: 20, // ลดขนาด Icon เพื่อให้อยู่ในขอบเขต
                  color: index == currentIndex ? Colors.white : Colors.grey,
                ),
                if (index == currentIndex) ...[
                  const SizedBox(width: 4), // ลดขนาดช่องว่าง
                  Flexible( // ห่อ Text ด้วย Flexible เพื่อป้องกัน overflow
                    child: Text(
                      item['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10, // ลดขนาด Text
                        overflow: TextOverflow.ellipsis, // ตัดข้อความถ้าเกิน
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