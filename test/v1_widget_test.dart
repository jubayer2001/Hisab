import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  testWidgets('Welcome: name, budget and reminder are saved, then Home greets you', (tester) async {
    await h.pumpApp(tester, onboarded: false);

    expect(find.text('Welcome to Hisab'), findsOneWidget);
    expect(find.text('Spent today'), findsNothing); // the app itself is not showing yet

    await typeInto(tester, 'What should we call you? (optional)', 'Jubayer');
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await h.settle(tester);

    expect(find.text('Set a monthly budget'), findsOneWidget);
    await typeInto(tester, 'Monthly budget (optional)', '25000');
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await h.settle(tester);

    expect(find.text('An evening reminder'), findsOneWidget);
    expect(find.text('10:00 PM'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
    await h.settle(tester);

    // Now the app itself.
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.textContaining(', Jubayer'), findsOneWidget);
    expect(find.textContaining('left of ৳25,000 budget'), findsOneWidget);

    final budgets = await h.real(tester, () => h.db.watchBudgets().first);
    expect(budgets.single.categoryId, isNull);
    expect(budgets.single.amountPoisha, 2500000);
    expect(h.notifications.syncs.last.enabled, isTrue);
    expect(h.notifications.syncs.last.minutes, 22 * 60);

    await h.closeApp(tester);
  });

  testWidgets('Welcome: skipping sets nothing and goes straight to the app', (tester) async {
    await h.pumpApp(tester, onboarded: false);

    await tester.tap(find.text('Skip'));
    await h.settle(tester);

    expect(find.text('Spent today'), findsOneWidget);
    expect(find.textContaining(RegExp(r'Good (morning|afternoon|evening|night),')), findsNothing); // no ", name"
    expect(find.textContaining(RegExp(r'^Good (morning|afternoon|evening|night)$')), findsOneWidget);
    expect(await h.real(tester, () => h.db.watchBudgets().first), isEmpty);

    await h.closeApp(tester);
  });

  testWidgets('Welcome: the reminder can be turned off, and Back works', (tester) async {
    await h.pumpApp(tester, onboarded: false);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await h.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await h.settle(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();

    await tester.tap(find.text('Back'));
    await h.settle(tester);
    expect(find.text('Set a monthly budget'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await h.settle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
    await h.settle(tester);

    expect(find.text('Spent today'), findsOneWidget);
    expect(h.notifications.syncs.last.enabled, isFalse);

    await h.closeApp(tester);
  });

  testWidgets('More: the name can be changed and removed', (tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.text('More'));
    await h.settle(tester);

    await tester.scrollUntilVisible(find.text('Name shown on Home'), 200);
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.text('Name shown on Home'));
    await h.settle(tester);
    await typeInto(tester, 'Name (leave empty to hide it)', '  Rafi ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await h.settle(tester);
    expect(find.text('Rafi'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await h.settle(tester);
    expect(find.textContaining(', Rafi'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Backup: saves a file named with the date, and remembers when', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 18000, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Lunch');

    await h.openFromMore(tester, 'Backup and restore');
    expect(find.text('No backup yet'), findsOneWidget);

    await tester.tap(find.text('Save backup file'));
    await h.settle(tester);

    final file = h.files.saved.single;
    expect(file.name, 'hisab-backup-${dayKey(DateTime.now())}.json');
    expect(h.files.mimeTypes.single, 'application/json');
    final json = jsonDecode(utf8.decode(file.bytes)) as Map<String, dynamic>;
    expect(json['format'], 'hisab-backup');
    expect((json['entries'] as List).single['note'], 'Lunch');
    expect(find.textContaining('Backup saved'), findsOneWidget);
    expect(find.textContaining('Last backup:'), findsOneWidget);
    expect(find.text('No backup yet'), findsNothing);

    await h.closeApp(tester);
  });

  testWidgets('Backup: cancelling the save dialog saves nothing and shows no success message', (tester) async {
    await h.pumpApp(tester);
    await h.openFromMore(tester, 'Backup and restore');

    h.files.cancelSave = true;
    await tester.tap(find.text('Save backup file'));
    await h.settle(tester);

    expect(h.files.saved, isEmpty);
    expect(find.textContaining('Backup saved'), findsNothing);
    expect(find.text('No backup yet'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Restore: replaces the data after a confirmation, and cancel keeps it', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 11100, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Current');

    // A backup made on another "phone" with different data.
    h.files.toPick = await h.real(tester, () async {
      final other = AppDatabase(NativeDatabase.memory());
      final cats = await other.watchCategories().first;
      final transport = cats.firstWhere((c) => c.name == 'Transport');
      await other.addEntry(type: EntryType.expense, amountPoisha: 6000, categoryId: transport.id, date: '2026-09-01', note: 'Rickshaw');
      await other.addEntry(type: EntryType.expense, amountPoisha: 7000, categoryId: transport.id, date: '2026-09-02', note: 'Bus');
      final bytes = encodeBackup(await createBackup(other, settings: {'userName': 'From backup'}));
      await other.close();
      return bytes;
    });

    await h.openFromMore(tester, 'Backup and restore');
    await tester.tap(find.text('Restore from a backup file'));
    await h.settle(tester);

    expect(find.text('Replace your data?'), findsOneWidget);
    expect(find.textContaining('has 2 entries. This phone has 1.'), findsOneWidget);

    // Cancel: nothing changes.
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect((await h.entries(tester)).map((e) => e.entry.note), ['Current']);

    // Replace.
    await tester.tap(find.text('Restore from a backup file'));
    await h.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
    await h.settle(tester);

    expect(find.text('Restored 2 entries.'), findsOneWidget);
    expect((await h.entries(tester)).map((e) => e.entry.note).toSet(), {'Rickshaw', 'Bus'});

    // The name saved in the backup comes back too.
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.text('Home'));
    await h.settle(tester);
    expect(find.textContaining(', From backup'), findsOneWidget);

    await h.closeApp(tester);
  });

  testWidgets('Restore: a file that is not a backup is refused and nothing changes', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 11100, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Keep me');

    h.files.toPick = utf8.encode('this is just a text file') as dynamic;
    await h.openFromMore(tester, 'Backup and restore');
    await tester.tap(find.text('Restore from a backup file'));
    await h.settle(tester);

    expect(find.text('That file is not a Hisab backup.'), findsOneWidget);
    expect(find.text('Replace your data?'), findsNothing);
    expect((await h.entries(tester)).single.entry.note, 'Keep me');

    await h.closeApp(tester);
  });

  testWidgets('Restore: cancelling the file picker does nothing', (tester) async {
    await h.pumpApp(tester);
    h.files.toPick = null;
    await h.openFromMore(tester, 'Backup and restore');
    await tester.tap(find.text('Restore from a backup file'));
    await h.settle(tester);

    expect(find.text('Replace your data?'), findsNothing);
    expect(find.textContaining('not a Hisab backup'), findsNothing);

    await h.closeApp(tester);
  });

  testWidgets('CSV: exports every entry as a spreadsheet file', (tester) async {
    await h.pumpApp(tester);
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 18000, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Lunch');
    await h.addEntry(tester, amount: 2500, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Tea');

    await h.openFromMore(tester, 'Backup and restore');
    await tester.ensureVisible(find.text('Export to CSV'));
    await tester.pump();
    await tester.tap(find.text('Export to CSV'));
    await h.settle(tester);

    final file = h.files.saved.single;
    expect(file.name, 'hisab-entries-${dayKey(DateTime.now())}.csv');
    expect(h.files.mimeTypes.single, 'text/csv');
    // The first three bytes are the UTF-8 byte order mark, which makes Excel read Bangla text.
    expect(file.bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(file.bytes); // (this drops the byte order mark)
    expect(text, startsWith('Date,Type,Category'));
    expect(text, contains('180.00'));
    expect(text, contains('25.00'));
    expect(find.text('Saved 2 entries as a spreadsheet file.'), findsOneWidget);

    await h.closeApp(tester);
  });
}
