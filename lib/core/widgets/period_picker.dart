import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/db/app_database.dart' show EntryWithCategory;
import '../../data/logic/periods.dart';
import '../../data/providers.dart';
import '../../l10n/text.dart';
import '../dates.dart';

/// What the calendar picker hands back: a kind of period and how far from today it is.
class PeriodChoice {
  const PeriodChoice(this.type, this.offset);

  final PeriodType type;
  final int offset;
}

/// A small calendar window to jump straight to a day, a week (Saturday to Friday), a month or a
/// year. Used by Reports and History. [type] and [offset] are what is showing now.
Future<PeriodChoice?> showPeriodPicker(BuildContext context, {required PeriodType type, required int offset}) {
  return showDialog<PeriodChoice>(
    context: context,
    builder: (_) => _PeriodPickerDialog(type: type, offset: offset),
  );
}

/// The date label shown above Reports and History: tap it to open the calendar.
class PeriodPickButton extends StatelessWidget {
  const PeriodPickButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: tr('Go to date'),
      excludeSemantics: true,
      child: Material(
        color: context.hisab.card,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: context.hisab.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodPickerDialog extends ConsumerStatefulWidget {
  const _PeriodPickerDialog({required this.type, required this.offset});

  final PeriodType type;
  final int offset;

  @override
  ConsumerState<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends ConsumerState<_PeriodPickerDialog> {
  late PeriodType _mode;
  late final Period _selected;
  late int _viewYear;
  late int _viewMonth;

  /// For the year grid: 0 shows the 12 years ending this year, -1 the 12 before, and so on.
  int _yearBlock = 0;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _mode = widget.type;
    _selected = shiftPeriod(periodFor(widget.type, today), widget.offset);
    _viewYear = _selected.start.year;
    _viewMonth = _selected.start.month;
  }

  void _choose(PeriodType type, DateTime date) {
    final offset = periodOffset(type, date, ref.read(todayProvider));
    Navigator.pop(context, PeriodChoice(type, offset > 0 ? 0 : offset));
  }

  bool _isSelected(PeriodType type, DateTime date) => _selected.type == type && _selected.contains(date);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final daysWithEntries = <String>{for (final e in ref.watch(allEntriesProvider).value ?? const <EntryWithCategory>[]) e.entry.date};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text('Go to date', style: theme.textTheme.titleLarge),
            ),
            SegmentedButton<PeriodType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: PeriodType.day, label: Text('Day')),
                ButtonSegment(value: PeriodType.week, label: Text('Week')),
                ButtonSegment(value: PeriodType.month, label: Text('Month')),
                ButtonSegment(value: PeriodType.year, label: Text('Year')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 8),
            switch (_mode) {
              PeriodType.day || PeriodType.week => _days(context, today, daysWithEntries),
              PeriodType.month => _months(context, today),
              PeriodType.year => _years(context, today),
            },
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, PeriodChoice(_mode, 0)),
                    child: const Text('Today'),
                  ),
                ),
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, {required String label, required VoidCallback onPrev, VoidCallback? onNext}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(tooltip: tr('Previous'), onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(
          child: Text(label, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        ),
        IconButton(tooltip: tr('Next'), onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
      ],
    );
  }

  Widget _days(BuildContext context, DateTime today, Set<String> daysWithEntries) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final first = DateTime(_viewYear, _viewMonth, 1);
    final count = DateTime(_viewYear, _viewMonth + 1, 0).day;
    // Weeks start on Saturday, as everywhere else in the app.
    final lead = (first.weekday - weekStartsOn) % 7;
    final atCurrentMonth = _viewYear > today.year || (_viewYear == today.year && _viewMonth >= today.month);
    const letters = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];

    return Column(
      children: [
        _header(
          context,
          label: DateFormat('MMMM y').format(first),
          onPrev: () => setState(() {
            final m = DateTime(_viewYear, _viewMonth - 1);
            _viewYear = m.year;
            _viewMonth = m.month;
          }),
          onNext: atCurrentMonth
              ? null
              : () => setState(() {
                  final m = DateTime(_viewYear, _viewMonth + 1);
                  _viewYear = m.year;
                  _viewMonth = m.month;
                }),
        ),
        Row(
          children: [
            for (final l in letters)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(l, style: theme.textTheme.labelSmall?.copyWith(color: colors.muted)),
                  ),
                ),
              ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= count; d++)
              _DayCell(
                date: DateTime(_viewYear, _viewMonth, d),
                today: today,
                selected: _isSelected(_mode, DateTime(_viewYear, _viewMonth, d)),
                hasEntries: daysWithEntries.contains(dayKey(DateTime(_viewYear, _viewMonth, d))),
                onTap: () => _choose(_mode, DateTime(_viewYear, _viewMonth, d)),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            _mode == PeriodType.week
                ? 'Tap any day to pick its whole week (Saturday to Friday)'
                : 'Dots show days that have entries',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }

  Widget _months(BuildContext context, DateTime today) {
    return Column(
      children: [
        _header(
          context,
          label: '$_viewYear',
          onPrev: () => setState(() => _viewYear--),
          onNext: _viewYear >= today.year ? null : () => setState(() => _viewYear++),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(vertical: 6),
          children: [
            for (var m = 1; m <= 12; m++)
              _GridCell(
                label: DateFormat('MMM').format(DateTime(2000, m)),
                selected: _isSelected(PeriodType.month, DateTime(_viewYear, m, 1)),
                enabled: !DateTime(_viewYear, m, 1).isAfter(DateTime(today.year, today.month, 1)),
                onTap: () => _choose(PeriodType.month, DateTime(_viewYear, m, 1)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _years(BuildContext context, DateTime today) {
    final end = today.year + 12 * _yearBlock;
    final start = end - 11;
    return Column(
      children: [
        _header(
          context,
          label: '$start – $end',
          onPrev: () => setState(() => _yearBlock--),
          onNext: _yearBlock >= 0 ? null : () => setState(() => _yearBlock++),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(vertical: 6),
          children: [
            for (var y = start; y <= end; y++)
              _GridCell(
                label: '$y',
                selected: _isSelected(PeriodType.year, DateTime(y, 1, 1)),
                enabled: y <= today.year,
                onTap: () => _choose(PeriodType.year, DateTime(y, 1, 1)),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.selected,
    required this.hasEntries,
    required this.onTap,
  });

  final DateTime date;
  final DateTime today;
  final bool selected;
  final bool hasEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final future = date.isAfter(dateOnly(today));
    final isToday = date == dateOnly(today);
    final textColor = selected ? scheme.onPrimary : (future ? scheme.onSurface.withValues(alpha: 0.3) : scheme.onSurface);

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: CircleBorder(side: isToday && !selected ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: future ? null : onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (hasEntries)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? scheme.onPrimary : scheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.label, required this.selected, required this.enabled, required this.onTap});

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? scheme.onPrimary : (enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.3)),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
