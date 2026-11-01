import 'dart:math' as math;

import '../../core/dates.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// A point-in-time balance. Reservations are part of total, not extra money.
class Funds {
  const Funds({this.total = 0, this.reserved = 0});

  final int total;
  final int reserved;
  int get available => total - reserved;
}

/// The balance as of [asOf]: money saved from earlier months, plus this month's income minus
/// this month's spending.
///
/// Only saved money moves from one month to the next. A month that ends with more spent than
/// earned passes on 0, never a negative number, so spending ৳2,000 in a month with no income
/// does not reduce next month's balance. Inside the month itself a shortfall is still shown as
/// negative. Entries after [asOf] are ignored.
int carriedBalance(Iterable<Entry> entries, DateTime asOf) {
  final cutoff = dayKey(asOf);
  final thisMonth = cutoff.substring(0, 7);
  final net = <String, int>{};
  for (final entry in entries) {
    if (entry.date.compareTo(cutoff) > 0) continue;
    final change = entry.type == EntryType.expense ? -entry.amountPoisha : entry.amountPoisha;
    net.update(entry.date.substring(0, 7), (v) => v + change, ifAbsent: () => change);
  }
  // Earlier months, oldest first ("yyyy-MM" sorts correctly as text). Months with no entries
  // change nothing, because passing on an amount that is already 0 or more leaves it as it is.
  final earlier = net.keys.where((m) => m.compareTo(thisMonth) < 0).toList()..sort();
  var carry = 0;
  for (final month in earlier) {
    carry = math.max(0, carry + net[month]!);
  }
  return carry + (net[thisMonth] ?? 0);
}

Funds computeFunds({
  required Iterable<Entry> entries,
  required Iterable<GoalDeposit> deposits,
  required DateTime asOf,
}) {
  final cutoff = dayKey(asOf);
  final goals = <int, int>{};
  for (final deposit in deposits) {
    if (deposit.date.compareTo(cutoff) > 0) continue;
    goals.update(deposit.goalId, (v) => v + deposit.amountPoisha, ifAbsent: () => deposit.amountPoisha);
  }
  for (final entry in entries) {
    if (entry.date.compareTo(cutoff) > 0) continue;
    final goal = entry.savingsGoalId;
    if (entry.type == EntryType.expense && goal != null) {
      goals.update(goal, (v) => v - entry.amountPoisha, ifAbsent: () => -entry.amountPoisha);
    }
  }
  // A malformed old withdrawal must not cancel another goal's reservation.
  return Funds(
    total: carriedBalance(entries, asOf),
    reserved: goals.values.fold(0, (sum, value) => sum + math.max(0, value)),
  );
}

int reservedForGoal({
  required int goalId,
  required Iterable<Entry> entries,
  required Iterable<GoalDeposit> deposits,
  required DateTime asOf,
}) {
  final cutoff = dayKey(asOf);
  final saved = deposits
      .where((d) => d.goalId == goalId && d.date.compareTo(cutoff) <= 0)
      .fold<int>(0, (sum, d) => sum + d.amountPoisha);
  final spent = entries
      .where((e) => e.savingsGoalId == goalId && e.type == EntryType.expense && e.date.compareTo(cutoff) <= 0)
      .fold<int>(0, (sum, e) => sum + e.amountPoisha);
  return math.max(0, saved - spent);
}
