import 'package:flutter/foundation.dart';
import '../models/meal.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Meal> _favorites = [];

  List<Meal> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String mealId) {
    return _favorites.any((meal) => meal.id == mealId);
  }

  void addFavorite(Meal meal) {
    if (!isFavorite(meal.id)) {
      _favorites.add(meal);
      notifyListeners();
    }
  }

  void removeFavorite(String mealId) {
    _favorites.removeWhere((meal) => meal.id == mealId);
    notifyListeners();
  }

  void toggleFavorite(Meal meal) {
    if (isFavorite(meal.id)) {
      removeFavorite(meal.id);
    } else {
      addFavorite(meal);
    }
  }
}
