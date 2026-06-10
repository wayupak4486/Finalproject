import 'package:intl/intl.dart';

class NumberFormatter {
  const NumberFormatter._();

  static String money(double value) {
    return '${NumberFormat('#,##0.00').format(value)} THB';
  }

  static String kg(double value) {
    return '${NumberFormat('#,##0.##').format(value)} kg';
  }

  static String co2(double value) {
    return '${NumberFormat('#,##0.##').format(value)} kgCO₂e';
  }

  static String percent(double value) {
    return '${NumberFormat('0.0').format(value * 100)}%';
  }
}
