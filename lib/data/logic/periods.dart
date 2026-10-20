import 'package:intl/intl.dart';

import '../../core/dates.dart';

enum PeriodType { day, week, month, year }

/// A stretch of days the Reports screen looks at. [start] and [end] are both inclusive.
class Period {
  const Period(this.type, this.start, this.end);

  final PeriodType type;
  final DateTime start;
  final DateTime end;

  String get startKey => dayKey(start);
  String get endKey => dayKey(end);

  bool containsKey(String key) => key.compareTo(startKey) >= 0 && key.compareTo(endKey) <= 0;

  bool contains(DateTime day) => containsKey(dayKey(day));

  int get lengthInDays => end.difference(start).inDays + 1;

  @override
  bool operator ==(Object other) =>
      other is Period && other.type == type && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(type, start, end);
}

/// Weeks run Saturday to Friday, the way weeks are usually counted in Bangladesh.
const int weekStartsOn = DateTime.saturday;

Period periodFor(PeriodType type, DateTime anchor) {
  final d = dateOnly(anchor);
  switch (type) {
    case PeriodType.day:
      return Period(type, d, d);
    case PeriodType.week:
      final back = (d.weekday - weekStartsOn) % 7;
      final start = DateTime(d.year, d.month, d.day - back);
      return Period(type, start, DateTime(start.year, start.month, start.day + 6));
    case PeriodType.month:
      return Period(type, DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 0));
    case PeriodType.year:
      return Period(type, DateTime(d.year, 1, 1), DateTime(d.year, 12, 31));
  }
}

/// The period [delta] steps away (-1 is the one before).
Period shiftPeriod(Period p, int delta) {
  switch (p.type) {
    case PeriodType.day:
      return periodFor(p.type, DateTime(p.start.year, p.start.month, p.start.day + delta));
    case PeriodType.week:
      return periodFor(p.type, DateTime(p.start.year, p.start.month, p.start.day + 7 * delta));
    case PeriodType.month:
      return periodFor(p.type, DateTime(p.start.year, p.start.month + delta, 1));
    case PeriodType.year:
      return periodFor(p.type, DateTime(p.start.year + delta, 1, 1));
  }
}

/// "Today", "20–26 Oct", "October 2026" or "2026".
String periodLabel(Period p, {DateTime? now}) {
  switch (p.type) {
    case PeriodType.day:
      return friendlyDay(p.start, now: now);
    case PeriodType.week:
      final sameMonth = p.start.month == p.end.month;
      final from = sameMonth ? DateFormat('d').format(p.start) : DateFormat('d MMM').format(p.start);
      return '$from–${DateFormat('d MMM').format(p.end)}';
    case PeriodType.month:
      return DateFormat('MMMM y').format(p.start);
    case PeriodType.year:
      return '${p.start.year}';
  }
}
