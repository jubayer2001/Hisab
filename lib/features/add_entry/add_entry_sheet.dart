import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/providers.dart';

/// Opens the add sheet, or the edit sheet when [editing] is given.
Future<void> showAddEntrySheet(
  BuildContext context, {
  EntryWithCategory? editing,
  String initialType = EntryType.expense,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AddEntrySheet(editing: editing, initialType: initialType),
  );
}

class AddEntrySheet extends ConsumerStatefulWidget {
  const AddEntrySheet({super.key, this.editing, this.initialType = EntryType.expense});

  final EntryWithCategory? editing;
  final String initialType;

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  static const _maxIntegerDigits = 9;

  late String _type;
  String _amountText = '';
  int? _categoryId;
  late DateTime _date;
  String? _payment;
  final _noteController = TextEditingController();

  bool get _isEditing => widget.editing != null;
  bool get _isExpense => _type == EntryType.expense;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      final e = editing.entry;
      _type = e.type;
      _amountText = _poishaToText(e.amountPoisha);
      _categoryId = e.categoryId;
      _date = parseDayKey(e.date);
      _payment = e.paymentMethod;
      _noteController.text = e.note ?? '';
    } else {
      _type = widget.initialType;
      _date = ref.read(todayProvider);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  static String _poishaToText(int poisha) {
    final taka = poisha ~/ 100;
    final rest = poisha % 100;
    if (rest == 0) return '$taka';
    return '$taka.${rest.toString().padLeft(2, '0')}'.replaceFirst(RegExp(r'0$'), '');
  }

  // ---- Keypad --------------------------------------------------------------

  void _onKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '.') {
        if (_amountText.contains('.')) return;
        _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
        return;
      }
      final dot = _amountText.indexOf('.');
      if (dot >= 0) {
        if (_amountText.length - dot - 1 >= 2) return;
      } else if (_amountText.length >= _maxIntegerDigits) {
        return;
      }
      _amountText = (_amountText == '0') ? key : '$_amountText$key';
    });
  }

  void _onBackspace() {
    if (_amountText.isEmpty) return;
    setState(() => _amountText = _amountText.substring(0, _amountText.length - 1));
  }

  String get _displayAmount {
    if (_amountText.isEmpty) return '0';
    final parts = _amountText.split('.');
    final whole = groupLakh(int.tryParse(parts[0]) ?? 0);
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  int? get _amountPoisha {
    final v = parseTakaToPoisha(_amountText);
    return (v == null || v <= 0) ? null : v;
  }

  bool get _canSave => _amountPoisha != null && _categoryId != null;

  // ---- Actions -------------------------------------------------------------

  void _setType(String type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      if (type == EntryType.income) _payment = null;
    });
  }

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

  Future<void> _save() async {
    final amount = _amountPoisha;
    final categoryId = _categoryId;
    if (amount == null || categoryId == null) return;

    final db = ref.read(databaseProvider);
    final note = _noteController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    final categoryName = categories.where((c) => c.id == categoryId).map((c) => c.name).firstOrNull ?? '';

    final editing = widget.editing;
    if (editing == null) {
      await db.addEntry(
        type: _type,
        amountPoisha: amount,
        categoryId: categoryId,
        date: dayKey(_date),
        paymentMethod: _isExpense ? _payment : null,
        note: note.isEmpty ? null : note,
      );
    } else {
      await db.updateEntry(
        editing.entry.copyWith(
          type: _type,
          amountPoisha: amount,
          categoryId: categoryId,
          date: dayKey(_date),
          paymentMethod: Value(_isExpense ? _payment : null),
          note: Value(note.isEmpty ? null : note),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${_isEditing ? 'Updated' : 'Saved'} ${formatTaka(amount)} · $categoryName'),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _delete() async {
    final editing = widget.editing;
    if (editing == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    await db.deleteEntry(editing.entry.id);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted ${formatTaka(editing.entry.amountPoisha)} · ${editing.category.name}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Undo', onPressed: () => db.restoreEntry(editing.entry)),
        ),
      );
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.hisab;
    final categories = ref.watch(pickableCategoriesProvider(_type));
    // When editing, the entry's own category must stay selectable even if it was archived.
    final editingCategory = widget.editing?.category;
    final shown = [
      ...categories,
      if (editingCategory != null && editingCategory.type == _type && !categories.any((c) => c.id == editingCategory.id))
        editingCategory,
    ];
    final accent = _isExpense ? colors.spending : colors.income;
    final today = ref.watch(todayProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edit ${_isExpense ? 'expense' : 'income'}',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: _delete,
                          icon: Icon(Icons.delete_outline_rounded, color: colors.spending),
                        ),
                      ],
                    )
                  else ...[
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: EntryType.expense, label: Text('Expense')),
                        ButtonSegment(value: EntryType.income, label: Text('Income')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => _setType(s.first),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _AmountDisplay(text: _displayAmount, isEmpty: _amountText.isEmpty, color: accent),
                  const SizedBox(height: 4),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.98,
                    children: [
                      for (final c in shown)
                        _CategoryChoice(
                          category: c,
                          selected: c.id == _categoryId,
                          onTap: () => setState(() => _categoryId = c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // One scrollable line: the date, then (for expenses) how it was paid.
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Center(
                          child: ActionChip(
                            avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              _date == today
                                  ? 'Today, ${DateFormat('d MMM').format(_date)}'
                                  : friendlyDay(_date, now: today),
                            ),
                            onPressed: _pickDate,
                          ),
                        ),
                        if (_isExpense)
                          for (final m in paymentMethods)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Center(
                                child: ChoiceChip(
                                  label: Text(m),
                                  selected: _payment == m,
                                  onSelected: (on) => setState(() => _payment = on ? m : null),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Note (optional)',
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: colors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Keypad(onKey: _onKey, onBackspace: _onBackspace, onClear: () => setState(() => _amountText = '')),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                child: Text(
                  _amountPoisha == null
                      ? 'Enter an amount'
                      : _categoryId == null
                          ? 'Pick a category'
                          : (_isEditing ? 'Save changes' : 'Save ${formatTaka(_amountPoisha!)}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.text, required this.isEmpty, required this.color});

  final String text;
  final bool isEmpty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.hisab.muted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(takaSign, style: theme.textTheme.headlineSmall?.copyWith(color: muted)),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isEmpty ? muted.withValues(alpha: 0.5) : color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({required this.category, required this.selected, required this.onTap});

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(category.colorValue),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconForKey(category.iconKey), color: Colors.white, size: 21),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.onBackspace, required this.onClear});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(
                    label: key,
                    onTap: () => key == '⌫' ? onBackspace() : onKey(key),
                    onLongPress: key == '⌫' ? onClear : null,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.onLongPress});

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: context.hisab.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 44,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, size: 22, color: theme.colorScheme.onSurface)
                  : Text(label, style: theme.textTheme.titleLarge),
            ),
          ),
        ),
      ),
    );
  }
}
