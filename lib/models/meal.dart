class Meal {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String? thumbnail;
  final String? tags;
  final String? youtubeUrl;
  final List<String> ingredients;
  final List<String> measures;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnail,
    this.tags,
    this.youtubeUrl,
    this.ingredients = const [],
    this.measures = const [],
  });

  factory Meal.fromSearchJson(Map<String, dynamic> json) {
    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      thumbnail: json['strMealThumb'],
    );
  }

  factory Meal.fromDetailJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final measures = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString().trim());
        measures.add(measure?.toString().trim() ?? '');
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      thumbnail: json['strMealThumb'],
      tags: json['strTags'],
      youtubeUrl: json['strYoutube'],
      ingredients: ingredients,
      measures: measures,
    );
  }

  factory Meal.fromStoredJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      area: json['area']?.toString(),
      instructions: json['instructions']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      tags: json['tags']?.toString(),
      youtubeUrl: json['youtubeUrl']?.toString(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((ingredient) => ingredient.toString())
              .toList() ??
          const [],
      measures: (json['measures'] as List<dynamic>?)
              ?.map((measure) => measure.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toStoredJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'instructions': instructions,
      'thumbnail': thumbnail,
      'tags': tags,
      'youtubeUrl': youtubeUrl,
      'ingredients': ingredients,
      'measures': measures,
    };
  }

  @override
  bool operator ==(Object other) => other is Meal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
