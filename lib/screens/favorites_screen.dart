import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  static const _categories = [
    _FavoriteCategory(
      title: 'Produits',
      count: '23 favoris',
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=80',
      alignment: Alignment.bottomCenter,
    ),
    _FavoriteCategory(
      title: 'Entrees',
      count: '23 favoris',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
      alignment: Alignment.bottomCenter,
    ),
    _FavoriteCategory(
      title: 'Plats',
      count: '23 favoris',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
      alignment: Alignment.bottomCenter,
    ),
    _FavoriteCategory(
      title: 'Desserts',
      count: '23 favoris',
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
      alignment: Alignment.bottomCenter,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FavoritesHeader(onBack: onBack),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 104),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _FavoriteCategoryCard(category: _categories[index]);
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
  const _FavoritesHeader({required this.onBack});

  final VoidCallback? onBack;

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
            const Text(
              'Favoris',
              style: TextStyle(
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

class _FavoriteCategory {
  const _FavoriteCategory({
    required this.title,
    required this.count,
    required this.imageUrl,
    required this.alignment,
  });

  final String title;
  final String count;
  final String imageUrl;
  final Alignment alignment;
}

class _FavoriteCategoryCard extends StatelessWidget {
  const _FavoriteCategoryCard({required this.category});

  final _FavoriteCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 146,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -8,
            right: -8,
            bottom: -26,
            height: 88,
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
          Positioned(
            right: 32,
            top: 16,
            child: Text(
              category.count,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                category.title,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
