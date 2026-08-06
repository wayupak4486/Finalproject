import '../../../../core/constants/database_constants.dart';
import '../../../../services/database/app_database.dart';
import '../models/material_price_model.dart';

class MaterialPriceRepository {
  MaterialPriceRepository({required this.database});

  final AppDatabase database;

  Future<List<MaterialPriceModel>> getAllPrices() async {
    final db = await database.database;

    final maps = await db.query(
      DatabaseConstants.materialPricesTable,
      orderBy: 'display_name ASC',
    );

    return maps.map(MaterialPriceModel.fromMap).toList();
  }

  Future<Map<String, double>> getPricesByLabel() async {
    final prices = await getAllPrices();

    return {for (final price in prices) price.label: price.pricePerKg};
  }

  Future<void> upsertPrice({
    required String label,
    required double pricePerKg,
    required String source,
    required DateTime updatedAt,
  }) async {
    final db = await database.database;

    await db.update(
      DatabaseConstants.materialPricesTable,
      {
        'price_per_kg': pricePerKg,
        'source': source,
        'updated_at': updatedAt.toIso8601String(),
      },
      where: 'label = ?',
      whereArgs: [label],
    );
  }
}
