import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
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

  final List<Widget> _screens = const [
    SearchScreen(),
    ExploreScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<FavoritesProvider>(
        builder: (context, favProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF7D).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: const Color(0xFF4CAF7D),
              unselectedItemColor: const Color(0xFFBDBDBD),
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Recherche',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_rounded),
                  label: 'Explorer',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: favProvider.favorites.isNotEmpty,
                    label: Text('${favProvider.favorites.length}'),
                    backgroundColor: const Color(0xFF4CAF7D),
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