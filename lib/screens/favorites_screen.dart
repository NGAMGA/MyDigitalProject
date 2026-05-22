import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF7D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Mes Favoris',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Vos recettes sauvegardees',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<FavoritesProvider>(
                builder: (context, favProvider, child) {
                  final favorites = favProvider.favorites;
                  if (favorites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EE),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: const Icon(Icons.favorite_border_rounded,
                                size: 46, color: Color(0xFF4CAF7D)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Aucun favori pour l\'instant',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A2A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez sur le coeur sur une recette\npour l\'ajouter ici',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          '${favorites.length} recette${favorites.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF7D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20, top: 8),
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final meal = favorites[index];
                            return MealCard(
                              meal: meal,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MealDetailScreen(
                                    mealId: meal.id,
                                    mealName: meal.name,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}