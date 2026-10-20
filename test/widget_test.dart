import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/app.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/providers.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';
import 'package:hisab/services/notifications.dart';
import 'package:hisab/services/reminder_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the Android notification plugin and records what would be scheduled.
class FakeNotificationService extends NotificationService {
  final List<({bool enabled, int minutes, String? todayBody})> syncs = [];
  int testNotifications = 0;

  @override
  Future<void> init({required void Function(String action) onAction}) async {}

  @override
  Future<String?> launchAction() async => null;

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> canUseExactAlarms() async => true;

  @override
  Future<void> requestExactAlarms() async {}

  @override
  Future<void> showTest() async => testNotifications++;

  @override
  Future<void> syncReminders({
    required bool enabled,
    required int minutes,
    required String? todayBody,
  }) async {
    syncs.add((enabled: enabled, minutes: minutes, todayBody: todayBody));
  }
}

void main() {
  late AppDatabase db;
  late FakeNotificationService notifications;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notifications = FakeNotificationService();
  });

  /// Widget tests run on a fake clock, so real database work has to run outside it.
  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async => (await tester.runAsync(body)) as T;

  /// Lets database streams deliver and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    // A phone-sized screen (about 392 x 873 logical pixels).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({reminderPermissionAskedKey: true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const HisabApp(),
      ),
    );
    await settle(tester);
  }

  Future<void> closeApp(WidgetTester tester) async {
    // Unmount the app so database streams are cancelled before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await real(tester, db.close);
  }

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.descendant(of: find.byType(AddEntrySheet), matching: find.text(d)));
      await tester.pump();
    }
  }

  /// Adds one expense while the app is showing, then lets the screens update. Adding several
  /// in one go would deadlock: each write makes the app's live queries refresh, and that
  /// refresh needs the test clock to move.
  Future<void> addEntry(
    WidgetTester tester, {
    required int amount,
    required int categoryId,
    required String date,
    String? note,
  }) async {
    await real(
      tester,
      () => db.addEntry(
        type: EntryType.expense,
        amountPoisha: amount,
        categoryId: categoryId,
        date: date,
        note: note,
      ),
    );
    await settle(tester);
  }

  Future<List<Category>> categories(WidgetTester tester) => real(tester, () => db.watchCategories().first);

  Future<List<EntryWithCategory>> entries(WidgetTester tester) => real(tester, () => db.watchEntries().first);

  testWidgets('starts on Home with empty totals and switches tabs', (tester) async {
    await pumpApp(tester);

    expect(find.text('Spent today'), findsOneWidget);
    expect(find.text('Nothing added today'), findsOneWidget);

    await tester.tap(find.text('History'));
    await settle(tester);
    expect(find.text('Nothing here yet'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await settle(tester);
    expect(find.text('No data to show yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Appearance'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('adding an expense with the keypad shows it on Home and updates totals', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await settle(tester);
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
    await settle(tester);

    expect(find.byType(AddEntrySheet), findsNothing);
    expect(find.text('−৳250'), findsOneWidget); // the entry row
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Saved ৳250 · Food'), findsOneWidget); // confirmation

    final saved = await entries(tester);
    expect(saved.single.entry.amountPoisha, 25000);
    expect(saved.single.entry.date, dayKey(DateTime.now()));

    await closeApp(tester);
  });

  testWidgets('income counts toward balance, not spending', (tester) async {
    await pumpApp(tester);
    final salary = (await categories(tester)).firstWhere((c) => c.name == 'Salary');
    await real(
      tester,
      () => db.addEntry(
        type: EntryType.income,
        amountPoisha: 5000000,
        categoryId: salary.id,
        date: dayKey(DateTime.now()),
      ),
    );
    await settle(tester);

    expect(find.text('+৳50,000'), findsOneWidget); // entry row
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('editing an entry changes it, and deleting from the sheet offers Undo', (tester) async {
    await pumpApp(tester);
    final food = (await categories(tester)).first;
    await real(
      tester,
      () => db.addEntry(
        type: EntryType.expense,
        amountPoisha: 18000,
        categoryId: food.id,
        date: dayKey(DateTime.now()),
        note: 'Lunch',
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Lunch'));
    await settle(tester);
    expect(find.text('Edit expense'), findsOneWidget);

    // Backspace twice (180 -> 1), then add 5 -> 15.
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    await typeAmount(tester, '5');
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    expect((await entries(tester)).single.entry.amountPoisha, 1500);

    await tester.tap(find.text('Lunch'));
    await settle(tester);
    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(await entries(tester), isEmpty);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await entries(tester)).single.entry.amountPoisha, 1500);

    await closeApp(tester);
  });

  testWidgets('History groups by day and search filters', (tester) async {
    await pumpApp(tester);
    final cats = await categories(tester);
    final food = cats.firstWhere((c) => c.name == 'Food');
    final transport = cats.firstWhere((c) => c.name == 'Transport');
    final today = dayKey(DateTime.now());
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    await addEntry(tester, amount: 18000, categoryId: food.id, date: today, note: 'Lunch');
    await addEntry(tester, amount: 6000, categoryId: transport.id, date: yesterday);

    await tester.tap(find.text('History'));
    await settle(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lunch');
    await settle(tester);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Transport'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(tester);
    expect(find.text('No matches'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('quick add chip adds a repeat expense in one tap', (tester) async {
    await pumpApp(tester);
    final food = (await categories(tester)).first;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = dayKey(DateTime.now().subtract(const Duration(days: 2)));
    for (final date in [yesterday, twoDaysAgo]) {
      await addEntry(tester, amount: 1000, categoryId: food.id, date: date, note: 'Tea');
    }

    expect(find.text('Quick add'), findsOneWidget);
    await tester.tap(find.text('Tea ৳10'));
    await settle(tester);

    final today = dayKey(DateTime.now());
    final added = (await entries(tester)).where((e) => e.entry.date == today).toList();
    expect(added.single.entry.amountPoisha, 1000);
    expect(added.single.entry.note, 'Tea');

    await closeApp(tester);
  });

  testWidgets('reminder text follows what was logged, and skips tonight when marked', (tester) async {
    await pumpApp(tester);
    expect(notifications.syncs.last.todayBody, contains("haven't added any expenses"));
    expect(notifications.syncs.last.enabled, isTrue);
    expect(notifications.syncs.last.minutes, 22 * 60);

    final food = (await categories(tester)).first;
    await real(
      tester,
      () => db.addEntry(
        type: EntryType.expense,
        amountPoisha: 64500,
        categoryId: food.id,
        date: dayKey(DateTime.now()),
      ),
    );
    await settle(tester);
    expect(notifications.syncs.last.todayBody, '৳645 logged today. Anything else to add?');

    await real(tester, () => db.setNoSpend(dayKey(DateTime.now()), true));
    await settle(tester);
    expect(notifications.syncs.last.todayBody, isNull);

    await closeApp(tester);
  });

  testWidgets('No spending today card marks the day', (tester) async {
    await pumpApp(tester);
    expect(find.text('Nothing spent today?'), findsOneWidget);

    await tester.tap(find.text('No spending'));
    await settle(tester);

    expect(find.text('Marked as no spending today'), findsOneWidget);
    expect(await real(tester, () => db.watchNoSpendDays().first), {dayKey(DateTime.now())});

    await closeApp(tester);
  });

  testWidgets('settings: reminder switch and test notification', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);

    expect(find.text('Remind me every evening'), findsOneWidget);
    expect(find.text('10:00 PM'), findsOneWidget);

    await tester.tap(find.text('Send a test reminder'));
    await tester.pump();
    expect(notifications.testNotifications, 1);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(notifications.syncs.last.enabled, isFalse);

    await closeApp(tester);
  });
}
