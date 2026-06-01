class ShoppingListAnalysisItem {
  const ShoppingListAnalysisItem({
    required this.name,
    required this.confidence,
  });

  factory ShoppingListAnalysisItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListAnalysisItem(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final String name;
  final double confidence;
}

class ShoppingListAnalysisResult {
  const ShoppingListAnalysisResult({
    required this.source,
    required this.rawText,
    required this.items,
    required this.rejectedItems,
  });

  factory ShoppingListAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawRejectedItems =
        json['rejectedItems'] as List<dynamic>? ?? const [];
    return ShoppingListAnalysisResult(
      source: json['source'] as String? ?? '',
      rawText: json['rawText'] as String? ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ShoppingListAnalysisItem.fromJson)
          .toList(),
      rejectedItems: rawRejectedItems
          .whereType<Map<String, dynamic>>()
          .map(ShoppingListRejectedItem.fromJson)
          .toList(),
    );
  }

  final String source;
  final String rawText;
  final List<ShoppingListAnalysisItem> items;
  final List<ShoppingListRejectedItem> rejectedItems;
}

class ShoppingListRejectedItem {
  const ShoppingListRejectedItem({
    required this.name,
    required this.reason,
  });

  factory ShoppingListRejectedItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListRejectedItem(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? 'Produit non alimentaire ignore',
    );
  }

  final String name;
  final String reason;
}
