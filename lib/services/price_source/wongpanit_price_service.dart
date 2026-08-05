import 'package:http/http.dart' as http;

import 'price_page_parser.dart';

class PriceFetchException implements Exception {
  PriceFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Scrapes the public buy-price table from the Wongpanit recycling center
/// website and maps each row to this app's material labels.
class WongpanitPriceService {
  WongpanitPriceService({http.Client? client, PricePageParser? parser})
    : _client = client,
      _parser = parser ?? const PricePageParser();

  static const String sourceUrl =
      'https://www.xn--12c7bzakgbj6bza1cbe6b3jwh.com/price';

  static const String sourceName = 'wongpanit';

  final http.Client? _client;
  final PricePageParser _parser;

  Future<Map<String, double>> fetchPrices() async {
    final http.Response response;

    try {
      response =
          await (_client?.get(Uri.parse(sourceUrl)) ??
                  http.get(Uri.parse(sourceUrl)))
              .timeout(const Duration(seconds: 20));
    } catch (error) {
      throw PriceFetchException('ไม่สามารถเชื่อมต่อเว็บไซต์ราคาได้: $error');
    }

    if (response.statusCode != 200) {
      throw PriceFetchException(
        'เว็บไซต์ราคาตอบกลับสถานะ ${response.statusCode}',
      );
    }

    final prices = _parser.parsePrices(response.body);

    if (prices.isEmpty) {
      throw PriceFetchException('ไม่พบวัสดุที่รู้จักในหน้าราคา');
    }

    return prices;
  }
}
