import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    return DateFormat.yMMMMd().format(date); // e.g. June 11, 2026
  }

  static String formatDateShort(DateTime date) {
    return DateFormat.yMd().format(date); // e.g. 6/11/2026
  }

  static String toDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date); // e.g. 2026-06-11
  }

  static String formatDuration(int days) {
    if (days <= 0) return '0 days';

    final int years = days ~/ 365;
    final int remainingDaysAfterYears = days % 365;
    final int months = remainingDaysAfterYears ~/ 30;
    final int remainingDays = remainingDaysAfterYears % 30;

    final List<String> parts = [];
    if (years > 0) {
      parts.add('$years ${years == 1 ? 'year' : 'years'}');
    }
    if (months > 0) {
      parts.add('$months ${months == 1 ? 'month' : 'months'}');
    }
    if (remainingDays > 0 && years == 0) { // Only show days if it's less than a year
      parts.add('$remainingDays ${remainingDays == 1 ? 'day' : 'days'}');
    }

    if (parts.isEmpty) {
      return '$days days';
    }

    return parts.join(', ');
  }
}
