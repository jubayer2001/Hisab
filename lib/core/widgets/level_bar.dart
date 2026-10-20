import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/logic/budgets.dart';

/// A thin rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.fraction, required this.color, this.height = 8});

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

/// Green-ish while fine, amber from 80% used, red once over the limit.
Color budgetLevelColor(BuildContext context, BudgetLevel level) {
  final colors = context.hisab;
  switch (level) {
    case BudgetLevel.ok:
      return Theme.of(context).colorScheme.primary;
    case BudgetLevel.warning:
      return colors.highlight;
    case BudgetLevel.over:
      return colors.spending;
  }
}
