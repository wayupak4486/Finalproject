class MaterialPriceModel {
  const MaterialPriceModel({
    this.id,
    required this.label,
    required this.displayName,
    required this.category,
    required this.pricePerKg,
    required this.co2Factor,
    required this.source,
    required this.updatedAt,
  });

  final int? id;
  final String label;
  final String displayName;
  final String category;
  final double pricePerKg;
  final double co2Factor;
  final String source;
  final DateTime updatedAt;

  factory MaterialPriceModel.fromMap(Map<String, Object?> map) {
    return MaterialPriceModel(
      id: map['id'] as int?,
      label: map['label'] as String,
      displayName: map['display_name'] as String,
      category: map['category'] as String,
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      co2Factor: (map['co2_factor'] as num).toDouble(),
      source: map['source'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'label': label,
      'display_name': displayName,
      'category': category,
      'price_per_kg': pricePerKg,
      'co2_factor': co2Factor,
      'source': source,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
