import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/periods.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  String today() => dayKey(DateTime.now());
  String daysFromNow(int n) => dayKey(DateTime.now().add(Duration(days: n)));

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(FilledButton, text));
    await h.settle(tester);
  }

  testWidgets('Reports shows totals and categories, and moves between periods', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    final transport = await h.category(tester, 'Transport');
    final salary = await h.category(tester, 'Salary', type: EntryType.income);
    await h.addEntry(tester, amount: 18000, categoryId: food.id, date: today());
    await h.addEntry(tester, amount: 6000, categoryId: transport.id, date: today());
    await h.addEntry(tester, type: EntryType.income, amount: 2000000, categoryId: salary.id, date: today());

    await tester.tap(find.text('Reports'));
    await h.settle(tester);

    expect(find.text(periodLabel(periodFor(PeriodType.month, DateTime.now()))), findsOneWidget);
    expect(find.text('৳240'), findsWidgets); // spent
    expect(find.text('৳20,000'), findsOneWidget); // income
    expect(find.text('Where it went'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget); // Food is 180 of 240
    expect(find.text('Each day this month'), findsOneWidget);
    expect(find.textContaining('Average per day'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await h.settle(tester);
    expect(find.text('Each day this week'), findsOneWidget);

    await tester.tap(find.text('Year'));
    await h.settle(tester);
    expect(find.text('Each month'), findsOneWidget);

    await tester.tap(find.text('Day'));
    await h.settle(tester);
    expect(find.text('Entries'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('−৳180'), 200);
    expect(find.text('−৳180'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('Previous'), -200);

    // Going back a day finds nothing, and the arrows turn it around again.
    await tester.tap(find.byTooltip('Previous'));
    await h.settle(tester);
    expect(find.text('Nothing in this period'), findsOneWidget);
    await tester.tap(find.byTooltip('Next'));
    await h.settle(tester);
    expect(find.text('Entries'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

    await h.closeApp(tester);
  });

  testWidgets('Budgets: set a monthly budget, get warned at 80%, see it on Home', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Budgets');

    expect(find.text('Set monthly budget'), findsOneWidget);
    await tapButton(tester, 'Set monthly budget');
    await typeInto(tester, 'Spend at most, each month', '1000');
    await tapButton(tester, 'Save');
    expect(find.text('৳1,000 left'), findsOneWidget);

    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.text('Home'));
    await h.settle(tester);

    // Spending ৳150 on Food is 15%: no warning yet.
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 15000, categoryId: food.id, date: today());
    expect(find.textContaining('budget is'), findsNothing);

    // Another ৳700 through the add sheet takes it to 85%.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await h.settle(tester);
    for (final d in '700'.split('')) {
      await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text(d)));
      await tester.pump();
    }
    // "Food" is also on the Home list behind the sheet, so pick the sheet's own chip.
    await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text('Food')));
    await tester.pump();
    await tester.tap(find.text('Save ৳700'));
    await h.settle(tester);

    expect(find.textContaining('Monthly budget 85% used'), findsOneWidget); // the snackbar
    expect(find.text('Your monthly budget is 85% used'), findsOneWidget); // the Home warning
    expect(find.textContaining('left of ৳1,000 budget'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Budget warning still works when adding from another tab', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 100000));
    await h.addEntry(tester, amount: 15000, categoryId: food.id, date: today());

    // Home is now hidden behind the History tab, and the + button still works.
    await tester.tap(find.text('History'));
    await h.settle(tester);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await h.settle(tester);
    for (final d in '700'.split('')) {
      await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text(d)));
      await tester.pump();
    }
    await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text('Food')));
    await tester.pump();
    await tester.tap(find.text('Save ৳700'));
    await h.settle(tester);

    expect(find.textContaining('Monthly budget 85% used'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Budgets: a category budget shows its progress', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.write(tester, () => h.db.setBudget(categoryId: food.id, amountPoisha: 50000));
    await h.addEntry(tester, amount: 45000, categoryId: food.id, date: today());

    expect(find.text('Your Food budget is 90% used'), findsOneWidget);

    await h.openFromMore(tester, 'Budgets');
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('৳450 / ৳500'), findsOneWidget);
    expect(find.textContaining('৳50 left'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Recurring: confirm a due bill in one tap, and skip another', (tester) async {
    await h.pumpApp(tester);
    final rent = await h.category(tester, 'Rent');
    final bills = await h.category(tester, 'Bills & Recharge');
    await h.write(
      tester,
      () => h.db.addRecurring(
        title: 'Rent',
        type: EntryType.expense,
        amountPoisha: 800000,
        categoryId: rent.id,
        dayOfMonth: 1,
      ),
    );
    await h.write(
      tester,
      () => h.db.addRecurring(
        title: 'Wi-Fi',
        type: EntryType.expense,
        amountPoisha: 100000,
        categoryId: bills.id,
        dayOfMonth: 1,
      ),
    );

    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Wi-Fi'), findsOneWidget);

    // Skip Wi-Fi for this month.
    await tester.tap(find.widgetWithText(TextButton, 'Skip').last);
    await h.settle(tester);
    expect(find.text('Skipped Wi-Fi for this month'), findsOneWidget);
    expect(find.text('Wi-Fi'), findsNothing);
    await tester.pump(const Duration(seconds: 6)); // let the snackbar go away
    await h.settle(tester);

    // Confirm Rent, changing the amount for this month.
    await tapButton(tester, 'Add');
    expect(find.text('Rent'), findsWidgets);
    await typeInto(tester, 'Amount', '8500');
    await tapButton(tester, 'Add ৳8,500');

    final entries = await h.entries(tester);
    expect(entries.single.entry.amountPoisha, 850000);
    expect(entries.single.entry.note, 'Rent');
    expect(entries.single.entry.date, today());
    expect(find.text('Due'), findsNothing); // nothing left waiting

    await h.closeApp(tester);
  });

  testWidgets('Recurring: create one from the screen', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Monthly bills & income');
    expect(find.text('Nothing monthly yet'), findsOneWidget);

    await tester.tap(find.text('New'));
    await h.settle(tester);
    await typeInto(tester, 'Name (like Rent or Wi-Fi)', 'Electricity');
    await typeInto(tester, 'Usual amount', '1200');
    await tester.tap(find.text('Bills & Recharge'));
    await tester.pump();
    await tapButton(tester, 'Save');

    expect(find.text('Electricity'), findsOneWidget);
    expect(find.textContaining('৳1,200 · every month on day 1'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Goals: create a goal, add money, take some out', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Savings goals');
    expect(find.text('No savings goals yet'), findsOneWidget);

    await tester.tap(find.text('New goal'));
    await h.settle(tester);
    await typeInto(tester, 'What are you saving for?', 'Eid shopping');
    await typeInto(tester, 'Target amount', '10000');
    await tapButton(tester, 'Save');

    expect(find.text('Eid shopping'), findsOneWidget);
    expect(find.text('৳0 of ৳10,000'), findsOneWidget);

    await tester.tap(find.text('Eid shopping'));
    await h.settle(tester);
    await tapButton(tester, 'Add money');
    await typeInto(tester, 'Amount', '2000');
    await tapButton(tester, 'Add ৳2,000');
    expect(find.text('৳2,000'), findsWidgets);
    expect(find.text('+৳2,000'), findsOneWidget);

    await tester.tap(find.text('Take out'));
    await h.settle(tester);
    await typeInto(tester, 'Amount', '500');
    await tapButton(tester, 'Take out ৳500');
    expect(find.text('৳1,500'), findsWidgets);
    expect(find.text('−৳500'), findsOneWidget);

    // Saved money is never spending.
    expect(await h.entries(tester), isEmpty);

    await h.closeApp(tester);
  });

  testWidgets('Goals: a deadline shows how much to save each month', (tester) async {
    await h.pumpApp(tester);
    await h.write(
      tester,
      () => h.db.addGoal(
        name: 'Laptop',
        targetPoisha: 6000000,
        colorValue: 0xFF4C8DF6,
        deadline: daysFromNow(180),
      ),
    );
    await h.openFromMore(tester, 'Savings goals');

    expect(find.text('Laptop'), findsOneWidget);
    expect(find.textContaining('a month'), findsOneWidget);
    expect(find.textContaining('save ৳10,000 a month'), findsOneWidget); // 6 months: 60,000 / 6

    await h.closeApp(tester);
  });

  testWidgets('Dhar: lend money, receive it back in parts, and settle', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Dhar');
    expect(find.text('Nobody owes you'), findsOneWidget);

    await tester.tap(find.text('New'));
    await h.settle(tester);
    await typeInto(tester, 'Who did you lend to?', 'Rahim');
    await typeInto(tester, 'Amount', '1000');
    await tapButton(tester, 'Save');

    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('You will get'), findsOneWidget);
    expect(find.text('৳1,000'), findsWidgets);

    await tester.tap(find.text('Rahim'));
    await h.settle(tester);
    expect(find.text('You lent ৳1,000'), findsOneWidget);

    await tapButton(tester, 'Money received');
    await typeInto(tester, 'Amount', '400');
    await tapButton(tester, 'Save ৳400');
    expect(find.text('৳600 to receive'), findsOneWidget);

    await tapButton(tester, 'Money received');
    await tapButton(tester, 'Save ৳600'); // the field starts at what is left
    expect(find.text('Settled'), findsWidgets);

    // Dhar is not spending or income.
    expect(await h.entries(tester), isEmpty);

    await h.closeApp(tester);
  });

  testWidgets('Dhar: a due date schedules a reminder, and settling removes it', (tester) async {
    await h.pumpApp(tester);
    final id = await h.write(
      tester,
      () => h.db.addDhar(
        person: 'Karim',
        direction: DharDirection.lent,
        amountPoisha: 100000,
        date: today(),
        dueDate: daysFromNow(2),
      ),
    );

    final scheduled = h.notifications.dharSyncs.last.single;
    expect(scheduled.title, 'Karim owes you ৳1,000');
    expect(scheduled.id, id);
    expect(dayKey(scheduled.due), daysFromNow(2));

    // Due within three days: Home points at it.
    expect(find.text('Dhar due: Karim'), findsOneWidget);

    await h.write(tester, () => h.db.setDharSettled(id, true));
    expect(h.notifications.dharSyncs.last, isEmpty);
    expect(find.text('Dhar due: Karim'), findsNothing);

    await h.closeApp(tester);
  });

  testWidgets('Home shows the logging streak', (tester) async {
    await h.pumpApp(tester);
    expect(find.text('1 day'), findsNothing);

    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 1000, categoryId: food.id, date: daysFromNow(-2));
    await h.addEntry(tester, amount: 1000, categoryId: food.id, date: daysFromNow(-1));
    expect(find.text('2 days'), findsOneWidget); // yesterday and the day before; today still open

    await h.addEntry(tester, amount: 1000, categoryId: food.id, date: today());
    expect(find.text('3 days'), findsOneWidget);

    await h.closeApp(tester);
  });
}
