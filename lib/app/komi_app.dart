import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/profile/profile_page.dart';
import '../features/scan/scan_page.dart';
import '../providers/favorites_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_session_provider.dart';
import '../screens/favorites_screen.dart';
import '../screens/search_screen.dart';

class KomiApp extends StatelessWidget {
  const KomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => UserSessionProvider()..load()),
      ],
      child: MaterialApp(
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
      ),
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

  final _titles = const [
    'Komi',
    'Recettes',
    'Scan',
    'Favoris',
    'Profile',
  ];

  void _selectPage(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenRecipes: () => _selectPage(1),
        onOpenScan: () => _selectPage(2),
        onOpenProfile: () => _selectPage(4),
      ),
      SearchScreen(onBack: () => _selectPage(0)),
      ScanPage(onBack: () => _selectPage(0)),
      FavoritesScreen(onBack: () => _selectPage(0)),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: _index == 0 ||
              _index == 1 ||
              _index == 2 ||
              _index == 3 ||
              _index == 4
          ? null
          : AppBar(
              title: Text(_titles[_index]),
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
            ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _KomiNavButton(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: _index == 0,
                onTap: () => _selectPage(0),
              ),
              _KomiNavButton(
                icon: Icons.search_rounded,
                selectedIcon: Icons.search_rounded,
                selected: _index == 1,
                onTap: () => _selectPage(1),
              ),
              _KomiNavButton(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long_rounded,
                selected: _index == 2,
                onTap: () => _selectPage(2),
              ),
              _KomiNavButton(
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                selected: _index == 3,
                onTap: () => _selectPage(3),
              ),
              _KomiNavButton(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                selected: _index == 4,
                onTap: () => _selectPage(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KomiNavButton extends StatelessWidget {
  const _KomiNavButton({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor:
            selected ? const Color(0xFF062F1A) : Colors.transparent,
        foregroundColor:
            selected ? const Color(0xFFDDF577) : const Color(0xFF062F1A),
      ),
      icon: Icon(selected ? selectedIcon : icon, size: 26),
    );
  }
}
