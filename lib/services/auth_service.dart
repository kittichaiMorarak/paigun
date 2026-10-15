import '../models/user.dart';

/// Abstract Interface สำหรับระบบล็อกอินผู้ใช้
abstract class AuthService {
  AppUser? get currentUser;
  Future<AppUser> loginWithEmail(String email, String password);
  Future<AppUser> loginWithGoogle();
  Future<AppUser> loginAsGuest();
  Future<void> logout();
}

/// Fake Auth Service จำลองการล็อกอิน พร้อมรองรับการกู้คืน User Session จาก Storage
class FakeAuthService implements AuthService {
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  void setCurrentUser(AppUser? user) {
    _currentUser = user;
  }

  @override
  Future<AppUser> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final parts = email.split('@');
    final name = parts.first.isNotEmpty ? parts.first : 'ผู้ใช้ทั่วไป';
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      isGuest: false,
    );
    return _currentUser!;
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = const AppUser(
      id: 'google_user_123',
      name: 'ผู้ใช้ Google',
      email: 'user@gmail.com',
      isGuest: false,
    );
    return _currentUser!;
  }

  @override
  Future<AppUser> loginAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = const AppUser(
      id: 'guest_user',
      name: 'ผู้เยี่ยมชม',
      email: '',
      isGuest: true,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }
}
