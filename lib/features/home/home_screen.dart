import 'package:flutter/material.dart' hide Text;
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
import '../../core/widgets/summary_stats.dart';
import '../../data/db/app_database.dart' show Recurring;
import '../account/backup_nudge.dart';
import '../../data/logic/budgets.dart';
import '../../data/logic/home_logic.dart';
import '../../data/logic/planning.dart';
import '../../data/providers.dart';
import '../../data/summary.dart';
import '../add_entry/entry_actions.dart';
import '../income/income_widgets.dart';
import '../goals/funds_sheet.dart';
import '../recurring/due_bills.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text.dart';

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
    final overall = ref.watch(budgetStatusesProvider).where((s) => s.isOverall).firstOrNull;
    final alerts = ref.watch(budgetAlertsProvider);
    final dharDue = ref.watch(dharDueSoonProvider);
    final name = ref.watch(userNameProvider);
    final notices = ref.watch(homeNoticesProvider);
    final goals = orderGoalsForHome(ref.watch(goalProgressProvider));
    final slot = computeHomeSlot(
      choice: ref.watch(homeDetailProvider),
      overall: overall,
      weekExpense: ref.watch(weekExpenseProvider),
      monthExpense: summary.monthExpense,
      recurrings: ref.watch(recurringsProvider).value ?? const <Recurring>[],
      today: today,
      showBudgetWarnings: notices.shows(HomeNotice.budget),
    );
    final slotRoute = slot?.route;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // The date and the language button share a line, so the greeting below has the full width.
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM').format(today),
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const _LanguageButton(),
                const SizedBox(width: 10),
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
            if (notices.shows(HomeNotice.backup) && ref.watch(showCloudNudgeProvider)) ...[
              const BackupNudge(),
              const SizedBox(height: 12),
            ],
            if (notices.shows(HomeNotice.income)) const IncomeNotes(),
            _SummaryCard(
              summary: summary,
              budget: overall,
              slot: slot,
              onSlotTap: slotRoute == null ? null : () => context.push(slotRoute),
              onIncomeTap: () => showIncomeBreakdown(context),
              onBalanceTap: () => showFundsSheet(context, title: 'Balance'),
            ),
            if (notices.shows(HomeNotice.budget))
              for (final alert in alerts.take(2))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _BudgetAlert(status: alert),
                ),
            if (notices.shows(HomeNotice.bills)) const DueBillsSection(),
            if (notices.shows(HomeNotice.bills) && dharDue.isNotEmpty)
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
            if (goals.isNotEmpty) _GoalsSection(goals: goals),
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
              _NoSpendCard(
                marked: markedNoSpend,
                date: dayKey(today),
                spentToday: todayEntries.any((e) => e.isExpense),
              ),
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

/// One tap switches the whole app between English and Bengali. It names the other language,
/// so it is clear what will happen: it says বাংলা while the app is in English, and English while
/// the app is in Bengali.
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bengali = ref.watch(languageProvider) == AppLanguage.bn;
    final color = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: bengali ? 'Switch to English' : 'বাংলায় দেখুন',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => ref.read(languageProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded, size: 20, color: color),
                const SizedBox(width: 6),
                Text(
                  bengali ? 'English' : 'বাংলা',
                  style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.budget,
    required this.slot,
    required this.onSlotTap,
    required this.onIncomeTap,
    required this.onBalanceTap,
  });

  final Summary summary;
  final BudgetStatus? budget;

  /// The one useful thing shown beside "Spent today", if there is one.
  final HomeSlot? slot;
  final VoidCallback? onSlotTap;

  /// Tapping the Income figure shows where it came from.
  final VoidCallback onIncomeTap;
  final VoidCallback onBalanceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final soft = on.withValues(alpha: 0.82);
    const tabular = [FontFeature.tabularFigures()];

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
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final today = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                ],
              );
              final s = slot;
              if (s == null) return Align(alignment: Alignment.centerLeft, child: today);
              final narrow = constraints.maxWidth < SummaryStats.columnsFrom;
              final chip = _SlotChip(slot: s, onTap: onSlotTap, fillWidth: narrow);
              // Narrow card: the chip goes under the amount as a full-width row. Otherwise it sits at
              // the right of the amount, and drops below it only when the amount is too long to share.
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [today, const SizedBox(height: 10), chip],
                );
              }
              // Full width, so the chip sits at the right edge of the card (without it the Wrap would
              // only be as wide as its contents and the chip would hug the amount).
              return SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runAlignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [today, chip],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: on.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 14),
          SummaryStats(
            stats: [
              SummaryStat('Spent this month', formatTaka(summary.monthExpense)),
              SummaryStat('Income', formatTaka(summary.monthIncome), onTap: onIncomeTap),
              SummaryStat('Balance', formatTaka(summary.balance), onTap: onBalanceTap),
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
  const _NoSpendCard({required this.marked, required this.date, required this.spentToday});

  final bool marked;
  final String date;

  /// Something was already spent today, so a marked day means "no more spending", not "none".
  final bool spentToday;

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
              marked ? (spentToday ? 'No more spending today' : 'Marked as no spending today') : 'Nothing spent today?',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: () => db.setNoSpend(date, !marked), child: Text(marked ? 'Undo' : 'No spending')),
        ],
      ),
    );
  }
}

/// The small block beside "Spent today": a label and one figure, tinted for budget warnings.
class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.onTap,
    required this.fillWidth,
  });

  final HomeSlot slot;
  final VoidCallback? onTap;

  /// On a narrow card the chip becomes a full-width row (label left, figure right).
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final on = theme.colorScheme.onPrimary;

    // On the teal card the usual red would be hard to read, so warnings use soft tones in
    // light mode and deeper ones in dark mode, where the card itself is pale.
    final (Color background, Color? figure) = switch (slot.kind) {
      HomeSlotKind.warning =>
        dark
            ? (
                const Color(0xFF784600).withValues(alpha: 0.16),
                const Color(0xFF6B3F00),
              )
            : (
                const Color(0xFFFFD27A).withValues(alpha: 0.24),
                const Color(0xFFFFD27A),
              ),
      HomeSlotKind.over =>
        dark
            ? (
                const Color(0xFF8C2819).withValues(alpha: 0.14),
                const Color(0xFF8A2A1D),
              )
            : (
                const Color(0xFFFFB4A8).withValues(alpha: 0.26),
                const Color(0xFFFFB4A8),
              ),
      _ => (on.withValues(alpha: dark ? 0.12 : 0.16), null),
    };

    final label = Text(
      slot.label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: on.withValues(alpha: 0.85),
      ),
    );
    // A very large figure shrinks to fit instead of overflowing.
    final value = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        slot.value,
        style: theme.textTheme.titleMedium?.copyWith(
          color: figure ?? on,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: '${slot.label}: ${slot.value}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: fillWidth
                ? Row(
                    children: [
                      Flexible(child: label),
                      const SizedBox(width: 12),
                      Expanded(child: value),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [label, value],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Savings goals on Home: shown only once a goal exists. Two at a time, the nearest
/// deadline first; the rest are one tap away.
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals});

  final List<GoalProgress> goals;

  static const _shown = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final more = goals.length - _shown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Savings goals', style: theme.textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () => context.push('/goals'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final g in goals.take(_shown))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GoalCard(progress: g),
          ),
        if (more > 0)
          Center(
            child: TextButton(
              onPressed: () => context.push('/goals'),
              child: Text(
                '+$more more ${more == 1 ? 'goal' : 'goals'} · See all',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final g = progress;
    final goalColor = Color(g.goal.colorValue);
    final deadline = g.goal.deadline;

    final months = g.monthsLeft;
    final detail = StringBuffer('${formatTaka(g.saved)} of ${formatTaka(g.target)}');
    if (!g.isDone && months != null && months > 0) {
      detail.write(' · $months ${months == 1 ? 'month' : 'months'} left');
    }

    final String footnote;
    var footnoteColor = colors.muted;
    if (g.isDone) {
      footnote = 'You reached your target';
    } else if (g.isOverdue) {
      footnote = 'Deadline passed · ${formatTaka(g.remaining)} still to go';
      footnoteColor = colors.spending;
    } else if (deadline != null && g.monthlyNeeded != null) {
      footnote =
          'Set aside ${formatTaka(g.monthlyNeeded!)} a month to finish by ${DateFormat('MMM y').format(parseDayKey(deadline))}';
    } else {
      footnote = 'No deadline set';
    }

    return AppCard(
      onTap: () => context.push('/goals'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: g.isDone
          ? Color.alphaBlend(colors.income.withValues(alpha: 0.12), colors.card)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: goalColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      detail.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (g.isDone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colors.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reached',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.income,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${(g.fraction * 100).floor()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: g.fraction,
              minHeight: 6,
              color: g.isDone ? colors.income : goalColor,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footnote,
            style: theme.textTheme.bodySmall?.copyWith(color: footnoteColor),
          ),
        ],
      ),
    );
  }
}
