import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/level_bar.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/logic/planning.dart';
import '../../data/providers.dart';

class DharScreen extends ConsumerStatefulWidget {
  const DharScreen({super.key});

  @override
  ConsumerState<DharScreen> createState() => _DharScreenState();
}

class _DharScreenState extends ConsumerState<DharScreen> {
  String _direction = DharDirection.lent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);
    final all = ref.watch(dharViewsProvider);
    final totals = ref.watch(dharTotalsProvider);

    final mine = all.where((v) => v.record.direction == _direction).toList();
    final open = mine.where((v) => !v.isSettled).toList();
    final settled = mine.where((v) => v.isSettled).toList();

    Widget summary(String label, int amount, Color color, String direction) => Expanded(
          child: AppCard(
            onTap: () => setState(() => _direction = direction),
            color: _direction == direction ? theme.colorScheme.primaryContainer : null,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatTaka(amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Dhar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDharEditor(context, initialDirection: _direction),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          Row(
            children: [
              summary('You will get', totals.toReceive, colors.income, DharDirection.lent),
              const SizedBox(width: 12),
              summary('You owe', totals.toPay, colors.spending, DharDirection.borrowed),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DharDirection.lent, label: Text('Owed to me')),
                ButtonSegment(value: DharDirection.borrowed, label: Text('I owe')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
          ),
          const SizedBox(height: 12),
          if (open.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmptyState(
                icon: Icons.handshake_outlined,
                title: _direction == DharDirection.lent ? 'Nobody owes you' : 'You owe nobody',
                message: _direction == DharDirection.lent
                    ? 'When you lend money, add it here and tick it off as it comes back. It is never counted as spending.'
                    : 'When you borrow money, add it here so you remember to pay it back.',
              ),
            )
          else
            for (final v in open)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: _DharCard(view: v, today: today)),
          if (settled.isNotEmpty)
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Settled (${settled.length})', style: theme.textTheme.titleSmall?.copyWith(color: colors.muted)),
                children: [
                  for (final v in settled)
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: _DharCard(view: v, today: today)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DharCard extends ConsumerWidget {
  const _DharCard({required this.view, required this.today});

  final DharView view;
  final DateTime today;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final payments = view.payments.length;
    final what = payments == 0 ? '' : ' and ${payments == 1 ? '1 payment' : '$payments payments'}';
    final ok = await confirmDestructive(
      context,
      title: 'Delete this entry?',
      message: '${view.record.person}$what will be deleted. '
          'This is never counted as spending, so your balance does not change.',
    );
    if (ok) await ref.read(databaseProvider).deleteDhar(view.record.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final r = view.record;
    final accent = view.isLent ? colors.income : colors.spending;
    final overdue = view.isOverdue(today);
    final dueSoon = view.isDueSoon(today);

    String? dueText;
    if (!view.isSettled && r.dueDate != null) {
      dueText = overdue ? 'Overdue since ${DateFormat('d MMM').format(parseDayKey(r.dueDate!))}' : 'Due ${friendlyDay(parseDayKey(r.dueDate!), now: today)}';
    }

    return AppCard(
      onTap: () => showDharDetail(context, r.id),
      child: Opacity(
        opacity: view.isSettled ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: Text(
                    r.person.characters.first.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(color: accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.person, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        (r.note ?? '').trim().isNotEmpty ? r.note!.trim() : friendlyDay(parseDayKey(r.date), now: today),
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      view.isSettled ? 'Settled' : formatTaka(view.remaining),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: view.isSettled ? colors.muted : accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (view.paid > 0 && !view.isSettled)
                      Text('of ${formatTaka(view.total)}', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                  ],
                ),
                IconButton(
                  tooltip: 'Delete this entry',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _delete(context, ref),
                  icon: Icon(Icons.delete_outline_rounded, size: 22, color: colors.muted),
                ),
              ],
            ),
            if (view.paid > 0 && !view.isSettled) ...[
              const SizedBox(height: 10),
              ProgressBar(fraction: view.fraction, color: accent),
            ],
            if (dueText != null) ...[
              const SizedBox(height: 8),
              Text(
                dueText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overdue ? colors.spending : (dueSoon ? colors.highlight : colors.muted),
                  fontWeight: overdue || dueSoon ? FontWeight.w600 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Detail ---------------------------------------------------------------

Future<void> showDharDetail(BuildContext context, int dharId) {
  return showAppSheet<void>(context, builder: (_) => _DharDetail(dharId: dharId));
}

class _DharDetail extends ConsumerStatefulWidget {
  const _DharDetail({required this.dharId});

  final int dharId;

  @override
  ConsumerState<_DharDetail> createState() => _DharDetailState();
}

class _DharDetailState extends ConsumerState<_DharDetail> {
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final view = ref.watch(dharViewsProvider).where((v) => v.record.id == widget.dharId).firstOrNull;
    if (view == null) return const SizedBox(height: 120);

    final db = ref.read(databaseProvider);
    final r = view.record;
    final accent = view.isLent ? colors.income : colors.spending;

    return SheetScaffold(
      children: [
        SheetHeader(
          r.person,
          trailing: IconButton(
            tooltip: 'Edit',
            onPressed: () => showDharEditor(context, existing: r),
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        Text(
          view.isLent ? 'You lent ${formatTaka(view.total)}' : 'You borrowed ${formatTaka(view.total)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          view.isSettled ? 'Settled' : '${formatTaka(view.remaining)} ${view.isLent ? 'to receive' : 'to pay back'}',
          style: theme.textTheme.displaySmall?.copyWith(
            color: view.isSettled ? colors.muted : accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        ProgressBar(fraction: view.isSettled ? 1 : view.fraction, color: accent, height: 10),
        if (r.dueDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Due ${DateFormat('d MMM y').format(parseDayKey(r.dueDate!))}',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
        if ((r.note ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.note!.trim(), style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (!view.isSettled) ...[
              Expanded(
                child: FilledButton(
                  onPressed: () => showAppSheet<void>(context, builder: (_) => _PaymentSheet(view: view)),
                  child: Text(view.isLent ? 'Money received' : 'I paid back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                  onPressed: () => db.setDharSettled(r.id, true),
                  child: const Text('Mark settled'),
                ),
              ),
            ] else if (view.remaining > 0)
              // Settled by hand with money still outstanding: it can be reopened. A fully
              // paid one reopens by deleting one of its payments below.
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                  onPressed: () => db.setDharSettled(r.id, false),
                  child: const Text('Reopen'),
                ),
              ),
          ],
        ),
        if (view.payments.isNotEmpty) ...[
          const SectionTitle('Payments'),
          for (final p in view.payments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(formatTaka(p.amountPoisha), style: theme.textTheme.titleSmall),
              subtitle: Text(friendlyDay(parseDayKey(p.date))),
              trailing: IconButton(
                tooltip: 'Delete payment',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () async {
                  await db.deleteDharPayment(p.id);
                  // A fully paid entry has something left to pay again once a payment goes.
                  if (view.remaining == 0 && r.settled) await db.setDharSettled(r.id, false);
                },
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
            await db.deleteDhar(r.id);
            nav.pop();
          },
          style: TextButton.styleFrom(foregroundColor: colors.spending),
          child: Text(_confirmDelete ? 'Tap again to delete this entry and its payments' : 'Delete'),
        ),
      ],
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.view});

  final DharView view;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: amountToText(widget.view.remaining));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _valid {
    final a = readAmount(_amount);
    return (a == null || a > widget.view.remaining) ? null : a;
  }

  Future<void> _save() async {
    final a = _valid;
    if (a == null) return;
    await ref.read(databaseProvider).addDharPayment(
          dharId: widget.view.record.id,
          amountPoisha: a,
          date: dayKey(ref.read(todayProvider)),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final v = widget.view;
    final tooMuch = (readAmount(_amount) ?? 0) > v.remaining;

    return SheetScaffold(
      footer: FilledButton(
        onPressed: _valid == null ? null : _save,
        child: Text(_valid == null ? 'Enter an amount' : 'Save ${formatTaka(_valid!)}'),
      ),
      children: [
        SheetHeader(v.isLent ? 'Money received from ${v.record.person}' : 'Paid back to ${v.record.person}'),
        AmountField(controller: _amount, autofocus: true, onChanged: () => setState(() {})),
        const SizedBox(height: 8),
        Text(
          tooMuch ? 'That is more than the ${formatTaka(v.remaining)} left.' : '${formatTaka(v.remaining)} left. Part payments are fine.',
          style: theme.textTheme.bodySmall?.copyWith(color: tooMuch ? colors.spending : colors.muted),
        ),
      ],
    );
  }
}

// ---- Editor ---------------------------------------------------------------

Future<void> showDharEditor(BuildContext context, {DharRecord? existing, String initialDirection = DharDirection.lent}) {
  return showAppSheet<void>(context, builder: (_) => _DharEditor(existing: existing, initialDirection: initialDirection));
}

class _DharEditor extends ConsumerStatefulWidget {
  const _DharEditor({this.existing, required this.initialDirection});

  final DharRecord? existing;
  final String initialDirection;

  @override
  ConsumerState<_DharEditor> createState() => _DharEditorState();
}

class _DharEditorState extends ConsumerState<_DharEditor> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _direction;
  late DateTime _date;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _date = ref.read(todayProvider);
    final r = widget.existing;
    if (r != null) {
      _person.text = r.person;
      _amount.text = amountToText(r.amountPoisha);
      _note.text = r.note ?? '';
      _direction = r.direction;
      _date = parseDayKey(r.date);
      _due = r.dueDate == null ? null : parseDayKey(r.dueDate!);
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _person.text.trim().isNotEmpty && readAmount(_amount) != null;

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickDue() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime(today.year, today.month, today.day + 7),
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) setState(() => _due = dateOnly(picked));
  }

  Future<void> _save() async {
    final amount = readAmount(_amount);
    if (amount == null) return;
    final db = ref.read(databaseProvider);
    final note = _note.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      await db.addDhar(
        person: _person.text.trim(),
        direction: _direction,
        amountPoisha: amount,
        date: dayKey(_date),
        dueDate: _due == null ? null : dayKey(_due!),
        note: note.isEmpty ? null : note,
      );
    } else {
      await db.updateDhar(
        DharRecord(
          id: existing.id,
          person: _person.text.trim(),
          direction: _direction,
          amountPoisha: amount,
          date: dayKey(_date),
          dueDate: _due == null ? null : dayKey(_due!),
          note: note.isEmpty ? null : note,
          settled: existing.settled,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final today = ref.watch(todayProvider);

    return SheetScaffold(
      footer: FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      children: [
        SheetHeader(widget.existing == null ? 'New dhar entry' : 'Edit dhar entry'),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: DharDirection.lent, label: Text('I lent')),
            ButtonSegment(value: DharDirection.borrowed, label: Text('I borrowed')),
          ],
          selected: {_direction},
          onSelectionChanged: (s) => setState(() => _direction = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _person,
          maxLength: 40,
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: fieldDecoration(context, label: _direction == DharDirection.lent ? 'Who did you lend to?' : 'Who did you borrow from?'),
        ),
        const SizedBox(height: 4),
        AmountField(controller: _amount, onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(friendlyDay(_date, now: today)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                onPressed: _pickDue,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(_due == null ? 'Due date' : DateFormat('d MMM y').format(_due!)),
              ),
            ),
            if (_due != null)
              IconButton(
                tooltip: 'Remove due date',
                onPressed: () => setState(() => _due = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        if (_due != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Hisab reminds you at 9 AM on the due date.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: fieldDecoration(context, label: 'Note (optional)'),
        ),
      ],
    );
  }
}
