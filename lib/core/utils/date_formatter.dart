import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String shortDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Numeric `dd/MM/yyyy HH:mm` form used by history list/detail cards.
  static String slashDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
