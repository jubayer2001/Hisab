import '../../core/dates.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'funds.dart';

// ---- Recurring bills --------------------------------------------------------

/// The day a recurring item falls due this month. In a month too short for
/// [Recurring.dayOfMonth] (31 in April, 30 in February) the last day is used.
DateTime recurringDueDate(Recurring r, DateTime today) {
  final lastDay = DateTime(today.year, today.month + 1, 0).day;
  final day = r.dayOfMonth < lastDay ? r.dayOfMonth : lastDay;
  return DateTime(today.year, today.month, day);
}

bool _handledThisMonth(Recurring r, DateTime today) => r.lastHandledMonth == monthKey(today);

/// Waiting for the user to confirm or skip: active, this month's due day has come, and
/// it has not been confirmed or skipped yet this month.
bool isRecurringDue(Recurring r, DateTime today) {
  if (!r.isActive || _handledThisMonth(r, today)) return false;
  return !dateOnly(today).isBefore(recurringDueDate(r, today));
}

/// Items waiting for a confirmation. Monthly income that adds itself never waits.
List<Recurring> dueRecurrings(List<Recurring> all, DateTime today) =>
    all.where((r) => !r.autoAdd && isRecurringDue(r, today)).toList();

/// The next day this item needs attention: this month's due day if it is still waiting,
/// otherwise next month's.
DateTime nextRecurringDate(Recurring r, DateTime today) {
  if (!_handledThisMonth(r, today)) return recurringDueDate(r, today);
  final nextMonth = DateTime(today.year, today.month + 1, 1);
  return recurringDueDate(r, nextMonth);
}

// ---- Savings goals ----------------------------------------------------------

class GoalProgress {
  const GoalProgress({required this.goal, required this.saved, required this.monthsLeft, required this.monthlyNeeded});

  final SavingsGoal goal;
  final int saved;

  /// Whole months until the deadline, at least 1 while it is still ahead. Null without a
  /// deadline, 0 when the deadline has passed.
  final int? monthsLeft;

  /// How much to set aside each month to reach the target in time.
  final int? monthlyNeeded;

  int get target => goal.targetPoisha;
  int get remaining => saved >= target ? 0 : target - saved;
  bool get isDone => saved >= target;
  bool get isOverdue => !isDone && monthsLeft == 0;
  double get fraction => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
}

GoalProgress computeGoalProgress(
  SavingsGoal goal,
  List<GoalDeposit> deposits,
  DateTime today, {
  Iterable<Entry> entries = const [],
}) {
  final saved = reservedForGoal(goalId: goal.id, entries: entries, deposits: deposits, asOf: today);
  final remaining = saved >= goal.targetPoisha ? 0 : goal.targetPoisha - saved;

  int? monthsLeft;
  int? monthlyNeeded;
  final deadline = goal.deadline;
  if (deadline != null) {
    final days = parseDayKey(deadline).difference(dateOnly(today)).inDays;
    if (days < 0) {
      monthsLeft = 0;
    } else {
      monthsLeft = (days / 30.4375).ceil().clamp(1, 1200);
      if (remaining > 0) monthlyNeeded = (remaining / monthsLeft).ceil();
    }
  }
  return GoalProgress(goal: goal, saved: saved, monthsLeft: monthsLeft, monthlyNeeded: monthlyNeeded);
}

// ---- Dhar (lend and borrow) -------------------------------------------------

class DharView {
  const DharView({required this.record, required this.paid, required this.payments});

  final DharRecord record;
  final int paid;
  final List<DharPayment> payments;

  bool get isLent => record.direction == DharDirection.lent;
  int get total => record.amountPoisha;
  int get remaining => paid >= total ? 0 : total - paid;
  bool get isSettled => record.settled || remaining == 0;
  double get fraction => total <= 0 ? 0 : (paid / total).clamp(0.0, 1.0);

  /// Past its due date and still not settled.
  bool isOverdue(DateTime today) {
    final due = record.dueDate;
    return !isSettled && due != null && due.compareTo(dayKey(today)) < 0;
  }

  /// Unsettled and due within [days] days (or already overdue).
  bool isDueSoon(DateTime today, {int days = 3}) {
    final due = record.dueDate;
    if (isSettled || due == null) return false;
    final limit = dayKey(DateTime(today.year, today.month, today.day + days));
    return due.compareTo(limit) <= 0;
  }
}

/// Open items first (earliest due date first, then newest), settled ones after.
List<DharView> computeDharViews(List<DharRecord> records, List<DharPayment> payments) {
  final byRecord = <int, List<DharPayment>>{};
  for (final p in payments) {
    byRecord.putIfAbsent(p.dharId, () => []).add(p);
  }
  final views = [
    for (final r in records)
      DharView(
        record: r,
        payments: byRecord[r.id] ?? const [],
        paid: (byRecord[r.id] ?? const <DharPayment>[]).fold<int>(0, (s, p) => s + p.amountPoisha),
      ),
  ];

  views.sort((a, b) {
    if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
    final ad = a.record.dueDate, bd = b.record.dueDate;
    if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
    if (ad != null && bd == null) return -1;
    if (ad == null && bd != null) return 1;
    return b.record.id.compareTo(a.record.id);
  });
  return views;
}

class DharTotals {
  const DharTotals({required this.toReceive, required this.toPay});

  /// What other people still owe you.
  final int toReceive;

  /// What you still owe other people.
  final int toPay;
}

DharTotals computeDharTotals(List<DharView> views) {
  var receive = 0, pay = 0;
  for (final v in views) {
    if (v.isSettled) continue;
    if (v.isLent) {
      receive += v.remaining;
    } else {
      pay += v.remaining;
    }
  }
  return DharTotals(toReceive: receive, toPay: pay);
}

// ---- Logging streak ---------------------------------------------------------

/// How many days in a row you have logged something or marked "No spending".
///
/// Today counts once it is handled. Until then the streak stands at yesterday's count
/// instead of dropping to zero, because the day is not over yet.
int computeStreak(Set<String> handledDays, DateTime today) {
  var day = dateOnly(today);
  if (!handledDays.contains(dayKey(day))) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  var count = 0;
  while (handledDays.contains(dayKey(day))) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}
