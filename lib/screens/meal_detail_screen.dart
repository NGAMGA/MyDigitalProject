import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../services/meal_api_service.dart';
import '../services/translation_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_session_provider.dart';
import '../services/menu_cart_service.dart';
import 'menu_cart_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;
  final String mealName;

  const MealDetailScreen({
    super.key,
    required this.mealId,
    required this.mealName,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final MealApiService _apiService = MealApiService();
  final TranslationService _translationService = TranslationService();

  Meal? _meal;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedLang = 'en';
  String? _translatedInstructions;
  bool _isTranslating = false;
  bool _isAddingToCart = false;
  bool _isLoadingNutritionTips = false;
  List<String> _nutritionTips = const [];
  String? _nutritionTipsError;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final meal = await _apiService.getMealDetail(widget.mealId);
      setState(() {
        _meal = meal;
        _isLoading = false;
      });
      if (meal != null) {
        await _loadNutritionTips(meal);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNutritionTips(Meal meal) async {
    final plan = context.read<UserSessionProvider>().user?.subscription.plan;
    if (plan?.toLowerCase() != 'premium') return;
    setState(() {
      _isLoadingNutritionTips = true;
      _nutritionTipsError = null;
    });
    try {
      final tips = await MenuCartService().getNutritionTips(meal.ingredients);
      if (!mounted) return;
      setState(() => _nutritionTips = tips);
    } on MenuCartException catch (error) {
      if (!mounted) return;
      setState(() => _nutritionTipsError = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingNutritionTips = false);
    }
  }

  String _buildDescription(Meal meal) {
    final parts = <String>[];
    if (meal.area != null) parts.add('Originaire de la cuisine ${meal.area}');
    if (meal.category != null) parts.add('catégorie ${meal.category}');
    if (meal.tags != null && meal.tags!.isNotEmpty) {
      final tags =
          meal.tags!.split(',').take(3).map((t) => t.trim()).join(', ');
      parts.add('tags : $tags');
    }
    if (parts.isEmpty) {
      return 'Un délicieux plat composé de ${meal.ingredients.length} ingrédients.';
    }
    return '${parts.join(', ')}. Ce plat nécessite ${meal.ingredients.length} ingrédients.';
  }

  double _complexityValue(int count) {
    if (count <= 5) return 2.0;
    if (count <= 8) return 3.0;
    if (count <= 12) return 3.5;
    if (count <= 16) return 4.0;
    return 5.0;
  }

  String _complexityLabel(int count) {
    if (count <= 5) return 'Facile';
    if (count <= 8) return 'Moyen';
    if (count <= 12) return 'Élaboré';
    if (count <= 16) return 'Avancé';
    return 'Complexe';
  }

  Future<void> _translate(String targetLang) async {
    if (_meal?.instructions == null) return;
    if (targetLang == _selectedLang) return;

    setState(() {
      _isTranslating = true;
      _translationError = null;
      _selectedLang = targetLang;
    });

    if (targetLang == 'en') {
      setState(() {
        _translatedInstructions = _meal!.instructions;
        _isTranslating = false;
      });
      return;
    }

    try {
      final translated = await _translationService.translate(
        _meal!.instructions!,
        targetLang,
      );
      setState(() {
        _translatedInstructions = translated;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _translationError = e.toString();
        _isTranslating = false;
      });
    }
  }

  void _showLanguagePicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Langue des instructions',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...TranslationService.supportedLanguages.entries.map((entry) {
                final isSelected = _selectedLang == entry.key;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _translate(entry.key);
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.language,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String get _displayedInstructions {
    if (_translatedInstructions != null) return _translatedInstructions!;
    return _meal?.instructions ?? '';
  }

  String get _currentLangLabel {
    return TranslationService.supportedLanguages[_selectedLang] ?? 'EN';
  }

  Future<void> _addToCart() async {
    final meal = _meal;
    if (meal == null || _isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      await MenuCartService().addMeal(meal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} ajoute au panier.')),
      );
    } on MenuCartException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  List<String> get _instructionSteps {
    return _stepsFromText(_displayedInstructions);
  }

  List<String> _stepsFromText(String text) {
    final normalized =
        text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return [];

    final stepMatches = RegExp(
      r'(?:^|\n)\s*(?:STEP|ETAPE|ÉTAPE)\s*\d+\s*[:.-]?\s*(.*?)(?=(?:\n\s*(?:STEP|ETAPE|ÉTAPE)\s*\d+\s*[:.-]?)|$)',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(normalized);
    final structuredSteps = stepMatches
        .map((match) => match.group(1)?.trim() ?? '')
        .where((step) => step.isNotEmpty)
        .toList();
    if (structuredSteps.isNotEmpty) return structuredSteps;

    final byLine = normalized
        .split('\n')
        .map((step) => step.trim())
        .where((step) =>
            step.isNotEmpty &&
            !RegExp(r'^(?:STEP|ETAPE|ÉTAPE)\s*\d+', caseSensitive: false)
                .hasMatch(step))
        .toList();
    if (byLine.length > 1) return byLine;

    return normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((step) => step.trim())
        .where((step) =>
            step.length > 3 &&
            !RegExp(r'^(?:STEP|ETAPE|ÉTAPE)\s*\d+$', caseSensitive: false)
                .hasMatch(step))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (_errorMessage != null) return _buildError();
    if (_meal == null) return _buildNotFound();
    return _buildDetail();
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealName),
        backgroundColor: const Color(0xFF4CAF7D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF757575))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadDetail,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF7D)),
                child: const Text('Reessayer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mealName)),
      body: const Center(child: Text('Recette introuvable.')),
    );
  }

  Widget _buildDetail() {
    final meal = _meal!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final complexity = _complexityValue(meal.ingredients.length);
    final complexityLabel = _complexityLabel(meal.ingredients.length);
    final description = _buildDescription(meal);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Voir le panier',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MenuCartScreen(),
                  ),
                ),
                icon: const Icon(Icons.shopping_basket_outlined),
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
                        color: isFav ? Colors.redAccent : Colors.white,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                end: 56,
                bottom: 14,
              ),
              title: Text(
                meal.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  meal.thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: meal.thumbnail!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) {
                            return Container(color: const Color(0xFFE8F5EE));
                          },
                          errorWidget: (context, url, error) {
                            return Container(color: const Color(0xFFE8F5EE));
                          },
                        )
                      : Container(color: const Color(0xFFE8F5EE)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black12,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (meal.area != null) _tag(Icons.public, meal.area!),
                      if (meal.category != null)
                        _tag(Icons.category_outlined, meal.category!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isAddingToCart ? null : _addToCart,
                    icon: _isAddingToCart
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      _isAddingToCart
                          ? 'Ajout en cours...'
                          : 'Ajouter au panier de recettes',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: _softCardDecoration(theme, colorScheme),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _softCardDecoration(theme, colorScheme),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < complexity.floor()
                                      ? Icons.star_rounded
                                      : (i < complexity
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded),
                                  color: const Color(0xFFFFB800),
                                  size: 26,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complexityLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              complexity.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            Text(
                              '/ 5.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _softCardDecoration(theme, colorScheme),
                    child: Column(
                      children: List.generate(meal.ingredients.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  meal.measures[i].isNotEmpty
                                      ? '${meal.measures[i]} - ${meal.ingredients[i]}'
                                      : meal.ingredients[i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildNutritionSection(theme, colorScheme, meal),
                  const SizedBox(height: 24),
                  if (meal.instructions != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _showLanguagePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.translate,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  _currentLangLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionsCard(theme, colorScheme, meal),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(
    ThemeData theme,
    ColorScheme colorScheme,
    Meal meal,
  ) {
    final isPremium = context
            .watch<UserSessionProvider>()
            .user
            ?.subscription
            .plan
            .toLowerCase() ==
        'premium';
    if (!isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _softCardDecoration(theme, colorScheme),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF9800)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Les conseils nutritionnels personnalises par recette '
                'sont disponibles avec Premium.',
              ),
            ),
          ],
        ),
      );
    }
    if (_isLoadingNutritionTips) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _softCardDecoration(theme, colorScheme),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Analyse nutritionnelle...'),
          ],
        ),
      );
    }
    if (_nutritionTipsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _softCardDecoration(theme, colorScheme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_nutritionTipsError!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadNutritionTips(meal),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(theme, colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: Color(0xFF2E7D52)),
              SizedBox(width: 8),
              Text(
                'Conseils nutritionnels Premium',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._nutritionTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('â€¢ '),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Meal meal,
  ) {
    if (_isTranslating) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _softCardDecoration(theme, colorScheme),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Traduction en cours...',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = _translationError != null
        ? _stepsFromText(meal.instructions!)
        : _instructionSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_translationError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _translationError!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...List.generate(steps.length, (index) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _softCardDecoration(theme, colorScheme),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  BoxDecoration _softCardDecoration(ThemeData theme, ColorScheme colorScheme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
