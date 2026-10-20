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
import 'package:hisab/data/backup.dart' show maxBackupBytes;
import 'package:hisab/data/db/database_security.dart';
import 'package:hisab/app/security_providers.dart';
import 'package:hisab/services/app_lock.dart';
import 'package:hisab/services/cloud_backup.dart';
import 'package:hisab/services/native_security.dart';
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
  Future<Uint8List?> pickFileBytes({int maxBytes = maxBackupBytes}) async => toPick;
}

/// Stands in for a Google account: one stored backup, and switches for bad days.
class FakeCloudBackupService implements CloudBackupService {
  bool configured = false;
  String email = 'person@example.com';
  Uint8List? stored;
  DateTime? modified;
  int uploads = 0;
  int signOuts = 0;

  /// The next calls fail as if the phone had no internet.
  bool offline = false;

  /// The next calls fail as if Google had forgotten the sign-in.
  bool forgotten = false;

  /// The sign-in dialog was cancelled.
  bool cancelSignIn = false;

  @override
  bool get isConfigured => configured;

  @override
  Future<String> signIn() async {
    if (cancelSignIn) throw const CloudException('Sign-in was cancelled.');
    if (offline) throw const CloudException('No internet connection.', offline: true);
    return email;
  }

  @override
  Future<void> signOut() async => signOuts++;

  void _check() {
    if (offline) throw const CloudException('No internet connection.', offline: true);
    if (forgotten) throw const CloudException('Sign in again.', needsSignIn: true);
  }

  @override
  Future<({Uint8List bytes, DateTime modified})?> download() async {
    _check();
    final bytes = stored;
    return bytes == null ? null : (bytes: bytes, modified: modified!);
  }

  int deletes = 0;

  @override
  Future<void> deleteBackup() async {
    _check();
    deletes++;
    stored = null;
    modified = null;
  }

  @override
  Future<DateTime> upload(Uint8List bytes) async {
    _check();
    uploads++;
    stored = bytes;
    modified = DateTime(2026, 10, 21, 9, uploads);
    return modified!;
  }
}

/// Stands in for the phone's secure storage and screen protection.
class FakeNativeSecurity implements NativeSecurity {
  /// Every value passed to [setSecureWindow], in order.
  final List<bool> secureCalls = [];

  @override
  Future<String> databaseKeyHex() async => '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  @override
  Future<void> setSecureWindow(bool on) async => secureCalls.add(on);

  @override
  Future<bool> isSecureWindow() async => secureCalls.isEmpty || secureCalls.last;
}

/// Stands in for the phone's fingerprint / PIN prompt.
class FakeAppLockService implements AppLockService {
  /// The phone has a screen lock set up.
  bool available = true;

  /// What the next prompts answer, in order. When empty, [defaultAnswer] is used.
  final List<bool> answers = [];
  bool defaultAnswer = true;

  /// The reasons shown on each prompt that was opened.
  final List<String> prompts = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts.add(reason);
    return answers.isEmpty ? defaultAnswer : answers.removeAt(0);
  }
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
        files = FakeFileService(),
        cloud = FakeCloudBackupService(),
        nativeSecurity = FakeNativeSecurity(),
        lock = FakeAppLockService();

  final AppDatabase db;
  final FakeNotificationService notifications;
  final FakeFileService files;
  final FakeCloudBackupService cloud;
  final FakeNativeSecurity nativeSecurity;
  final FakeAppLockService lock;

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
  Future<void> pumpApp(
    WidgetTester tester, {
    bool onboarded = true,
    Map<String, Object> prefs = const {},
    EncryptionState encryption = EncryptionState.encrypted,
  }) async {
    // A phone-sized screen (about 392 x 873 logical pixels).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      if (onboarded) reminderPermissionAskedKey: true,
      if (onboarded) onboardingDoneKey: true,
      ...prefs,
    });
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
          fileServiceProvider.overrideWithValue(files),
          cloudBackupServiceProvider.overrideWithValue(cloud),
          nativeSecurityProvider.overrideWithValue(nativeSecurity),
          appLockServiceProvider.overrideWithValue(lock),
          encryptionStateProvider.overrideWithValue(encryption),
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
