import '../../../../core/constants/material_catalog.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../repositories/material_price_repository.dart';

class PriceUpdateResult {
  const PriceUpdateResult({
    required this.updatedCount,
    required this.totalLabels,
    required this.updatedAt,
  });

  final int updatedCount;
  final int totalLabels;
  final DateTime updatedAt;
}

/// Fetches live prices from the web and persists them into SQLite so every
/// screen that reads [MaterialPriceRepository] reflects the new prices.
class PriceUpdateService {
  PriceUpdateService({
    required this.priceRepository,
    WongpanitPriceService? scraper,
  }) : _scraper = scraper ?? WongpanitPriceService();

  final MaterialPriceRepository priceRepository;
  final WongpanitPriceService _scraper;

  Future<PriceUpdateResult> updateFromWeb() async {
    final scrapedPrices = await _scraper.fetchPrices();
    final updatedAt = DateTime.now();

    for (final entry in scrapedPrices.entries) {
      await priceRepository.upsertPrice(
        label: entry.key,
        pricePerKg: entry.value,
        source: WongpanitPriceService.sourceName,
        updatedAt: updatedAt,
      );
    }

    return PriceUpdateResult(
      updatedCount: scrapedPrices.length,
      totalLabels: MaterialCatalog.byLabel.values
          .where((material) => material.isSellable)
          .length,
      updatedAt: updatedAt,
    );
  }
}
