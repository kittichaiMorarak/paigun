/// โมเดลข้อมูลผู้ใช้งาน (AppUser)
class AppUser {
  final String id;
  final String name;
  final String email;
  final bool isGuest;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
  });
}
