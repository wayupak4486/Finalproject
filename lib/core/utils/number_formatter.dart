import 'package:intl/intl.dart';

class NumberFormatter {
  const NumberFormatter._();

  static String money(double value) {
    return '${NumberFormat('#,##0.00').format(value)} บาท';
  }

  static String kg(double value) {
    return '${NumberFormat('#,##0.##').format(value)} กก.';
  }

  static String co2(double value) {
    return '${NumberFormat('#,##0.##').format(value)} กก.CO₂e';
  }

  static String percent(double value) {
    return '${NumberFormat('0.0').format(value * 100)}%';
  }
}
