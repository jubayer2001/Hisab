import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/providers.dart';
import 'package:hisab/services/cloud_backup.dart';
import 'package:hisab/services/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  // Tests open several in-memory databases on purpose ("another phone"); drift's warning is noise here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FakeCloudBackupService cloud;
  late ProviderContainer container;

  Future<void> addEntry(AppDatabase target, int amount, {String date = '2026-10-20'}) async {
    final categories = await target.watchCategories().first;
    final food = categories.firstWhere((c) => c.type == EntryType.expense);
    await target.addEntry(type: EntryType.expense, amountPoisha: amount, categoryId: food.id, date: date);
  }

  Future<int> entryCount(AppDatabase target) async => (await target.select(target.entries).get()).length;

  Future<ProviderContainer> start({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(p),
      databaseProvider.overrideWithValue(db),
      cloudBackupServiceProvider.overrideWithValue(cloud),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cloud = FakeCloudBackupService();
    container = await start();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('signing in', () {
    test('nothing in the account yet: the phone becomes the first backup', () async {
      await addEntry(db, 5000);
      final sync = container.read(cloudSyncProvider.notifier);

      final probe = await sync.signIn();
      expect(probe.cloud, isNull);
      expect(probe.phoneEntries, 1);
      expect(container.read(cloudSyncProvider).signedIn, isFalse, reason: 'nothing is linked until the person chooses');

      await sync.usePhoneData(probe);
      final state = container.read(cloudSyncProvider);
      expect(state.email, 'person@example.com');
      expect(state.lastBackup, isNotNull);
      expect(cloud.uploads, 1);
      expect(parseBackup(cloud.stored!, currentSchemaVersion: db.schemaVersion).entryCount, 1);
    });

    test('an existing backup is found, and nothing changes until the person chooses', () async {
      // Another phone (or an earlier install) already backed up two entries.
      final other = AppDatabase(NativeDatabase.memory());
      await addEntry(other, 1000);
      await addEntry(other, 2000);
      cloud.stored = encodeBackup(await createBackup(other));
      cloud.modified = DateTime(2026, 10, 1);
      await other.close();

      final probe = await container.read(cloudSyncProvider.notifier).signIn();
      expect(probe.cloud!.entryCount, 2);
      expect(probe.phoneEntries, 0);
      expect(await entryCount(db), 0, reason: 'asking must not touch the phone');
      expect(cloud.uploads, 0);
    });

    test('choosing the Google copy replaces the phone and does not upload it straight back', () async {
      final other = AppDatabase(NativeDatabase.memory());
      await addEntry(other, 1000);
      await addEntry(other, 2000);
      cloud.stored = encodeBackup(await createBackup(other));
      cloud.modified = DateTime(2026, 10, 1);
      await other.close();
      await addEntry(db, 999); // something on the phone that will be replaced

      final sync = container.read(cloudSyncProvider.notifier);
      final probe = await sync.signIn();
      await sync.useCloudData(probe);

      expect(await entryCount(db), 2);
      expect(container.read(cloudSyncProvider).email, 'person@example.com');
      expect(container.read(cloudSyncProvider).lastBackup, DateTime(2026, 10, 1));
      await sync.maybeBackup();
      expect(cloud.uploads, 0, reason: 'the restore itself is not a change to back up');
    });

    test('choosing the phone replaces the Google copy', () async {
      final other = AppDatabase(NativeDatabase.memory());
      await addEntry(other, 1000);
      cloud.stored = encodeBackup(await createBackup(other));
      cloud.modified = DateTime(2026, 10, 1);
      await other.close();
      await addEntry(db, 100);
      await addEntry(db, 200);
      await addEntry(db, 300);

      final sync = container.read(cloudSyncProvider.notifier);
      await sync.usePhoneData(await sync.signIn());

      expect(parseBackup(cloud.stored!, currentSchemaVersion: db.schemaVersion).entryCount, 3);
      expect(await entryCount(db), 3);
    });

    test('a backup from a newer app is refused and the person is signed out again', () async {
      final tooNew = encodeBackup({
        'format': 'hisab-backup',
        'formatVersion': 1,
        'schemaVersion': 999,
        'categories': <Object>[],
        'entries': <Object>[],
      });
      cloud.stored = tooNew;
      cloud.modified = DateTime(2026, 10, 1);

      await expectLater(
        container.read(cloudSyncProvider.notifier).signIn(),
        throwsA(isA<BackupException>()),
      );
      expect(cloud.signOuts, 1);
      expect(container.read(cloudSyncProvider).signedIn, isFalse);
    });

    test('backing out signs out and changes nothing', () async {
      await addEntry(db, 100);
      final sync = container.read(cloudSyncProvider.notifier);
      await sync.signIn();
      await sync.cancelSignIn();
      expect(cloud.signOuts, 1);
      expect(await entryCount(db), 1);
      expect(container.read(cloudSyncProvider).signedIn, isFalse);
    });
  });

  group('keeping the copy up to date', () {
    Future<CloudSyncNotifier> linked() async {
      final sync = container.read(cloudSyncProvider.notifier);
      await sync.usePhoneData(await sync.signIn());
      cloud.uploads = 0;
      return sync;
    }

    Future<void> change() async {
      await addEntry(db, 700);
      await Future<void>.delayed(const Duration(milliseconds: 50)); // let the change notice arrive
    }

    test('a change is uploaded, and an unchanged phone is not', () async {
      final sync = await linked();
      await sync.maybeBackup();
      expect(cloud.uploads, 0, reason: 'nothing changed');

      await change();
      await sync.maybeBackup();
      expect(cloud.uploads, 1);
      expect(parseBackup(cloud.stored!, currentSchemaVersion: db.schemaVersion).entryCount, 1);

      await sync.maybeBackup();
      expect(cloud.uploads, 1, reason: 'already up to date');
    });

    test('offline: the change waits, the phone keeps working, and it goes up later', () async {
      final sync = await linked();
      cloud.offline = true;
      await change();
      await sync.maybeBackup();

      expect(container.read(cloudSyncProvider).status, CloudStatus.waiting);
      expect(cloud.uploads, 0);
      expect(await entryCount(db), 1, reason: 'the data on the phone is untouched');

      cloud.offline = false;
      await sync.maybeBackup();
      expect(container.read(cloudSyncProvider).status, CloudStatus.idle);
      expect(cloud.uploads, 1);
    });

    test('a change waiting when the app is closed is still uploaded next time', () async {
      final sync = await linked();
      cloud.offline = true;
      await change();
      await sync.maybeBackup();
      container.dispose();

      // The app starts again: same saved settings, same phone data.
      final prefs = await SharedPreferences.getInstance();
      final again = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        cloudBackupServiceProvider.overrideWithValue(cloud),
      ]);
      addTearDown(again.dispose);
      cloud.offline = false;

      final restarted = again.read(cloudSyncProvider.notifier);
      expect(again.read(cloudSyncProvider).email, 'person@example.com', reason: 'still signed in');
      await restarted.maybeBackup();
      expect(cloud.uploads, 1);
    });

    test('automatic backup can be switched off, and "back up now" still works', () async {
      final sync = await linked();
      sync.setAuto(false);
      await change();
      await sync.maybeBackup();
      expect(cloud.uploads, 0);

      await sync.backupNow();
      expect(cloud.uploads, 1);
    });

    test('Google forgetting the sign-in is reported, not hidden, and the data waits', () async {
      final sync = await linked();
      cloud.forgotten = true;
      await change();
      await sync.maybeBackup();
      expect(container.read(cloudSyncProvider).status, CloudStatus.needsSignIn);

      cloud.forgotten = false;
      await sync.signInAgain();
      expect(container.read(cloudSyncProvider).status, CloudStatus.idle);
      expect(cloud.uploads, 1);
    });

    test('signing in again with a different account is refused', () async {
      final sync = await linked();
      cloud.forgotten = true;
      await change();
      await sync.maybeBackup();
      cloud.forgotten = false;
      cloud.email = 'someone.else@example.com';

      await expectLater(sync.signInAgain(), throwsA(isA<CloudException>()));
      expect(container.read(cloudSyncProvider).email, 'person@example.com');
    });
  });

  group('restoring and signing out', () {
    test('restore from Google brings the data back after the app was deleted', () async {
      // Phone 1 backs up three entries.
      await addEntry(db, 100);
      await addEntry(db, 200);
      await addEntry(db, 300);
      final sync = container.read(cloudSyncProvider.notifier);
      await sync.usePhoneData(await sync.signIn());
      final saved = cloud.stored!;
      final savedAt = cloud.modified;
      container.dispose();
      await db.close();

      // A fresh install: empty database, nothing remembered.
      db = AppDatabase(NativeDatabase.memory());
      container = await start();
      cloud.stored = saved;
      cloud.modified = savedAt;

      final fresh = container.read(cloudSyncProvider.notifier);
      final probe = await fresh.signIn();
      expect(probe.phoneEntries, 0);
      expect(probe.cloud!.entryCount, 3);
      await fresh.useCloudData(probe);
      expect(await entryCount(db), 3);
    });

    test('restoring on demand replaces the phone with the Google copy', () async {
      await addEntry(db, 100);
      final sync = container.read(cloudSyncProvider.notifier);
      await sync.usePhoneData(await sync.signIn());
      await addEntry(db, 200);
      await addEntry(db, 300);
      expect(await entryCount(db), 3);

      final found = await sync.fetchCloud();
      expect(found!.backup.entryCount, 1);
      await sync.restoreFromCloud(found.backup);
      expect(await entryCount(db), 1);
    });

    test('signing out stops the backups but keeps the data on the phone', () async {
      await addEntry(db, 100);
      final sync = container.read(cloudSyncProvider.notifier);
      await sync.usePhoneData(await sync.signIn());

      await sync.signOut();
      expect(container.read(cloudSyncProvider).signedIn, isFalse);
      expect(await entryCount(db), 1);

      await addEntry(db, 200);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cloud.uploads = 0;
      await sync.maybeBackup();
      expect(cloud.uploads, 0);
    });
  });
}
