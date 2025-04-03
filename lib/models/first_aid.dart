class FirstAid {
  final String id;
  final String title;
  final String content;

  FirstAid({
    required this.id,
    required this.title,
    required this.content,
  });

  factory FirstAid.fromJson(Map<String, dynamic> json) {
    return FirstAid(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }
} 