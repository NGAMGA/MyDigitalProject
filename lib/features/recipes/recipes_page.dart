import 'package:flutter/material.dart';

import '../../screens/explore_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/search_screen.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            child: TabBar(
              labelColor: Color(0xFF062F1A),
              unselectedLabelColor: Color(0xFF6E756F),
              indicatorColor: Color(0xFF062F1A),
              tabs: [
                Tab(icon: Icon(Icons.search_rounded), text: 'Recherche'),
                Tab(icon: Icon(Icons.explore_rounded), text: 'Explorer'),
                Tab(icon: Icon(Icons.favorite_rounded), text: 'Favoris'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SearchScreen(),
                ExploreScreen(),
                FavoritesScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
