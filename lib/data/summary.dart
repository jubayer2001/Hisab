import '../core/dates.dart';
import 'db/app_database.dart';

/// Totals shown on the Home card. All amounts are in poisha.
class Summary {
  const Summary({
    this.todayExpense = 0,
    this.todayIncome = 0,
    this.todayCount = 0,
    this.monthExpense = 0,
    this.monthIncome = 0,
  });

  final int todayExpense;
  final int todayIncome;
  final int todayCount;
  final int monthExpense;
  final int monthIncome;

  /// Income minus spending for the month. Negative when you spent more than you earned.
  int get monthBalance => monthIncome - monthExpense;
}

Summary computeSummary(List<EntryWithCategory> all, DateTime now) {
  final today = dayKey(now);
  final month = monthKey(now);
  var todayExpense = 0, todayIncome = 0, todayCount = 0, monthExpense = 0, monthIncome = 0;

  for (final e in all) {
    final entry = e.entry;
    final inMonth = entry.date.startsWith(month);
    if (entry.date == today) {
      todayCount++;
      if (e.isExpense) {
        todayExpense += entry.amountPoisha;
      } else {
        todayIncome += entry.amountPoisha;
      }
    }
    if (inMonth) {
      if (e.isExpense) {
        monthExpense += entry.amountPoisha;
      } else {
        monthIncome += entry.amountPoisha;
      }
    }
  }
  return Summary(
    todayExpense: todayExpense,
    todayIncome: todayIncome,
    todayCount: todayCount,
    monthExpense: monthExpense,
    monthIncome: monthIncome,
  );
}

/// A repeat expense offered as a one-tap shortcut, like "Tea ৳10".
class QuickAdd {
  const QuickAdd({required this.category, required this.amountPoisha, this.note});

  final Category category;
  final int amountPoisha;
  final String? note;

  String get label => (note != null && note!.isNotEmpty) ? note! : category.name;
}

/// The expenses you repeat most (same category, amount and note, at least twice in the
/// last 90 days). Ties go to whichever was added most recently.
List<QuickAdd> computeQuickAdds(List<EntryWithCategory> all, DateTime now, {int limit = 3}) {
  final since = dayKey(now.subtract(const Duration(days: 90)));
  final groups = <String, _Group>{};

  for (final e in all) {
    final entry = e.entry;
    if (!e.isExpense || e.category.isArchived || entry.date.compareTo(since) < 0) continue;
    final note = (entry.note ?? '').trim();
    final key = '${entry.categoryId}|${entry.amountPoisha}|$note';
    final g = groups.putIfAbsent(key, () => _Group(e, note));
    g.count++;
    if (entry.createdAt.isAfter(g.latest)) g.latest = entry.createdAt;
  }

  final repeated = groups.values.where((g) => g.count >= 2).toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.latest.compareTo(a.latest);
    });

  return [
    for (final g in repeated.take(limit))
      QuickAdd(
        category: g.sample.category,
        amountPoisha: g.sample.entry.amountPoisha,
        note: g.note.isEmpty ? null : g.note,
      ),
  ];
}

class _Group {
  _Group(this.sample, this.note) : latest = sample.entry.createdAt;

  final EntryWithCategory sample;
  final String note;
  int count = 0;
  DateTime latest;
}
