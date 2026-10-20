import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/profile_providers.dart';
import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entry_tile.dart';
import '../../core/widgets/level_bar.dart';
import '../../core/widgets/profile_avatar.dart';
import '../account/backup_nudge.dart';
import '../../data/logic/budgets.dart';
import '../../data/providers.dart';
import '../../data/summary.dart';
import '../add_entry/entry_actions.dart';
import '../income/income_widgets.dart';
import '../recurring/due_bills.dart';

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
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final summary = ref.watch(summaryProvider);
    final todayEntries = ref.watch(todayEntriesProvider);
    final quickAdds = ref.watch(quickAddsProvider);
    final handled = ref.watch(todayHandledProvider);
    final noSpendDays = ref.watch(noSpendDaysProvider).value ?? const <String>{};
    final markedNoSpend = noSpendDays.contains(dayKey(today));
    final streak = ref.watch(streakProvider);
    final overall = ref.watch(budgetStatusesProvider).where((s) => s.isOverall).firstOrNull;
    final alerts = ref.watch(budgetAlertsProvider);
    final dharDue = ref.watch(dharDueSoonProvider);
    final name = ref.watch(userNameProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // The date and the streak share a line, so the greeting below has the full width.
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM').format(today),
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                if (streak > 0) ...[
                  _StreakChip(days: streak),
                  const SizedBox(width: 10),
                ],
                const ProfileAvatar(),
              ],
            ),
            Text(
              name.isEmpty ? _greeting(DateTime.now()) : '${_greeting(DateTime.now())}, $name',
              style: theme.textTheme.headlineMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (ref.watch(showCloudNudgeProvider)) ...[
              const BackupNudge(),
              const SizedBox(height: 12),
            ],
            const IncomeNotes(),
            _SummaryCard(summary: summary, budget: overall, onIncomeTap: () => showIncomeBreakdown(context)),
            for (final alert in alerts.take(2))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _BudgetAlert(status: alert),
              ),
            const DueBillsSection(),
            if (dharDue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AppCard(
                  onTap: () => context.push('/dhar'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Icon(Icons.handshake_outlined, color: colors.highlight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dharDue.length == 1
                              ? 'Dhar due: ${dharDue.first.record.person}'
                              : '${dharDue.length} dhar entries are due',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
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

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: colors.highlight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 18, color: colors.highlight),
          const SizedBox(width: 4),
          Text(
            days == 1 ? '1 day' : '$days days',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.budget, required this.onIncomeTap});

  final Summary summary;
  final BudgetStatus? budget;

  /// Tapping the Income figure shows where it came from.
  final VoidCallback onIncomeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final soft = on.withValues(alpha: 0.82);
    const tabular = [FontFeature.tabularFigures()];

    Widget stat(String label, String value, {VoidCallback? onTap}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
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
          ),
        );

    final b = budget;
    // On the teal card the usual red would be hard to read, so "over" uses a soft coral.
    final barColor = b == null
        ? on
        : switch (b.level) {
            BudgetLevel.ok => on,
            BudgetLevel.warning => const Color(0xFFFFD27A),
            BudgetLevel.over => const Color(0xFFFFB4A8),
          };

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
              stat('Income', formatTaka(summary.monthIncome), onTap: onIncomeTap),
              stat('Balance', formatTaka(summary.monthBalance)),
            ],
          ),
          if (b != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: b.fraction.clamp(0.0, 1.0),
                minHeight: 8,
                color: barColor,
                backgroundColor: on.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              b.remaining >= 0
                  ? '${formatTaka(b.remaining)} left of ${formatTaka(b.limit)} budget'
                  : '${formatTaka(-b.remaining)} over your ${formatTaka(b.limit)} budget',
              style: theme.textTheme.bodySmall?.copyWith(color: soft),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetAlert extends StatelessWidget {
  const _BudgetAlert({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = status.level == BudgetLevel.over;
    final color = budgetLevelColor(context, status.level);
    final what = status.isOverall ? 'monthly budget' : '${status.name} budget';

    return AppCard(
      onTap: () => context.push('/budgets'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(over ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              over ? 'Over your $what' : 'Your $what is ${(status.fraction * 100).floor()}% used',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
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

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
