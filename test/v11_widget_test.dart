import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/category_style.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/widgets/category_color_picker.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/periods.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  setUp(() => h = Harness());

  Future<int> seed(WidgetTester tester) => h.real(tester, () async {
    final categories = await h.db.watchCategories().first;
    final now = DateTime.now();
    final date = dayKey(DateTime(now.year, now.month - 1, 1));
    await h.db.addEntry(
      type: EntryType.income,
      amountPoisha: 3000000,
      categoryId: categories.firstWhere((c) => c.name == 'Salary').id,
      date: date,
    );
    await h.db.addEntry(
      type: EntryType.expense,
      amountPoisha: 2200000,
      categoryId: categories.firstWhere((c) => c.name == 'Food').id,
      date: date,
    );
    final goal = await h.db.addGoal(name: 'Laptop', targetPoisha: 1000000, colorValue: 0xFF4C8DF6);
    await h.db.allocateGoal(goalId: goal, amountPoisha: 300000, date: date);
    return goal;
  });

  testWidgets('Home carries previous cash quietly and opens the allocation on demand', (tester) async {
    await seed(tester);
    await h.pumpApp(tester);
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.text(formatTaka(800000)), findsOneWidget);
    expect(find.textContaining('Carries'), findsNothing);
    expect(find.text('Reserved for goals'), findsNothing);
    await tester.tap(find.text('Balance'));
    await h.settle(tester);
    expect(find.text('Available to spend'), findsOneWidget);
    expect(find.text(formatTaka(500000)), findsOneWidget);
    expect(find.text('Reserved for goals'), findsOneWidget);
    expect(find.text(formatTaka(300000)), findsOneWidget);
    await tester.tap(find.text('Manage savings goals'));
    await h.settle(tester);
    expect(find.text('Savings goals'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    await h.closeApp(tester);
  });

  testWidgets('Year displays twelve months and opens a historical monthly report on a narrow screen', (tester) async {
    await seed(tester);
    await h.pumpApp(tester);
    tester.view.physicalSize = const Size(880, 1925); // 320 logical pixels.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await h.settle(tester);
    expect(find.text('Saved balance'), findsOneWidget);
    expect(find.text(formatTaka(800000)), findsOneWidget);
    await tester.tap(find.text('Year'));
    await h.settle(tester);
    await tester.ensureVisible(find.text('Each month'));
    for (final month in ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']) {
      expect(find.text(month), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    // January always exists as a past/current month; its cell is a drill-down.
    await tester.ensureVisible(find.text('Jan'));
    await tester.tap(find.text('Jan'));
    await h.settle(tester);
    final january = periodFor(PeriodType.month, DateTime(DateTime.now().year, 1));
    await tester.scrollUntilVisible(find.text(periodLabel(january)), -200);
    expect(find.text(periodLabel(january)), findsOneWidget);
    expect(find.text('Each month'), findsNothing);
    expect(tester.takeException(), isNull);
    await h.closeApp(tester);
  });

  testWidgets('A goal purchase records one expense and deleting it restores the reservation', (tester) async {
    final goal = await seed(tester);
    await h.pumpApp(tester);
    await tester.tap(find.text('Balance'));
    await h.settle(tester);
    await tester.tap(find.text('Manage savings goals'));
    await h.settle(tester);
    await tester.tap(find.text('Laptop'));
    await h.settle(tester);
    await tester.tap(find.text('Spend from this goal'));
    await h.settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '500');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Spend ${formatTaka(50000)}'));
    await h.settle(tester);
    final linked = (await h.entries(tester)).where((e) => e.entry.savingsGoalId == goal).toList();
    expect(linked, hasLength(1));
    expect(linked.single.entry.amountPoisha, 50000);
    expect(find.text(formatTaka(250000)), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Delete expense'));
    await tester.tap(find.byTooltip('Delete expense'));
    await h.settle(tester);
    expect(find.text('Delete this entry?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect((await h.entries(tester)).where((e) => e.entry.savingsGoalId == goal), hasLength(1), reason: 'Cancel keeps it');
    await tester.tap(find.byTooltip('Delete expense'));
    await h.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await h.settle(tester);
    expect(find.text('${formatTaka(300000)} of ${formatTaka(1000000)}'), findsOneWidget);
    expect((await h.entries(tester)).where((e) => e.entry.savingsGoalId == goal), isEmpty);
    await tester.tap(find.text('Undo'));
    await h.settle(tester);
    expect((await h.entries(tester)).where((e) => e.entry.savingsGoalId == goal), hasLength(1));
    expect(find.text('${formatTaka(250000)} of ${formatTaka(1000000)}'), findsOneWidget);
    await h.closeApp(tester);
  });

  testWidgets('History edit keeps the native keypad and explains an unfunded goal expense inline', (tester) async {
    final goal = await seed(tester);
    await h.real(tester, () async {
      final food = (await h.db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await h.db.spendFromGoal(goalId: goal, amountPoisha: 50000, categoryId: food.id, date: dayKey(DateTime.now()));
    });
    await h.pumpApp(tester);
    await tester.tap(find.text('History'));
    await h.settle(tester);
    await tester.tap(find.text('Laptop'));
    await h.settle(tester);
    expect(find.byType(AddEntrySheet), findsOneWidget);
    await tester.ensureVisible(find.descendant(of: find.byType(AddEntrySheet), matching: find.text('0')));
    await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text('0')));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await h.settle(tester);
    expect(find.text('This is more than the goal’s saved amount.'), findsOneWidget);
    expect((await h.entries(tester)).singleWhere((e) => e.entry.savingsGoalId == goal).entry.amountPoisha, 50000);
    expect(find.byType(AddEntrySheet), findsOneWidget);
    await h.closeApp(tester);
  });

  testWidgets('Custom colour wheel cancels safely and saves a Donation symbol and picked colour', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Categories');
    await tester.tap(find.text('New category'));
    await h.settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Charity');
    await tester.ensureVisible(find.text('More symbols'));
    await tester.tap(find.text('More symbols'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(categoryIcons['donation']!));
    await tester.tap(find.byIcon(categoryIcons['donation']!));
    final custom = find.byKey(const ValueKey('custom-category-colour'));
    await tester.ensureVisible(custom);
    await tester.tap(custom);
    await h.settle(tester);
    expect(find.descendant(of: find.byType(CategoryColorPicker), matching: find.byType(TextField)), findsNothing);
    final preview = find.byKey(const ValueKey('selected-category-colour'));
    Color selected() => (tester.widget<Container>(preview).decoration! as BoxDecoration).color!;
    final original = selected();
    final wheel = find.byKey(const ValueKey('category-colour-wheel'));
    await tester.tapAt(tester.getCenter(wheel) + const Offset(70, 15));
    await tester.pump();
    expect(selected(), isNot(original));
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    await tester.ensureVisible(custom);
    await tester.tap(custom);
    await h.settle(tester);
    expect(selected(), original);
    await tester.tapAt(tester.getCenter(wheel) + const Offset(-70, 20));
    await tester.pump();
    final picked = selected().toARGB32();
    await tester.tap(find.text('Done'));
    await h.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await h.settle(tester);
    final saved = (await h.categories(tester)).singleWhere((c) => c.name == 'Charity');
    expect(saved.iconKey, 'donation');
    expect(saved.colorValue, picked);
    expect(tester.takeException(), isNull);
    await h.closeApp(tester);
  });
}
