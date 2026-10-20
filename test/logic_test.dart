import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/budgets.dart';
import 'package:hisab/data/logic/periods.dart';
import 'package:hisab/data/logic/planning.dart';
import 'package:hisab/data/logic/reports.dart';

const _food = Category(
  id: 1, name: 'Food', type: EntryType.expense, iconKey: 'food', colorValue: 0xFFF29E4C, sortOrder: 0, isArchived: false,
);
const _transport = Category(
  id: 2, name: 'Transport', type: EntryType.expense, iconKey: 'bus', colorValue: 0xFF4C8DF6, sortOrder: 1, isArchived: false,
);
const _salary = Category(
  id: 11, name: 'Salary', type: EntryType.income, iconKey: 'salary', colorValue: 0xFF2E9E6B, sortOrder: 10, isArchived: false,
);

var _nextId = 1;

EntryWithCategory _entry(Category c, int poisha, String date) {
  final id = _nextId++;
  return EntryWithCategory(
    Entry(
      id: id, type: c.type, amountPoisha: poisha, categoryId: c.id,
      paymentMethod: null, note: null, date: date, createdAt: DateTime(2026, 10, 1).add(Duration(minutes: id)), recurringId: null,
    ),
    c,
  );
}

Recurring _recurring({int day = 1, bool active = true, String? handled}) => Recurring(
      id: 1, title: 'Rent', type: EntryType.expense, amountPoisha: 800000, categoryId: 1,
      dayOfMonth: day, isActive: active, lastHandledMonth: handled, autoAdd: false, startMonth: null,
    );

SavingsGoal _goal({String? deadline, int target = 1000000}) =>
    SavingsGoal(id: 1, name: 'Eid shopping', targetPoisha: target, deadline: deadline, colorValue: 0xFFE86A9A);

GoalDeposit _deposit(int poisha, {int goalId = 1, int id = 1}) =>
    GoalDeposit(id: id, goalId: goalId, amountPoisha: poisha, date: '2026-10-01');

DharRecord _dhar({
  int id = 1,
  String direction = DharDirection.lent,
  int amount = 100000,
  String? due,
  bool settled = false,
}) =>
    DharRecord(
      id: id, person: 'Rahim', direction: direction, amountPoisha: amount,
      date: '2026-10-01', dueDate: due, note: null, settled: settled,
    );

DharPayment _payment(int poisha, {int dharId = 1, int id = 1}) =>
    DharPayment(id: id, dharId: dharId, amountPoisha: poisha, date: '2026-10-05');

void main() {
  // Tuesday 20 October 2026.
  final now = DateTime(2026, 10, 20, 21, 30);

  group('periods', () {
    test('a week runs Saturday to Friday', () {
      for (final day in [17, 18, 20, 23]) {
        final week = periodFor(PeriodType.week, DateTime(2026, 10, day));
        expect(week.start, DateTime(2026, 10, 17), reason: '$day Oct');
        expect(week.end, DateTime(2026, 10, 23), reason: '$day Oct');
      }
      expect(periodFor(PeriodType.week, DateTime(2026, 10, 24)).start, DateTime(2026, 10, 24));
    });

    test('month and year bounds, including leap years', () {
      expect(periodFor(PeriodType.month, now).end, DateTime(2026, 10, 31));
      expect(periodFor(PeriodType.month, DateTime(2026, 2, 10)).end, DateTime(2026, 2, 28));
      expect(periodFor(PeriodType.month, DateTime(2028, 2, 10)).end, DateTime(2028, 2, 29));
      final year = periodFor(PeriodType.year, now);
      expect(year.start, DateTime(2026, 1, 1));
      expect(year.end, DateTime(2026, 12, 31));
      expect(year.lengthInDays, 365);
    });

    test('shifting moves by whole periods and crosses year ends', () {
      final jan = periodFor(PeriodType.month, DateTime(2026, 1, 15));
      expect(shiftPeriod(jan, -1).start, DateTime(2025, 12, 1));
      expect(shiftPeriod(jan, 12).start, DateTime(2027, 1, 1));
      final week = periodFor(PeriodType.week, now);
      expect(shiftPeriod(week, -1).start, DateTime(2026, 10, 10));
      expect(shiftPeriod(periodFor(PeriodType.day, DateTime(2026, 3, 1)), -1).start, DateTime(2026, 2, 28));
      expect(shiftPeriod(periodFor(PeriodType.year, now), -1).start, DateTime(2025, 1, 1));
    });

    test('labels', () {
      expect(periodLabel(periodFor(PeriodType.day, now), now: now), 'Today');
      expect(periodLabel(periodFor(PeriodType.week, now)), '17–23 Oct');
      expect(periodLabel(periodFor(PeriodType.week, DateTime(2026, 10, 31))), '31 Oct–6 Nov');
      expect(periodLabel(periodFor(PeriodType.month, now)), 'October 2026');
      expect(periodLabel(periodFor(PeriodType.year, now)), '2026');
    });

    test('contains', () {
      final week = periodFor(PeriodType.week, now);
      expect(week.contains(DateTime(2026, 10, 17)), isTrue);
      expect(week.contains(DateTime(2026, 10, 23)), isTrue);
      expect(week.contains(DateTime(2026, 10, 24)), isFalse);
      expect(week.contains(DateTime(2026, 10, 16)), isFalse);
    });
  });

  group('buildReport', () {
    final entries = [
      _entry(_food, 18000, '2026-10-20'),
      _entry(_transport, 6000, '2026-10-20'),
      _entry(_food, 30000, '2026-10-17'), // Saturday: first bar of the week
      _entry(_salary, 2000000, '2026-10-01'),
      _entry(_food, 50000, '2026-10-10'), // previous week
      _entry(_food, 12000, '2026-09-15'), // previous month
    ];
    final deposits = [_deposit(200000), _deposit(-50000, id: 2)];

    test('week totals, categories and bars', () {
      final r = buildReport(
        all: entries, deposits: deposits, period: periodFor(PeriodType.week, now), now: now,
      );
      expect(r.expense, 54000);
      expect(r.income, 0);
      expect(r.entries, hasLength(3));
      expect(r.byCategory.map((c) => c.category.name), ['Food', 'Transport']);
      expect(r.byCategory.first.amount, 48000);
      expect(r.byCategory.first.share, closeTo(48000 / 54000, 1e-9));
      expect(r.bars.map((b) => b.label), ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
      expect(r.bars[0].amount, 30000); // Saturday 17th
      expect(r.bars[3].amount, 24000); // Tuesday 20th
      expect(r.bars.fold<int>(0, (s, b) => s + b.amount), r.expense);
      expect(r.previousExpense, 50000);
      expect(r.averagePerDay, 54000 ~/ 4); // Sat..Tue = 4 days so far
    });

    test('month report has a bar per day, income, balance and saved money', () {
      final r = buildReport(
        all: entries, deposits: deposits, period: periodFor(PeriodType.month, now), now: now,
      );
      expect(r.bars, hasLength(31));
      expect(r.bars[19].amount, 24000); // 20th
      expect(r.bars[0].amount, 0);
      expect(r.income, 2000000);
      expect(r.expense, 104000);
      expect(r.balance, 1896000);
      expect(r.saved, 150000); // 200,000 in, 50,000 back out
      expect(r.previousExpense, 12000);
      expect(r.averagePerDay, 104000 ~/ 20);
    });

    test('year report groups by month', () {
      final r = buildReport(
        all: entries, deposits: deposits, period: periodFor(PeriodType.year, now), now: now,
      );
      expect(r.bars, hasLength(12));
      expect(r.bars[9].amount, 104000); // October
      expect(r.bars[8].amount, 12000); // September
      expect(r.bars[0].label, 'Jan');
    });

    test('day report lists that day and has no bars', () {
      final r = buildReport(
        all: entries, deposits: deposits, period: periodFor(PeriodType.day, now), now: now,
      );
      expect(r.bars, isEmpty);
      expect(r.entries, hasLength(2));
      expect(r.expense, 24000);
      expect(r.averagePerDay, 24000);
    });

    test('a finished period averages over its whole length; a future one is zero', () {
      final past = buildReport(
        all: entries, deposits: const [], period: periodFor(PeriodType.month, DateTime(2026, 9, 1)), now: now,
      );
      expect(past.averagePerDay, 12000 ~/ 30);
      final future = buildReport(
        all: entries, deposits: const [], period: periodFor(PeriodType.month, DateTime(2026, 12, 1)), now: now,
      );
      expect(future.averagePerDay, 0);
      expect(future.isEmpty, isTrue);
    });
  });

  group('budgets', () {
    final overall = const Budget(id: 1, categoryId: null, amountPoisha: 100000);
    final foodBudget = const Budget(id: 2, categoryId: 1, amountPoisha: 50000);
    final all = const [_food, _transport, _salary];

    List<BudgetStatus> statuses(List<EntryWithCategory> e) =>
        computeBudgetStatuses(entries: e, budgets: [foodBudget, overall], categories: all, now: now);

    test('overall comes first and spending counts only this month', () {
      final s = statuses([
        _entry(_food, 30000, '2026-10-03'),
        _entry(_transport, 20000, '2026-10-04'),
        _entry(_food, 99999, '2026-09-30'), // last month
        _entry(_salary, 500000, '2026-10-01'), // income is not spending
      ]);
      expect(s.first.isOverall, isTrue);
      expect(s.first.spent, 50000);
      expect(s.first.remaining, 50000);
      expect(s.last.name, 'Food');
      expect(s.last.spent, 30000);
    });

    test('levels switch at 80% and 100%', () {
      BudgetLevel foodLevel(int spent) => statuses([_entry(_food, spent, '2026-10-03')])
          .firstWhere((x) => !x.isOverall)
          .level;
      expect(foodLevel(39999), BudgetLevel.ok);
      expect(foodLevel(40000), BudgetLevel.warning);
      expect(foodLevel(49999), BudgetLevel.warning);
      expect(foodLevel(50000), BudgetLevel.over);
      expect(foodLevel(80000), BudgetLevel.over);
    });

    test('warning messages when an expense crosses a line', () {
      final before = statuses([_entry(_food, 35000, '2026-10-03')]);
      expect(budgetWarningAfterAdding(before, categoryId: 1, addedPoisha: 1000), isNull);
      expect(budgetWarningAfterAdding(before, categoryId: 1, addedPoisha: 5000), 'Food budget 80% used');
      expect(budgetWarningAfterAdding(before, categoryId: 1, addedPoisha: 15000), 'Over your Food budget');
      // A transport expense does not touch the Food budget, but does move the overall one.
      expect(budgetWarningAfterAdding(before, categoryId: 2, addedPoisha: 5000), isNull);
      expect(budgetWarningAfterAdding(before, categoryId: 2, addedPoisha: 45000), 'Monthly budget 80% used');
      expect(budgetWarningAfterAdding(before, categoryId: 2, addedPoisha: 65000), 'Over your monthly budget');
    });

    test('already over budget does not warn again', () {
      final before = statuses([_entry(_food, 60000, '2026-10-03')]);
      expect(budgetWarningAfterAdding(before, categoryId: 1, addedPoisha: 1000), isNull);
    });
  });

  group('recurring bills', () {
    test('the due day is clamped to short months', () {
      expect(recurringDueDate(_recurring(day: 31), DateTime(2026, 2, 5)), DateTime(2026, 2, 28));
      expect(recurringDueDate(_recurring(day: 31), DateTime(2026, 4, 5)), DateTime(2026, 4, 30));
      expect(recurringDueDate(_recurring(day: 5), DateTime(2026, 10, 20)), DateTime(2026, 10, 5));
    });

    test('due once the day has come, until confirmed or skipped this month', () {
      expect(isRecurringDue(_recurring(day: 25), now), isFalse); // not yet
      expect(isRecurringDue(_recurring(day: 20), now), isTrue); // today
      expect(isRecurringDue(_recurring(day: 1), now), isTrue); // overdue
      expect(isRecurringDue(_recurring(day: 1, handled: '2026-10'), now), isFalse);
      expect(isRecurringDue(_recurring(day: 1, handled: '2026-09'), now), isTrue); // last month's
      expect(isRecurringDue(_recurring(day: 1, active: false), now), isFalse);
    });

    test('next date is this month while waiting, next month once handled', () {
      expect(nextRecurringDate(_recurring(day: 25), now), DateTime(2026, 10, 25));
      expect(nextRecurringDate(_recurring(day: 1), now), DateTime(2026, 10, 1)); // overdue
      expect(nextRecurringDate(_recurring(day: 1, handled: '2026-10'), now), DateTime(2026, 11, 1));
      expect(nextRecurringDate(_recurring(day: 31, handled: '2026-10'), now), DateTime(2026, 11, 30));
    });
  });

  group('savings goals', () {
    test('saved is the sum of deposits and withdrawals for that goal only', () {
      final p = computeGoalProgress(
        _goal(), [_deposit(300000), _deposit(-50000, id: 2), _deposit(999999, goalId: 2, id: 3)], now,
      );
      expect(p.saved, 250000);
      expect(p.remaining, 750000);
      expect(p.fraction, closeTo(0.25, 1e-9));
      expect(p.isDone, isFalse);
      expect(p.monthsLeft, isNull);
      expect(p.monthlyNeeded, isNull);
    });

    test('monthly amount needed to reach the deadline', () {
      // 20 Oct to 20 Mar is 151 days, about 5 months. 800,000 left / 5 = 160,000 a month.
      final p = computeGoalProgress(_goal(deadline: '2027-03-20'), [_deposit(200000)], now);
      expect(p.monthsLeft, 5);
      expect(p.monthlyNeeded, 160000);
      expect(p.isOverdue, isFalse);
    });

    test('a deadline within the month counts as one month', () {
      final p = computeGoalProgress(_goal(deadline: '2026-10-25'), [_deposit(900000)], now);
      expect(p.monthsLeft, 1);
      expect(p.monthlyNeeded, 100000);
    });

    test('done and overdue goals', () {
      final done = computeGoalProgress(_goal(deadline: '2027-03-20'), [_deposit(1200000)], now);
      expect(done.isDone, isTrue);
      expect(done.remaining, 0);
      expect(done.fraction, 1.0);
      expect(done.monthlyNeeded, isNull);

      final overdue = computeGoalProgress(_goal(deadline: '2026-10-01'), [_deposit(100000)], now);
      expect(overdue.isOverdue, isTrue);
      expect(overdue.monthsLeft, 0);
      expect(overdue.monthlyNeeded, isNull);
    });
  });

  group('dhar', () {
    test('remaining shrinks with part payments and settles at zero', () {
      final views = computeDharViews([_dhar(amount: 100000)], [_payment(30000), _payment(20000, id: 2)]);
      expect(views.single.paid, 50000);
      expect(views.single.remaining, 50000);
      expect(views.single.isSettled, isFalse);
      expect(views.single.fraction, closeTo(0.5, 1e-9));

      final full = computeDharViews([_dhar(amount: 100000)], [_payment(100000)]);
      expect(full.single.isSettled, isTrue);
      expect(computeDharViews([_dhar(settled: true)], const []).single.isSettled, isTrue);
    });

    test('totals split into owed to you and owed by you, ignoring settled ones', () {
      final views = computeDharViews([
        _dhar(id: 1, amount: 100000),
        _dhar(id: 2, amount: 50000, direction: DharDirection.borrowed),
        _dhar(id: 3, amount: 70000, settled: true),
        _dhar(id: 4, amount: 40000, direction: DharDirection.borrowed),
      ], [_payment(30000, dharId: 1), _payment(10000, dharId: 4, id: 2)]);
      final totals = computeDharTotals(views);
      expect(totals.toReceive, 70000);
      expect(totals.toPay, 80000);
    });

    test('overdue and due soon', () {
      final today = DateTime(2026, 10, 20);
      DharView view(String? due, {bool settled = false}) =>
          computeDharViews([_dhar(due: due, settled: settled)], const []).single;
      expect(view('2026-10-19').isOverdue(today), isTrue);
      expect(view('2026-10-20').isOverdue(today), isFalse);
      expect(view('2026-10-20').isDueSoon(today), isTrue);
      expect(view('2026-10-23').isDueSoon(today), isTrue);
      expect(view('2026-10-24').isDueSoon(today), isFalse);
      expect(view('2026-10-19', settled: true).isOverdue(today), isFalse);
      expect(view(null).isDueSoon(today), isFalse);
    });

    test('open items first, earliest due date first, settled last', () {
      final views = computeDharViews([
        _dhar(id: 1, settled: true),
        _dhar(id: 2),
        _dhar(id: 3, due: '2026-11-05'),
        _dhar(id: 4, due: '2026-10-25'),
      ], const []);
      expect(views.map((v) => v.record.id), [4, 3, 2, 1]);
    });
  });

  group('logging streak', () {
    final today = DateTime(2026, 10, 20);

    test('counts consecutive days ending today', () {
      expect(computeStreak({'2026-10-20', '2026-10-19', '2026-10-18'}, today), 3);
    });

    test('stands at yesterday\'s count while today is still open', () {
      expect(computeStreak({'2026-10-19', '2026-10-18'}, today), 2);
    });

    test('a missed day resets it', () {
      expect(computeStreak({'2026-10-20', '2026-10-18', '2026-10-17'}, today), 1);
      expect(computeStreak({'2026-10-18', '2026-10-17'}, today), 0);
      expect(computeStreak(const {}, today), 0);
    });

    test('works across month and year ends', () {
      expect(computeStreak({'2027-01-01', '2026-12-31', '2026-12-30'}, DateTime(2027, 1, 1)), 3);
    });
  });
}
