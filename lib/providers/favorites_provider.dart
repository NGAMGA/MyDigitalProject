import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'komi_favorite_meals';

  final List<Meal> _favorites = [];
  bool _loaded = false;

  List<Meal> get favorites => List.unmodifiable(_favorites);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final storedFavorites = prefs.getStringList(_storageKey) ?? const [];

    _favorites
      ..clear()
      ..addAll(
        storedFavorites
            .map((item) {
              try {
                final json = jsonDecode(item) as Map<String, dynamic>;
                return Meal.fromStoredJson(json);
              } catch (_) {
                return null;
              }
            })
            .whereType<Meal>()
            .where((meal) => meal.id.isNotEmpty),
      );

    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String mealId) {
    return _favorites.any((meal) => meal.id == mealId);
  }

  void addFavorite(Meal meal) {
    if (!isFavorite(meal.id)) {
      _favorites.add(meal);
      notifyListeners();
      unawaited(_saveFavorites());
    }
  }

  void removeFavorite(String mealId) {
    _favorites.removeWhere((meal) => meal.id == mealId);
    notifyListeners();
    unawaited(_saveFavorites());
  }

  void toggleFavorite(Meal meal) {
    if (isFavorite(meal.id)) {
      removeFavorite(meal.id);
    } else {
      addFavorite(meal);
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedFavorites = _favorites
        .map((meal) => jsonEncode(meal.toStoredJson()))
        .toList(growable: false);

    await prefs.setStringList(_storageKey, encodedFavorites);
  }
}
