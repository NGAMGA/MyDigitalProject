import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/shopping_product.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final List<ShoppingProduct> _products = [];
  final ShoppingListService _service = ShoppingListService();
  List<ShoppingListSnapshot> _history = const [];
  String _currentListName = 'Liste de courses actuelle';
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _syncError;
  Future<void> _saveQueue = Future<void>.value();

  static const List<ShoppingProduct> _catalog = [
    ShoppingProduct(
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
    ShoppingProduct(
      id: '3274080005003',
      name: 'Yaourt nature',
      brand: 'Ferme locale',
      quantity: 1,
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
    ShoppingProduct(
      id: '3560070478786',
      name: 'Filets de poulet',
      brand: 'Carrefour',
      quantity: 1,
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
    ShoppingProduct(
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
    ShoppingProduct(
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
    ShoppingProduct(
      id: '3045140105506',
      name: 'Tomates',
      brand: 'Marche frais',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?auto=format&fit=crop&w=300&q=80',
      energyKcal: 18,
      proteins: 0.9,
      fibers: 1.2,
      fat: 0.2,
      sugars: 2.6,
      salt: 0.01,
      nutriScore: 'A',
    ),
    ShoppingProduct(
      id: '3222475920455',
      name: 'Riz basmati',
      brand: 'Taureau Aile',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31d?auto=format&fit=crop&w=300&q=80',
      energyKcal: 356,
      proteins: 7.5,
      fibers: 1.1,
      fat: 0.8,
      sugars: 0.2,
      salt: 0.01,
      nutriScore: 'B',
    ),
    ShoppingProduct(
      id: '7622210449283',
      name: 'Avocat',
      brand: 'Primeur',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=300&q=80',
      energyKcal: 160,
      proteins: 2.0,
      fibers: 6.7,
      fat: 14.7,
      sugars: 0.7,
      salt: 0.01,
      nutriScore: 'B',
    ),
  ];

  List<ShoppingProduct> get products => List.unmodifiable(_products);
  List<ShoppingListSnapshot> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;

  String get currentListName => _currentListName;

  int get productCount =>
      _products.fold(0, (sum, product) => sum + product.quantity);

  int addRecognizedProducts(Iterable<String> names) {
    var addedCount = 0;
    for (final name in names) {
      if (addManualProduct(name, notify: false)) {
        addedCount++;
      }
    }

    if (addedCount > 0) {
      notifyListeners();
      _schedulePersist();
    }
    return addedCount;
  }

  bool addManualProduct(String query, {bool notify = true}) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return false;

    final catalogMatch = _catalog.cast<ShoppingProduct?>().firstWhere(
      (product) {
        final name = _normalize(product!.name);
        final brand = _normalize(product.brand);
        return name.contains(normalizedQuery) ||
            normalizedQuery.contains(name) ||
            brand.contains(normalizedQuery);
      },
      orElse: () => null,
    );

    final existingIndex = _products.indexWhere(
      (product) => _normalize(product.name) == normalizedQuery,
    );

    if (existingIndex >= 0) {
      final current = _products[existingIndex];
      _products[existingIndex] = ShoppingProduct(
        id: current.id,
        name: current.name,
        brand: current.brand,
        quantity: current.quantity + 1,
        imageUrl: current.imageUrl,
        energyKcal: current.energyKcal,
        proteins: current.proteins,
        fibers: current.fibers,
        fat: current.fat,
        sugars: current.sugars,
        salt: current.salt,
        nutriScore: current.nutriScore,
      );
      if (notify) {
        notifyListeners();
        _schedulePersist();
      }
      return true;
    }

    final product = catalogMatch ?? _buildGenericProduct(query);
    _products.insert(
      0,
      ShoppingProduct(
        id: product.id,
        name: _capitalize(query.trim()),
        brand: product.brand,
        quantity: 1,
        imageUrl: product.imageUrl,
        energyKcal: product.energyKcal,
        proteins: product.proteins,
        fibers: product.fibers,
        fat: product.fat,
        sugars: product.sugars,
        salt: product.salt,
        nutriScore: product.nutriScore,
      ),
    );
    if (notify) {
      notifyListeners();
      _schedulePersist();
    }
    return true;
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    _syncError = null;
    notifyListeners();
    try {
      final snapshot = await _service.loadCurrent();
      _applySnapshot(snapshot);
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeProduct(String productId) async {
    _products.removeWhere((product) => product.id == productId);
    notifyListeners();
    _schedulePersist();
    await _saveQueue;
  }

  Future<void> clearCurrent() async {
    await _saveQueue;
    _isSyncing = true;
    notifyListeners();
    try {
      _applySnapshot(await _service.clearCurrent());
      _syncError = null;
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> createNewList({String? name}) async {
    await _saveQueue;
    _isSyncing = true;
    notifyListeners();
    try {
      _applySnapshot(await _service.createNew(name: name));
      _syncError = null;
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await _service.loadHistory();
      _syncError = null;
    } catch (error) {
      _history = const [];
      _syncError = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    _isSyncing = true;
    notifyListeners();
    try {
      _applySnapshot(await _service.replaceItems(_products));
      _syncError = null;
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _schedulePersist() {
    _saveQueue = _saveQueue.then((_) => _persist());
    unawaited(_saveQueue);
  }

  void _applySnapshot(ShoppingListSnapshot snapshot) {
    _currentListName = snapshot.name;
    _products
      ..clear()
      ..addAll(snapshot.items);
  }

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
      label: _products.isEmpty ? 'A completer' : _scoreLabel(score),
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

  ShoppingProduct _buildGenericProduct(String query) {
    return ShoppingProduct(
      id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
      name: _capitalize(query.trim()),
      brand: 'A completer',
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80',
      energyKcal: 0,
      proteins: 0,
      fibers: 0,
      fat: 0,
      sugars: 0,
      salt: 0,
      nutriScore: '-',
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
