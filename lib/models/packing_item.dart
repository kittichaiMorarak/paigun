/// โมเดลรายการสิ่งของในเช็กลิสต์จัดกระเป๋า (PackingItem)
class PackingItem {
  final String id;
  final String title;
  final String category;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.title,
    required this.category,
    this.isPacked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'isPacked': isPacked,
      };

  factory PackingItem.fromJson(Map<String, dynamic> json) => PackingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String? ?? 'ทั่วไป',
        isPacked: json['isPacked'] as bool? ?? false,
      );
}
