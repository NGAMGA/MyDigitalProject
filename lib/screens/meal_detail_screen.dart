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

  // Traduction
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


  String _complexityScore(int ingredientCount) {
    if (ingredientCount <= 5) return ' Facile';
    if (ingredientCount <= 10) return 'Moyen';
    if (ingredientCount <= 15) return 'Elabore';
    return 'Complexe';
  }

  double _complexityValue(int ingredientCount) {
    if (ingredientCount <= 5) return 2.5;
    if (ingredientCount <= 10) return 3.5;
    if (ingredientCount <= 15) return 4.2;
    return 5.0;
  }

  String _buildDescription(Meal meal) {
    final parts = <String>[];
    if (meal.area != null) parts.add('Originaire de la cuisine ${meal.area}');
    if (meal.category != null) parts.add('categorie ${meal.category}');
    if (meal.tags != null && meal.tags!.isNotEmpty) {
      final tags = meal.tags!.split(',').take(3).join(', ');
      parts.add('tags : $tags');
    }
    if (parts.isEmpty) return 'Un delicieux plat avec ${meal.ingredients.length} ingredients.';
    return '${parts.join(', ')}. Ce plat necessite ${meal.ingredients.length} ingredients.';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              const Text(
                'Traduire les instructions',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A2A),
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
                          ? const Color(0xFF4CAF7D)
                          : const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.language,
                      color: isSelected ? Colors.white : const Color(0xFF4CAF7D),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF1A3A2A),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF4CAF7D))
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4FAF6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF7D))),
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
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center,
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
    final complexity = _complexityValue(meal.ingredients.length);
    final complexityLabel = _complexityScore(meal.ingredients.length);
    final description = _buildDescription(meal);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: CustomScrollView(
        slivers: [
          // AppBar avec image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF4CAF7D),
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
                        colors: [Colors.transparent, Colors.black54],
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

                  // Tags region + categorie
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


                  _sectionTitle('Description'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF7D).withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),


                  _sectionTitle('Note de complexite'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF7D).withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Etoiles
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
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complexityLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D52),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Chiffre
                        Column(
                          children: [
                            Text(
                              complexity.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A2A),
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const Text(
                              '/ 5.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),


                  _sectionTitle('Ingredients'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF7D).withOpacity(0.08),
                          blurRadius: 8,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF7D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  meal.measures[i].isNotEmpty
                                      ? '${meal.measures[i]} - ${meal.ingredients[i]}'
                                      : meal.ingredients[i],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),


                  if (meal.instructions != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Instructions'),
                        GestureDetector(
                          onTap: _showLanguagePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF7D),
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
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF7D).withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isTranslating
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                  color: Color(0xFF4CAF7D)),
                              SizedBox(height: 12),
                              Text(
                                'Traduction en cours...',
                                style: TextStyle(
                                    color: Color(0xFF4CAF7D),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                          : _translationError != null
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translationError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meal.instructions!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3D3D3D),
                              height: 1.7,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        _displayedInstructions,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3D3D3D),
                          height: 1.7,
                        ),
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4CAF7D)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2E7D52),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3A2A),
      ),
    );
  }
}
