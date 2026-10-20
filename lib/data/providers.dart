import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import 'db/app_database.dart';
import 'db/tables.dart';
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

final allEntriesProvider = StreamProvider<List<EntryWithCategory>>(
  (ref) => ref.watch(databaseProvider).watchEntries(),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(databaseProvider).watchCategories(),
);

/// Categories you can pick from for a given type (hides archived ones).
final pickableCategoriesProvider = Provider.family<List<Category>, String>((ref, type) {
  final all = ref.watch(categoriesProvider).value ?? const <Category>[];
  return all.where((c) => c.type == type && !c.isArchived).toList();
});

final noSpendDaysProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(databaseProvider).watchNoSpendDays(),
);

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

/// True once a day has at least one expense or has been marked "No spending today".
final todayHandledProvider = Provider<bool>((ref) {
  final today = dayKey(ref.watch(todayProvider));
  final marked = ref.watch(noSpendDaysProvider).value?.contains(today) ?? false;
  final hasExpense = ref.watch(todayEntriesProvider).any((e) => e.entry.type == EntryType.expense);
  return marked || hasExpense;
});
