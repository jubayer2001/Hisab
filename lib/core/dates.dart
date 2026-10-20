import 'package:intl/intl.dart';

/// Days are stored as plain "yyyy-MM-dd" text, so they sort correctly, compare with
/// simple string ranges, and never shift with time zones or daylight saving.
String dayKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-$m-$day';
}

DateTime parseDayKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String monthKey(DateTime d) => dayKey(d).substring(0, 7);

/// "Today", "Yesterday", "Tue, 20 Oct" or "Tue, 20 Oct 2025" for other years.
String friendlyDay(DateTime day, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final d = dateOnly(day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final pattern = d.year == today.year ? 'EEE, d MMM' : 'EEE, d MMM y';
  return DateFormat(pattern).format(d);
}
