import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../providers/favorites_provider.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _FavoriteCategoryType? _selectedCategory;
  final _searchController = TextEditingController();
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;

    if (_selectedCategory != null) {
      return _FavoriteMealsPage(
        category: _selectedCategory!,
        favorites: favorites,
        searchController: _searchController,
        sortAscending: _sortAscending,
        onBack: () => setState(() => _selectedCategory = null),
        onSearchChanged: () => setState(() {}),
        onToggleSort: () => setState(() => _sortAscending = !_sortAscending),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FavoritesHeader(onBack: widget.onBack, title: 'Favoris'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 104),
                itemCount: _favoriteCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final category = _favoriteCategories[index];
                  final count =
                      _mealsForCategory(favorites, category.type).length;
                  return _FavoriteCategoryCard(
                    category: category,
                    count: count,
                    onTap: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = category.type);
                    },
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

class _FavoriteMealsPage extends StatelessWidget {
  const _FavoriteMealsPage({
    required this.category,
    required this.favorites,
    required this.searchController,
    required this.sortAscending,
    required this.onBack,
    required this.onSearchChanged,
    required this.onToggleSort,
  });

  final _FavoriteCategoryType category;
  final List<Meal> favorites;
  final TextEditingController searchController;
  final bool sortAscending;
  final VoidCallback onBack;
  final VoidCallback onSearchChanged;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final meals = _mealsForCategory(favorites, category)
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) {
        final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return sortAscending ? comparison : -comparison;
      });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FavoritesHeader(
                onBack: onBack, title: _labelForCategory(category)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 29,
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => onSearchChanged(),
                        textAlign: TextAlign.center,
                        cursorColor: const Color(0xFF062F1A),
                        decoration: InputDecoration(
                          hintText: 'Rechercher',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: Color(0xFF202020),
                              width: 1.6,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: Color(0xFF062F1A),
                              width: 1.8,
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundToolButton(
                    icon: Icons.tune_rounded,
                    onTap: onToggleSort,
                  ),
                  const SizedBox(width: 7),
                  _RoundToolButton(
                    icon: sortAscending
                        ? Icons.format_list_bulleted_rounded
                        : Icons.sort_by_alpha_rounded,
                    onTap: onToggleSort,
                  ),
                ],
              ),
            ),
            Expanded(
              child: meals.isEmpty
                  ? _EmptyCategoryMessage(category: category)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 104),
                      itemCount: meals.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE0E0E0),
                      ),
                      itemBuilder: (context, index) {
                        return _FavoriteMealRow(meal: meals[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.onBack, required this.title});

  final VoidCallback? onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 8, 0),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_rounded, size: 25),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundToolButton extends StatelessWidget {
  const _RoundToolButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF202020), width: 1.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF202020), size: 17),
      ),
    );
  }
}

class _FavoriteMealRow extends StatelessWidget {
  const _FavoriteMealRow({required this.meal});

  final Meal meal;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MealDetailScreen(
          mealId: meal.id,
          mealName: meal.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetail(context),
      child: SizedBox(
        height: 51,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: CachedNetworkImage(
                imageUrl: meal.thumbnail ?? '',
                width: 27,
                height: 27,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFEAF5D6),
                  child: const SizedBox.shrink(),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 27,
                  height: 27,
                  color: const Color(0xFFEAF5D6),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFF062F1A),
                    size: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _subtitleForMeal(meal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.read<FavoritesProvider>().removeFavorite(
                    meal.id,
                  ),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF202020),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleForMeal(Meal meal) {
    final parts = [
      if ((meal.area ?? '').trim().isNotEmpty) meal.area!.trim(),
      if ((meal.category ?? '').trim().isNotEmpty) meal.category!.trim(),
    ];
    if (parts.isEmpty) return 'Recette aimee';
    return parts.join(' - ');
  }
}

class _EmptyCategoryMessage extends StatelessWidget {
  const _EmptyCategoryMessage({required this.category});

  final _FavoriteCategoryType category;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          'Aucun favori dans ${_labelForCategory(category).toLowerCase()} pour le moment.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _FavoriteCategory {
  const _FavoriteCategory({
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.alignment,
  });

  final _FavoriteCategoryType type;
  final String title;
  final String imageUrl;
  final Alignment alignment;
}

class _FavoriteCategoryCard extends StatelessWidget {
  const _FavoriteCategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final _FavoriteCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Image.network(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    alignment: category.alignment,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/komi-bowl.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.title,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$count favori${count > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF062F1A),
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FavoriteCategoryType { starters, mains, desserts }

const _favoriteCategories = [
  _FavoriteCategory(
    type: _FavoriteCategoryType.starters,
    title: 'Entrees',
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
    alignment: Alignment.bottomCenter,
  ),
  _FavoriteCategory(
    type: _FavoriteCategoryType.mains,
    title: 'Plats',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
    alignment: Alignment.bottomCenter,
  ),
  _FavoriteCategory(
    type: _FavoriteCategoryType.desserts,
    title: 'Desserts',
    imageUrl:
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
    alignment: Alignment.bottomCenter,
  ),
];

List<Meal> _mealsForCategory(
  List<Meal> favorites,
  _FavoriteCategoryType category,
) {
  return favorites.where((meal) => _categoryForMeal(meal) == category).toList();
}

_FavoriteCategoryType _categoryForMeal(Meal meal) {
  final category = (meal.category ?? '').trim().toLowerCase();

  if (category == 'starter' || category == 'side') {
    return _FavoriteCategoryType.starters;
  }
  if (category == 'dessert') return _FavoriteCategoryType.desserts;
  return _FavoriteCategoryType.mains;
}

String _labelForCategory(_FavoriteCategoryType category) {
  switch (category) {
    case _FavoriteCategoryType.starters:
      return 'Entrees';
    case _FavoriteCategoryType.mains:
      return 'Plats';
    case _FavoriteCategoryType.desserts:
      return 'Desserts';
  }
}
