import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/entry_tile.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/logic/periods.dart';
import '../../data/providers.dart';
import '../add_entry/add_entry_sheet.dart';
import '../../l10n/text.dart';

/// Every expense in [categoryIds] for [period], opened from the Reports donut or its legend.
/// "Others" passes all the categories it groups together.
Future<void> showCategorySpendingSheet(
  BuildContext context, {
  required String name,
  required Color color,
  required IconData icon,
  required Set<int> categoryIds,
  required Period period,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => _CategorySpendingSheet(
      name: name,
      color: color,
      icon: icon,
      categoryIds: categoryIds,
      period: period,
      onClose: () => Navigator.pop(sheetContext),
    ),
  );
}

class _CategorySpendingSheet extends ConsumerWidget {
  const _CategorySpendingSheet({
    required this.name,
    required this.color,
    required this.icon,
    required this.categoryIds,
    required this.period,
    required this.onClose,
  });

  final String name;
  final Color color;
  final IconData icon;
  final Set<int> categoryIds;
  final Period period;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final todayKey = dayKey(today);

    // The same rule the report itself uses: expenses inside the period, none dated in the future.
    final inPeriod = [
      for (final e
          in ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[])
        if (e.isExpense &&
            period.containsKey(e.entry.date) &&
            e.entry.date.compareTo(todayKey) <= 0)
          e,
    ];
    final items =
        [
          for (final e in inPeriod)
            if (categoryIds.contains(e.category.id)) e,
        ]..sort((a, b) {
          final byDay = b.entry.date.compareTo(a.entry.date);
          return byDay != 0 ? byDay : b.entry.id.compareTo(a.entry.id);
        });

    final total = items.fold<int>(0, (s, e) => s + e.entry.amountPoisha);
    final periodTotal = inPeriod.fold<int>(
      0,
      (s, e) => s + e.entry.amountPoisha,
    );
    final share = periodTotal == 0 ? 0 : (total / periodTotal * 100).round();

    // Group by day, newest first, with each day's total.
    final days = <String, List<EntryWithCategory>>{};
    for (final e in items) {
      days.putIfAbsent(e.entry.date, () => []).add(e);
    }

    return SheetScaffold(
      footer: FilledButton.tonal(
        onPressed: onClose,
        child: const Text('Close'),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      '${periodLabel(period, now: today)} · ${items.length} ${items.length == 1 ? 'entry' : 'entries'} · $share% of spending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTaka(total),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.spending,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Nothing spent here in this period.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          ),
        for (final day in days.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    friendlyDay(parseDayKey(day.key), now: today),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ),
                Text(
                  formatTaka(
                    day.value.fold<int>(0, (s, e) => s + e.entry.amountPoisha),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          for (final e in day.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryTile(
                item: e,
                onTap: () => showAddEntrySheet(context, editing: e),
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
