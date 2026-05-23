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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: meal.thumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: meal.thumbnail!,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      placeholder: (context, url) {
                        return Container(
                          width: 112,
                          height: 112,
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
                          width: 112,
                          height: 112,
                          color: const Color(0xFFE8F5EE),
                          child: Icon(Icons.restaurant,
                              color: colorScheme.primary, size: 36),
                        );
                      },
                    )
                  : Container(
                      width: 112,
                      height: 112,
                      color: const Color(0xFFE8F5EE),
                      child: Icon(Icons.restaurant,
                          color: colorScheme.primary, size: 36),
                    ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (meal.area != null)
                      Row(
                        children: [
                          Icon(Icons.public,
                              size: 12, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            meal.area!,
                            style: TextStyle(
                                fontSize: 12, color: colorScheme.primary),
                          ),
                        ],
                      ),
                    if (meal.category != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal.category!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav ? colorScheme.primary : colorScheme.outline,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.outline,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
