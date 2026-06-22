import 'package:dio/dio.dart';
import '../models/meal.dart';

const List<String> validAreas = [
  'American',
  'British',
  'Canadian',
  'Chinese',
  'Croatian',
  'Dutch',
  'Egyptian',
  'Filipino',
  'French',
  'Greek',
  'Indian',
  'Irish',
  'Italian',
  'Jamaican',
  'Japanese',
  'Kenyan',
  'Malaysian',
  'Mexican',
  'Moroccan',
  'Polish',
  'Portuguese',
  'Russian',
  'Spanish',
  'Thai',
  'Tunisian',
  'Turkish',
  'Ukrainian',
  'Vietnamese',
];

class MealApiService {
  late final Dio _dio;

  MealApiService() {
    const baseUrl = String.fromEnvironment(
      'MEAL_API_BASE',
      defaultValue: 'https://www.themealdb.com/api/json/v1/1',
    );
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<List<Meal>> searchMeals(String query) async {
    try {
      final response =
          await _dio.get('/search.php', queryParameters: {'s': query});
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List)
          .map((j) => Meal.fromSearchJson(j))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Meal>> discoverMeals() async {
    const discoveryAreas = [
      'French',
      'Italian',
      'Japanese',
      'Mexican',
      'Moroccan',
      'Indian',
    ];

    final results = await Future.wait(
      discoveryAreas.map(getMealsByArea),
    );

    final uniqueMeals = <String, Meal>{};
    var row = 0;
    while (uniqueMeals.length < 18) {
      var addedAtThisRow = false;
      for (final meals in results) {
        if (row >= meals.length) continue;
        addedAtThisRow = true;
        uniqueMeals.putIfAbsent(meals[row].id, () => meals[row]);
      }
      if (!addedAtThisRow) break;
      row++;
    }

    return uniqueMeals.values.toList();
  }

  Future<List<Meal>> getMealsByIngredients(List<String> ingredients) async {
    final normalizedIngredients = ingredients
        .map(_ingredientForApi)
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet()
        .take(5)
        .toList();

    if (normalizedIngredients.isEmpty) return [];

    final results = await Future.wait(
      normalizedIngredients.map(_getMealsByIngredient),
    );

    final uniqueMeals = <String, Meal>{};
    var row = 0;
    while (uniqueMeals.length < 12) {
      var addedAtThisRow = false;
      for (final meals in results) {
        if (row >= meals.length) continue;
        addedAtThisRow = true;
        uniqueMeals.putIfAbsent(meals[row].id, () => meals[row]);
      }
      if (!addedAtThisRow) break;
      row++;
    }

    return uniqueMeals.values.toList();
  }

  Future<List<Meal>> _getMealsByIngredient(String ingredient) async {
    try {
      final response = await _dio.get(
        '/filter.php',
        queryParameters: {'i': ingredient},
      );
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List)
          .map((json) => Meal.fromSearchJson(json))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Meal?> getMealDetail(String id) async {
    try {
      final response =
          await _dio.get('/lookup.php', queryParameters: {'i': id});
      final data = response.data;
      if (data['meals'] == null || (data['meals'] as List).isEmpty) return null;
      return Meal.fromDetailJson(data['meals'][0]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Meal>> getMealsByArea(String area) async {
    try {
      final response =
          await _dio.get('/filter.php', queryParameters: {'a': area});
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List)
          .map((j) => Meal.fromSearchJson(j))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getAllAreas() async {
    return validAreas;
  }

  String _ingredientForApi(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâäãå]'), 'a')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôöõ]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const aliases = <String, String>{
      'petit poids': 'peas',
      'petits poids': 'peas',
      'petit pois': 'peas',
      'petits pois': 'peas',
      'pates semi completes': 'pasta',
      'pates completes': 'pasta',
      'pates': 'pasta',
      'pate': 'pasta',
      'riz basmati': 'rice',
      'riz': 'rice',
      'poulet': 'chicken',
      'filets de poulet': 'chicken',
      'boeuf': 'beef',
      'porc': 'pork',
      'saumon': 'salmon',
      'thon': 'tuna',
      'poisson': 'fish',
      'tomates': 'tomato',
      'tomate': 'tomato',
      'pommes de terre': 'potato',
      'pomme de terre': 'potato',
      'oignons': 'onion',
      'oignon': 'onion',
      'oeufs': 'egg',
      'oeuf': 'egg',
      'fromage': 'cheese',
      'champignons': 'mushroom',
      'champignon': 'mushroom',
      'carottes': 'carrot',
      'carotte': 'carrot',
      'salade': 'lettuce',
      'avocat': 'avocado',
      'courgette': 'zucchini',
      'aubergine': 'eggplant',
      'poivron': 'pepper',
      'ail': 'garlic',
      'lait': 'milk',
      'beurre': 'butter',
      'creme': 'cream',
      'farine': 'flour',
      'pain complet': 'bread',
      'pain': 'bread',
    };

    if (aliases.containsKey(normalized)) return aliases[normalized]!;

    for (final entry in aliases.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    return normalized;
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Delai de connexion depasse. Verifiez votre reseau.';
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter. Verifiez votre reseau.';
      default:
        return 'Une erreur est survenue. Veuillez reessayer.';
    }
  }
}
