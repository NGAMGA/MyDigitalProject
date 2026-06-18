class ShoppingProduct {
  const ShoppingProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.imageUrl,
    required this.energyKcal,
    required this.proteins,
    required this.fibers,
    required this.fat,
    required this.sugars,
    required this.salt,
    required this.nutriScore,
  });

  final String id;
  final String name;
  final String brand;
  final int quantity;
  final String imageUrl;
  final double energyKcal;
  final double proteins;
  final double fibers;
  final double fat;
  final double sugars;
  final double salt;
  final String nutriScore;

  factory ShoppingProduct.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return ShoppingProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? 'A completer',
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['imageUrl'] as String? ?? '',
      energyKcal: number('energyKcal'),
      proteins: number('proteins'),
      fibers: number('fibers'),
      fat: number('fat'),
      sugars: number('sugars'),
      salt: number('salt'),
      nutriScore: json['nutriScore'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'energyKcal': energyKcal,
        'proteins': proteins,
        'fibers': fibers,
        'fat': fat,
        'sugars': sugars,
        'salt': salt,
        'nutriScore': nutriScore,
      };

  double get proteinTotal => proteins * quantity;
  double get fiberTotal => fibers * quantity;
  double get fatTotal => fat * quantity;
  double get sugarTotal => sugars * quantity;
}

class ShoppingNutritionSummary {
  const ShoppingNutritionSummary({
    required this.score,
    required this.label,
    required this.proteins,
    required this.fibers,
    required this.fat,
    required this.sugars,
  });

  final int score;
  final String label;
  final double proteins;
  final double fibers;
  final double fat;
  final double sugars;
}
