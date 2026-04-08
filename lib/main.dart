import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/analytics_screen.dart';
import 'theme/app_theme.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const LinxApp());
}

class LinxApp extends StatefulWidget {
  const LinxApp({super.key});

  @override
  State<LinxApp> createState() => _LinxAppState();
}

class _LinxAppState extends State<LinxApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() => setState(() {
        _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainShell(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const MainShell({super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school_rounded, label: 'Subjects'),
    _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    SubjectsScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: cs.outlineVariant, width: 1)),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Linx', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      onPressed: widget.onToggleTheme,
                      icon: Icon(
                        widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      ),
                      tooltip: 'Toggle theme',
                    ),
                  ),
                ),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          ),
          // Main content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
