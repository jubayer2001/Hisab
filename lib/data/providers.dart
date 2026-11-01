import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import 'db/app_database.dart';
import 'db/tables.dart';
import 'logic/auto_income.dart';
import 'logic/budgets.dart';
import 'logic/funds.dart';
import 'logic/planning.dart';
import 'summary.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Today's date. Refreshes itself at midnight and when the app comes back to the
/// foreground (see AppShell), so "Today" is never stale.
class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _scheduleMidnight();
    return dateOnly(DateTime.now());
  }

  void refresh() {
    final now = dateOnly(DateTime.now());
    if (now != state) state = now;
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _timer = Timer(next.difference(now), refresh);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

final allEntriesProvider = StreamProvider<List<EntryWithCategory>>((ref) => ref.watch(databaseProvider).watchEntries());

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(databaseProvider).watchCategories());

/// Categories you can pick from for a given type (hides archived ones).
final pickableCategoriesProvider = Provider.family<List<Category>, String>((ref, type) {
  final all = ref.watch(categoriesProvider).value ?? const <Category>[];
  return all.where((c) => c.type == type && !c.isArchived).toList();
});

final noSpendDaysProvider = StreamProvider<Set<String>>((ref) => ref.watch(databaseProvider).watchNoSpendDays());

final summaryProvider = Provider<Summary>((ref) {
  final entries = ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[];
  return computeSummary(entries, ref.watch(todayProvider));
});

final todayEntriesProvider = Provider<List<EntryWithCategory>>((ref) {
  final entries = ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[];
  final today = dayKey(ref.watch(todayProvider));
  return entries.where((e) => e.entry.date == today).toList();
});

final quickAddsProvider = Provider<List<QuickAdd>>((ref) {
  final entries = ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[];
  return computeQuickAdds(entries, ref.watch(todayProvider));
});

// ---- Budgets, bills, goals, dhar, streak (v0.3 and v0.4) -----------------------

final budgetsProvider = StreamProvider<List<Budget>>((ref) => ref.watch(databaseProvider).watchBudgets());

final recurringsProvider = StreamProvider<List<Recurring>>((ref) => ref.watch(databaseProvider).watchRecurrings());

final goalsProvider = StreamProvider<List<SavingsGoal>>((ref) => ref.watch(databaseProvider).watchGoals());

final depositsProvider = StreamProvider<List<GoalDeposit>>((ref) => ref.watch(databaseProvider).watchDeposits());

final fundsProvider = Provider<Funds>(
  (ref) => computeFunds(
    entries: (ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[]).map((e) => e.entry),
    deposits: ref.watch(depositsProvider).value ?? const [],
    asOf: ref.watch(todayProvider),
  ),
);

final dharRecordsProvider = StreamProvider<List<DharRecord>>((ref) => ref.watch(databaseProvider).watchDhar());

final dharPaymentsProvider = StreamProvider<List<DharPayment>>(
  (ref) => ref.watch(databaseProvider).watchDharPayments(),
);

/// How each budget stands this month (the overall one first).
final budgetStatusesProvider = Provider<List<BudgetStatus>>((ref) {
  return computeBudgetStatuses(
    entries: ref.watch(allEntriesProvider).value ?? const [],
    budgets: ref.watch(budgetsProvider).value ?? const [],
    categories: ref.watch(categoriesProvider).value ?? const [],
    now: ref.watch(todayProvider),
  );
});

/// Budgets at 80% or more, for the warnings on Home.
final budgetAlertsProvider = Provider<List<BudgetStatus>>((ref) {
  return ref.watch(budgetStatusesProvider).where((s) => s.level != BudgetLevel.ok).toList();
});

/// Recurring bills and income waiting to be confirmed or skipped.
final dueRecurringsProvider = Provider<List<Recurring>>((ref) {
  return dueRecurrings(ref.watch(recurringsProvider).value ?? const [], ref.watch(todayProvider));
});

final goalProgressProvider = Provider<List<GoalProgress>>((ref) {
  final deposits = ref.watch(depositsProvider).value ?? const <GoalDeposit>[];
  final today = ref.watch(todayProvider);
  final entries = (ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[]).map((e) => e.entry);
  return [
    for (final g in ref.watch(goalsProvider).value ?? const <SavingsGoal>[])
      computeGoalProgress(g, deposits, today, entries: entries),
  ];
});

final dharViewsProvider = Provider<List<DharView>>((ref) {
  return computeDharViews(
    ref.watch(dharRecordsProvider).value ?? const [],
    ref.watch(dharPaymentsProvider).value ?? const [],
  );
});

final dharTotalsProvider = Provider<DharTotals>((ref) => computeDharTotals(ref.watch(dharViewsProvider)));

/// Open dhar entries that are overdue or due within three days.
final dharDueSoonProvider = Provider<List<DharView>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(dharViewsProvider).where((v) => v.isDueSoon(today)).toList();
});

/// Days in a row with something logged or marked "No spending".
final streakProvider = Provider<int>((ref) {
  final days = <String>{
    for (final e in ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[]) e.entry.date,
    ...?ref.watch(noSpendDaysProvider).value,
  };
  return computeStreak(days, ref.watch(todayProvider));
});

/// True once a day has at least one expense or has been marked "No spending today".
final todayHandledProvider = Provider<bool>((ref) {
  final today = dayKey(ref.watch(todayProvider));
  final marked = ref.watch(noSpendDaysProvider).value?.contains(today) ?? false;
  final hasExpense = ref.watch(todayEntriesProvider).any((e) => e.entry.type == EntryType.expense);
  return marked || hasExpense;
});

/// Adds monthly income that has come due and is not in the list yet. Runs when the app
/// starts, when the day changes, and whenever the recurring items change (so a newly set up
/// income appears at once). Safe to repeat: nothing is ever added twice.
final autoIncomeSyncProvider = FutureProvider<int>((ref) async {
  final today = ref.watch(todayProvider);
  ref.watch(recurringsProvider);
  final added = await applyAutoIncome(ref.watch(databaseProvider), today);
  return added.length;
});

/// What the active automatic incomes add up to in a month (poisha).
final monthlyIncomeTotalProvider = Provider<int>((ref) {
  return monthlyIncomeTotal(ref.watch(recurringsProvider).value ?? const <Recurring>[]);
});
