import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_models.dart';
import '../../features/auth/data/auth_session_store.dart';
import '../../models/meal.dart';
import '../../models/shopping_product.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../screens/meal_detail_screen.dart';
import '../../services/meal_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenRecipes,
    required this.onOpenScan,
  });

  final VoidCallback onOpenRecipes;
  final VoidCallback onOpenScan;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sessionStore = const AuthSessionStore();
  final _mealApi = MealApiService();

  KomiUser? _user;
  List<Meal> _suggestions = const [];
  bool _loadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final user = await _sessionStore.readUser();
    var suggestions = <Meal>[];

    try {
      suggestions = await _mealApi.searchMeals('chicken');
    } catch (_) {
      suggestions = <Meal>[];
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _suggestions = suggestions.take(6).toList();
      _loadingSuggestions = false;
    });
  }

  String get _displayName {
    final name = _user?.name.trim();
    if (name == null || name.isEmpty) return 'Mathis';
    return name.split(RegExp(r'\s+')).first;
  }

  String get _initial {
    final name = _displayName.trim();
    if (name.isEmpty) return 'M';
    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingList = context.watch<ShoppingListProvider>();
    final summary = shoppingList.summary;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          const bottomReserve = 74.0;
          final topPadding = (height * 0.026).clamp(16.0, 24.0);
          final usableHeight = height - topPadding - bottomReserve;
          final scale = (usableHeight / 640).clamp(0.92, 1.12);
          final sectionGap = 14.0 * scale;
          final smallGap = 8.0 * scale;
          final headerHeight = 47.0 * scale;
          final scoreHeight = 135.0 * scale;
          final titleHeight = 24.0 * scale;
          final scanTileHeight = 63.0 * scale;
          final metricHeight = 57.0 * scale;

          final usedHeight = headerHeight +
              sectionGap +
              scoreHeight +
              sectionGap +
              titleHeight +
              smallGap +
              scanTileHeight +
              smallGap +
              metricHeight +
              sectionGap +
              titleHeight +
              smallGap;
          final recipeHeight = (usableHeight - usedHeight).clamp(
            170.0 * scale,
            270.0 * scale,
          );

          return RefreshIndicator(
            color: const Color(0xFF062F1A),
            onRefresh: _loadHomeData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(10, topPadding, 10, bottomReserve),
              children: [
                SizedBox(
                  height: headerHeight,
                  child: _Header(
                    name: _displayName,
                    initial: _initial,
                    scale: scale,
                  ),
                ),
                SizedBox(height: sectionGap),
                _ShoppingScoreCard(height: scoreHeight, summary: summary),
                SizedBox(height: sectionGap),
                SizedBox(
                  height: titleHeight,
                  child: _SectionTitle(
                    title: 'Liste actuelle',
                    actionLabel: 'Importer',
                    onAction: widget.onOpenScan,
                  ),
                ),
                SizedBox(height: smallGap),
                _LastScanCard(
                  scanTileHeight: scanTileHeight,
                  metricHeight: metricHeight,
                  gap: smallGap,
                  listName: shoppingList.currentListName,
                  productCount: shoppingList.productCount,
                  summary: summary,
                ),
                SizedBox(height: sectionGap),
                SizedBox(
                  height: titleHeight,
                  child: _SectionTitle(
                    title: 'Suggestions de recettes',
                    actionLabel: 'Voir tout',
                    onAction: widget.onOpenRecipes,
                  ),
                ),
                SizedBox(height: smallGap),
                _RecipeSuggestions(
                  meals: _suggestions,
                  isLoading: _loadingSuggestions,
                  height: recipeHeight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initial,
    required this.scale,
  });

  final String name;
  final String initial;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/komi-logo-long.svg',
                width: 58 * scale,
                height: 22 * scale,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
              Text(
                'Bonjour $name !',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 20 * scale,
                  height: 1.02,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 17 * scale,
          backgroundColor: const Color(0xFF222222),
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingScoreCard extends StatelessWidget {
  const _ShoppingScoreCard({
    required this.height,
    required this.summary,
  });

  final double height;
  final ShoppingNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9EEB66),
            Color(0xFF6EDD56),
            Color(0xFF9AF46E),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A062F1A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Bilan des courses',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  summary.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.score}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 47,
                  height: 0.92,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Row(
            children: [
              _MacroBar(label: 'Proteines'),
              SizedBox(width: 10),
              _MacroBar(label: 'Fibres'),
              SizedBox(width: 10),
              _MacroBar(label: 'Lipides'),
              SizedBox(width: 10),
              _MacroBar(label: 'Sucres'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF242424),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFF062F1A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LastScanCard extends StatelessWidget {
  const _LastScanCard({
    required this.scanTileHeight,
    required this.metricHeight,
    required this.gap,
    required this.listName,
    required this.productCount,
    required this.summary,
  });

  final double scanTileHeight;
  final double metricHeight;
  final double gap;
  final String listName;
  final int productCount;
  final ShoppingNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: scanTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              const _ScanIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF151515),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$productCount produit${productCount > 1 ? 's' : ''} analyses',
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            _MetricTile(
              value: _formatGrams(summary.proteins),
              label: 'Proteines',
              height: metricHeight,
            ),
            const SizedBox(width: 15),
            _MetricTile(
              value: _formatGrams(summary.fibers),
              label: 'Fibres',
              height: metricHeight,
            ),
            const SizedBox(width: 15),
            _MetricTile(
              value: _formatGrams(summary.fat),
              label: 'Lipides',
              height: metricHeight,
            ),
            const SizedBox(width: 15),
            _MetricTile(
              value: _formatGrams(summary.sugars),
              label: 'Sucres',
              height: metricHeight,
            ),
          ],
        ),
      ],
    );
  }

  String _formatGrams(double value) {
    return '${value.round()}g';
  }
}

class _ScanIcon extends StatelessWidget {
  const _ScanIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF577),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Icon(
        Icons.document_scanner_outlined,
        color: Color(0xFF062F1A),
        size: 19,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.height,
  });

  final String value;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF303030),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSuggestions extends StatelessWidget {
  const _RecipeSuggestions({
    required this.meals,
    required this.isLoading,
    required this.height,
  });

  final List<Meal> meals;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF062F1A),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (meals.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Aucune suggestion disponible'),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _RecipeCard(meal: meals[index], height: height);
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.meal, required this.height});

  final Meal meal;
  final double height;

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
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final isFavorite = favorites.isFavorite(meal.id);
        return GestureDetector(
          onTap: () => _openDetail(context),
          child: SizedBox(
            width: ((height - 28) * 1.04).clamp(142.0, 218.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: meal.thumbnail ?? '',
                        width: ((height - 28) * 1.04).clamp(142.0, 218.0),
                        height: (height - 34).clamp(130.0, 228.0),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFEAF5D6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF062F1A),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFEAF5D6),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFF062F1A),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: InkWell(
                        onTap: () => favorites.toggleFavorite(meal),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.42),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 12.5,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
