import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/translations.dart';
import 'explore_tab.dart';
import 'map_tab.dart';
import 'plan_tab.dart';
import 'shared_plans_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final user = appState.currentUser;

    final pages = const [
      ExploreTab(),
      MapTab(),
      PlanTab(),
      SharedPlansScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_rounded,
                  color: Color(0xFFE5A93C), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              tr(context, 'ไปกัน', 'Paigan'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // User Avatar Badge
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5A93C).withAlpha(128),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin,
                          size: 14, color: Color(0xFFE5A93C)),
                      const SizedBox(width: 4),
                      Text(
                        user.isGuest
                            ? tr(context, 'ผู้เยี่ยมชม', 'Guest')
                            : user.name,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Language Switcher Button (TH / EN)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => appState.toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C).withAlpha(60),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5A93C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded,
                      size: 14, color: Color(0xFFE5A93C)),
                  const SizedBox(width: 4),
                  Text(
                    appState.isEnglish ? 'EN' : 'TH',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dark Mode Toggle Button
          IconButton(
            tooltip: appState.isDarkMode
                ? tr(context, 'เปิดโหมดสว่าง', 'Light Mode')
                : tr(context, 'เปิดโหมดมืด', 'Dark Mode'),
            icon: Icon(
              appState.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => appState.toggleThemeMode(),
          ),

          // Logout Button
          IconButton(
            tooltip: tr(context, 'ออกจากระบบ', 'Logout'),
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr(context, 'ออกจากระบบ', 'Logout')),
                  content: Text(tr(context, 'คุณต้องการออกจากระบบหรือไม่?',
                      'Are you sure you want to log out?')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr(context, 'ยกเลิก', 'Cancel')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr(context, 'ออกจากระบบ', 'Logout')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                appState.logout();
              }
            },
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          indicatorColor: const Color(0xFF134E3A).withAlpha(38),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.travel_explore_outlined),
              selectedIcon:
                  const Icon(Icons.travel_explore, color: Color(0xFF134E3A)),
              label: tr(context, 'สำรวจ', 'Explore'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map, color: Color(0xFF134E3A)),
              label: tr(context, 'แผนที่', 'Map'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_note_outlined),
              selectedIcon:
                  const Icon(Icons.event_note, color: Color(0xFF134E3A)),
              label: tr(context, 'แผนเที่ยว', 'My Trip'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.share_outlined),
              selectedIcon: const Icon(Icons.share, color: Color(0xFF134E3A)),
              label: tr(context, 'แผนจากเพื่อน', 'Shared Plans'),
            ),
          ],
        ),
      ),
    );
  }
}
