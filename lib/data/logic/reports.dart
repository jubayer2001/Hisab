import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../db/app_database.dart';
import 'periods.dart';

class CategoryTotal {
  const CategoryTotal({required this.category, required this.amount, required this.share});

  final Category category;
  final int amount;

  /// 0 to 1: this category's part of all spending in the period.
  final double share;
}

class BarData {
  const BarData({required this.label, required this.fullLabel, required this.amount});

  /// Short label under the bar, like "Sat", "12" or "Jan".
  final String label;

  /// Longer text shown when the bar is tapped, like "Sat, 17 Oct".
  final String fullLabel;
  final int amount;
}

/// Everything the Reports screen shows for one period. Amounts are in poisha.
class Report {
  const Report({
    required this.period,
    required this.expense,
    required this.income,
    required this.saved,
    required this.byCategory,
    required this.bars,
    required this.entries,
    required this.previousExpense,
    required this.averagePerDay,
  });

  final Period period;
  final int expense;
  final int income;

  /// Money moved into savings goals in this period, minus money taken back out.
  final int saved;
  final List<CategoryTotal> byCategory;
  final List<BarData> bars;

  /// Every entry in the period, newest first.
  final List<EntryWithCategory> entries;
  final int previousExpense;
  final int averagePerDay;

  int get balance => income - expense;

  bool get isEmpty => entries.isEmpty;
}

Report buildReport({
  required List<EntryWithCategory> all,
  required List<GoalDeposit> deposits,
  required Period period,
  required DateTime now,
}) {
  final inPeriod = <EntryWithCategory>[];
  var expense = 0, income = 0;
  final byCategory = <int, int>{};
  final categoryOf = <int, Category>{};

  final barAmounts = _emptyBars(period);

  for (final e in all) {
    if (!period.containsKey(e.entry.date)) continue;
    inPeriod.add(e);
    if (e.isExpense) {
      expense += e.entry.amountPoisha;
      byCategory.update(e.category.id, (v) => v + e.entry.amountPoisha, ifAbsent: () => e.entry.amountPoisha);
      categoryOf[e.category.id] = e.category;
      final index = _barIndex(period, parseDayKey(e.entry.date));
      if (index != null) barAmounts[index] += e.entry.amountPoisha;
    } else {
      income += e.entry.amountPoisha;
    }
  }

  final totals = [
    for (final entry in byCategory.entries)
      CategoryTotal(
        category: categoryOf[entry.key]!,
        amount: entry.value,
        share: expense == 0 ? 0 : entry.value / expense,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final previous = shiftPeriod(period, -1);
  var previousExpense = 0;
  for (final e in all) {
    if (e.isExpense && previous.containsKey(e.entry.date)) previousExpense += e.entry.amountPoisha;
  }

  var saved = 0;
  for (final d in deposits) {
    if (period.containsKey(d.date)) saved += d.amountPoisha;
  }

  final today = dateOnly(now);
  final lastCounted = today.isBefore(period.end) ? today : period.end;
  final elapsed = lastCounted.isBefore(period.start) ? 0 : lastCounted.difference(period.start).inDays + 1;

  return Report(
    period: period,
    expense: expense,
    income: income,
    saved: saved,
    byCategory: totals,
    bars: _buildBars(period, barAmounts),
    entries: inPeriod,
    previousExpense: previousExpense,
    averagePerDay: elapsed == 0 ? 0 : expense ~/ elapsed,
  );
}

int _barCount(Period p) {
  switch (p.type) {
    case PeriodType.day:
      return 0;
    case PeriodType.week:
      return 7;
    case PeriodType.month:
      return p.lengthInDays;
    case PeriodType.year:
      return 12;
  }
}

List<int> _emptyBars(Period p) => List<int>.filled(_barCount(p), 0);

int? _barIndex(Period p, DateTime day) {
  switch (p.type) {
    case PeriodType.day:
      return null;
    case PeriodType.week:
    case PeriodType.month:
      return day.difference(p.start).inDays;
    case PeriodType.year:
      return day.month - 1;
  }
}

List<BarData> _buildBars(Period p, List<int> amounts) {
  return [
    for (var i = 0; i < amounts.length; i++)
      switch (p.type) {
        PeriodType.week => () {
            final day = DateTime(p.start.year, p.start.month, p.start.day + i);
            return BarData(
              label: DateFormat('E').format(day),
              fullLabel: DateFormat('EEE, d MMM').format(day),
              amount: amounts[i],
            );
          }(),
        PeriodType.month => () {
            final day = DateTime(p.start.year, p.start.month, i + 1);
            return BarData(
              label: '${i + 1}',
              fullLabel: DateFormat('EEE, d MMM').format(day),
              amount: amounts[i],
            );
          }(),
        PeriodType.year => () {
            final month = DateTime(p.start.year, i + 1, 1);
            return BarData(
              label: DateFormat('MMM').format(month),
              fullLabel: DateFormat('MMMM y').format(month),
              amount: amounts[i],
            );
          }(),
        PeriodType.day => throw StateError('Day reports have no bars'),
      },
  ];
}
