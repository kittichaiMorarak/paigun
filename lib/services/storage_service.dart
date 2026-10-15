import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/shared_plan.dart';
import '../models/user.dart';

/// บริการจัดการข้อมูลคงทน (Persistent Storage Service) บันทึกลง Disk ในเครื่องด้วย SharedPreferences
class StorageService {
  static const _keyUser = 'paigan_current_user';
  static const _keySelectedPlaceIds = 'paigan_selected_place_ids';
  static const _keyFavoritePlaceIds = 'paigan_favorite_place_ids';
  static const _keyTripStartDate = 'paigan_trip_start_date';
  static const _keyTripEndDate = 'paigan_trip_end_date';
  static const _keyPackingList = 'paigan_packing_list';
  static const _keyCustomPlaces = 'paigan_custom_places';
  static const _keySharedPlans = 'paigan_shared_plans';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- บันทึก / โหลด ผู้ใช้ปัจจุบัน ---
  static Future<void> saveCurrentUser(AppUser? user) async {
    final prefs = await _instance;
    if (user == null) {
      await prefs.remove(_keyUser);
    } else {
      final map = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'isGuest': user.isGuest,
      };
      await prefs.setString(_keyUser, jsonEncode(map));
    }
  }

  static Future<AppUser?> loadCurrentUser() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        isGuest: map['isGuest'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  // --- บันทึก / โหลด สถานที่ที่เลือกในทริป ---
  static Future<void> saveSelectedPlaceIds(List<int> ids) async {
    final prefs = await _instance;
    final strList = ids.map((id) => id.toString()).toList();
    await prefs.setStringList(_keySelectedPlaceIds, strList);
  }

  static Future<List<int>> loadSelectedPlaceIds() async {
    final prefs = await _instance;
    final strList = prefs.getStringList(_keySelectedPlaceIds);
    if (strList == null) return [];
    return strList.map((s) => int.tryParse(s) ?? 0).where((id) => id != 0).toList();
  }

  // --- บันทึก / โหลด รายการโปรด Wishlist ---
  static Future<void> saveFavoritePlaceIds(List<int> ids) async {
    final prefs = await _instance;
    final strList = ids.map((id) => id.toString()).toList();
    await prefs.setStringList(_keyFavoritePlaceIds, strList);
  }

  static Future<List<int>> loadFavoritePlaceIds() async {
    final prefs = await _instance;
    final strList = prefs.getStringList(_keyFavoritePlaceIds);
    if (strList == null) return [];
    return strList.map((s) => int.tryParse(s) ?? 0).where((id) => id != 0).toList();
  }

  // --- บันทึก / โหลด วันเดินทาง ---
  static Future<void> saveTripDates(DateTime? start, DateTime? end) async {
    final prefs = await _instance;
    if (start == null) {
      await prefs.remove(_keyTripStartDate);
    } else {
      await prefs.setString(_keyTripStartDate, start.toIso8601String());
    }
    if (end == null) {
      await prefs.remove(_keyTripEndDate);
    } else {
      await prefs.setString(_keyTripEndDate, end.toIso8601String());
    }
  }

  static Future<Map<String, DateTime?>> loadTripDates() async {
    final prefs = await _instance;
    final startStr = prefs.getString(_keyTripStartDate);
    final endStr = prefs.getString(_keyTripEndDate);
    return {
      'start': startStr != null ? DateTime.tryParse(startStr) : null,
      'end': endStr != null ? DateTime.tryParse(endStr) : null,
    };
  }

  // --- บันทึก / โหลด เช็กลิสต์จัดกระเป๋า ---
  static Future<void> savePackingList(List<PackingItem> items) async {
    final prefs = await _instance;
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_keyPackingList, jsonEncode(jsonList));
  }

  static Future<List<PackingItem>?> loadPackingList() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyPackingList);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => PackingItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      return null;
    }
  }

  // --- บันทึก / โหลด สถานที่ใหม่ที่ผู้ใช้เพิ่ม ---
  static Future<void> saveCustomPlaces(List<Place> customPlaces) async {
    final prefs = await _instance;
    final jsonList = customPlaces.map((p) => {
      'id': p.id,
      'name': p.name,
      'province': p.province,
      'region': p.region,
      'category': p.category,
      'lat': p.lat,
      'lng': p.lng,
      'avg_duration_min': p.avgDurationMin,
      'open': p.open,
      'close': p.close,
      'fee': p.fee,
      'description': p.description,
      'verified': p.verified,
      'image_url': p.imageUrl,
      'rating': p.rating,
      'review_count': p.reviewCount,
    }).toList();
    await prefs.setString(_keyCustomPlaces, jsonEncode(jsonList));
  }

  static Future<List<Place>> loadCustomPlaces() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyCustomPlaces);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      return [];
    }
  }

  // --- บันทึก / โหลด แผนเที่ยวแชร์ของชุมชน ---
  static Future<void> saveSharedPlans(List<SharedPlan> plans) async {
    final prefs = await _instance;
    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_keySharedPlans, jsonEncode(jsonList));
  }

  static Future<List<SharedPlan>?> loadSharedPlans() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keySharedPlans);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => SharedPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      return null;
    }
  }
}
