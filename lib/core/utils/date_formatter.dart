import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String shortDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}
