import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/widgets/sheet.dart';
import '../../data/logic/funds.dart';
import '../../data/providers.dart';

Future<void> showFundsSheet(BuildContext context, {String title = 'Saved balance', String? caption, DateTime? asOf}) {
  final router = GoRouter.of(context);
  return showAppSheet<void>(
    context,
    builder: (_) => _FundsSheet(
      title: title,
      caption: caption,
      asOf: asOf,
      onGoals: (sheetContext) {
        Navigator.pop(sheetContext);
        router.push('/goals');
      },
    ),
  );
}

class _FundsSheet extends ConsumerWidget {
  const _FundsSheet({required this.title, this.caption, this.asOf, required this.onGoals});
  final String title;
  final String? caption;
  final DateTime? asOf;
  final void Function(BuildContext) onGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), colors = context.hisab;
    final funds = computeFunds(
      entries: (ref.watch(allEntriesProvider).value ?? const []).map((e) => e.entry),
      deposits: ref.watch(depositsProvider).value ?? const [],
      asOf: asOf ?? ref.watch(todayProvider),
    );
    final share = funds.total > 0 ? (funds.reserved / funds.total).clamp(0.0, 1.0) : (funds.reserved > 0 ? 1.0 : 0.0);
    Widget row(String label, int amount, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(formatTaka(amount), style: theme.textTheme.titleMedium),
        ],
      ),
    );
    return SheetScaffold(
      children: [
        SheetHeader(title),
        Text(
          formatTaka(funds.total),
          style: theme.textTheme.displaySmall?.copyWith(
            color: funds.total < 0 ? colors.spending : theme.colorScheme.primary,
          ),
        ),
        if (caption != null) Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
        const SizedBox(height: 22),
        Semantics(
          label: 'Available ${formatTaka(funds.available)}, reserved ${formatTaka(funds.reserved)}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (share < 1)
                    Expanded(
                      flex: ((1 - share) * 10000).round().clamp(1, 10000),
                      child: ColoredBox(color: theme.colorScheme.primary),
                    ),
                  if (share > 0)
                    Expanded(
                      flex: (share * 10000).round().clamp(1, 10000),
                      child: ColoredBox(color: colors.highlight),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        row('Available to spend', funds.available, theme.colorScheme.primary),
        row('Reserved for goals', funds.reserved, colors.highlight),
        const SizedBox(height: 12),
        Text(
          'Goal savings are included in this balance.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        if (funds.available < 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Some reserved savings are no longer covered by your balance.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.spending),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => onGoals(context), child: const Text('Manage savings goals')),
        ),
      ],
    );
  }
}
