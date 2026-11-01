import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/db/app_database.dart';
import '../../data/logic/budgets.dart';
import '../../data/providers.dart';
import '../../data/summary.dart';

/// Asks "Delete this entry?" before a single expense or income is deleted. True only if the
/// person pressed the red Delete button. Undo is still offered afterwards.
Future<bool> confirmDeleteEntry(BuildContext context, EntryWithCategory item) {
  return confirmDestructive(
    context,
    title: 'Delete this entry?',
    message: '${formatTaka(item.entry.amountPoisha)} · ${item.category.name} will be deleted. '
        'You can undo it right after.',
  );
}

/// The same question for several entries at once.
Future<bool> confirmDeleteEntries(BuildContext context, int count) {
  return confirmDestructive(
    context,
    title: count == 1 ? 'Delete 1 entry?' : 'Delete $count entries?',
    message: count == 1
        ? 'This entry will be deleted. You can undo it right after.'
        : 'These $count entries will be deleted. You can undo it right after.',
  );
}

/// Deletes an entry and offers "Undo" for a few seconds. Callers ask first with
/// [confirmDeleteEntry].
Future<void> deleteEntryWithUndo(BuildContext context, WidgetRef ref, EntryWithCategory item) async {
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  await db.deleteEntry(item.entry.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Deleted ${formatTaka(item.entry.amountPoisha)} · ${item.category.name}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreEntry(item.entry)),
      ),
    );
}

/// Deletes several entries at once and offers one "Undo" that brings them all back.
Future<void> deleteEntriesWithUndo(BuildContext context, WidgetRef ref, List<EntryWithCategory> items) async {
  if (items.isEmpty) return;
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  final removed = [for (final i in items) i.entry];
  await db.deleteEntries(removed.map((e) => e.id));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(removed.length == 1 ? 'Deleted 1 entry' : 'Deleted ${removed.length} entries'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreEntries(removed)),
      ),
    );
}

/// A budget warning to show after saving an expense, such as "Food budget 85% used", or null.
///
/// This reads the current totals straight from the database. It must not use the budget
/// providers: Riverpod pauses a screen's providers while it is hidden behind another tab,
/// and the + button works from every tab, so they could be out of date.
Future<String?> budgetWarning(
  WidgetRef ref, {
  required String type,
  required int categoryId,
  required int amountPoisha,
}) async {
  if (type != 'expense') return null;
  final db = ref.read(databaseProvider);
  final statuses = computeBudgetStatuses(
    entries: await db.watchEntries().first,
    budgets: await db.watchBudgets().first,
    categories: await db.watchCategories().first,
    now: ref.read(todayProvider),
  );
  return budgetWarningAfterAdding(statuses, categoryId: categoryId, addedPoisha: amountPoisha);
}

/// One-tap add for a repeat expense (the "Quick add" chips on Home).
Future<void> addQuickEntry(BuildContext context, WidgetRef ref, QuickAdd quick) async {
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  final warning = await budgetWarning(
    ref,
    type: 'expense',
    categoryId: quick.category.id,
    amountPoisha: quick.amountPoisha,
  );
  final id = await db.addEntry(
    type: 'expense',
    amountPoisha: quick.amountPoisha,
    categoryId: quick.category.id,
    note: quick.note,
    date: dayKey(ref.read(todayProvider)),
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Added ${quick.label} ${formatTaka(quick.amountPoisha)}${warning == null ? '' : '\n$warning'}',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.deleteEntry(id)),
      ),
    );
}
