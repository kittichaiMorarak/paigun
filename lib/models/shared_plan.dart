/// โมเดลแผนเที่ยวที่แชร์จากเพื่อน (SharedPlan)
class SharedPlan {
  final int id;
  final String title;
  final String authorName;
  final String description;
  final List<List<int>> days; // รายการ ID สถานที่แยกตามวัน
  final int likes;

  const SharedPlan({
    required this.id,
    required this.title,
    required this.authorName,
    required this.description,
    required this.days,
    required this.likes,
  });

  factory SharedPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>;
    final daysList = rawDays.map((d) {
      return (d as List<dynamic>).map((e) => e as int).toList();
    }).toList();

    return SharedPlan(
      id: json['id'] as int,
      title: json['title'] as String,
      authorName: json['authorName'] as String? ?? json['author_name'] as String? ?? 'ไม่ระบุชื่อ',
      description: json['description'] as String? ?? '',
      days: daysList,
      likes: json['likes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authorName': authorName,
    'description': description,
    'days': days,
    'likes': likes,
  };

  SharedPlan copyWith({
    int? id,
    String? title,
    String? authorName,
    String? description,
    List<List<int>>? days,
    int? likes,
  }) {
    return SharedPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      description: description ?? this.description,
      days: days ?? this.days,
      likes: likes ?? this.likes,
    );
  }
}
