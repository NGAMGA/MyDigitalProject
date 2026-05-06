import 'package:flutter/material.dart';

import '../features/auth/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/profile/profile_page.dart';
import '../features/recipes/recipes_page.dart';
import '../features/scan/scan_page.dart';

class KomiApp extends StatelessWidget {
  const KomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Komi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF062F1A),
          primary: const Color(0xFF062F1A),
          secondary: const Color(0xFFDDF577),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    ScanPage(),
    RecipesPage(),
    ProfilePage(),
  ];

  final _titles = const [
    'Komi',
    'Scan',
    'Recipes',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF5D6),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_rounded), label: 'Recipes'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
