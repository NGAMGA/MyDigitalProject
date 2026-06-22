import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_session_store.dart';
import '../models/meal.dart';

class MenuCartException implements Exception {
  const MenuCartException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MenuCartItem {
  const MenuCartItem({
    required this.id,
    required this.mealId,
    required this.mealName,
    required this.mealThumb,
  });

  factory MenuCartItem.fromJson(Map<String, dynamic> json) {
    return MenuCartItem(
      id: json['id'] as int? ?? 0,
      mealId: json['meal_id']?.toString() ?? '',
      mealName: json['meal_name']?.toString() ?? 'Recette',
      mealThumb: json['meal_thumb']?.toString() ?? '',
    );
  }

  final int id;
  final String mealId;
  final String mealName;
  final String mealThumb;
}

class GeneratedIngredient {
  const GeneratedIngredient({
    required this.name,
    required this.measure,
  });

  factory GeneratedIngredient.fromJson(Map<String, dynamic> json) {
    return GeneratedIngredient(
      name: json['ingredient']?.toString() ?? '',
      measure: json['measure']?.toString() ?? '',
    );
  }

  final String name;
  final String measure;
}

class GeneratedShoppingList {
  const GeneratedShoppingList({
    required this.ingredients,
    required this.recipeCount,
  });

  final List<GeneratedIngredient> ingredients;
  final int recipeCount;
}

class MenuCartService {
  MenuCartService({
    http.Client? httpClient,
    AuthSessionStore? sessionStore,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _sessionStore = sessionStore ?? const AuthSessionStore(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'KOMI_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final http.Client _httpClient;
  final AuthSessionStore _sessionStore;
  final String baseUrl;

  Future<List<MenuCartItem>> getCart() async {
    final response = await _request('GET', '/menus/cart');
    return (response['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MenuCartItem.fromJson)
        .toList();
  }

  Future<MenuCartItem> addMeal(Meal meal) async {
    final query = <String, String>{
      'meal_id': meal.id,
      'meal_name': meal.name,
      if ((meal.thumbnail ?? '').isNotEmpty) 'meal_thumb': meal.thumbnail!,
    };
    final response = await _request(
      'POST',
      '/menus/cart/add',
      queryParameters: query,
    );
    return MenuCartItem.fromJson(
      response['item'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> removeMeal(String mealId) async {
    await _request('DELETE', '/menus/cart/$mealId');
  }

  Future<GeneratedShoppingList> generateShoppingList() async {
    final response = await _request('POST', '/menus/cart/generate-list');
    final ingredients =
        (response['shopping_list'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GeneratedIngredient.fromJson)
            .where((ingredient) => ingredient.name.isNotEmpty)
            .toList();
    final recipes = response['recipes'] as List<dynamic>? ?? const [];
    return GeneratedShoppingList(
      ingredients: ingredients,
      recipeCount: recipes.length,
    );
  }

  Future<List<String>> getNutritionTips(List<String> ingredients) async {
    if (ingredients.isEmpty) return const [];
    final response = await _request(
      'GET',
      '/menus/nutrition-tips',
      queryParameters: {'ingredients': ingredients},
    );
    return (response['tips'] as List<dynamic>? ?? const [])
        .map((tip) => tip.toString())
        .where((tip) => tip.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const MenuCartException('Session expiree.');
    }
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final headers = {'Authorization': 'Bearer $token'};
    try {
      late http.Response response;
      switch (method) {
        case 'POST':
          response = await _httpClient.post(uri, headers: headers);
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
          break;
        default:
          response = await _httpClient.get(uri, headers: headers);
      }
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));
      final data =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MenuCartException(
          data['detail']?.toString() ??
              'Impossible de mettre a jour le panier.',
        );
      }
      return data;
    } on MenuCartException {
      rethrow;
    } catch (_) {
      throw const MenuCartException('Impossible de joindre le serveur Komi.');
    }
  }
}
