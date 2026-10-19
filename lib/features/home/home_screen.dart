import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(now),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(_greeting(now), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            _SummaryCard(todayPoisha: 0, monthPoisha: 0),
            const SizedBox(height: 32),
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Tap the + button below to add your first expense.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.todayPoisha, required this.monthPoisha});

  final int todayPoisha;
  final int monthPoisha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent today', style: theme.textTheme.bodyMedium?.copyWith(color: on.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(
            formatTaka(todayPoisha),
            style: theme.textTheme.displaySmall?.copyWith(
              color: on,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This month: ${formatTaka(monthPoisha)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: on.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
