import 'dart:math';

/// โมเดลข้อมูลสถานที่ท่องเที่ยว (Place)
class Place {
  final int id;
  final String name;
  final String province;
  final String region;
  final String category;
  final double lat;
  final double lng;
  final int avgDurationMin;
  final String? open;
  final String? close;
  final String? fee;
  final String description;
  final bool verified;
  final String? imageUrl;
  final double rating;
  final int reviewCount;

  const Place({
    required this.id,
    required this.name,
    required this.province,
    required this.region,
    required this.category,
    required this.lat,
    required this.lng,
    required this.avgDurationMin,
    required this.open,
    required this.close,
    required this.fee,
    required this.description,
    required this.verified,
    this.imageUrl,
    this.rating = 4.5,
    this.reviewCount = 50,
  });

  /// แปลง JSON Map เป็นวัตถุ Place
  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as int,
        name: j['name'] as String,
        province: j['province'] as String,
        region: j['region'] as String,
        category: j['category'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        avgDurationMin: j['avg_duration_min'] as int,
        open: j['open'] as String?,
        close: j['close'] as String?,
        fee: j['fee'] as String?,
        description: j['description'] as String,
        verified: j['verified'] as bool? ?? false,
        imageUrl: j['image_url'] as String? ?? j['imageUrl'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? (4.2 + (j['id'] as int) % 8 * 0.1),
        reviewCount: (j['review_count'] as int?) ?? (30 + (j['id'] as int) * 12 % 300),
      );

  /// คืนค่า URL รูปภาพสถานที่ หรือใช้รูปสำรองแยกตามหมวดหมู่ถ้าไม่มีรูป
  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    switch (category) {
      case 'temple':
        return 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600';
      case 'nature':
        return 'https://images.unsplash.com/photo-1511497584788-876761c119ef?w=600';
      case 'beach':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600';
      case 'history':
        return 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=600';
      case 'market':
        return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600';
      case 'cafe':
        return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600';
      default:
        return 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600';
    }
  }

  /// คำนวณระยะเส้นตรงถึงสถานที่ B (กิโลเมตร) ตามสูตร Haversine
  double distanceKm(Place b) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(b.lat - lat);
    final dLng = rad(b.lng - lng);
    final h = pow(sin(dLat / 2), 2) +
        cos(rad(lat)) * cos(rad(b.lat)) * pow(sin(dLng / 2), 2);
    return 2 * r * asin(sqrt(h));
  }
}
