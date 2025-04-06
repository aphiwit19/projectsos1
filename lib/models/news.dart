class News {
  final String id;
  final String title;
  final String content;
  final DateTime? date;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.date,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    DateTime? dateTime;
    if (json['date'] != null) {
      // รองรับทั้ง Timestamp จาก Firestore และ String
      if (json['date'] is String) {
        dateTime = DateTime.parse(json['date']);
      } else if (json['date'] is DateTime) {
        dateTime = json['date'];
      } else {
        // กรณีเป็น Timestamp จาก Firestore
        try {
          dateTime = json['date'].toDate();
        } catch (e) {
          print('Error converting date: $e');
        }
      }
    }

    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: dateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date?.toIso8601String(),
    };
  }

  String getPreviewContent({int maxLength = 120}) {
    if (content.length <= maxLength) {
      return content;
    }
    return content.substring(0, maxLength) + '...';
  }

  String getFormattedDate() {
    if (date == null) return '';
    
    // แปลงเป็นรูปแบบวันที่ไทย
    final List<String> thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    return '${date!.day} ${thaiMonths[date!.month - 1]} ${date!.year + 543}';
  }
} 