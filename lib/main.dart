import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';

/// จุดเริ่มต้นหลักของแอปพลิเคชัน "ไปกัน"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadInitialData(); // โหลดข้อมูลสถานที่และแผนตัวอย่างล่วงหน้า
  runApp(PaiganApp(appState: appState));
}

/// คลาสหลัก PaiganApp สำหรับกำหนดสี ThemeData โหมดมืด/สว่าง และตัวจัดการสถานะหลัก
class PaiganApp extends StatelessWidget {
  final AppState appState;

  const PaiganApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF134E3A); // สีหลักเขียวมรกต
    const secondaryGold = Color(0xFFE5A93C); // สีเน้นเหลืองทอง
    const bgCream = Color(0xFFF8F7F2); // สีพื้นหลังครีมอ่อน

    // ชุดสีสว่าง (Light Theme)
    final colorSchemeLight = ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      primary: primaryEmerald,
      secondary: secondaryGold,
      surface: bgCream,
      brightness: Brightness.light,
    );

    // ชุดสีมืด (Dark Theme)
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      primary: const Color(0xFF1E6C52),
      secondary: secondaryGold,
      surface: const Color(0xFF121C18),
      brightness: Brightness.dark,
    );

    return AppStateProvider(
      appState: appState,
      child: MaterialApp(
        title: 'ไปกัน',
        debugShowCheckedModeBanner: false,
        themeMode: appState.themeMode, // รองรับการสลับธีมมืด/สว่าง
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorSchemeLight,
          scaffoldBackgroundColor: bgCream,
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryEmerald,
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 2,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withAlpha(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: primaryEmerald, width: 1.8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shadowColor: primaryEmerald.withAlpha(75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: colorSchemeDark,
          scaffoldBackgroundColor: const Color(0xFF0E1714),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0E1714),
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF172420),
            elevation: 2,
            shadowColor: Colors.black.withAlpha(80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF172420),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// ส่วนสลับหน้าระหว่าง LoginScreen กับ HomeShell ตามสถานะการล็อกอินของผู้ใช้
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    if (!appState.isLoggedIn) {
      return const LoginScreen(); // ถ้ายังไม่ล็อกอิน เปิดหน้า Login
    }
    return const HomeShell(); // ถ้าล็อกอินแล้ว เปิดหน้าหลัก
  }
}
