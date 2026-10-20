import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/level_bar.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/tables.dart';
import '../../data/logic/budgets.dart';
import '../../data/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static String _levelText(BudgetStatus s) {
    switch (s.level) {
      case BudgetLevel.ok:
        return '${(s.fraction * 100).floor()}% used';
      case BudgetLevel.warning:
        return '${(s.fraction * 100).floor()}% used, nearly there';
      case BudgetLevel.over:
        return 'Over budget';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final statuses = ref.watch(budgetStatusesProvider);
    final overall = statuses.where((s) => s.isOverall).firstOrNull;
    final byCategory = statuses.where((s) => !s.isOverall).toList();
    final daysLeft = DateTime(today.year, today.month + 1, 0).day - today.day + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBudgetEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Category budget'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          if (overall == null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly budget', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Set how much you want to spend each month and Hisab will show how much is left.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => showBudgetEditor(context, overall: true),
                    child: const Text('Set monthly budget'),
                  ),
                ],
              ),
            )
          else
            AppCard(
              onTap: () => showBudgetEditor(context, existing: overall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('This month', style: theme.textTheme.titleMedium)),
                      Text(
                        _levelText(overall),
                        style: theme.textTheme.bodySmall?.copyWith(color: budgetLevelColor(context, overall.level)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overall.remaining >= 0
                        ? '${formatTaka(overall.remaining)} left'
                        : '${formatTaka(-overall.remaining)} over',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: overall.remaining >= 0 ? null : colors.spending,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Spent ${formatTaka(overall.spent)} of ${formatTaka(overall.limit)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(fraction: overall.fraction, color: budgetLevelColor(context, overall.level), height: 10),
                  if (overall.remaining > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      daysLeft <= 1
                          ? 'Last day of the month'
                          // Whole Taka, rounded down, so the daily figure is never over-promised.
                          : 'About ${formatTaka((overall.remaining ~/ daysLeft) ~/ 100 * 100)} a day for the next $daysLeft days',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
          const SectionTitle('By category'),
          if (byCategory.isEmpty)
            Text(
              'Limit a category that tends to run away, like Food or Shopping. Tap "Category budget" to add one.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            )
          else
            for (final s in byCategory)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => showBudgetEditor(context, existing: s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(s.category!.colorValue),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(iconForKey(s.category!.iconKey), color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s.name, style: theme.textTheme.titleMedium)),
                          Text(
                            '${formatTaka(s.spent)} / ${formatTaka(s.limit)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ProgressBar(fraction: s.fraction, color: budgetLevelColor(context, s.level)),
                      const SizedBox(height: 6),
                      Text(
                        s.remaining >= 0
                            ? '${formatTaka(s.remaining)} left · ${_levelText(s)}'
                            : '${formatTaka(-s.remaining)} over',
                        style: theme.textTheme.bodySmall?.copyWith(color: budgetLevelColor(context, s.level)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Opens the budget sheet. Pass [existing] to edit, [overall] to create the monthly
/// budget, or neither to create a category budget.
Future<void> showBudgetEditor(BuildContext context, {BudgetStatus? existing, bool overall = false}) {
  return showAppSheet<void>(context, builder: (_) => _BudgetEditor(existing: existing, overall: overall));
}

class _BudgetEditor extends ConsumerStatefulWidget {
  const _BudgetEditor({this.existing, this.overall = false});

  final BudgetStatus? existing;
  final bool overall;

  @override
  ConsumerState<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<_BudgetEditor> {
  final _amount = TextEditingController();
  int? _categoryId;

  bool get _isOverall => widget.overall || (widget.existing?.isOverall ?? false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amount.text = amountToText(e.limit);
      _categoryId = e.budget.categoryId;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  bool get _canSave => readAmount(_amount) != null && (_isOverall || _categoryId != null);

  Future<void> _save() async {
    final amount = readAmount(_amount);
    if (amount == null) return;
    await ref.read(databaseProvider).setBudget(categoryId: _isOverall ? null : _categoryId, amountPoisha: amount);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(databaseProvider).removeBudget(widget.existing!.budget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final existing = widget.existing;

    // When adding, offer only expense categories that have no budget yet.
    final taken = {for (final s in ref.watch(budgetStatusesProvider)) s.budget.categoryId};
    final choices = existing?.category != null
        ? [existing!.category!]
        : ref.watch(pickableCategoriesProvider(EntryType.expense)).where((c) => !taken.contains(c.id)).toList();

    return SheetScaffold(
      footer: FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      children: [
        SheetHeader(
          _isOverall
              ? 'Monthly budget'
              : existing == null
                  ? 'New category budget'
                  : '${existing.name} budget',
          trailing: existing == null
              ? null
              : IconButton(
                  tooltip: 'Remove budget',
                  onPressed: _remove,
                  icon: Icon(Icons.delete_outline_rounded, color: colors.spending),
                ),
        ),
        if (!_isOverall) ...[
          if (choices.isEmpty)
            Text(
              'Every category already has a budget.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            )
          else
            CategoryChips(
              categories: choices,
              selectedId: _categoryId,
              onSelected: existing != null ? (_) {} : (id) => setState(() => _categoryId = id),
            ),
          const SizedBox(height: 16),
        ],
        AmountField(
          controller: _amount,
          label: _isOverall ? 'Spend at most, each month' : 'Limit for this category, each month',
          autofocus: existing == null && _isOverall,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'It applies to every month. Hisab warns you when you reach 80%.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
