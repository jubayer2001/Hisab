import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';
import 'package:hisab/services/notifications.dart';
import 'package:hisab/services/reminder_providers.dart';

import 'support/harness.dart';

void main() {
  group('the notification\'s two buttons', () {
    List<String> labels(bool spentToday) {
      final details = NotificationService().detailsFor(spentToday: spentToday);
      return [for (final a in details.android!.actions!) a.title];
    }

    List<String> ids(bool spentToday) {
      final details = NotificationService().detailsFor(spentToday: spentToday);
      return [for (final a in details.android!.actions!) a.id];
    }

    test('before anything is spent: "Add expense" and "No spending today"', () {
      expect(labels(false), ['Add expense', 'No spending today']);
    });

    test('after spending: "Add expense" and "No more spending today"', () {
      expect(labels(true), ['Add expense', 'No more spending today']);
    });

    test('both versions use the same two actions, so the app reacts the same way', () {
      expect(ids(false), [ReminderAction.add, ReminderAction.noSpend]);
      expect(ids(true), [ReminderAction.add, ReminderAction.noSpend]);
    });

    test('both buttons open the app, and close the notification once pressed', () {
      for (final spent in [false, true]) {
        for (final action in NotificationService().detailsFor(spentToday: spent).android!.actions!) {
          expect(action.showsUserInterface, isTrue);
          expect(action.cancelNotification, isTrue);
        }
      }
    });

    test('the label helper agrees with what the notification shows', () {
      expect(NotificationService.noSpendLabel(spentToday: false), 'No spending today');
      expect(NotificationService.noSpendLabel(spentToday: true), 'No more spending today');
    });
  });

  group('what the app tells the notification service', () {
    late Harness h;
    setUp(() => h = Harness());

    String today() => dayKey(DateTime.now());

    testWidgets('spentToday is false with nothing logged, true after spending, false again after Undo-style removal', (tester) async {
      await h.pumpApp(tester);
      expect(h.notifications.syncs.last.spentToday, isFalse);

      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 64500, categoryId: food.id, date: today());
      expect(h.notifications.syncs.last.spentToday, isTrue);
      expect(h.notifications.syncs.last.todayBody, contains('logged today'));

      final id = (await h.entries(tester)).single.entry.id;
      await h.write(tester, () => h.db.deleteEntry(id));
      expect(h.notifications.syncs.last.spentToday, isFalse);
      await h.closeApp(tester);
    });

    testWidgets('income alone does not count as spending', (tester) async {
      await h.pumpApp(tester);
      final gift = await h.category(tester, 'Gift', type: 'income');
      await h.addEntry(tester, amount: 100000, categoryId: gift.id, date: today(), type: 'income');
      expect(h.notifications.syncs.last.spentToday, isFalse);
      await h.closeApp(tester);
    });

    testWidgets('spending on another day does not change tonight\'s buttons', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 5000, categoryId: food.id, date: '2026-01-01');
      expect(h.notifications.syncs.last.spentToday, isFalse);
      await h.closeApp(tester);
    });
  });

  group('pressing the buttons', () {
    late Harness h;
    setUp(() => h = Harness());

    String today() => dayKey(DateTime.now());

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    Future<void> press(WidgetTester tester, String action) async {
      containerOf(tester).read(notificationActionProvider.notifier).set(action);
      await h.settle(tester);
    }

    testWidgets('"No spending today" with nothing spent marks the day and says so', (tester) async {
      await h.pumpApp(tester);
      await press(tester, ReminderAction.noSpend);

      expect(find.text('Marked as no spending today'), findsWidgets);
      expect(await h.real(tester, () => h.db.watchNoSpendDays().first), {today()});
      expect(h.notifications.syncs.last.todayBody, isNull, reason: 'no more reminders tonight');
      await h.closeApp(tester);
    });

    testWidgets('"No more spending today" after spending ends the day, and says it that way', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 64500, categoryId: food.id, date: today(), note: 'Bazar');
      await press(tester, ReminderAction.noSpend);

      expect(find.text('No more spending today'), findsWidgets);
      expect(find.text('Marked as no spending today'), findsNothing);
      expect(await h.real(tester, () => h.db.watchNoSpendDays().first), {today()});
      expect(h.notifications.syncs.last.todayBody, isNull);
      expect((await h.entries(tester)).single.entry.note, 'Bazar', reason: 'the spending itself is untouched');
      await h.closeApp(tester);
    });

    testWidgets('Home shows the same wording, and Undo reopens the day', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 64500, categoryId: food.id, date: today());
      await press(tester, ReminderAction.noSpend);
      await tester.pump(const Duration(seconds: 6)); // let the message go
      await tester.pumpAndSettle();

      expect(find.text('No more spending today'), findsOneWidget, reason: 'the Home card');
      await tester.tap(find.text('Undo'));
      await h.settle(tester);
      expect(await h.real(tester, () => h.db.watchNoSpendDays().first), isEmpty);
      expect(h.notifications.syncs.last.todayBody, contains('logged today'), reason: 'tonight reminds again');
      await h.closeApp(tester);
    });

    testWidgets('"Add expense" still opens the add sheet', (tester) async {
      await h.pumpApp(tester);
      await press(tester, ReminderAction.add);
      expect(find.byType(AddEntrySheet), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the Home card keeps its old wording on a day with no spending', (tester) async {
      await h.pumpApp(tester);
      expect(find.text('Nothing spent today?'), findsOneWidget);
      await tester.tap(find.text('No spending'));
      await h.settle(tester);
      expect(find.text('Marked as no spending today'), findsOneWidget);
      await h.closeApp(tester);
    });
  });
}
