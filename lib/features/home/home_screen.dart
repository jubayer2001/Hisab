import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entry_tile.dart';
import '../../data/providers.dart';
import '../../data/summary.dart';
import '../add_entry/entry_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final summary = ref.watch(summaryProvider);
    final todayEntries = ref.watch(todayEntriesProvider);
    final quickAdds = ref.watch(quickAddsProvider);
    final handled = ref.watch(todayHandledProvider);
    final noSpendDays = ref.watch(noSpendDaysProvider).value ?? const <String>{};
    final markedNoSpend = noSpendDays.contains(dayKey(today));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(today),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(_greeting(DateTime.now()), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            _SummaryCard(summary: summary),
            if (quickAdds.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Quick add', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in quickAdds)
                    ActionChip(
                      avatar: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
                      label: Text('${q.label} ${formatTaka(q.amountPoisha)}'),
                      onPressed: () => addQuickEntry(context, ref, q),
                    ),
                ],
              ),
            ],
            if (!handled || markedNoSpend) ...[
              const SizedBox(height: 16),
              _NoSpendCard(marked: markedNoSpend, date: dayKey(today)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text('Today', style: theme.textTheme.titleMedium)),
                TextButton(onPressed: () => context.go('/history'), child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 4),
            if (todayEntries.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing added today',
                message: 'Tap the + button below to add an expense or income.',
              )
            else
              for (final item in todayEntries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SwipeToDeleteTile(item: item),
                ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final soft = on.withValues(alpha: 0.82);
    const tabular = [FontFeature.tabularFigures()];

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: soft)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(color: on, fontFeatures: tabular),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent today', style: theme.textTheme.bodyMedium?.copyWith(color: soft)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatTaka(summary.todayExpense),
              style: theme.textTheme.displaySmall?.copyWith(color: on, fontFeatures: tabular),
            ),
          ),
          if (summary.todayIncome > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+${formatTaka(summary.todayIncome)} income today',
              style: theme.textTheme.bodySmall?.copyWith(color: soft),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: on.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Spent this month', formatTaka(summary.monthExpense)),
              stat('Income', formatTaka(summary.monthIncome)),
              stat('Balance', formatTaka(summary.monthBalance)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoSpendCard extends ConsumerWidget {
  const _NoSpendCard({required this.marked, required this.date});

  final bool marked;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final db = ref.read(databaseProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(
            marked ? Icons.check_circle_rounded : Icons.wallet_outlined,
            color: marked ? colors.income : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              marked ? 'Marked as no spending today' : 'Nothing spent today?',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => db.setNoSpend(date, !marked),
            child: Text(marked ? 'Undo' : 'No spending'),
          ),
        ],
      ),
    );
  }
}
