import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entry_tile.dart';
import '../../data/logic/periods.dart';
import '../../data/logic/reports.dart';
import '../../data/providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  PeriodType _type = PeriodType.month;

  /// 0 is the current period, -1 the one before, and so on. You cannot look ahead.
  int _offset = 0;
  int? _selectedBar;

  void _setType(PeriodType type) => setState(() {
        _type = type;
        _offset = 0;
        _selectedBar = null;
      });

  void _move(int delta) => setState(() {
        _offset = (_offset + delta).clamp(-1200, 0);
        _selectedBar = null;
      });

  static String _previousName(PeriodType t) => switch (t) {
        PeriodType.day => 'yesterday',
        PeriodType.week => 'the week before',
        PeriodType.month => 'last month',
        PeriodType.year => 'last year',
      };

  /// How this period compares with the one before it.
  String? _comparison(Report r, DateTime today) {
    if (r.previousExpense <= 0) return null;
    final name = _previousName(r.period.type);
    // A period still in progress would always look smaller, so show the plain total.
    if (r.period.contains(today)) return 'Total $name: ${formatTaka(r.previousExpense)}';
    if (r.expense <= 0) return null;
    final diff = r.expense - r.previousExpense;
    final pct = (diff.abs() / r.previousExpense * 100).round();
    if (pct == 0) return 'About the same as $name';
    return '$pct% ${diff > 0 ? 'more' : 'less'} than $name';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final entries = ref.watch(allEntriesProvider).value ?? const [];
    final deposits = ref.watch(depositsProvider).value ?? const [];

    final period = shiftPeriod(periodFor(_type, today), _offset);
    final report = buildReport(all: entries, deposits: deposits, period: period, now: today);
    final comparison = _comparison(report, today);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PeriodType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: PeriodType.day, label: Text('Day')),
                ButtonSegment(value: PeriodType.week, label: Text('Week')),
                ButtonSegment(value: PeriodType.month, label: Text('Month')),
                ButtonSegment(value: PeriodType.year, label: Text('Year')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => _setType(s.first),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _offset == 0 ? null : () => _move(-_offset),
                  child: Text(
                    periodLabel(period, now: today),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _offset == 0 ? scheme.onSurface : scheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: _offset == 0 ? null : () => _move(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SummaryCard(report: report, comparison: comparison),
          if (report.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: EmptyState(
                icon: Icons.insert_chart_outlined,
                title: 'Nothing in this period',
                message: 'Expenses and income you add will show up here as charts.',
              ),
            )
          else ...[
            const SectionTitle('Where it went'),
            AppCard(child: _CategoryBreakdown(report: report)),
            if (report.period.type == PeriodType.day) ...[
              const SectionTitle('Entries'),
              for (final item in report.entries)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: SwipeToDeleteTile(item: item)),
            ] else ...[
              SectionTitle(switch (report.period.type) {
                PeriodType.week => 'Each day this week',
                PeriodType.month => 'Each day this month',
                _ => 'Each month',
              }),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBar == null
                          ? 'Average per day: ${formatTaka(report.averagePerDay)}'
                          : '${report.bars[_selectedBar!].fullLabel}: ${formatTaka(report.bars[_selectedBar!].amount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: 12),
                    SpendBarChart(
                      bars: report.bars,
                      color: scheme.primary,
                      labelStyle: theme.textTheme.labelSmall!.copyWith(color: colors.muted),
                      selectedIndex: _selectedBar,
                      onSelected: (i) => setState(() => _selectedBar = i),
                      labelEvery: report.period.type == PeriodType.month ? 5 : 1,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report, required this.comparison});

  final Report report;
  final String? comparison;

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
                child: Text(value, style: theme.textTheme.titleMedium?.copyWith(color: on, fontFeatures: tabular)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent', style: theme.textTheme.bodyMedium?.copyWith(color: soft)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatTaka(report.expense),
              style: theme.textTheme.displaySmall?.copyWith(color: on, fontFeatures: tabular),
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 2),
            Text(comparison!, style: theme.textTheme.bodySmall?.copyWith(color: soft)),
          ],
          const SizedBox(height: 16),
          Divider(color: on.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Income', formatTaka(report.income)),
              stat('Balance', formatTaka(report.balance)),
              stat('Saved', formatTaka(report.saved)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The donut and its legend: the biggest categories, with the rest grouped as "Others".
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.report});

  final Report report;

  static const _maxRows = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;

    if (report.byCategory.isEmpty) {
      return Text('No spending in this period.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted));
    }

    final shown = report.byCategory.take(_maxRows - 1).toList();
    final rest = report.byCategory.skip(_maxRows - 1).toList();
    final restAmount = rest.fold<int>(0, (s, c) => s + c.amount);

    final rows = [
      for (final c in shown) (name: c.category.name, color: Color(c.category.colorValue), amount: c.amount, share: c.share),
      if (rest.isNotEmpty)
        (name: 'Others', color: Colors.blueGrey, amount: restAmount, share: restAmount / report.expense),
    ];

    return Column(
      children: [
        DonutChart(
          slices: [for (final r in rows) DonutSlice(value: r.amount.toDouble(), color: r.color)],
          trackColor: theme.colorScheme.outlineVariant,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Spent', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
              Text(formatTaka(report.expense), style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: r.color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(
                  formatTaka(r.amount),
                  style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(r.share * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
