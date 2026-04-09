import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime get today => normalizeDate(DateTime.now());

  static String formatForHeatmap(DateTime date) {
    return DateFormat('yy.MM.dd').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int weeksBetween(DateTime from, DateTime to) {
    final fromNorm = normalizeDate(from);
    final toNorm = normalizeDate(to);
    return ((toNorm.difference(fromNorm).inDays) / 7).ceil();
  }
}
