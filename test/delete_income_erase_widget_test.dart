import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/widgets/profile_avatar.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/auto_income.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  String today() => dayKey(DateTime.now());

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  Future<void> addNotes(WidgetTester tester, List<String> notes) async {
    final food = await h.category(tester, 'Food');
    for (final n in notes) {
      await h.addEntry(tester, amount: 5000, categoryId: food.id, date: today(), note: n);
    }
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.text('History'));
    await h.settle(tester);
  }

  Future<List<String>> noteList(WidgetTester tester) async =>
      (await h.entries(tester)).map((e) => e.entry.note ?? '').toList();

  ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  group('a bin on every entry', () {
    testWidgets('History: the bin deletes that entry and Undo brings it back', (tester) async {
      await h.pumpApp(tester);
      await addNotes(tester, ['Lunch', 'Tea', 'Bus']);
      await openHistory(tester);

      expect(find.byTooltip('Delete entry'), findsNWidgets(3));
      await tester.tap(find.descendant(of: find.widgetWithText(InkWell, 'Tea'), matching: find.byTooltip('Delete entry')));
      await h.settle(tester);

      expect(await noteList(tester), isNot(contains('Tea')));
      expect(find.byTooltip('Delete entry'), findsNWidgets(2));
      expect(find.textContaining('Deleted ৳50'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      expect(await noteList(tester), containsAll(['Lunch', 'Tea', 'Bus']));
      await h.closeApp(tester);
    });

    testWidgets('Home: today\'s list has bins too', (tester) async {
      await h.pumpApp(tester);
      await addNotes(tester, ['Lunch']);

      await tester.tap(find.byTooltip('Delete entry'));
      await h.settle(tester);
      expect(await noteList(tester), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('swiping still deletes', (tester) async {
      await h.pumpApp(tester);
      await addNotes(tester, ['Lunch']);
      await tester.drag(find.text('Lunch'), const Offset(-500, 0));
      await h.settle(tester);
      expect(await noteList(tester), isEmpty);
      await h.closeApp(tester);
    });
  });

  group('deleting several at once', () {
    testWidgets('press and hold, tick more, delete, and one Undo brings them all back', (tester) async {
      await h.pumpApp(tester);
      await addNotes(tester, ['Lunch', 'Tea', 'Bus', 'Bazar']);
      await openHistory(tester);

      await tester.longPress(find.text('Tea'));
      await h.settle(tester);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byTooltip('Delete entry'), findsNothing, reason: 'bins give way to tick circles');

      // While selecting, a tap ticks instead of opening the edit sheet.
      await tester.tap(find.text('Bus'));
      await h.settle(tester);
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.text('Bus')); // untick
      await h.settle(tester);
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.text('Lunch'));
      await h.settle(tester);
      expect(find.text('Delete 2 entries'), findsOneWidget);

      await tester.tap(find.text('Delete 2 entries'));
      await h.settle(tester);
      expect((await noteList(tester)).toSet(), {'Bus', 'Bazar'});
      expect(find.text('Deleted 2 entries'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);

      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      expect((await noteList(tester)).toSet(), {'Lunch', 'Tea', 'Bus', 'Bazar'});
      await h.closeApp(tester);
    });

    testWidgets('"Select all" ticks everything, and closing leaves the data alone', (tester) async {
      await h.pumpApp(tester);
      await addNotes(tester, ['Lunch', 'Tea', 'Bus']);
      await openHistory(tester);

      await tester.longPress(find.text('Tea'));
      await h.settle(tester);
      await tester.tap(find.text('Select all'));
      await h.settle(tester);
      expect(find.text('3 selected'), findsOneWidget);
      expect(find.text('Delete 3 entries'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel selection'));
      await h.settle(tester);
      expect(find.textContaining('selected'), findsNothing);
      expect((await noteList(tester)).length, 3);
      await h.closeApp(tester);
    });
  });

  group('bins on the other lists', () {
    testWidgets('a goal asks first, mentions its deposits, and cancelling keeps it', (tester) async {
      await h.pumpApp(tester);
      final goal = await h.write(tester, () => h.db.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A));
      await h.write(tester, () => h.db.addDeposit(goalId: goal, amountPoisha: 1000, date: today()));
      await h.openFromMore(tester, 'Savings goals');

      await tester.tap(find.byTooltip('Delete this goal'));
      await h.settle(tester);
      expect(find.text('Delete this goal?'), findsOneWidget);
      expect(find.textContaining('"Eid" and its 1 deposit will be deleted'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await h.settle(tester);
      expect(await h.real(tester, () => h.db.watchGoals().first), hasLength(1));

      await tester.tap(find.byTooltip('Delete this goal'));
      await h.settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await h.settle(tester);
      expect(await h.real(tester, () => h.db.watchGoals().first), isEmpty);
      expect(await h.real(tester, () => h.db.watchDeposits().first), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('a dhar entry asks first and takes its payments with it', (tester) async {
      await h.pumpApp(tester);
      final id = await h.write(tester, () => h.db.addDhar(person: 'Rahim', direction: DharDirection.lent, amountPoisha: 5000, date: today()));
      await h.write(tester, () => h.db.addDharPayment(dharId: id, amountPoisha: 1000, date: today()));
      await h.openFromMore(tester, 'Dhar');

      await tester.tap(find.byTooltip('Delete this entry'));
      await h.settle(tester);
      expect(find.textContaining('Rahim and 1 payment will be deleted'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await h.settle(tester);

      expect(await h.real(tester, () => h.db.watchDhar().first), isEmpty);
      expect(await h.real(tester, () => h.db.watchDharPayments().first), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('a category budget is removed with Undo, and comes back with the same limit', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      await h.write(tester, () => h.db.setBudget(categoryId: food.id, amountPoisha: 800000));
      await h.openFromMore(tester, 'Budgets');

      await tester.tap(find.byTooltip('Remove this budget'));
      await h.settle(tester);
      expect(await h.real(tester, () => h.db.watchBudgets().first), isEmpty);

      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      final back = await h.real(tester, () => h.db.watchBudgets().first);
      expect(back.single.categoryId, food.id);
      expect(back.single.amountPoisha, 800000);
      await h.closeApp(tester);
    });

    testWidgets('a monthly item is deleted with Undo', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      await h.write(tester, () => h.db.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 100000, categoryId: food.id, dayOfMonth: 5));
      await h.openFromMore(tester, 'Monthly bills & income');

      await tester.tap(find.byTooltip('Delete this item'));
      await h.settle(tester);
      expect(await h.real(tester, () => h.db.watchRecurrings().first), isEmpty);
      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      expect((await h.real(tester, () => h.db.watchRecurrings().first)).single.title, 'Wi-Fi');
      await h.closeApp(tester);
    });
  });

  group('monthly income', () {
    /// Call this BEFORE pumpApp: once the app runs, its own income engine also writes, and two
    /// writers at once would wait on each other under the test's fake clock.
    Future<void> createSalary(WidgetTester tester, {int? day, bool received = true}) async {
      final salary = (await h.categories(tester)).firstWhere((c) => c.name == 'Salary');
      await h.real(
        tester,
        () => createMonthlyIncome(
          h.db,
          DateTime.now(),
          title: 'Salary',
          amountPoisha: 4500000,
          categoryId: salary.id,
          dayOfMonth: day ?? DateTime.now().day,
          receivedThisMonth: received,
        ),
      );
    }

    testWidgets('set up from the Monthly bills & income screen, it records itself', (tester) async {
      await h.pumpApp(tester);
      await h.openFromMore(tester, 'Monthly bills & income');
      expect(find.text('Nothing monthly yet'), findsOneWidget);

      await tester.tap(find.text('New'));
      await h.settle(tester);
      await tester.tap(find.text('Income'));
      await tester.pump();
      await typeInto(tester, 'Name (like Salary or Tuition)', 'Salary');
      await typeInto(tester, 'Usual amount', '45000');
      await tester.tap(find.text('Salary').last); // the category chip
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      expect(find.text('Monthly income'), findsOneWidget);
      expect(find.textContaining('+৳45,000 · every month on day 1'), findsOneWidget);
      expect(find.textContaining('Adds itself'), findsOneWidget);
      expect(find.textContaining('Regular income: ৳45,000 a month'), findsOneWidget);

      final entry = (await h.entries(tester)).single.entry;
      expect(entry.amountPoisha, 4500000);
      expect(entry.date, '${monthKey(DateTime.now())}-01');
      await h.closeApp(tester);
    });

    testWidgets('"Already received" off: nothing is added until next month', (tester) async {
      await h.pumpApp(tester);
      await h.openFromMore(tester, 'Monthly bills & income');
      await tester.tap(find.text('New'));
      await h.settle(tester);
      await tester.tap(find.text('Income'));
      await tester.pump();
      await typeInto(tester, 'Name (like Salary or Tuition)', 'Salary');
      await typeInto(tester, 'Usual amount', '45000');
      await tester.tap(find.text('Salary').last);
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(SwitchListTile, 'Already received this month'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Already received this month'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      expect(await h.entries(tester), isEmpty);
      expect((await h.real(tester, () => h.db.watchRecurrings().first)).single.autoAdd, isTrue);
      await h.closeApp(tester);
    });

    testWidgets('Home announces it, and "Dismiss" closes the note', (tester) async {
      await createSalary(tester);
      await h.pumpApp(tester);

      expect(find.textContaining('Salary ৳45,000 added today'), findsOneWidget);
      expect(find.text('Different this month?'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await h.settle(tester);
      expect(find.textContaining('added today'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('Change: only this month leaves the usual amount alone', (tester) async {
      await createSalary(tester);
      await h.pumpApp(tester);
      await tester.tap(find.text('Change'));
      await h.settle(tester);

      await typeInto(tester, 'Amount', '48500');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      expect((await h.entries(tester)).single.entry.amountPoisha, 4850000);
      expect((await h.real(tester, () => h.db.watchRecurrings().first)).single.amountPoisha, 4500000);
      await h.closeApp(tester);
    });

    testWidgets('Change: from now on updates the usual amount too', (tester) async {
      await createSalary(tester);
      await h.pumpApp(tester);
      await tester.tap(find.text('Change'));
      await h.settle(tester);

      await typeInto(tester, 'Amount', '50000');
      await tester.tap(find.text('From now on'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      expect((await h.entries(tester)).single.entry.amountPoisha, 5000000);
      expect((await h.real(tester, () => h.db.watchRecurrings().first)).single.amountPoisha, 5000000);
      await h.closeApp(tester);
    });

    testWidgets('"Didn\'t receive it" removes this month\'s entry, with Undo, and it stays removed', (tester) async {
      await createSalary(tester);
      await h.pumpApp(tester);
      await tester.tap(find.text('Change'));
      await h.settle(tester);
      await tester.tap(find.text('Didn\'t receive it this month'));
      await h.settle(tester);

      expect(await h.entries(tester), isEmpty);
      // The engine runs again (e.g. after the next app start) and must not bring it back.
      await h.write(tester, () => applyAutoIncome(h.db, DateTime.now()));
      expect(await h.entries(tester), isEmpty);

      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      expect(await h.entries(tester), hasLength(1));
      await h.closeApp(tester);
    });

    testWidgets('tapping Income on Home splits monthly income from extras', (tester) async {
      await createSalary(tester);
      await h.pumpApp(tester);
      final gift = (await h.categories(tester)).firstWhere((c) => c.name == 'Gift');
      await h.addEntry(tester, amount: 250000, categoryId: gift.id, date: today(), type: EntryType.income, note: 'Gift from Uncle');

      await tester.tap(find.text('Income'));
      await h.settle(tester);
      expect(find.textContaining('Income in '), findsOneWidget);
      expect(find.textContaining('Monthly ·'), findsOneWidget);
      expect(find.textContaining('Extra ·'), findsOneWidget);
      expect(find.text('৳47,500'), findsWidgets); // the total
      await h.closeApp(tester);
    });

    testWidgets('More and Account show the regular income', (tester) async {
      await createSalary(tester, received: false);
      await h.pumpApp(tester);

      await tester.tap(find.text('More'));
      await h.settle(tester);
      expect(find.textContaining('Income ৳45,000 a month', findRichText: true), findsOneWidget);

      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      expect(find.widgetWithText(ListTile, 'Monthly income'), findsOneWidget);
      expect(find.text('৳45,000'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('an automatic income never shows up in the "Due" list', (tester) async {
      await createSalary(tester, day: 1);
      await h.pumpApp(tester);
      expect(find.text('Due'), findsNothing);
      await h.closeApp(tester);
    });
  });

  group('erase all data', () {
    Future<void> fillSome(WidgetTester tester) async {
      await addNotes(tester, ['Lunch', 'Tea']);
      await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 2500000));
      await h.write(tester, () => h.db.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A));
    }

    Future<void> openErase(WidgetTester tester) async {
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.scrollUntilVisible(find.text('Erase all data'), 300);
      await tester.ensureVisible(find.text('Erase all data'));
      await tester.pump();
      await tester.tap(find.text('Erase all data'));
      await h.settle(tester);
    }

    bool eraseEnabled(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Erase everything')).onPressed != null;

    testWidgets('it shows what will go, and nothing happens until ERASE is typed', (tester) async {
      await h.pumpApp(tester);
      await fillSome(tester);
      await openErase(tester);

      expect(find.textContaining('This will erase 2 entries, 1 budget, 1 goal', findRichText: true), findsOneWidget);
      expect(eraseEnabled(tester), isFalse);
      await typeInto(tester, 'Type ERASE to confirm', 'ERAS');
      expect(eraseEnabled(tester), isFalse);
      await typeInto(tester, 'Type ERASE to confirm', 'erase');
      expect(eraseEnabled(tester), isTrue, reason: 'any capitalisation is accepted');
      expect(await noteList(tester), hasLength(2), reason: 'still untouched');
      await h.closeApp(tester);
    });

    testWidgets('erasing empties everything, keeps the name, and Account offers Undo', (tester) async {
      await h.pumpApp(tester);
      containerOf(tester).read(userNameProvider.notifier).set('Tania');
      await fillSome(tester);
      await openErase(tester);
      await typeInto(tester, 'Type ERASE to confirm', 'ERASE');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Erase everything'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Erase everything'));
      await h.settle(tester);

      // Back on Home, empty, still greeting by name.
      expect(find.textContaining(', Tania'), findsOneWidget);
      expect(await h.entries(tester), isEmpty);
      expect(await h.real(tester, () => h.db.watchBudgets().first), isEmpty);
      expect(await h.real(tester, () => h.db.watchGoals().first), isEmpty);
      expect(find.textContaining('Everything was erased'), findsOneWidget);

      // The default categories are back, ready for new entries.
      expect((await h.categories(tester)).length, 15);

      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      expect(find.textContaining('You erased your data on'), findsOneWidget);

      await tester.tap(find.text('Undo erase'));
      await h.settle(tester);
      expect(find.text('Undo the erase?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Bring it back'));
      await h.settle(tester);

      expect((await noteList(tester)).toSet(), {'Lunch', 'Tea'});
      expect((await h.real(tester, () => h.db.watchBudgets().first)).single.amountPoisha, 2500000);
      expect((await h.real(tester, () => h.db.watchGoals().first)).single.name, 'Eid');
      expect(find.textContaining('You erased your data on'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('Google, "this phone and Google": the Drive copy is deleted too and they stay signed in', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await fillSome(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);
      await tester.pump(const Duration(seconds: 6)); // let the "Signed in" message go, it covers the bottom
      await tester.pumpAndSettle();
      expect(h.cloud.stored, isNotNull);

      await tester.scrollUntilVisible(find.text('Erase all data'), 300);
      await tester.ensureVisible(find.text('Erase all data'));
      await tester.pump();
      await tester.tap(find.text('Erase all data'));
      await h.settle(tester);
      expect(find.text('Your Google copy'), findsOneWidget);
      await typeInto(tester, 'Type ERASE to confirm', 'ERASE');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Erase everything'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Erase everything'));
      await h.settle(tester);

      expect(h.cloud.deletes, 1);
      expect(h.cloud.stored, isNull);
      expect(h.cloud.signOuts, 0, reason: 'still signed in');
      expect(await h.entries(tester), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('Google, "this phone only": the Drive copy is left alone and they are signed out', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await fillSome(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);
      await tester.pump(const Duration(seconds: 6)); // let the "Signed in" message go, it covers the bottom
      await tester.pumpAndSettle();
      final before = h.cloud.stored;

      await tester.scrollUntilVisible(find.text('Erase all data'), 300);
      await tester.ensureVisible(find.text('Erase all data'));
      await tester.pump();
      await tester.tap(find.text('Erase all data'));
      await h.settle(tester);
      await tester.tap(find.text('This phone only'));
      await tester.pump();
      await typeInto(tester, 'Type ERASE to confirm', 'ERASE');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Erase everything'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Erase everything'));
      await h.settle(tester);

      expect(h.cloud.deletes, 0);
      expect(h.cloud.stored, before, reason: 'the Google copy is untouched');
      expect(h.cloud.signOuts, 1);
      expect(await h.entries(tester), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('if the Google copy cannot be deleted (offline), nothing is erased', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await fillSome(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);
      await tester.pump(const Duration(seconds: 6)); // let the "Signed in" message go, it covers the bottom
      await tester.pumpAndSettle();
      h.cloud.offline = true;

      await tester.scrollUntilVisible(find.text('Erase all data'), 300);
      await tester.ensureVisible(find.text('Erase all data'));
      await tester.pump();
      await tester.tap(find.text('Erase all data'));
      await h.settle(tester);
      await typeInto(tester, 'Type ERASE to confirm', 'ERASE');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Erase everything'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Erase everything'));
      await h.settle(tester);

      expect(find.textContaining('Nothing was erased'), findsOneWidget);
      expect(await noteList(tester), hasLength(2));
      expect((await h.real(tester, () => h.db.watchGoals().first)), hasLength(1));
      await h.closeApp(tester);
    });

    testWidgets('an expired safety copy is not offered', (tester) async {
      await h.pumpApp(tester);
      await fillSome(tester);
      await h.write(tester, () => h.db.saveEraseSnapshot('{}'));
      // Make it look eight days old.
      await h.write(tester, () => h.db.customStatement("UPDATE erase_snapshots SET created_at = created_at - ${8 * 24 * 3600}"));

      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      expect(find.textContaining('You erased your data on'), findsNothing);
      await h.closeApp(tester);
    });
  });
}
