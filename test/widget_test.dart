import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text(d)));
      await tester.pump();
    }
  }

  testWidgets('starts on Home with empty totals and switches tabs', (tester) async {
    await h.pumpApp(tester);

    expect(find.text('Spent today'), findsOneWidget);
    expect(find.text('Nothing added today'), findsOneWidget);

    await tester.tap(find.text('History'));
    await h.settle(tester);
    expect(find.text('Nothing here yet'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await h.settle(tester);
    expect(find.text('Nothing in this period'), findsOneWidget);

    await tester.tap(find.text('More'));
    await h.settle(tester);
    expect(find.text('Budgets'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Appearance'), 300);
    expect(find.text('Appearance'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('adding an expense with the keypad shows it on Home and updates totals', (tester) async {
    await h.pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await h.settle(tester);
    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);

    // The bottom keypad row and the Save button must be reachable without scrolling.
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    // (The empty amount display also reads "0", so take the last match: the keypad key.)
    final zeroKey = find.descendant(of: find.byType(AddEntrySheet), matching: find.text('0')).last;
    expect(tester.getRect(zeroKey).bottom, lessThan(screenHeight));
    expect(tester.getRect(find.text('Enter an amount')).bottom, lessThan(screenHeight));

    await typeAmount(tester, '250');
    expect(find.text('Pick a category'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(find.text('Save ৳250'), findsOneWidget);

    await tester.tap(find.text('Save ৳250'));
    await h.settle(tester);

    expect(find.byType(AddEntrySheet), findsNothing);
    expect(find.text('−৳250'), findsOneWidget); // the entry row
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Saved ৳250 · Food'), findsOneWidget); // confirmation

    final saved = await h.entries(tester);
    expect(saved.single.entry.amountPoisha, 25000);
    expect(saved.single.entry.date, dayKey(DateTime.now()));

    await h.closeApp(tester);
  });

  testWidgets('income counts toward balance, not spending', (tester) async {
    await h.pumpApp(tester);
    final salary = await h.category(tester, 'Salary', type: EntryType.income);
    await h.addEntry(
      tester,
      type: EntryType.income,
      amount: 5000000,
      categoryId: salary.id,
      date: dayKey(DateTime.now()),
    );

    expect(find.text('+৳50,000'), findsOneWidget); // entry row
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('editing an entry changes it, and deleting from the sheet offers Undo', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 18000, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Lunch');

    await tester.tap(find.text('Lunch'));
    await h.settle(tester);
    expect(find.text('Edit expense'), findsOneWidget);

    // Backspace twice (180 -> 1), then add 5 -> 15.
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    await typeAmount(tester, '5');
    await tester.tap(find.text('Save changes'));
    await h.settle(tester);

    expect((await h.entries(tester)).single.entry.amountPoisha, 1500);

    await tester.tap(find.text('Lunch'));
    await h.settle(tester);
    await tester.tap(find.byTooltip('Delete'));
    await h.settle(tester);
    expect(await h.entries(tester), isEmpty);

    await tester.tap(find.text('Undo'));
    await h.settle(tester);
    expect((await h.entries(tester)).single.entry.amountPoisha, 1500);

    await h.closeApp(tester);
  });

  testWidgets('History groups by day and search filters', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    final transport = await h.category(tester, 'Transport');
    final today = dayKey(DateTime.now());
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    await h.addEntry(tester, amount: 18000, categoryId: food.id, date: today, note: 'Lunch');
    await h.addEntry(tester, amount: 6000, categoryId: transport.id, date: yesterday);

    await tester.tap(find.text('History'));
    await h.settle(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lunch');
    await h.settle(tester);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Transport'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await h.settle(tester);
    expect(find.text('No matches'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('quick add chip adds a repeat expense in one tap', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = dayKey(DateTime.now().subtract(const Duration(days: 2)));
    for (final date in [yesterday, twoDaysAgo]) {
      await h.addEntry(tester, amount: 1000, categoryId: food.id, date: date, note: 'Tea');
    }

    expect(find.text('Quick add'), findsOneWidget);
    await tester.tap(find.text('Tea ৳10'));
    await h.settle(tester);

    final today = dayKey(DateTime.now());
    final added = (await h.entries(tester)).where((e) => e.entry.date == today).toList();
    expect(added.single.entry.amountPoisha, 1000);
    expect(added.single.entry.note, 'Tea');

    await h.closeApp(tester);
  });

  testWidgets('reminder text follows what was logged, and skips tonight when marked', (tester) async {
    await h.pumpApp(tester);
    expect(h.notifications.syncs.last.todayBody, contains("haven't added any expenses"));
    expect(h.notifications.syncs.last.enabled, isTrue);
    expect(h.notifications.syncs.last.minutes, 22 * 60);

    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 64500, categoryId: food.id, date: dayKey(DateTime.now()));
    expect(h.notifications.syncs.last.todayBody, '৳645 logged today. Anything else to add?');

    await h.write(tester, () => h.db.setNoSpend(dayKey(DateTime.now()), true));
    expect(h.notifications.syncs.last.todayBody, isNull);

    await h.closeApp(tester);
  });

  testWidgets('No spending today card marks the day', (tester) async {
    await h.pumpApp(tester);
    expect(find.text('Nothing spent today?'), findsOneWidget);

    await tester.tap(find.text('No spending'));
    await h.settle(tester);

    expect(find.text('Marked as no spending today'), findsOneWidget);
    expect(await h.real(tester, () => h.db.watchNoSpendDays().first), {dayKey(DateTime.now())});

    await h.closeApp(tester);
  });

  testWidgets('More: reminder switch and test notification', (tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.text('More'));
    await h.settle(tester);

    // The reminder settings sit below the money tools, so scroll to them.
    await tester.scrollUntilVisible(find.text('Remind me every evening'), 300);
    expect(find.text('10:00 PM'), findsOneWidget);

    await tester.ensureVisible(find.text('Send a test reminder'));
    await tester.pump();
    await tester.tap(find.text('Send a test reminder'));
    await tester.pump();
    expect(h.notifications.testNotifications, 1);

    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    expect(h.notifications.syncs.last.enabled, isFalse);

    await h.closeApp(tester);
  });
}
