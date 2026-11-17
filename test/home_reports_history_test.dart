import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/theme.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/widgets/charts.dart';
import 'package:hisab/core/widgets/summary_stats.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/budgets.dart';
import 'package:hisab/data/logic/home_logic.dart';
import 'package:hisab/data/logic/planning.dart';

import 'support/harness.dart';

BudgetStatus _overall({required int limit, required int spent}) => BudgetStatus(
  budget: Budget(id: 1, amountPoisha: limit),
  category: null,
  spent: spent,
);

GoalProgress _goal(
  String name, {
  String? deadline,
  int saved = 0,
  int target = 100000,
}) => GoalProgress(
  goal: SavingsGoal(
    id: name.hashCode,
    name: name,
    targetPoisha: target,
    deadline: deadline,
    colorValue: 0xFF157A6E,
  ),
  saved: saved,
  monthsLeft: deadline == null ? null : 3,
  monthlyNeeded: null,
);

Recurring _bill(
  String title,
  int day, {
  int amount = 110000,
  String? handled,
  bool active = true,
  bool auto = false,
  String type = EntryType.expense,
}) => Recurring(
  id: title.hashCode + day,
  title: title,
  type: type,
  amountPoisha: amount,
  categoryId: 1,
  dayOfMonth: day,
  isActive: active,
  lastHandledMonth: handled,
  autoAdd: auto,
);

/// Fails with the full layout error (which names the widget) if anything overflowed.
void _noOverflow(WidgetTester tester) {
  final error = tester.takeException();
  if (error == null) return;
  final text = error is FlutterError
      ? error.diagnostics.map((d) => d.toStringDeep()).join('\n')
      : '$error';
  fail(text);
}

void main() {
  group('Home slot beside "Spent today" (the user\'s choice)', () {
    final day = DateTime(2026, 11, 17); // 14 days left including today

    HomeSlot? slot(
      HomeDetail choice, {
      BudgetStatus? budget,
      int week = 0,
      int month = 0,
      List<Recurring> bills = const [],
      bool warnings = true,
    }) => computeHomeSlot(
      choice: choice,
      overall: budget,
      weekExpense: week,
      monthExpense: month,
      recurrings: bills,
      today: day,
      showBudgetWarnings: warnings,
    );

    test('the default, nothing, shows nothing whatever the data says', () {
      final over = _overall(limit: 3000000, spent: 3120000);
      expect(slot(HomeDetail.none, budget: over, week: 5000, month: 9000, bills: [_bill('Wi-Fi', 17)]), isNull);
    });

    test('budget status: on track shows the daily allowance in whole Taka', () {
      final s = slot(HomeDetail.budget, budget: _overall(limit: 3000000, spent: 1245000))!; // ৳17,550 over 14 days
      expect(s.kind, HomeSlotKind.allowance);
      expect(s.value, '৳1,253 / day');
      expect(s.route, '/budgets');
    });

    test('budget status: 80% used and over the budget are warnings', () {
      final warn = slot(HomeDetail.budget, budget: _overall(limit: 3000000, spent: 2460000))!;
      expect(warn.kind, HomeSlotKind.warning);
      expect(warn.label, 'Budget 82% used');
      expect(warn.value, '৳5,400 left');
      final over = slot(HomeDetail.budget, budget: _overall(limit: 3000000, spent: 3120000))!;
      expect(over.kind, HomeSlotKind.over);
      expect(over.value, '৳1,200');
    });

    test('budget status: with budget warnings hidden the warnings step aside, and no budget means nothing', () {
      expect(
        slot(HomeDetail.budget, budget: _overall(limit: 3000000, spent: 2460000), warnings: false)!.kind,
        HomeSlotKind.allowance,
      );
      expect(slot(HomeDetail.budget, budget: _overall(limit: 3000000, spent: 3120000), warnings: false), isNull);
      expect(slot(HomeDetail.budget), isNull);
    });

    test('this week and the daily average appear only once something was spent', () {
      expect(slot(HomeDetail.week, week: 124000)!.value, '৳1,240');
      expect(slot(HomeDetail.week), isNull);
      // ৳5,582 over the 17 days so far
      expect(slot(HomeDetail.average, month: 558200)!.value, '৳328 / day');
      expect(slot(HomeDetail.average), isNull);
    });

    test('bill due soon: the nearest bill within 3 days, late ones too; income, paused and automatic ones never', () {
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 20), _bill('Wi-Fi', 18)])!.label, 'Wi-Fi · due tomorrow');
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 20)])!.label, 'Rent · in 3 days');
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 17)])!.label, 'Rent · due today');
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 15)])!.label, 'Rent · late');
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 20, amount: 550000)])!.value, '৳5,500');
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 21)]), isNull); // 4 days away
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 15, handled: '2026-11')]), isNull); // done this month
      expect(slot(HomeDetail.bill, bills: [_bill('Salary', 18, type: EntryType.income)]), isNull);
      expect(slot(HomeDetail.bill, bills: [_bill('Wi-Fi', 18, active: false)]), isNull);
      expect(slot(HomeDetail.bill, bills: [_bill('Wi-Fi', 18, auto: true)]), isNull);
      expect(slot(HomeDetail.bill, bills: [_bill('Rent', 20)])!.route, '/recurring');
      expect(slot(HomeDetail.week, week: 1000)!.route, isNull);
    });
  });

  for (final width in [280.0, 300.0, 340.0]) {
    testWidgets('the figures row never cuts a label off at ${width.toInt()} px', (tester) async {
      // The app's real font: the test default is far wider and would say nothing about a phone.
      final loader = FontLoader('HindSiliguri');
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/HindSiliguri-$weight.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
      }
      await loader.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const SummaryStats(
                  stats: [
                    SummaryStat('Spent this month', '৳5,582'),
                    SummaryStat('Income', '৳5,602'),
                    SummaryStat('Balance', '৳20'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final label in ['Spent this month', 'Income', 'Balance']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
        expect(paragraph.didExceedMaxLines, isFalse, reason: '"$label" was cut off at $width px');
      }
      // All three figures sit on one line.
      final ys = [for (final v in ['৳5,582', '৳5,602', '৳20']) tester.getTopLeft(find.text(v)).dy];
      expect(ys.every((y) => (y - ys.first).abs() < 0.5), isTrue, reason: 'figures are not level: $ys');
    });
  }

  test('Home features unfinished goals by deadline, then the rest, and reached goals last', () {
    final ordered = orderGoalsForHome([
      _goal('Done', saved: 100000),
      _goal('No deadline', saved: 90000),
      _goal('Later', deadline: '2027-03-01', saved: 50000),
      _goal('Soon', deadline: '2027-01-01', saved: 10000),
    ]);
    expect(
      [for (final g in ordered) g.goal.name],
      ['Soon', 'Later', 'No deadline', 'Done'],
    );
  });

  test('a tap on the donut finds the right slice, and ignores the hole and the outside', () {
    const size = 150.0, thickness = 22.0;
    int? at(double angleFromTop, {double radius = 64}) {
      final a = angleFromTop - math.pi / 2;
      return donutSliceAt(
        Offset(
          size / 2 + radius * math.cos(a),
          size / 2 + radius * math.sin(a),
        ),
        size: size,
        thickness: thickness,
        values: const [50, 30, 20],
      );
    }

    expect(at(0.2), 0); // just after 12 o'clock
    expect(at(math.pi * 2 * 0.6), 1); // 50%-80% of the way round
    expect(at(math.pi * 2 * 0.95), 2);
    expect(at(1, radius: 20), isNull); // the hole
    expect(at(1, radius: 90), isNull); // outside
    expect(
      donutSliceAt(
        const Offset(75, 11),
        size: size,
        thickness: thickness,
        values: const [],
      ),
      isNull,
    );
  });

  group('on the phone', () {
    late Harness h;
    setUp(() => h = Harness());

    String today() => dayKey(DateTime.now());

    Future<void> openMore(WidgetTester tester) async {
      await tester.tap(find.text('More'));
      await h.settle(tester);
    }

    testWidgets(
      'Home notices are hidden until the switch in More is turned on',
      (tester) async {
        await h.pumpApp(tester);
        final food = await h.category(tester, 'Food');
        await h.write(
          tester,
          () => h.db.setBudget(categoryId: food.id, amountPoisha: 50000),
        );
        await h.addEntry(
          tester,
          amount: 45000,
          categoryId: food.id,
          date: today(),
        );
        expect(find.text('Your Food budget is 90% used'), findsNothing);

        await openMore(tester);
        await tester.scrollUntilVisible(find.text('Show notices on Home'), 300);
        await tester.ensureVisible(find.text('Show notices on Home'));
        await tester.pump();
        await tester.tap(find.text('Show notices on Home'));
        await h.settle(tester);

        await tester.tap(find.text('Home'));
        await h.settle(tester);
        expect(find.text('Your Food budget is 90% used'), findsOneWidget);

        await h.closeApp(tester);
      },
    );

    testWidgets('each kind of notice can be hidden on its own', (tester) async {
      await h.pumpApp(
        tester,
        prefs: {...homeNoticesOn, 'homeNoticeBudget': false},
      );
      final food = await h.category(tester, 'Food');
      await h.write(
        tester,
        () => h.db.setBudget(categoryId: food.id, amountPoisha: 50000),
      );
      await h.addEntry(
        tester,
        amount: 45000,
        categoryId: food.id,
        date: today(),
      );
      expect(find.text('Your Food budget is 90% used'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets(
      'by default nothing is shown beside Spent today, even with a budget',
      (tester) async {
        await h.pumpApp(tester);
        await h.write(
          tester,
          () => h.db.setBudget(categoryId: null, amountPoisha: 3000000),
        );
        expect(find.text('Daily allowance'), findsNothing);
        expect(find.textContaining('/ day'), findsNothing);
        await h.closeApp(tester);
      },
    );

    testWidgets(
      'choosing Budget status shows the daily allowance beside Spent today',
      (tester) async {
        await h.pumpApp(tester, prefs: {'homeDetail': 'budget'});
        await h.write(
          tester,
          () => h.db.setBudget(categoryId: null, amountPoisha: 3000000),
        );
        expect(find.text('Daily allowance'), findsOneWidget);
        expect(find.textContaining('/ day'), findsOneWidget);
        await h.closeApp(tester);
      },
    );

    testWidgets(
      'the choice is made in More, saved, and shows on Home',
      (tester) async {
        await h.pumpApp(tester);
        final food = await h.category(tester, 'Food');
        await h.addEntry(
          tester,
          amount: 18000,
          categoryId: food.id,
          date: today(),
        );
        expect(find.text('This week'), findsNothing);

        await tester.tap(find.text('More'));
        await h.settle(tester);
        await tester.scrollUntilVisible(
          find.text('Show beside "Spent today"'),
          300,
        );
        await tester.ensureVisible(find.text('Show beside "Spent today"'));
        await tester.pump();
        expect(find.text('Nothing'), findsOneWidget); // the default
        await tester.tap(find.text('Show beside "Spent today"'));
        await h.settle(tester);
        await tester.tap(find.text('This week'));
        await h.settle(tester);
        expect(find.text('This week'), findsOneWidget); // now the row's subtitle

        await tester.tap(find.text('Home'));
        await h.settle(tester);
        expect(find.text('This week'), findsOneWidget);
        expect(find.text('৳180'), findsWidgets);
        await h.closeApp(tester);
      },
    );

    testWidgets(
      'going over the monthly budget shows an alert beside Spent today',
      (tester) async {
        await h.pumpApp(
          tester,
          prefs: {...homeNoticesOn, 'homeDetail': 'budget'},
        );
        final food = await h.category(tester, 'Food');
        await h.write(
          tester,
          () => h.db.setBudget(categoryId: null, amountPoisha: 100000),
        );
        await h.addEntry(
          tester,
          amount: 120000,
          categoryId: food.id,
          date: today(),
        );
        expect(find.text('Over budget by'), findsOneWidget);
        await h.closeApp(tester);
      },
    );

    testWidgets(
      'Savings goals appear on Home once a goal exists, and not before',
      (tester) async {
        await h.pumpApp(tester);
        expect(find.text('Savings goals'), findsNothing);

        final id = await h.real(
          tester,
          () => h.db.addGoal(
            name: 'New laptop',
            targetPoisha: 6000000,
            colorValue: 0xFF4C8DF6,
          ),
        );
        await h.write(
          tester,
          () =>
              h.db.addDeposit(goalId: id, amountPoisha: 3600000, date: today()),
        );
        expect(find.text('Savings goals'), findsOneWidget);
        expect(find.text('New laptop'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        expect(find.text('No deadline set'), findsOneWidget);
        await h.closeApp(tester);
      },
    );

    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets(
        'Home and Reports fit a ${width.toInt()}-px-wide phone with everything showing',
        (tester) async {
          await h.pumpApp(
            tester,
            prefs: {...homeNoticesOn, 'homeDetail': 'budget'},
          );
          final food = await h.category(tester, 'Food');
          final salary = await h.category(
            tester,
            'Salary',
            type: EntryType.income,
          );
          await h.write(
            tester,
            () => h.db.setBudget(categoryId: null, amountPoisha: 10000000),
          );
          await h.addEntry(
            tester,
            amount: 12500000,
            categoryId: food.id,
            date: today(),
            note: 'Big purchase',
          );
          await h.addEntry(
            tester,
            type: EntryType.income,
            amount: 4500000,
            categoryId: salary.id,
            date: today(),
          );
          final id = await h.real(
            tester,
            () => h.db.addGoal(
              name: 'A goal with a rather long name indeed',
              targetPoisha: 6000000,
              colorValue: 0xFF4C8DF6,
              deadline: '2030-01-01',
            ),
          );
          await h.write(
            tester,
            () => h.db.addDeposit(
              goalId: id,
              amountPoisha: 100000,
              date: today(),
            ),
          );

          tester.view.physicalSize = Size(width * 2.75, 2400);
          await h.settle(tester);
          _noOverflow(tester);
          expect(find.text('Over budget by'), findsOneWidget);
          expect(find.text('Savings goals'), findsOneWidget);

          await tester.tap(find.text('Reports'));
          await h.settle(tester);
          _noOverflow(tester);
          expect(find.text('Shortfall'), findsOneWidget);
          await h.closeApp(tester);
        },
      );
    }

    testWidgets(
      'Reports: tapping a category lists everything spent on it for the period',
      (tester) async {
        await h.pumpApp(tester);
        final food = await h.category(tester, 'Food');
        final transport = await h.category(tester, 'Transport');
        await h.addEntry(
          tester,
          amount: 18000,
          categoryId: food.id,
          date: today(),
          note: 'Team lunch',
        );
        await h.addEntry(
          tester,
          amount: 6000,
          categoryId: transport.id,
          date: today(),
          note: 'Rickshaw ride',
        );

        await tester.tap(find.text('Reports'));
        await h.settle(tester);
        expect(find.text('Team lunch'), findsNothing);

        await tester.tap(find.text('Food'));
        await h.settle(tester);
        expect(find.text('Team lunch'), findsOneWidget);
        expect(find.text('Rickshaw ride'), findsNothing);
        expect(find.textContaining('1 entry'), findsOneWidget);
        expect(find.textContaining('75% of spending'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await h.settle(tester);
        expect(find.text('Team lunch'), findsNothing);
        await h.closeApp(tester);
      },
    );

    testWidgets(
      'History: Day, Month and Year narrow the list, and the arrows move back',
      (tester) async {
        await h.pumpApp(tester);
        final food = await h.category(tester, 'Food');
        final now = DateTime.now();
        await h.addEntry(
          tester,
          amount: 10000,
          categoryId: food.id,
          date: today(),
          note: 'Tea today',
        );
        await h.addEntry(
          tester,
          amount: 20000,
          categoryId: food.id,
          date: dayKey(DateTime(now.year, now.month - 1, 15)),
          note: 'Last month lunch',
        );
        await h.addEntry(
          tester,
          amount: 30000,
          categoryId: food.id,
          date: dayKey(DateTime(now.year - 1, 6, 15)),
          note: 'Last year dinner',
        );

        await tester.tap(find.text('History'));
        await h.settle(tester);
        // "All" is the old behaviour: everything is listed.
        expect(find.text('Tea today'), findsOneWidget);
        expect(find.text('Last month lunch'), findsOneWidget);
        expect(find.text('Last year dinner'), findsOneWidget);

        await tester.tap(find.text('Day'));
        await h.settle(tester);
        expect(find.text('Tea today'), findsOneWidget);
        expect(find.text('Last month lunch'), findsNothing);
        await tester.tap(find.byTooltip('Previous'));
        await h.settle(tester);
        expect(find.text('Nothing in this day'), findsOneWidget);

        await tester.tap(find.text('Month'));
        await h.settle(tester);
        expect(find.text('This month'), findsOneWidget);
        expect(find.text('Tea today'), findsOneWidget);
        expect(find.text('Last month lunch'), findsNothing);
        await tester.tap(find.byTooltip('Previous'));
        await h.settle(tester);
        expect(find.text('Last month lunch'), findsOneWidget);
        expect(find.text('Tea today'), findsNothing);
        await tester.tap(find.byTooltip('Next'));
        await h.settle(tester);
        expect(find.text('Tea today'), findsOneWidget);

        await tester.tap(find.text('Year'));
        await h.settle(tester);
        expect(find.text('This year'), findsOneWidget);
        expect(find.text('Last year dinner'), findsNothing);
        await tester.tap(find.byTooltip('Previous'));
        await h.settle(tester);
        expect(find.text('Last year dinner'), findsOneWidget);

        await tester.tap(find.text('All').first);
        await h.settle(tester);
        expect(find.text('Tea today'), findsOneWidget);
        expect(find.text('Last year dinner'), findsOneWidget);
        await h.closeApp(tester);
      },
    );
  });
}
