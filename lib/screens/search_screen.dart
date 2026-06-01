import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../providers/favorites_provider.dart';
import '../services/meal_api_service.dart';
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController(text: 'Chicken');
  final _apiService = MealApiService();

  List<Meal> _results = const [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounceTimer;

  Meal? get _currentMeal {
    if (_results.isEmpty) return null;
    return _results[_currentIndex.clamp(0, _results.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _search();
    _searchController.addListener(_scheduleSearch);
  }

  void _scheduleSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 650), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) _search();
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchMeals(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _goToNextMeal() {
    if (_results.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _results.length;
    });
  }

  void _saveAndNext() {
    final meal = _currentMeal;
    if (meal == null) return;
    context.read<FavoritesProvider>().addFavorite(meal);
    _goToNextMeal();
  }

  void _skipAndNext() {
    final meal = _currentMeal;
    if (meal == null) return;
    context.read<FavoritesProvider>().removeFavorite(meal.id);
    _goToNextMeal();
  }

  void _openDetail() {
    final meal = _currentMeal;
    if (meal == null) return;
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
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_scheduleSearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 18, 9, 88),
          child: Column(
            children: [
              _SearchHeader(onBack: widget.onBack),
              const SizedBox(height: 20),
              _SearchField(
                controller: _searchController,
                onSubmitted: _search,
              ),
              const SizedBox(height: 26),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF062F1A),
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null) {
      return _SearchMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Recherche impossible',
        message: _errorMessage!,
        action: _search,
      );
    }

    final meal = _currentMeal;
    if (meal == null) {
      return _SearchMessage(
        icon: Icons.no_food_rounded,
        title: 'Aucune recette',
        message: 'Essaie une autre recherche.',
        action: _search,
      );
    }

    return _FeaturedMealCard(
      meal: meal,
      currentIndex: _currentIndex,
      total: _results.length,
      onSkip: _skipAndNext,
      onSave: _saveAndNext,
      onOpenDetail: _openDetail,
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
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
            'Recherche',
            style: TextStyle(
              color: Color(0xFF202020),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmitted(),
      cursorColor: const Color(0xFF062F1A),
      decoration: InputDecoration(
        hintText: 'Rechercher',
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFF202020), width: 1.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFF062F1A), width: 2),
        ),
      ),
      style: const TextStyle(
        color: Color(0xFF202020),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _FeaturedMealCard extends StatefulWidget {
  const _FeaturedMealCard({
    required this.meal,
    required this.currentIndex,
    required this.total,
    required this.onSkip,
    required this.onSave,
    required this.onOpenDetail,
  });

  final Meal meal;
  final int currentIndex;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onSave;
  final VoidCallback onOpenDetail;

  @override
  State<_FeaturedMealCard> createState() => _FeaturedMealCardState();
}

class _FeaturedMealCardState extends State<_FeaturedMealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _slideProgress;
  int _slideDirection = 0;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideProgress = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _slideThen(int direction, VoidCallback action) async {
    if (_isSliding) return;

    setState(() {
      _isSliding = true;
      _slideDirection = direction;
    });

    await _slideController.forward(from: 0);
    if (!mounted) return;
    action();
    _slideController.reset();

    if (!mounted) return;
    setState(() {
      _isSliding = false;
      _slideDirection = 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 180) {
      _slideThen(1, widget.onSave);
    } else if (velocity < -180) {
      _slideThen(-1, widget.onSkip);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: _slideProgress,
            builder: (context, child) {
              final progress = _slideProgress.value;
              final direction = _slideDirection.toDouble();
              final dx = direction * progress * constraints.maxWidth * 1.08;
              final angle = direction * progress * 0.08;
              final opacity = 1 - (progress * 0.28);

              return Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.rotate(
                  angle: angle,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onOpenDetail,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.meal.thumbnail ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFEAF5D6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF062F1A),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFEAF5D6),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFF062F1A),
                            size: 46,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _RoundAction(
                    icon: Icons.receipt_long_outlined,
                    onTap: widget.onOpenDetail,
                    size: 52,
                    iconSize: 28,
                    backgroundColor: Colors.white.withOpacity(0.92),
                  ),
                ),
                Positioned(
                  left: 17,
                  right: 17,
                  bottom: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavCluster(
                        leadingIcon: Icons.arrow_back_rounded,
                        trailingIcon: Icons.close_rounded,
                        onLeading: () => _slideThen(-1, widget.onSkip),
                        onTrailing: () => _slideThen(-1, widget.onSkip),
                      ),
                      _NavCluster(
                        leadingIcon: Icons.favorite_rounded,
                        trailingIcon: Icons.arrow_forward_rounded,
                        onLeading: () => _slideThen(1, widget.onSave),
                        onTrailing: () => _slideThen(1, widget.onSave),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 84,
                  child: _MealCaption(
                    meal: widget.meal,
                    currentIndex: widget.currentIndex,
                    total: widget.total,
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

class _MealCaption extends StatelessWidget {
  const _MealCaption({
    required this.meal,
    required this.currentIndex,
    required this.total,
  });

  final Meal meal;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                meal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${currentIndex + 1}/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCluster extends StatelessWidget {
  const _NavCluster({
    required this.leadingIcon,
    required this.trailingIcon,
    required this.onLeading,
    required this.onTrailing,
  });

  final IconData leadingIcon;
  final IconData trailingIcon;
  final VoidCallback onLeading;
  final VoidCallback onTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundAction(
            icon: leadingIcon,
            onTap: onLeading,
            size: 40,
            iconSize: 28,
            backgroundColor: Colors.transparent,
          ),
          _RoundAction(
            icon: trailingIcon,
            onTap: onTrailing,
            size: 40,
            iconSize: 28,
            backgroundColor: const Color(0xFF062F1A),
            foregroundColor: const Color(0xFFDDF577),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
    required this.backgroundColor,
    this.foregroundColor = const Color(0xFF062F1A),
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foregroundColor, size: iconSize),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: const Color(0xFF062F1A)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6F6F6F)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: action,
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}
