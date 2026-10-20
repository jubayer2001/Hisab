import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;

import '../../core/dates.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'planning.dart';

/// The most months an automatic income is filled in for at once (two years). A phone left
/// untouched for longer than that is not silently given dozens of entries.
const maxAutoIncomeMonths = 24;

/// "yyyy-MM" → the first day of that month, or null if it is not that shape.
DateTime? _monthStart(String? key) {
  if (key == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final month = int.parse(m.group(2)!);
  if (month < 1 || month > 12) return null;
  return DateTime(int.parse(m.group(1)!), month, 1);
}

/// The months (each as the 1st of the month) an automatic [item] still has to be added for,
/// oldest first, up to and including this month once its day has come.
///
/// A month is skipped once it has been handled, whether it was added, removed or skipped, so
/// running this twice never adds anything twice.
List<DateTime> pendingAutoIncomeMonths(Recurring item, DateTime today) {
  if (!item.autoAdd || !item.isActive || item.type != EntryType.income) return const [];

  final thisMonth = DateTime(today.year, today.month, 1);
  var first = _monthStart(item.startMonth) ?? thisMonth;
  final handled = _monthStart(item.lastHandledMonth);
  if (handled != null) {
    final next = DateTime(handled.year, handled.month + 1, 1);
    if (next.isAfter(first)) first = next;
  }

  final months = <DateTime>[];
  for (var m = first; !m.isAfter(thisMonth); m = DateTime(m.year, m.month + 1, 1)) {
    // This month's income is only added once its day has come.
    if (m == thisMonth && dateOnly(today).isBefore(recurringDueDate(item, today))) continue;
    months.add(m);
  }
  return months.length > maxAutoIncomeMonths ? months.sublist(months.length - maxAutoIncomeMonths) : months;
}

/// Adds the entries for every automatic income that is due and was not added yet. Returns
/// the entries it added (usually none). Safe to run as often as you like.
Future<List<Entry>> applyAutoIncome(AppDatabase db, DateTime today) async {
  final added = <Entry>[];
  await db.transaction(() async {
    final items = await (db.select(db.recurrings)
          ..where((r) => r.autoAdd.equals(true) & r.isActive.equals(true) & r.type.equals(EntryType.income)))
        .get();
    for (final item in items) {
      final months = pendingAutoIncomeMonths(item, today);
      if (months.isEmpty) continue;
      for (final month in months) {
        final due = recurringDueDate(item, month);
        final id = await db.addEntry(
          type: EntryType.income,
          amountPoisha: item.amountPoisha,
          categoryId: item.categoryId,
          date: dayKey(due),
          note: item.title,
        );
        await (db.update(db.entries)..where((e) => e.id.equals(id))).write(EntriesCompanion(recurringId: Value(item.id)));
        added.add(await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle());
      }
      await db.markRecurringHandled(item.id, monthKey(months.last));
    }
  });
  return added;
}

/// Sets up a monthly income that records itself, and adds this month's entry if it should
/// already exist.
///
/// [receivedThisMonth] says whether this month's money counts: if true, this month's entry is
/// added now (on its day if that has come, otherwise today); if false, the first entry is next
/// month's, so nothing is added for a pay day that has not happened or was missed.
Future<int> createMonthlyIncome(
  AppDatabase db,
  DateTime today, {
  required String title,
  required int amountPoisha,
  required int categoryId,
  required int dayOfMonth,
  required bool receivedThisMonth,
}) async {
  final thisMonth = DateTime(today.year, today.month, 1);
  final start = receivedThisMonth ? thisMonth : DateTime(today.year, today.month + 1, 1);
  final id = await db.addRecurring(
    title: title,
    type: EntryType.income,
    amountPoisha: amountPoisha,
    categoryId: categoryId,
    dayOfMonth: dayOfMonth,
    autoAdd: true,
    startMonth: monthKey(start),
  );

  if (receivedThisMonth) {
    final item = (await db.select(db.recurrings).get()).firstWhere((r) => r.id == id);
    if (dateOnly(today).isBefore(recurringDueDate(item, today))) {
      // Received early: it counts today, and the engine must not add it again on its day.
      final entryId = await db.addEntry(
        type: EntryType.income,
        amountPoisha: amountPoisha,
        categoryId: categoryId,
        date: dayKey(today),
        note: title,
      );
      await (db.update(db.entries)..where((e) => e.id.equals(entryId))).write(EntriesCompanion(recurringId: Value(id)));
      await db.markRecurringHandled(id, monthKey(today));
    }
  }
  await applyAutoIncome(db, today);
  return id;
}

/// What all the active automatic incomes add up to in a month, in poisha.
int monthlyIncomeTotal(Iterable<Recurring> items) => items
    .where((r) => r.autoAdd && r.isActive && r.type == EntryType.income)
    .fold(0, (sum, r) => sum + r.amountPoisha);
