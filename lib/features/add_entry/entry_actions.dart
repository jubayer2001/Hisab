import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/summary.dart';

/// Deletes an entry and offers "Undo" for a few seconds instead of a confirm dialog.
Future<void> deleteEntryWithUndo(BuildContext context, WidgetRef ref, EntryWithCategory item) async {
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  await db.deleteEntry(item.entry.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Deleted ${formatTaka(item.entry.amountPoisha)} · ${item.category.name}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreEntry(item.entry)),
      ),
    );
}

/// One-tap add for a repeat expense (the "Quick add" chips on Home).
Future<void> addQuickEntry(BuildContext context, WidgetRef ref, QuickAdd quick) async {
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
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
        content: Text('Added ${quick.label} ${formatTaka(quick.amountPoisha)}'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.deleteEntry(id)),
      ),
    );
}
