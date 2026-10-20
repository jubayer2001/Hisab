import '../../core/dates.dart';
import '../db/app_database.dart';

enum BudgetLevel { ok, warning, over }

/// Where one budget stands this month. [category] is null for the overall monthly budget.
class BudgetStatus {
  const BudgetStatus({required this.budget, required this.category, required this.spent});

  final Budget budget;
  final Category? category;
  final int spent;

  bool get isOverall => budget.categoryId == null;
  int get limit => budget.amountPoisha;
  int get remaining => limit - spent;
  String get name => category?.name ?? 'Monthly';

  double get fraction => limit <= 0 ? 0 : spent / limit;

  BudgetLevel get level {
    if (fraction >= 1) return BudgetLevel.over;
    if (fraction >= warnAt) return BudgetLevel.warning;
    return BudgetLevel.ok;
  }
}

/// A budget turns to "warning" when this much of it is used.
const double warnAt = 0.8;

/// Statuses for this month: the overall budget first, then the rest, most used first.
List<BudgetStatus> computeBudgetStatuses({
  required List<EntryWithCategory> entries,
  required List<Budget> budgets,
  required List<Category> categories,
  required DateTime now,
}) {
  final month = monthKey(now);
  var total = 0;
  final perCategory = <int, int>{};
  for (final e in entries) {
    if (!e.isExpense || !e.entry.date.startsWith(month)) continue;
    total += e.entry.amountPoisha;
    perCategory.update(e.entry.categoryId, (v) => v + e.entry.amountPoisha, ifAbsent: () => e.entry.amountPoisha);
  }

  final byId = {for (final c in categories) c.id: c};
  final statuses = [
    for (final b in budgets)
      if (b.categoryId == null)
        BudgetStatus(budget: b, category: null, spent: total)
      else if (byId[b.categoryId] != null)
        BudgetStatus(budget: b, category: byId[b.categoryId], spent: perCategory[b.categoryId] ?? 0),
  ];

  statuses.sort((a, b) {
    if (a.isOverall != b.isOverall) return a.isOverall ? -1 : 1;
    return b.fraction.compareTo(a.fraction);
  });
  return statuses;
}

/// If adding [addedPoisha] to [categoryId] would push a budget past 80% or 100%, a short
/// message saying so. Used right after saving an expense.
String? budgetWarningAfterAdding(List<BudgetStatus> before, {required int categoryId, required int addedPoisha}) {
  String? warning;
  for (final s in before) {
    if (!s.isOverall && s.budget.categoryId != categoryId) continue;
    if (s.limit <= 0) continue;
    final after = (s.spent + addedPoisha) / s.limit;
    if (s.fraction < 1 && after >= 1) {
      return 'Over your ${s.isOverall ? 'monthly' : s.name} budget';
    }
    if (s.fraction < warnAt && after >= warnAt) {
      warning ??= '${s.isOverall ? 'Monthly' : s.name} budget ${(after * 100).floor()}% used';
    }
  }
  return warning;
}
