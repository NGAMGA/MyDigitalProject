import 'package:flutter/foundation.dart';

import '../models/shopping_product.dart';

class ShoppingListProvider extends ChangeNotifier {
  final List<ShoppingProduct> _products = [
    const ShoppingProduct(
      id: '3017620422003',
      name: 'Pain complet',
      brand: 'Komi Market',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=300&q=80',
      energyKcal: 247,
      proteins: 9.2,
      fibers: 6.8,
      fat: 3.3,
      sugars: 4.1,
      salt: 1.1,
      nutriScore: 'A',
    ),
    const ShoppingProduct(
      id: '3274080005003',
      name: 'Yaourt nature',
      brand: 'Ferme locale',
      quantity: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&w=300&q=80',
      energyKcal: 62,
      proteins: 4.1,
      fibers: 0,
      fat: 3.2,
      sugars: 4.7,
      salt: 0.12,
      nutriScore: 'B',
    ),
    const ShoppingProduct(
      id: '3560070478786',
      name: 'Filets de poulet',
      brand: 'Carrefour',
      quantity: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=300&q=80',
      energyKcal: 121,
      proteins: 23.0,
      fibers: 0,
      fat: 2.2,
      sugars: 0.2,
      salt: 0.18,
      nutriScore: 'A',
    ),
    const ShoppingProduct(
      id: '3045320501015',
      name: 'Pates semi-completes',
      brand: 'Bjorg',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1551462147-37885acc36f1?auto=format&fit=crop&w=300&q=80',
      energyKcal: 352,
      proteins: 12.0,
      fibers: 7.1,
      fat: 2.5,
      sugars: 3.4,
      salt: 0.03,
      nutriScore: 'A',
    ),
    const ShoppingProduct(
      id: '5449000000996',
      name: 'Soda cola',
      brand: 'Coca-Cola',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?auto=format&fit=crop&w=300&q=80',
      energyKcal: 42,
      proteins: 0,
      fibers: 0,
      fat: 0,
      sugars: 10.6,
      salt: 0,
      nutriScore: 'E',
    ),
  ];

  List<ShoppingProduct> get products => List.unmodifiable(_products);

  String get currentListName => 'Liste de courses actuelle';

  int get productCount =>
      _products.fold(0, (sum, product) => sum + product.quantity);

  ShoppingNutritionSummary get summary {
    final proteins =
        _products.fold<double>(0, (sum, p) => sum + p.proteinTotal);
    final fibers = _products.fold<double>(0, (sum, p) => sum + p.fiberTotal);
    final fat = _products.fold<double>(0, (sum, p) => sum + p.fatTotal);
    final sugars = _products.fold<double>(0, (sum, p) => sum + p.sugarTotal);

    final score = _products.isEmpty
        ? 0
        : (_products.map(_productScore).reduce((a, b) => a + b) /
                _products.length)
            .round()
            .clamp(0, 100);

    return ShoppingNutritionSummary(
      score: score,
      label: _scoreLabel(score),
      proteins: proteins,
      fibers: fibers,
      fat: fat,
      sugars: sugars,
    );
  }

  double _productScore(ShoppingProduct product) {
    final base = switch (product.nutriScore.toUpperCase()) {
      'A' => 92.0,
      'B' => 78.0,
      'C' => 62.0,
      'D' => 42.0,
      'E' => 24.0,
      _ => 55.0,
    };

    final sugarPenalty = product.sugars > 8 ? (product.sugars - 8) * 1.4 : 0;
    final saltPenalty = product.salt > 1 ? (product.salt - 1) * 5 : 0;
    final fiberBonus = product.fibers > 3 ? (product.fibers - 3) * 1.8 : 0;
    final proteinBonus =
        product.proteins > 8 ? (product.proteins - 8) * 0.45 : 0;

    return (base - sugarPenalty - saltPenalty + fiberBonus + proteinBonus)
        .clamp(0, 100);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Tres bon';
    if (score >= 65) return 'Plutot bien';
    if (score >= 45) return 'A surveiller';
    return 'A ameliorer';
  }
}
