import 'package:flutter/material.dart';
import '../services/meal_api_service.dart';
import '../models/meal.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

const Map<String, String> areaToRegion = {
  'American': 'Ameriques',
  'British': 'Europe',
  'Canadian': 'Ameriques',
  'Chinese': 'Asie',
  'Croatian': 'Europe',
  'Dutch': 'Europe',
  'Egyptian': 'Afrique',
  'Filipino': 'Asie',
  'French': 'Europe',
  'Greek': 'Europe',
  'Indian': 'Asie',
  'Irish': 'Europe',
  'Italian': 'Europe',
  'Jamaican': 'Ameriques',
  'Japanese': 'Asie',
  'Kenyan': 'Afrique',
  'Malaysian': 'Asie',
  'Mexican': 'Ameriques',
  'Moroccan': 'Afrique',
  'Polish': 'Europe',
  'Portuguese': 'Europe',
  'Russian': 'Europe',
  'Spanish': 'Europe',
  'Thai': 'Asie',
  'Tunisian': 'Afrique',
  'Turkish': 'Moyen-Orient',
  'Ukrainian': 'Europe',
  'Vietnamese': 'Asie',
};

const Map<String, IconData> regionIcons = {
  'Ameriques': Icons.public,
  'Europe': Icons.castle,
  'Asie': Icons.temple_buddhist,
  'Afrique': Icons.wb_sunny,
  'Moyen-Orient': Icons.mosque,
};

const Map<String, Color> regionColors = {
  'Ameriques': Color(0xFF2196F3),
  'Europe': Color(0xFF9C27B0),
  'Asie': Color(0xFFFF5722),
  'Afrique': Color(0xFFFF9800),
  'Moyen-Orient': Color(0xFF4CAF7D),
};

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MealApiService _apiService = MealApiService();

  List<String> _allAreas = [];
  String? _selectedRegion;
  String? _selectedArea;
  List<Meal> _meals = [];
  bool _loadingAreas = true;
  bool _loadingMeals = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await _apiService.getAllAreas();
      setState(() {
        _allAreas = areas;
        _loadingAreas = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingAreas = false;
      });
    }
  }

  Future<void> _loadMealsByArea(String area) async {
    setState(() {
      _selectedArea = area;
      _loadingMeals = true;
      _meals = [];
    });
    try {
      final meals = await _apiService.getMealsByArea(area);
      setState(() {
        _meals = meals;
        _loadingMeals = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingMeals = false;
      });
    }
  }


  List<String> get _filteredAreas {
    if (_selectedRegion == null) return _allAreas;
    return _allAreas
        .where((a) => (areaToRegion[a] ?? 'Autre') == _selectedRegion)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.explore_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Explorer',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cuisines du monde entier',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Filtre par grande région
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _regionChip(null, 'Tout'),
                        ...regionColors.keys.map((r) => _regionChip(r, r)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_loadingAreas)
              const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF7D))),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              )
            else
              Expanded(
                child: _selectedArea == null
                    ? _buildAreaGrid()
                    : _buildMealsList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _regionChip(String? region, String label) {
    final isSelected = _selectedRegion == region;
    final color =
        region != null ? regionColors[region]! : const Color(0xFF4CAF7D);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRegion = region;
        _selectedArea = null;
        _meals = [];
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaGrid() {
    final areas = _filteredAreas;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        final region = areaToRegion[area] ?? 'Autre';
        final color = regionColors[region] ?? const Color(0xFF4CAF7D);
        final icon = regionIcons[region] ?? Icons.restaurant;
        return GestureDetector(
          onTap: () => _loadMealsByArea(area),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon,
                      color: Colors.white.withValues(alpha: 0.8), size: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      Text(
                        region,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealsList() {
    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedArea = null;
                  _meals = [];
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: Color(0xFF2E7D52)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cuisine $_selectedArea',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A2A),
                ),
              ),
            ],
          ),
        ),
        if (_loadingMeals)
          const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF7D))),
          )
        else if (_meals.isEmpty)
          const Expanded(
            child: Center(child: Text('Aucun plat trouve pour cette region.')),
          )
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Text(
                    '${_meals.length} plat${_meals.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF7D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _meals.length,
                    itemBuilder: (context, index) {
                      final meal = _meals[index];
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
            ),
          ),
      ],
    );
  }
}
