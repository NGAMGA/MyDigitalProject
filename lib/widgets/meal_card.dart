import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/favorites_provider.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;

  const MealCard({super.key, required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF7D).withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: meal.thumbnail != null
                  ? CachedNetworkImage(
                imageUrl: meal.thumbnail!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Container(
                    width: 110,
                    height: 110,
                    color: const Color(0xFFE8F5EE),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF7D),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return Container(
                    width: 110,
                    height: 110,
                    color: const Color(0xFFE8F5EE),
                    child: const Icon(Icons.restaurant, color: Color(0xFF4CAF7D), size: 36),
                  );
                },
              )
                  : Container(
                width: 110,
                height: 110,
                color: const Color(0xFFE8F5EE),
                child: const Icon(Icons.restaurant, color: Color(0xFF4CAF7D), size: 36),
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A2A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (meal.area != null)
                      Row(
                        children: [
                          const Icon(Icons.public, size: 12, color: Color(0xFF4CAF7D)),
                          const SizedBox(width: 4),
                          Text(
                            meal.area!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF7D)),
                          ),
                        ],
                      ),
                    if (meal.category != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal.category!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D52),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Favori
            Consumer<FavoritesProvider>(
              builder: (context, favProvider, child) {
                final isFav = favProvider.isFavorite(meal.id);
                return IconButton(
                  onPressed: () => favProvider.toggleFavorite(meal),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav ? const Color(0xFF4CAF7D) : const Color(0xFFBDBDBD),
                      size: 26,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}