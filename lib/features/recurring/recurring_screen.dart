import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/logic/auto_income.dart';
import '../../data/logic/planning.dart';
import '../../data/providers.dart';
import '../add_entry/entry_actions.dart';

/// Monthly bills (which ask first) and monthly income (which can add itself), in one place.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final items = ref.watch(recurringsProvider).value ?? const <Recurring>[];
    final categories = {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c};
    final db = ref.read(databaseProvider);
    final income = items.where((r) => r.type == EntryType.income).toList();
    final bills = items.where((r) => r.type != EntryType.income).toList();
    final total = ref.watch(monthlyIncomeTotalProvider);

    Widget card(Recurring r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => showRecurringEditor(context, existing: r),
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(categories[r.categoryId]?.colorValue ?? 0xFF94A3A0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(iconForKey(categories[r.categoryId]?.iconKey ?? 'dots'), color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${r.type == EntryType.income ? '+' : ''}${formatTaka(r.amountPoisha)} · every month on day ${r.dayOfMonth}',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                      Text(
                        !r.isActive
                            ? 'Paused'
                            : r.autoAdd
                                ? 'Adds itself · next ${DateFormat('d MMM').format(nextRecurringDate(r, today))}'
                                : 'Asks you first · next ${DateFormat('d MMM').format(nextRecurringDate(r, today))}',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: r.isActive,
                  onChanged: (v) => db.updateRecurring(r.copyWith(isActive: v)),
                ),
                IconButton(
                  tooltip: 'Delete this item',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteWithUndo(context, ref, r),
                  icon: Icon(Icons.delete_outline_rounded, size: 22, color: colors.muted),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly bills & income')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRecurringEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.event_repeat_rounded,
              title: 'Nothing monthly yet',
              message:
                  'Add your salary and it records itself every month. Add rent or Wi-Fi and Hisab asks you to confirm it with one tap.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                if (income.isNotEmpty) ...[
                  const SectionTitle('Monthly income'),
                  for (final r in income) card(r),
                  if (total > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(
                        'Regular income: ${formatTaka(total)} a month',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                    ),
                ],
                if (bills.isNotEmpty) ...[
                  const SectionTitle('Monthly bills'),
                  for (final r in bills) card(r),
                ],
              ],
            ),
    );
  }
}

/// Deletes a recurring item and offers "Undo". Entries it already created are not touched.
Future<void> _deleteWithUndo(BuildContext context, WidgetRef ref, Recurring item) async {
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  await db.deleteRecurring(item.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Deleted ${item.title}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreRecurring(item)),
      ),
    );
}

Future<void> showRecurringEditor(BuildContext context, {Recurring? existing, String? initialType}) {
  return showAppSheet<void>(context, builder: (_) => _RecurringEditor(existing: existing, initialType: initialType));
}

class _RecurringEditor extends ConsumerStatefulWidget {
  const _RecurringEditor({this.existing, this.initialType});

  final Recurring? existing;
  final String? initialType;

  @override
  ConsumerState<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends ConsumerState<_RecurringEditor> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _type = EntryType.expense;
  int? _categoryId;
  int _day = 1;

  /// Income only: record it by itself on its day.
  bool _auto = true;

  /// New automatic income only: this month's money counts as already received.
  late bool _received;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _title.text = r.title;
      _amount.text = amountToText(r.amountPoisha);
      _type = r.type;
      _categoryId = r.categoryId;
      _day = r.dayOfMonth;
      _auto = r.autoAdd;
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    _received = _day <= ref.read(todayProvider).day;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _isIncome => _type == EntryType.income;

  bool get _canSave => _title.text.trim().isNotEmpty && readAmount(_amount) != null && _categoryId != null;

  Future<void> _save() async {
    final amount = readAmount(_amount);
    final categoryId = _categoryId;
    if (amount == null || categoryId == null) return;
    final db = ref.read(databaseProvider);
    final existing = widget.existing;
    final auto = _isIncome && _auto;
    if (existing == null) {
      if (auto) {
        await createMonthlyIncome(
          db,
          ref.read(todayProvider),
          title: _title.text.trim(),
          amountPoisha: amount,
          categoryId: categoryId,
          dayOfMonth: _day,
          receivedThisMonth: _received,
        );
      } else {
        await db.addRecurring(
          title: _title.text.trim(),
          type: _type,
          amountPoisha: amount,
          categoryId: categoryId,
          dayOfMonth: _day,
        );
      }
    } else {
      await db.updateRecurring(
        existing.copyWith(
          title: _title.text.trim(),
          type: _type,
          amountPoisha: amount,
          categoryId: categoryId,
          dayOfMonth: _day,
          autoAdd: auto,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteRecurring(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final categories = ref.watch(pickableCategoriesProvider(_type));
    final isNew = widget.existing == null;

    return SheetScaffold(
      footer: FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      children: [
        SheetHeader(
          isNew ? 'New monthly item' : 'Edit monthly item',
          trailing: isNew
              ? null
              : IconButton(
                  tooltip: 'Delete',
                  onPressed: _delete,
                  icon: Icon(Icons.delete_outline_rounded, color: colors.spending),
                ),
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: EntryType.expense, label: Text('Bill / expense')),
            ButtonSegment(value: EntryType.income, label: Text('Income')),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() {
            _type = s.first;
            _categoryId = null;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: fieldDecoration(context, label: _isIncome ? 'Name (like Salary or Tuition)' : 'Name (like Rent or Wi-Fi)'),
        ),
        const SizedBox(height: 4),
        AmountField(
          controller: _amount,
          label: 'Usual amount',
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 4),
        Text(
          _isIncome && _auto
              ? 'You can change a month\'s amount from the note on Home.'
              : 'You can change the amount when you confirm it each month.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 16),
        Text('Category', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        CategoryChips(
          categories: categories,
          selectedId: _categoryId,
          onSelected: (id) => setState(() => _categoryId = id),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _day,
          decoration: fieldDecoration(context, label: _isIncome ? 'It arrives on day' : 'Day of the month'),
          items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('Day $d'))],
          onChanged: (v) => setState(() {
            _day = v ?? _day;
            if (isNew) _received = _day <= ref.read(todayProvider).day;
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'In shorter months it falls on the last day.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        if (_isIncome) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _auto,
            onChanged: (v) => setState(() => _auto = v),
            title: const Text('Add it automatically'),
            subtitle: Text(_auto ? 'Recorded for you on its day' : 'Hisab asks you to confirm it each month'),
          ),
          if (isNew && _auto)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _received,
              onChanged: (v) => setState(() => _received = v),
              title: const Text('Already received this month'),
              subtitle: Text(_received ? 'Counts toward this month now' : 'The first one is next month'),
            ),
        ],
      ],
    );
  }
}

/// Asks for the amount (prefilled) and adds the bill to today's entries.
Future<void> showConfirmRecurring(BuildContext context, Recurring r) {
  return showAppSheet<void>(context, builder: (_) => _ConfirmRecurring(recurring: r));
}

class _ConfirmRecurring extends ConsumerStatefulWidget {
  const _ConfirmRecurring({required this.recurring});

  final Recurring recurring;

  @override
  ConsumerState<_ConfirmRecurring> createState() => _ConfirmRecurringState();
}

class _ConfirmRecurringState extends ConsumerState<_ConfirmRecurring> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: amountToText(widget.recurring.amountPoisha));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final amount = readAmount(_amount);
    if (amount == null) return;
    final r = widget.recurring;
    final db = ref.read(databaseProvider);
    final today = ref.read(todayProvider);
    final messenger = ScaffoldMessenger.of(context);
    final warning = await budgetWarning(ref, type: r.type, categoryId: r.categoryId, amountPoisha: amount);
    await db.addEntry(
      type: r.type,
      amountPoisha: amount,
      categoryId: r.categoryId,
      date: dayKey(today),
      note: r.title,
    );
    await db.markRecurringHandled(r.id, monthKey(today));
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Added ${r.title} ${formatTaka(amount)}${warning == null ? '' : '\n$warning'}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.recurring;
    return SheetScaffold(
      footer: FilledButton(
        onPressed: readAmount(_amount) == null ? null : _confirm,
        child: Text(readAmount(_amount) == null ? 'Enter an amount' : 'Add ${formatTaka(readAmount(_amount)!)}'),
      ),
      children: [
        SheetHeader(r.title),
        Text(
          'This is added to today as ${r.type == EntryType.income ? 'income' : 'an expense'}. Change the amount if this month is different.',
          style: theme.textTheme.bodyMedium?.copyWith(color: context.hisab.muted),
        ),
        const SizedBox(height: 12),
        AmountField(
          controller: _amount,
          label: 'Amount',
          autofocus: true,
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }
}
