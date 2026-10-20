import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/app.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/providers.dart';
import 'package:hisab/services/file_service.dart';
import 'package:hisab/services/notifications.dart';
import 'package:hisab/services/reminder_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the Android notification plugin and records what would be scheduled.
class FakeNotificationService extends NotificationService {
  final List<({bool enabled, int minutes, String? todayBody})> syncs = [];
  final List<List<DharReminder>> dharSyncs = [];
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

  @override
  Future<void> syncDharReminders(List<DharReminder> reminders) async {
    dharSyncs.add(reminders);
  }
}

/// Stands in for the phone's save and open dialogs.
class FakeFileService implements FileService {
  final List<({String name, Uint8List bytes})> saved = [];
  final List<String> mimeTypes = [];

  /// What the next "pick a file" dialog returns. Null means the user cancelled.
  Uint8List? toPick;

  /// When true, the next save dialog is cancelled.
  bool cancelSave = false;

  @override
  Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    if (cancelSave) return false;
    saved.add((name: fileName, bytes: bytes));
    mimeTypes.add(mimeType);
    return true;
  }

  @override
  Future<Uint8List?> pickFileBytes() async => toPick;
}

/// Everything a widget test needs: an in-memory database, a fake notification service, and
/// helpers that cope with Flutter's fake clock.
///
/// Two rules learned the hard way:
///  * Real database work must run inside [real] (it uses tester.runAsync).
///  * Write one row at a time and [settle] in between. Each write makes the app's live
///    queries refresh, and that refresh needs the test clock to move.
class Harness {
  Harness()
      : db = AppDatabase(NativeDatabase.memory()),
        notifications = FakeNotificationService(),
        files = FakeFileService();

  final AppDatabase db;
  final FakeNotificationService notifications;
  final FakeFileService files;

  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async => (await tester.runAsync(body)) as T;

  /// Lets database streams deliver and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
  }

  /// Starts the app. By default the welcome steps are treated as already done; pass
  /// `onboarded: false` to see them.
  Future<void> pumpApp(WidgetTester tester, {bool onboarded = true}) async {
    // A phone-sized screen (about 392 x 873 logical pixels).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      if (onboarded) reminderPermissionAskedKey: true,
      if (onboarded) onboardingDoneKey: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
          fileServiceProvider.overrideWithValue(files),
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

  /// Runs one database write, then lets the screens update.
  Future<T> write<T>(WidgetTester tester, Future<T> Function() body) async {
    final result = await real(tester, body);
    await settle(tester);
    return result;
  }

  Future<List<Category>> categories(WidgetTester tester) => real(tester, () => db.watchCategories().first);

  Future<Category> category(WidgetTester tester, String name, {String type = EntryType.expense}) async =>
      (await categories(tester)).firstWhere((c) => c.name == name && c.type == type);

  Future<List<EntryWithCategory>> entries(WidgetTester tester) => real(tester, () => db.watchEntries().first);

  Future<void> addEntry(
    WidgetTester tester, {
    required int amount,
    required int categoryId,
    required String date,
    String type = EntryType.expense,
    String? note,
  }) {
    return write(
      tester,
      () => db.addEntry(type: type, amountPoisha: amount, categoryId: categoryId, date: date, note: note),
    );
  }

  /// Every piece of text currently built on screen, for debugging a failing test.
  String screenTexts(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().join(' | ');

  /// Opens a screen from the "More" tab.
  Future<void> openFromMore(WidgetTester tester, String tileTitle) async {
    await tester.tap(find.text('More'));
    await settle(tester);
    await tester.tap(find.text(tileTitle));
    await settle(tester);
  }
}
