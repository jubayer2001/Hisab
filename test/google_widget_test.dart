import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

import 'support/harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Harness h;

  setUp(() => h = Harness());

  /// Puts a backup with [notes] as entries into the fake Google account.
  Future<void> putBackupInGoogle(WidgetTester tester, List<String> notes) async {
    final bytes = await h.real(tester, () async {
      final other = AppDatabase(NativeDatabase.memory());
      final cats = await other.watchCategories().first;
      final food = cats.firstWhere((c) => c.name == 'Food');
      for (final note in notes) {
        await other.addEntry(type: EntryType.expense, amountPoisha: 5000, categoryId: food.id, date: '2026-09-01', note: note);
      }
      final data = encodeBackup(await createBackup(other, settings: {'userName': 'From Google'}));
      await other.close();
      return data;
    });
    h.cloud.stored = bytes;
    h.cloud.modified = DateTime(2026, 9, 5);
  }

  testWidgets('Backup: without a Google client ID the sign-in section is not shown', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Backup and export');

    expect(find.text('Sign in with Google'), findsNothing);
    expect(find.text('Save a backup file'), findsOneWidget); // the file backup is always there
    await h.closeApp(tester);
  });

  testWidgets('Backup: signing in with nothing in Google yet starts backing up this phone', (tester) async {
    h.cloud.configured = true;
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 4000, categoryId: food.id, date: '2026-10-20', note: 'Lunch');

    await h.openFromMore(tester, 'Backup and export');
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Back up automatically'), findsNothing);

    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);

    expect(find.textContaining('Signed in as person@example.com'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Back up automatically'), findsOneWidget);
    expect(find.textContaining('Backed up 21 Oct 2026'), findsOneWidget); // when the fake Google saved it
    expect(h.cloud.uploads, 1);

    await h.closeApp(tester);
  });

  testWidgets('Backup: a cancelled sign-in changes nothing', (tester) async {
    h.cloud.configured = true;
    h.cloud.cancelSignIn = true;
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Backup and export');

    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);

    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(h.cloud.uploads, 0);
    await h.closeApp(tester);
  });

  testWidgets('Backup: an empty phone offers to restore what is in Google, and does so', (tester) async {
    h.cloud.configured = true;
    await h.pumpApp(tester);
    await putBackupInGoogle(tester, ['Rickshaw', 'Bus']);

    await h.openFromMore(tester, 'Backup and export');
    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('Google account: 2 entries'), findsOneWidget);
    expect(find.textContaining('This phone: 0 entries'), findsOneWidget);
    expect(find.text('Use this phone'), findsNothing, reason: 'an empty phone is not offered as the data to keep');

    await tester.tap(find.widgetWithText(FilledButton, 'Restore my data'));
    await h.settle(tester);

    expect((await h.entries(tester)).map((e) => e.entry.note).toSet(), {'Rickshaw', 'Bus'});
    expect(find.text('Restored 2 entries from your Google account.'), findsOneWidget);
    expect(h.cloud.uploads, 0, reason: 'restoring must not upload straight back');

    await h.closeApp(tester);
  });

  testWidgets('Backup: with data on both sides the person chooses, and cancelling signs out', (tester) async {
    h.cloud.configured = true;
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 4000, categoryId: food.id, date: '2026-10-20', note: 'On the phone');
    await putBackupInGoogle(tester, ['In Google']);

    await h.openFromMore(tester, 'Backup and export');
    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);

    expect(find.text('Which data do you want?'), findsOneWidget);
    expect(find.textContaining('Whichever you choose replaces the other'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.cloud.signOuts, 1);
    expect((await h.entries(tester)).single.entry.note, 'On the phone');
    expect(find.text('Sign in with Google'), findsOneWidget);

    // Again, this time keeping the phone's data.
    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);
    await tester.tap(find.text('Use this phone'));
    await h.settle(tester);

    expect((await h.entries(tester)).single.entry.note, 'On the phone');
    expect(h.cloud.uploads, 1);
    expect(parseBackup(h.cloud.stored!, currentSchemaVersion: h.db.schemaVersion).entryCount, 1);

    await h.closeApp(tester);
  });

  testWidgets('Backup: signed in, it shows the account and can sign out without touching the data', (tester) async {
    h.cloud.configured = true;
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 4000, categoryId: food.id, date: '2026-10-20', note: 'Keep me');

    await h.openFromMore(tester, 'Backup and export');
    await tester.tap(find.text('Sign in with Google'));
    await h.settle(tester);

    await tester.pump(const Duration(seconds: 6)); // let the "Signed in" message go, it covers the bottom
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 300);
    await tester.tap(find.text('Sign out'));
    await h.settle(tester);
    expect(find.text('Sign out of Google?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await h.settle(tester);

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect((await h.entries(tester)).single.entry.note, 'Keep me');
    await h.closeApp(tester);
  });

  testWidgets('Welcome: a returning person can restore from Google and skip the setup', (tester) async {
    h.cloud.configured = true;
    await h.pumpApp(tester, onboarded: false);
    await putBackupInGoogle(tester, ['Old entry']);

    await tester.tap(find.text('Already used Hisab? Restore from Google'));
    await h.settle(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Restore my data'));
    await h.settle(tester);

    // Straight into the app, with the saved name.
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.textContaining(', From Google'), findsOneWidget);
    expect((await h.entries(tester)).single.entry.note, 'Old entry');

    await h.closeApp(tester);
  });

  testWidgets('Welcome: the restore button is hidden when Google sign-in is not set up', (tester) async {
    await h.pumpApp(tester, onboarded: false);
    expect(find.text('Already used Hisab? Restore from Google'), findsNothing);
    await h.closeApp(tester);
  });
}
