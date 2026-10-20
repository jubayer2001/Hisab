import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/level_bar.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/logic/planning.dart';
import '../../data/providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: goals.isEmpty
          ? const EmptyState(
              icon: Icons.savings_outlined,
              title: 'No savings goals yet',
              message: 'Save for something, like "Eid shopping ৳10,000 by March". Money you put into a goal counts as saved, not spent.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                for (final g in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GoalCard(progress: g),
                  ),
              ],
            ),
    );
  }
}

String goalDeadlineText(GoalProgress p) {
  if (p.isDone) return 'Goal reached';
  final deadline = p.goal.deadline;
  if (deadline == null) return 'No deadline';
  final date = DateFormat('d MMM y').format(parseDayKey(deadline));
  if (p.isOverdue) return 'Deadline passed ($date)';
  final monthly = p.monthlyNeeded;
  return monthly == null ? 'By $date' : 'By $date · save ${formatTaka(monthly)} a month';
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final color = Color(progress.goal.colorValue);
    final deadlineColor = progress.isDone
        ? colors.income
        : progress.isOverdue
            ? colors.spending
            : colors.muted;

    return AppCard(
      onTap: () => showGoalDetail(context, progress.goal.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(progress.isDone ? Icons.check_rounded : Icons.savings_rounded, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(progress.goal.name, style: theme.textTheme.titleMedium)),
              Text('${(progress.fraction * 100).floor()}%', style: theme.textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(fraction: progress.fraction, color: color, height: 10),
          const SizedBox(height: 8),
          Text(
            '${formatTaka(progress.saved)} of ${formatTaka(progress.target)}',
            style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Text(goalDeadlineText(progress), style: theme.textTheme.bodySmall?.copyWith(color: deadlineColor)),
        ],
      ),
    );
  }
}

// ---- Detail ---------------------------------------------------------------

Future<void> showGoalDetail(BuildContext context, int goalId) {
  return showAppSheet<void>(context, builder: (_) => _GoalDetail(goalId: goalId));
}

class _GoalDetail extends ConsumerStatefulWidget {
  const _GoalDetail({required this.goalId});

  final int goalId;

  @override
  ConsumerState<_GoalDetail> createState() => _GoalDetailState();
}

class _GoalDetailState extends ConsumerState<_GoalDetail> {
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final progress = ref.watch(goalProgressProvider).where((p) => p.goal.id == widget.goalId).firstOrNull;
    if (progress == null) return const SizedBox(height: 120);

    final color = Color(progress.goal.colorValue);
    final deposits = (ref.watch(depositsProvider).value ?? const <GoalDeposit>[])
        .where((d) => d.goalId == widget.goalId)
        .take(6)
        .toList();
    final db = ref.read(databaseProvider);

    return SheetScaffold(
      children: [
        SheetHeader(
          progress.goal.name,
          trailing: IconButton(
            tooltip: 'Edit goal',
            onPressed: () => showGoalEditor(context, existing: progress.goal),
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        Text(
          formatTaka(progress.saved),
          style: theme.textTheme.displaySmall?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        Text(
          'of ${formatTaka(progress.target)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 10),
        ProgressBar(fraction: progress.fraction, color: color, height: 10),
        const SizedBox(height: 8),
        Text(goalDeadlineText(progress), style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _showMoneySheet(context, progress, withdraw: false),
                child: const Text('Add money'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                onPressed: progress.saved <= 0 ? null : () => _showMoneySheet(context, progress, withdraw: true),
                child: const Text('Take out'),
              ),
            ),
          ],
        ),
        if (deposits.isNotEmpty) ...[
          const SectionTitle('Recent'),
          for (final d in deposits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                '${d.amountPoisha >= 0 ? '+' : '−'}${formatTaka(d.amountPoisha.abs())}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: d.amountPoisha >= 0 ? colors.income : colors.spending,
                ),
              ),
              subtitle: Text(friendlyDay(parseDayKey(d.date))),
              trailing: IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => db.deleteDeposit(d.id),
              ),
            ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            if (!_confirmDelete) {
              setState(() => _confirmDelete = true);
              return;
            }
            final nav = Navigator.of(context);
            await db.deleteGoal(widget.goalId);
            nav.pop();
          },
          style: TextButton.styleFrom(foregroundColor: colors.spending),
          child: Text(_confirmDelete ? 'Tap again to delete this goal and its history' : 'Delete goal'),
        ),
      ],
    );
  }

  Future<void> _showMoneySheet(BuildContext context, GoalProgress progress, {required bool withdraw}) {
    return showAppSheet<void>(context, builder: (_) => _MoneySheet(progress: progress, withdraw: withdraw));
  }
}

class _MoneySheet extends ConsumerStatefulWidget {
  const _MoneySheet({required this.progress, required this.withdraw});

  final GoalProgress progress;
  final bool withdraw;

  @override
  ConsumerState<_MoneySheet> createState() => _MoneySheetState();
}

class _MoneySheetState extends ConsumerState<_MoneySheet> {
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    final suggestion = widget.withdraw ? null : widget.progress.monthlyNeeded;
    if (suggestion != null) _amount.text = amountToText(suggestion);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _valid {
    final a = readAmount(_amount);
    if (a == null) return null;
    if (widget.withdraw && a > widget.progress.saved) return null;
    return a;
  }

  Future<void> _save() async {
    final a = _valid;
    if (a == null) return;
    await ref.read(databaseProvider).addDeposit(
          goalId: widget.progress.goal.id,
          amountPoisha: widget.withdraw ? -a : a,
          date: dayKey(ref.read(todayProvider)),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final over = widget.withdraw && (readAmount(_amount) ?? 0) > widget.progress.saved;

    return SheetScaffold(
      footer: FilledButton(
        onPressed: _valid == null ? null : _save,
        child: Text(_valid == null ? 'Enter an amount' : (widget.withdraw ? 'Take out ${formatTaka(_valid!)}' : 'Add ${formatTaka(_valid!)}')),
      ),
      children: [
        SheetHeader(widget.withdraw ? 'Take money out' : 'Add money to ${widget.progress.goal.name}'),
        AmountField(controller: _amount, autofocus: true, onChanged: () => setState(() {})),
        const SizedBox(height: 8),
        Text(
          over
              ? 'You only have ${formatTaka(widget.progress.saved)} saved in this goal.'
              : widget.withdraw
                  ? 'You have ${formatTaka(widget.progress.saved)} saved here.'
                  : 'This moves the money into the goal. It is saved, not spent.',
          style: theme.textTheme.bodySmall?.copyWith(color: over ? colors.spending : colors.muted),
        ),
      ],
    );
  }
}

// ---- Editor ---------------------------------------------------------------

Future<void> showGoalEditor(BuildContext context, {SavingsGoal? existing}) {
  return showAppSheet<void>(context, builder: (_) => _GoalEditor(existing: existing));
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.existing});

  final SavingsGoal? existing;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  DateTime? _deadline;
  int _colorValue = categoryPalette[5].toARGB32();

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      _name.text = g.name;
      _target.text = amountToText(g.targetPoisha);
      _deadline = g.deadline == null ? null : parseDayKey(g.deadline!);
      _colorValue = g.colorValue;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && readAmount(_target) != null;

  Future<void> _pickDeadline() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime(today.year, today.month + 3, today.day),
      firstDate: today,
      lastDate: DateTime(today.year + 20),
    );
    if (picked != null) setState(() => _deadline = dateOnly(picked));
  }

  Future<void> _save() async {
    final target = readAmount(_target);
    if (target == null) return;
    final db = ref.read(databaseProvider);
    final deadline = _deadline == null ? null : dayKey(_deadline!);
    final existing = widget.existing;
    if (existing == null) {
      await db.addGoal(
        name: _name.text.trim(),
        targetPoisha: target,
        colorValue: _colorValue,
        deadline: deadline,
      );
    } else {
      await db.updateGoal(
        SavingsGoal(
          id: existing.id,
          name: _name.text.trim(),
          targetPoisha: target,
          deadline: deadline,
          colorValue: _colorValue,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SheetScaffold(
      footer: FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      children: [
        SheetHeader(widget.existing == null ? 'New savings goal' : 'Edit goal'),
        TextField(
          controller: _name,
          maxLength: 40,
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: fieldDecoration(context, label: 'What are you saving for?'),
        ),
        const SizedBox(height: 4),
        AmountField(controller: _target, label: 'Target amount', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                onPressed: _pickDeadline,
                icon: const Icon(Icons.event_rounded),
                label: Text(_deadline == null ? 'Deadline (optional)' : DateFormat('d MMM y').format(_deadline!)),
              ),
            ),
            if (_deadline != null)
              IconButton(
                tooltip: 'Remove deadline',
                onPressed: () => setState(() => _deadline = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in categoryPalette)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _colorValue = c.toARGB32()),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.toARGB32() == _colorValue ? scheme.onSurface : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: c.toARGB32() == _colorValue ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
