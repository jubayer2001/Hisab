import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/app_card.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/logic/planning.dart';
import '../../data/providers.dart';
import 'recurring_screen.dart';

/// Home cards for recurring bills and income that are due: one tap to add, or skip this month.
class DueBillsSection extends ConsumerWidget {
  const DueBillsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueRecurringsProvider);
    if (due.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final categories = {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c};
    final db = ref.read(databaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Due'),
        for (final r in due)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(categories[r.categoryId]?.colorValue ?? 0xFF94A3A0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconForKey(categories[r.categoryId]?.iconKey ?? 'dots'), color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${formatTaka(r.amountPoisha)} · ${_dueText(recurringDueDate(r, today), today)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await db.markRecurringHandled(r.id, monthKey(today));
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('Skipped ${r.title} for this month')));
                    },
                    child: const Text('Skip'),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                    onPressed: () => showConfirmRecurring(context, r),
                    child: Text(r.type == EntryType.income ? 'Received' : 'Add'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _dueText(DateTime due, DateTime today) {
    if (due == dateOnly(today)) return 'due today';
    return 'due ${DateFormat('d MMM').format(due)}';
  }
}
