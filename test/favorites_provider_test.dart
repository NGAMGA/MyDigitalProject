import 'package:flutter_test/flutter_test.dart';
import 'package:my_digital_project/models/meal.dart';
import 'package:my_digital_project/providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('favorites are persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final meal = Meal(id: '42', name: 'Test meal');
    final provider = FavoritesProvider();
    await provider.load();

    provider.addFavorite(meal);
    await Future<void>.delayed(Duration.zero);

    final restored = FavoritesProvider();
    await restored.load();
    expect(restored.isFavorite('42'), isTrue);

    restored.removeFavorite('42');
    await Future<void>.delayed(Duration.zero);

    final empty = FavoritesProvider();
    await empty.load();
    expect(empty.favorites, isEmpty);
  });
}
