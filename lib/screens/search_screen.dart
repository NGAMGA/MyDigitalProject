import 'package:flutter/material.dart';
import '../services/meal_api_service.dart';
import '../models/meal.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MealApiService _apiService = MealApiService();

  List<Meal> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await _apiService.searchMeals(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Meal Explorer',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _search(),
                          style: const TextStyle(color: Color(0xFF1A3A2A), fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Pasta, Chicken, Sushi...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF7D), size: 22),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D52),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Go',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF7D)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF757575), fontSize: 15),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _search,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF7D),
                  side: const BorderSide(color: Color(0xFF4CAF7D)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
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
              child: const Icon(Icons.search, size: 48, color: Color(0xFF4CAF7D)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recherchez une recette',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pasta, Chicken, Sushi...',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_food, size: 56, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            Text(
              'Aucune recette trouvee\npour "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF757575), fontSize: 15),
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
            '${_results.length} recette${_results.length > 1 ? 's' : ''} trouvee${_results.length > 1 ? 's' : ''}',
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
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final meal = _results[index];
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
  }
}