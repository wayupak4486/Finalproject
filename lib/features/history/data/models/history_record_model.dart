class HistoryRecordModel {
  const HistoryRecordModel({
    this.id,
    required this.imagePath,
    required this.material,
    required this.category,
    required this.confidence,
    required this.weight,
    required this.pricePerKg,
    required this.estimatedPrice,
    required this.co2Saved,
    required this.pointsEarned,
    required this.note,
    required this.createdAt,
  });

  final int? id;
  final String imagePath;
  final String material;
  final String category;
  final double confidence;
  final double weight;
  final double pricePerKg;
  final double estimatedPrice;
  final double co2Saved;
  final int pointsEarned;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'material': material,
      'category': category,
      'confidence': confidence,
      'weight': weight,
      'price_per_kg': pricePerKg,
      'estimated_price': estimatedPrice,
      'co2_saved': co2Saved,
      'points_earned': pointsEarned,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryRecordModel.fromMap(Map<String, dynamic> map) {
    return HistoryRecordModel(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      material: map['material'] as String,
      category: map['category'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
      co2Saved: (map['co2_saved'] as num).toDouble(),
      pointsEarned: map['points_earned'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}