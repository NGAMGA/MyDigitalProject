import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import 'search_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<bool> _visitedTabs = [true, false, false];

  final List<Widget> _screens = const [
    SearchScreen(),
    ExploreScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (index) => _visitedTabs[index] ? _screens[index] : const SizedBox(),
        ),
      ),
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return FloatingActionButton.small(
            tooltip: themeProvider.isDarkMode
                ? 'Passer en mode clair'
                : 'Passer en mode sombre',
            onPressed: themeProvider.toggleTheme,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<FavoritesProvider>(
        builder: (context, favProvider, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              height: 76,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                  _visitedTabs[index] = true;
                });
              },
              indicatorColor: colorScheme.primaryContainer,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Recherche',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.travel_explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explorer',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: favProvider.favorites.isNotEmpty,
                    label: Text('${favProvider.favorites.length}'),
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.favorite_border_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: favProvider.favorites.isNotEmpty,
                    label: Text('${favProvider.favorites.length}'),
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.favorite_rounded),
                  ),
                  label: 'Favoris',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
