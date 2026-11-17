import '../../core/dates.dart';
import '../../core/money.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'budgets.dart';
import 'planning.dart';

/// What the user can ask Home to show beside "Spent today". [none] is the default and leaves
/// Home exactly as it was.
enum HomeDetail { none, budget, week, average, bill }

/// What the small block beside "Spent today" on Home is saying.
enum HomeSlotKind { allowance, warning, over, week, average, bill }

class HomeSlot {
  const HomeSlot({required this.kind, required this.label, required this.value});

  final HomeSlotKind kind;
  final String label;
  final String value;

  /// The screen a tap opens, or null when the block is only information.
  String? get route => switch (kind) {
    HomeSlotKind.allowance || HomeSlotKind.warning || HomeSlotKind.over => '/budgets',
    HomeSlotKind.bill => '/recurring',
    _ => null,
  };
}

/// The one detail the user chose for the space beside "Spent today", or null when that choice
/// has nothing to say right now (no budget set, no bill coming up, nothing spent yet).
///
/// "Budget status" shows, in order of need: over the monthly budget, a budget nearly used, or
/// what is left to spend per day. The first two are budget warnings: when the user has hidden
/// budget warnings ([showBudgetWarnings] false) only the calm daily allowance can show.
HomeSlot? computeHomeSlot({
  required HomeDetail choice,
  required BudgetStatus? overall,
  required int weekExpense,
  required int monthExpense,
  required List<Recurring> recurrings,
  required DateTime today,
  required bool showBudgetWarnings,
}) {
  switch (choice) {
    case HomeDetail.none:
      return null;

    case HomeDetail.budget:
      if (overall == null) return null;
      if (showBudgetWarnings && overall.level == BudgetLevel.over) {
        return HomeSlot(kind: HomeSlotKind.over, label: 'Over budget by', value: formatTaka(-overall.remaining));
      }
      if (showBudgetWarnings && overall.level == BudgetLevel.warning) {
        return HomeSlot(
          kind: HomeSlotKind.warning,
          label: 'Budget ${(overall.fraction * 100).floor()}% used',
          value: '${formatTaka(overall.remaining)} left',
        );
      }
      if (overall.remaining <= 0) return null;
      // Today counts as a day still to spend in. Rounded down to whole Taka so it never promises extra.
      final daysLeft = DateTime(today.year, today.month + 1, 0).day - today.day + 1;
      final perDay = overall.remaining ~/ daysLeft ~/ 100 * 100;
      return HomeSlot(kind: HomeSlotKind.allowance, label: 'Daily allowance', value: '${formatTaka(perDay)} / day');

    case HomeDetail.week:
      if (weekExpense <= 0) return null;
      return HomeSlot(kind: HomeSlotKind.week, label: 'This week', value: formatTaka(weekExpense));

    case HomeDetail.average:
      if (monthExpense <= 0) return null;
      final perDay = (monthExpense / today.day / 100).round() * 100;
      return HomeSlot(kind: HomeSlotKind.average, label: 'Daily average', value: '${formatTaka(perDay)} / day');

    case HomeDetail.bill:
      final due = dueSoonBill(recurrings, today);
      if (due == null) return null;
      return HomeSlot(
        kind: HomeSlotKind.bill,
        label: '${due.bill.title} · ${_dueWords(due.days)}',
        value: formatTaka(due.bill.amountPoisha),
      );
  }
}

/// How many days ahead a bill still counts as "due soon".
const int billSoonDays = 3;

class DueSoon {
  const DueSoon(this.bill, this.days);

  final Recurring bill;

  /// Days from today until it falls due; negative when it is already late.
  final int days;
}

/// The monthly bill (not income) that needs attention soonest, if it falls due within
/// [billSoonDays] days or is already late. Automatic items and paused ones are ignored.
DueSoon? dueSoonBill(List<Recurring> recurrings, DateTime today) {
  final base = dateOnly(today);
  DueSoon? best;
  for (final r in recurrings) {
    if (!r.isActive || r.autoAdd || r.type != EntryType.expense) continue;
    final days = nextRecurringDate(r, base).difference(base).inDays;
    if (days > billSoonDays) continue;
    if (best == null || days < best.days) best = DueSoon(r, days);
  }
  return best;
}

String _dueWords(int days) {
  if (days < 0) return 'late';
  if (days == 0) return 'due today';
  if (days == 1) return 'due tomorrow';
  return 'in $days days';
}

/// The goals to feature on Home: unfinished ones first, nearest deadline first (goals with
/// no deadline after those), then the most advanced; reached goals come last.
List<GoalProgress> orderGoalsForHome(List<GoalProgress> goals) {
  final sorted = [...goals];
  int rank(GoalProgress g) => g.isDone ? 2 : (g.goal.deadline == null ? 1 : 0);
  sorted.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    if (rank(a) == 0) {
      final byDeadline = a.goal.deadline!.compareTo(b.goal.deadline!);
      if (byDeadline != 0) return byDeadline;
    }
    return b.fraction.compareTo(a.fraction);
  });
  return sorted;
}
