import 'package:html/parser.dart' as html_parser;

class _ScrapedItem {
  const _ScrapedItem({required this.name, required this.pricePerKg});

  final String name;
  final double pricePerKg;
}

/// Parses the public Wongpanit price page without performing network I/O.
/// Keeping parsing separate makes markup changes testable with saved fixtures.
class PricePageParser {
  const PricePageParser();

  static const Map<String, List<String>> _keywordsByLabel = {
    'pet_plastic_bottle': ['พลาสติกเพทใส ไม่แกะ'],
    'hdpe_plastic': ['แกลลอนนม'],
    'paper_cardboard': ['กระดาษลัง'],
    'aluminum_can': ['อลูมิเนียมกระป๋อง'],
    'glass': ['แก้วรวม'],
    'steel_scrap': ['เหล็กรวม'],
  };

  Map<String, double> parsePrices(String body) {
    final items = _parseItems(body);
    final prices = <String, double>{};

    for (final entry in _keywordsByLabel.entries) {
      final price = _findPrice(items, entry.value);
      if (price != null) {
        prices[entry.key] = price;
      }
    }

    return prices;
  }

  List<_ScrapedItem> _parseItems(String body) {
    final document = html_parser.parse(body);
    final rows = document.querySelectorAll('table tr');
    final items = <_ScrapedItem>[];

    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      final nameIndex = cells.indexWhere((cell) => !_isPureNumber(cell.text));
      if (nameIndex == -1) continue;

      final name = _cleanName(cells[nameIndex].text);
      if (name.isEmpty) continue;

      double? price;
      for (final cell in cells.skip(nameIndex + 1)) {
        price = _tryParsePrice(cell.text);
        if (price != null) break;
      }

      if (price != null) {
        items.add(_ScrapedItem(name: name, pricePerKg: price));
      }
    }

    return items;
  }

  bool _isPureNumber(String raw) => RegExp(r'^\d+$').hasMatch(raw.trim());

  String _cleanName(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
  }

  double? _tryParsePrice(String raw) {
    final normalized = raw.trim().replaceAll(',', '');
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(normalized);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  double? _findPrice(List<_ScrapedItem> items, List<String> keywords) {
    for (final keyword in keywords) {
      for (final item in items) {
        if (item.name.contains(keyword)) return item.pricePerKg;
      }
    }
    return null;
  }
}
