import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../services/meal_api_service.dart';
import '../services/translation_service.dart';
import '../providers/favorites_provider.dart';

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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _translate(String targetLang) async {
    if (_meal?.instructions == null) return;
    if (targetLang == _selectedLang) return;

    setState(() {
      _isTranslating = true;
      _translationError = null;
      _selectedLang = targetLang;
    });

    // Si on revient à l'anglais (langue source), pas besoin de traduire
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
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
                  // Dégradé bas
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
                  // Tags région + catégorie
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (meal.area != null) _tag(Icons.public, meal.area!),
                      if (meal.category != null)
                        _tag(Icons.category_outlined, meal.category!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingrédients
                  _sectionTitle('Ingredients'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 28),

                  // Instructions avec bouton traduction
                  if (meal.instructions != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Instructions'),
                        // Bouton traduction
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

                    // Contenu instructions
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
      border:
          Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }
}
