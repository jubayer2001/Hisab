import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';

const _noteKey = 'incomeNoteDismissed';

/// Ids of automatic-income entries whose Home note was closed.
class DismissedIncomeNotes extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final saved = ref.watch(sharedPrefsProvider).getStringList(_noteKey) ?? const [];
    return {for (final s in saved) ?int.tryParse(s)};
  }

  void dismiss(int entryId) {
    state = {...state, entryId};
    // Only the latest few matter, so the saved list never grows without end.
    final keep = state.toList()..sort();
    final trimmed = keep.length > 50 ? keep.sublist(keep.length - 50) : keep;
    ref.read(sharedPrefsProvider).setStringList(_noteKey, [for (final id in trimmed) '$id']);
  }
}

final dismissedIncomeNotesProvider = NotifierProvider<DismissedIncomeNotes, Set<int>>(DismissedIncomeNotes.new);

/// How many days an automatic income stays announced on Home.
const incomeNoteDays = 3;

/// Automatic income entries added in the last few days that have not been closed yet.
final incomeNotesProvider = Provider<List<EntryWithCategory>>((ref) {
  final today = ref.watch(todayProvider);
  final dismissed = ref.watch(dismissedIncomeNotesProvider);
  final since = dayKey(dateOnly(today).subtract(const Duration(days: incomeNoteDays)));
  final entries = ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[];
  return [
    for (final e in entries)
      if (e.entry.recurringId != null &&
          e.entry.date.compareTo(since) >= 0 &&
          e.entry.date.compareTo(dayKey(today)) <= 0 &&
          !dismissed.contains(e.entry.id))
        e,
  ].take(2).toList();
});

/// "Salary ৳45,000 added today. Different this month? Change". One card per fresh automatic income.
class IncomeNotes extends ConsumerWidget {
  const IncomeNotes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(incomeNotesProvider);
    if (notes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);

    return Column(
      children: [
        for (final item in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              decoration: BoxDecoration(
                color: colors.income.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: colors.income),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.entry.note ?? item.category.name} ${formatTaka(item.entry.amountPoisha)} '
                          '${item.entry.date == dayKey(today) ? 'added today' : 'added ${friendlyDay(parseDayKey(item.entry.date), now: today).toLowerCase()}'}',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text('Different this month?', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => showChangeIncomeSheet(context, item),
                    child: const Text('Change'),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 20, color: colors.muted),
                    onPressed: () => ref.read(dismissedIncomeNotesProvider.notifier).dismiss(item.entry.id),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showChangeIncomeSheet(BuildContext context, EntryWithCategory item) {
  return showAppSheet<void>(context, builder: (_) => _ChangeIncomeSheet(item: item));
}

class _ChangeIncomeSheet extends ConsumerStatefulWidget {
  const _ChangeIncomeSheet({required this.item});

  final EntryWithCategory item;

  @override
  ConsumerState<_ChangeIncomeSheet> createState() => _ChangeIncomeSheetState();
}

class _ChangeIncomeSheetState extends ConsumerState<_ChangeIncomeSheet> {
  late final TextEditingController _amount;
  bool _fromNowOn = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: amountToText(widget.item.entry.amountPoisha));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = readAmount(_amount);
    if (amount == null) return;
    final db = ref.read(databaseProvider);
    final entry = widget.item.entry;
    await db.updateEntry(entry.copyWith(amountPoisha: amount));
    if (_fromNowOn && entry.recurringId != null) {
      final item = (await db.watchRecurrings().first).where((r) => r.id == entry.recurringId).firstOrNull;
      if (item != null) await db.updateRecurring(item.copyWith(amountPoisha: amount));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _notReceived() async {
    final db = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    final entry = widget.item.entry;
    final name = entry.note ?? widget.item.category.name;
    await db.deleteEntry(entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed $name for this month'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreEntry(entry)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final entry = widget.item.entry;
    final month = DateFormat('MMMM').format(parseDayKey(entry.date));
    final name = entry.note ?? widget.item.category.name;
    final canChangeRegular = entry.recurringId != null;

    return SheetScaffold(
      footer: FilledButton(onPressed: readAmount(_amount) == null ? null : _save, child: const Text('Save')),
      children: [
        SheetHeader('$name for $month'),
        AmountField(controller: _amount, label: 'Amount', autofocus: true, onChanged: () => setState(() {})),
        if (canChangeRegular) ...[
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Only this month')),
              ButtonSegment(value: true, label: Text('From now on')),
            ],
            selected: {_fromNowOn},
            onSelectionChanged: (s) => setState(() => _fromNowOn = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _fromNowOn
                ? 'The new amount is used for every month from now on. Past months stay as they are.'
                : 'A bonus or a cut this month? Next month still uses your usual amount.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.spending),
          onPressed: _notReceived,
          child: const Text('Didn\'t receive it this month'),
        ),
      ],
    );
  }
}

// ---- Income breakdown ----------------------------------------------------------

Future<void> showIncomeBreakdown(BuildContext context) {
  return showAppSheet<void>(context, builder: (_) => const _IncomeBreakdown());
}

/// This month's income, split into the regular monthly income and one-off extras.
class _IncomeBreakdown extends ConsumerWidget {
  const _IncomeBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final month = monthKey(today);
    final entries = (ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[])
        .where((e) => e.entry.type == 'income' && e.entry.date.startsWith(month))
        .toList()
      ..sort((a, b) => a.entry.date.compareTo(b.entry.date));
    final total = entries.fold<int>(0, (s, e) => s + e.entry.amountPoisha);

    return SheetScaffold(
      children: [
        SheetHeader('Income in ${DateFormat('MMMM').format(today)}'),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'No income yet this month. Add some with the + button, or set up a monthly income in More.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          )
        else ...[
          for (final e in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Color(e.category.colorValue), borderRadius: BorderRadius.circular(12)),
                child: Icon(iconForKey(e.category.iconKey), color: Colors.white, size: 22),
              ),
              title: Text(
                (e.entry.note ?? '').trim().isEmpty ? e.category.name : e.entry.note!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${e.entry.recurringId != null ? 'Monthly' : 'Extra'} · ${DateFormat('d MMM').format(parseDayKey(e.entry.date))}'),
              trailing: Text(
                '+${formatTaka(e.entry.amountPoisha)}',
                style: theme.textTheme.titleMedium?.copyWith(color: colors.income),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
                Text(formatTaka(total), style: theme.textTheme.titleMedium?.copyWith(color: colors.income)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
