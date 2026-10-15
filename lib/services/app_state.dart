import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/place_seed_data.dart';
import '../models/shared_plan.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// ตัวจัดการสถานะส่วนกลางของแอป (Centralized State Management) พร้อมระบบบันทึกข้อมูลคงทน (Persistent Storage)
class AppState extends ChangeNotifier {
  final AuthService authService;

  List<Place> _places = [];
  final List<int> _selectedPlaceIds = [];
  final List<int> _favoritePlaceIds = [];
  List<SharedPlan> _sharedPlans = [];
  bool _isLoading = true;

  // สถานะธีมและภาษา
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'th';

  // ประวัติการค้นหาล่าสุด
  final List<String> _recentSearches = ['เชียงใหม่', 'ภูเก็ต', 'วัด', 'ทะเล', 'คาเฟ่'];

  // กำหนดวันเดินทาง
  DateTime? tripStartDate;
  DateTime? tripEndDate;

  // รายการเช็กลิสต์จัดกระเป๋า
  List<PackingItem> _packingList = [
    PackingItem(id: '1', title: 'บัตรประชาชน / พาสปอร์ต', category: 'เอกสาร'),
    PackingItem(id: '2', title: 'ตั๋วเดินทาง / ใบจองโรงแรม', category: 'เอกสาร'),
    PackingItem(id: '3', title: 'สายชาร์จ / พาวเวอร์แบงก์', category: 'ไอที'),
    PackingItem(id: '4', title: 'ยาประจำตัว / พลาสเตอร์ยา', category: 'ยา/สุขภาพ'),
    PackingItem(id: '5', title: 'ครีมกันแดด / แว่นกันแดด', category: 'ของใช้'),
    PackingItem(id: '6', title: 'กล้องถ่ายรูป', category: 'ไอที'),
    PackingItem(id: '7', title: 'เสื้อผ้า / หมวก', category: 'เสื้อผ้า'),
    PackingItem(id: '8', title: 'รองเท้าผ้าใบเดินสบาย', category: 'เสื้อผ้า'),
  ];

  AppState({AuthService? authService})
      : authService = authService ?? FakeAuthService();

  List<Place> get places => List.unmodifiable(_places);
  List<int> get selectedPlaceIds => List.unmodifiable(_selectedPlaceIds);
  List<int> get favoritePlaceIds => List.unmodifiable(_favoritePlaceIds);
  List<SharedPlan> get sharedPlans => List.unmodifiable(_sharedPlans);
  List<PackingItem> get packingList => List.unmodifiable(_packingList);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isLoading => _isLoading;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String get language => _language;
  bool get isEnglish => _language == 'en';

  AppUser? get currentUser => authService.currentUser;
  bool get isLoggedIn => currentUser != null;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == 'th' ? 'en' : 'th';
    notifyListeners();
  }

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  List<Place> get selectedPlaces {
    final result = <Place>[];
    for (final id in _selectedPlaceIds) {
      for (final p in _places) {
        if (p.id == id) {
          result.add(p);
          break;
        }
      }
    }
    return result;
  }

  List<Place> get favoritePlaces {
    final result = <Place>[];
    for (final id in _favoritePlaceIds) {
      for (final p in _places) {
        if (p.id == id) {
          result.add(p);
          break;
        }
      }
    }
    return result;
  }

  /// โหลดข้อมูลทั้งหมดเมื่อเริ่มแอป (ทั้งจาก Seed Assets, Storage, และ Fallback Data)
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. โหลดข้อมูลสถานที่
      try {
        final placesRaw = await rootBundle.loadString('assets/places_seed.json');
        final seedPlaces = (jsonDecode(placesRaw) as List)
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
        final customPlaces = await StorageService.loadCustomPlaces();
        _places = [...customPlaces, ...seedPlaces];
      } catch (e) {
        // Fallback ถ้ามีปัญหาโหลด Asset
        final customPlaces = await StorageService.loadCustomPlaces();
        _places = [...customPlaces, ...fallbackPlacesList];
      }

      if (_places.isEmpty) {
        _places = List.from(fallbackPlacesList);
      }

      // 2. โหลดแผนแชร์
      final storedPlans = await StorageService.loadSharedPlans();
      if (storedPlans != null && storedPlans.isNotEmpty) {
        _sharedPlans = storedPlans;
      } else {
        try {
          final plansRaw =
              await rootBundle.loadString('assets/shared_plans_seed.json');
          _sharedPlans = (jsonDecode(plansRaw) as List)
              .map((e) => SharedPlan.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          _sharedPlans = List.from(fallbackSharedPlansList);
        }
      }

      if (_sharedPlans.isEmpty) {
        _sharedPlans = List.from(fallbackSharedPlansList);
      }

      // 3. โหลดสภาวะการล็อกอิน
      final savedUser = await StorageService.loadCurrentUser();
      if (savedUser != null && authService is FakeAuthService) {
        (authService as FakeAuthService).setCurrentUser(savedUser);
      }

      // 4. โหลดข้อมูลในทริปและรายการโปรด
      final savedSelected = await StorageService.loadSelectedPlaceIds();
      _selectedPlaceIds.clear();
      _selectedPlaceIds.addAll(savedSelected);

      final savedFavorites = await StorageService.loadFavoritePlaceIds();
      _favoritePlaceIds.clear();
      _favoritePlaceIds.addAll(savedFavorites);

      // 5. โหลดวันเดินทาง
      final dates = await StorageService.loadTripDates();
      tripStartDate = dates['start'];
      tripEndDate = dates['end'];

      // 6. โหลดเช็กลิสต์จัดกระเป๋า
      final savedPacking = await StorageService.loadPackingList();
      if (savedPacking != null && savedPacking.isNotEmpty) {
        _packingList = savedPacking;
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (_places.isEmpty) _places = List.from(fallbackPlacesList);
      if (_sharedPlans.isEmpty) _sharedPlans = List.from(fallbackSharedPlansList);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePlaceSelection(int placeId) {
    if (_selectedPlaceIds.contains(placeId)) {
      _selectedPlaceIds.remove(placeId);
    } else {
      _selectedPlaceIds.add(placeId);
    }
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void clearPlaceSelection() {
    _selectedPlaceIds.clear();
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void toggleFavorite(int placeId) {
    if (_favoritePlaceIds.contains(placeId)) {
      _favoritePlaceIds.remove(placeId);
    } else {
      _favoritePlaceIds.add(placeId);
    }
    StorageService.saveFavoritePlaceIds(_favoritePlaceIds);
    notifyListeners();
  }

  void setPlaceSelection(List<int> placeIds) {
    _selectedPlaceIds.clear();
    _selectedPlaceIds.addAll(placeIds);
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void reorderSelectedPlaces(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _selectedPlaceIds.removeAt(oldIndex);
    _selectedPlaceIds.insert(newIndex, item);
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void reorderSelectedPlacesDirect(int oldIndex, int newIndex) {
    final item = _selectedPlaceIds.removeAt(oldIndex);
    _selectedPlaceIds.insert(newIndex, item);
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void sortSelectedPlacesByRoute() {
    if (_selectedPlaceIds.length < 2) return;

    final placesList = selectedPlaces;
    final unvisited = List<Place>.from(placesList);
    final sorted = <Place>[];

    var current = unvisited.removeAt(0);
    sorted.add(current);

    while (unvisited.isNotEmpty) {
      int nearestIndex = 0;
      double minDistance = current.distanceKm(unvisited[0]);
      for (var i = 1; i < unvisited.length; i++) {
        final d = current.distanceKm(unvisited[i]);
        if (d < minDistance) {
          minDistance = d;
          nearestIndex = i;
        }
      }
      current = unvisited.removeAt(nearestIndex);
      sorted.add(current);
    }

    _selectedPlaceIds.clear();
    _selectedPlaceIds.addAll(sorted.map((p) => p.id));
    StorageService.saveSelectedPlaceIds(_selectedPlaceIds);
    notifyListeners();
  }

  void setTripDates(DateTime? start, DateTime? end) {
    tripStartDate = start;
    tripEndDate = end;
    StorageService.saveTripDates(start, end);
    notifyListeners();
  }

  int? get daysUntilTrip {
    if (tripStartDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(tripStartDate!.year, tripStartDate!.month, tripStartDate!.day);
    return start.difference(today).inDays;
  }

  void togglePackingItem(String itemId) {
    final index = _packingList.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _packingList[index].isPacked = !_packingList[index].isPacked;
      StorageService.savePackingList(_packingList);
      notifyListeners();
    }
  }

  void addPackingItem(String title, String category) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _packingList.add(PackingItem(id: newId, title: title, category: category));
    StorageService.savePackingList(_packingList);
    notifyListeners();
  }

  void deletePackingItem(String itemId) {
    _packingList.removeWhere((item) => item.id == itemId);
    StorageService.savePackingList(_packingList);
    notifyListeners();
  }

  void addCustomPlace(Place newPlace) {
    _places.insert(0, newPlace);
    final customPlaces = _places.where((p) => p.id >= 10000 || p.verified).toList();
    StorageService.saveCustomPlaces(customPlaces);
    notifyListeners();
  }

  void addSharedPlan({
    required String title,
    required String description,
    required List<List<int>> days,
  }) {
    final newId = DateTime.now().millisecondsSinceEpoch;
    final authorName = currentUser?.name ?? 'ผู้ใช้ทั่วไป';
    final newPlan = SharedPlan(
      id: newId,
      title: title,
      authorName: authorName,
      description: description,
      days: days,
      likes: 0,
    );
    _sharedPlans = [newPlan, ..._sharedPlans];
    StorageService.saveSharedPlans(_sharedPlans);
    notifyListeners();
  }

  void toggleLikeSharedPlan(int planId) {
    final index = _sharedPlans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      final old = _sharedPlans[index];
      final updated = old.copyWith(likes: old.likes + 1);
      final updatedList = List<SharedPlan>.from(_sharedPlans);
      updatedList[index] = updated;
      _sharedPlans = updatedList;
      StorageService.saveSharedPlans(_sharedPlans);
      notifyListeners();
    }
  }

  // Budget, Time & Distance Calculations
  double get totalTripDistanceKm {
    final sel = selectedPlaces;
    if (sel.length < 2) return 0.0;
    double dist = 0.0;
    for (var i = 0; i < sel.length - 1; i++) {
      dist += sel[i].distanceKm(sel[i + 1]);
    }
    return dist;
  }

  int get totalVisitDurationMin {
    final sel = selectedPlaces;
    int total = 0;
    for (final p in sel) {
      total += p.avgDurationMin;
    }
    return total;
  }

  int get totalTravelTimeMin {
    final dist = totalTripDistanceKm;
    if (dist == 0) return 0;
    return ((dist / 40.0) * 60).round();
  }

  int get totalEstimatedEntranceFee {
    final sel = selectedPlaces;
    int total = 0;
    for (final p in sel) {
      total += _parseFee(p.fee);
    }
    return total;
  }

  int _parseFee(String? feeStr) {
    if (feeStr == null || feeStr.isEmpty || feeStr.contains('ฟรี')) return 0;
    final digits = RegExp(r'\d+').allMatches(feeStr);
    if (digits.isNotEmpty) {
      return int.tryParse(digits.first.group(0) ?? '0') ?? 0;
    }
    return 0;
  }

  double get estimatedFuelCost => totalTripDistanceKm * 3.5;

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final user = await authService.loginWithEmail(email, password);
      await StorageService.saveCurrentUser(user);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final user = await authService.loginWithGoogle();
      await StorageService.saveCurrentUser(user);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    try {
      final user = await authService.loginAsGuest();
      await StorageService.saveCurrentUser(user);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    await StorageService.saveCurrentUser(null);
    notifyListeners();
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
