import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/csv.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

/// A backup file is untrusted input. These tests feed the restore code damaged, hostile and
/// absurd files and check that every one is refused with a clear message, and that the data
/// already on the phone is never touched.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase source;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    final cats = await source.watchCategories().first;
    final food = cats.firstWhere((c) => c.name == 'Food');
    final salary = cats.firstWhere((c) => c.name == 'Salary');
    await source.addEntry(type: EntryType.expense, amountPoisha: 18000, categoryId: food.id, date: '2026-10-19', note: 'Lunch');
    await source.addEntry(type: EntryType.income, amountPoisha: 4500000, categoryId: salary.id, date: '2026-10-01');
    await source.setBudget(categoryId: null, amountPoisha: 2500000);
    await source.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 100000, categoryId: food.id, dayOfMonth: 5);
    final goal = await source.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A, deadline: '2027-03-20');
    await source.addDeposit(goalId: goal, amountPoisha: -500, date: '2026-10-20');
    final dhar = await source.addDhar(person: 'Rahim', direction: DharDirection.lent, amountPoisha: 5000, date: '2026-10-01');
    await source.addDharPayment(dharId: dhar, amountPoisha: 1000, date: '2026-10-02');
  });
  tearDown(() => source.close());

  Future<Map<String, dynamic>> goodBackup() async =>
      jsonDecode(utf8.decode(encodeBackup(await createBackup(source)))) as Map<String, dynamic>;

  Uint8List bytesOf(Map<String, dynamic> m) => Uint8List.fromList(utf8.encode(jsonEncode(m)));

  BackupContents parse(Map<String, dynamic> m) => parseBackup(bytesOf(m), currentSchemaVersion: source.schemaVersion);

  Matcher refusedAs(String message) => throwsA(isA<BackupException>().having((e) => e.message, 'message', message));

  const damaged = 'That backup file is damaged.';

  group('a good file', () {
    test('is accepted, with unknown extra fields ignored', () async {
      final m = await goodBackup();
      m['somethingNew'] = {'a': 1};
      (m['entries'] as List).first['futureField'] = 'ok';
      expect(parse(m).entryCount, 2);
    });
  });

  group('size', () {
    test('a file over the limit is refused before it is read', () {
      final huge = Uint8List(maxBackupBytes + 1)..fillRange(0, maxBackupBytes + 1, 32);
      expect(() => parseBackup(huge, currentSchemaVersion: 3), throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('too large'))));
    });

    test('a file just under the limit is read normally (and rejected only for being not a backup)', () {
      final big = Uint8List(1024 * 1024)..fillRange(0, 1024 * 1024, 120);
      expect(() => parseBackup(big, currentSchemaVersion: 3), refusedAs('That file is not a Hisab backup.'));
    });

    test('absurdly deep nesting does not crash the app', () {
      final deep = Uint8List.fromList(utf8.encode('${'[' * 200000}${']' * 200000}'));
      expect(() => parseBackup(deep, currentSchemaVersion: 3), throwsA(isA<BackupException>()));
    });
  });

  group('every value is checked', () {
    Future<void> expectDamaged(void Function(Map<String, dynamic> m) mutate) async {
      final m = await goodBackup();
      mutate(m);
      expect(() => parse(m), refusedAs(damaged));
    }

    Map<String, dynamic> entry(Map<String, dynamic> m) => (m['entries'] as List).first as Map<String, dynamic>;

    test('amounts must be whole, sensible, non-negative numbers', () async {
      await expectDamaged((m) => entry(m)['amountPoisha'] = -1);
      await expectDamaged((m) => entry(m)['amountPoisha'] = '500');
      await expectDamaged((m) => entry(m)['amountPoisha'] = 12.5);
      await expectDamaged((m) => entry(m)['amountPoisha'] = null);
      await expectDamaged((m) => entry(m)['amountPoisha'] = 99999999999999999);
    });

    test('a goal withdrawal may be negative, but not absurd', () async {
      final m = await goodBackup();
      expect(parse(m).entryCount, 2, reason: 'the fixture already holds a -500 withdrawal');
      await expectDamaged((m) => (m['goalDeposits'] as List).first['amountPoisha'] = -99999999999999999);
    });

    test('types must be exactly expense or income', () async {
      await expectDamaged((m) => entry(m)['type'] = 'transfer');
      await expectDamaged((m) => entry(m)['type'] = 3);
      await expectDamaged((m) => (m['categories'] as List).first['type'] = '');
    });

    test('dates must be real yyyy-MM-dd dates', () async {
      await expectDamaged((m) => entry(m)['date'] = '2026-13-40');
      await expectDamaged((m) => entry(m)['date'] = '19/10/2026');
      await expectDamaged((m) => entry(m)['date'] = '2026-10-19; DROP TABLE entries');
      await expectDamaged((m) => entry(m)['date'] = '../../etc/passwd');
      await expectDamaged((m) => entry(m)['date'] = 20261019);
      await expectDamaged((m) => entry(m)['date'] = null);
    });

    test('text must be text and not enormous', () async {
      await expectDamaged((m) => entry(m)['note'] = 'x' * 2001);
      await expectDamaged((m) => entry(m)['note'] = 42);
      await expectDamaged((m) => (m['categories'] as List).first['name'] = '');
      await expectDamaged((m) => (m['categories'] as List).first['name'] = 'n' * 41);
      await expectDamaged((m) => (m['dharRecords'] as List).first['person'] = ['Rahim']);
    });

    test('a missing optional note is fine', () async {
      final m = await goodBackup();
      entry(m).remove('note');
      expect(parse(m).entryCount, 2);
    });

    test('recurring items: day 1 to 31, months as yyyy-MM, flags as true or false', () async {
      await expectDamaged((m) => (m['recurrings'] as List).first['dayOfMonth'] = 0);
      await expectDamaged((m) => (m['recurrings'] as List).first['dayOfMonth'] = 32);
      await expectDamaged((m) => (m['recurrings'] as List).first['lastHandledMonth'] = '2026-13');
      await expectDamaged((m) => (m['recurrings'] as List).first['autoAdd'] = 'yes');
      await expectDamaged((m) => (m['recurrings'] as List).first['isActive'] = 1);
    });

    test('tables must be lists of objects', () async {
      await expectDamaged((m) => m['entries'] = {'a': 1});
      await expectDamaged((m) => m['entries'] = [1, 2, 3]);
      await expectDamaged((m) => m['budgets'] = 'lots');
      await expectDamaged((m) => m['settings'] = 'nope');
      await expectDamaged((m) => m['categories'] = null);
    });

    test('an empty file, nothing, and non-text are all refused', () {
      expect(() => parseBackup(Uint8List(0), currentSchemaVersion: 3), refusedAs('That file is not a Hisab backup.'));
      expect(() => parseBackup(Uint8List.fromList([0xff, 0xfe, 0x00, 0x80]), currentSchemaVersion: 3), refusedAs('That file is not a Hisab backup.'));
      expect(() => parseBackup(Uint8List.fromList(utf8.encode('null')), currentSchemaVersion: 3), refusedAs('That file is not a Hisab backup.'));
      expect(() => parseBackup(Uint8List.fromList(utf8.encode('{"format":"other"}')), currentSchemaVersion: 3), refusedAs('That file is not a Hisab backup.'));
    });
  });

  group('a file that passes the checks but does not fit together changes nothing', () {
    late AppDatabase target;
    setUp(() async {
      target = AppDatabase(NativeDatabase.memory());
      final food = (await target.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await target.addEntry(type: EntryType.expense, amountPoisha: 777, categoryId: food.id, date: '2026-10-20', note: 'Precious');
    });
    tearDown(() => target.close());

    Future<void> expectUntouched() async {
      final entries = await target.watchEntries().first;
      expect(entries.single.entry.note, 'Precious');
      expect(await target.watchCategories().first, hasLength(15));
    }

    test('an entry pointing at a category that is not in the file', () async {
      final m = await goodBackup();
      (m['entries'] as List).first['categoryId'] = 9999;
      await expectLater(restoreBackup(target, parse(m)), throwsA(isA<BackupException>()));
      await expectUntouched();
    });

    test('two entries with the same id', () async {
      final m = await goodBackup();
      final entries = m['entries'] as List;
      entries[1]['id'] = entries[0]['id'];
      await expectLater(restoreBackup(target, parse(m)), throwsA(isA<BackupException>()));
      await expectUntouched();
    });

    test('a goal deposit for a goal that does not exist', () async {
      final m = await goodBackup();
      (m['goalDeposits'] as List).first['goalId'] = 424242;
      await expectLater(restoreBackup(target, parse(m)), throwsA(isA<BackupException>()));
      await expectUntouched();
    });
  });

  group('text is only ever data', () {
    test('SQL, HTML and script in notes are stored and returned as plain text, and nothing is run', () async {
      const nasty = ["'; DROP TABLE entries; --", '<script>alert(1)</script>', '"; DELETE FROM categories; "', r'$(rm -rf /)', '=cmd|\' /C calc\'!A0'];
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      for (final n in nasty) {
        await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-20', note: n);
      }

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await restoreBackup(restored, parseBackup(encodeBackup(await createBackup(db)), currentSchemaVersion: 3));

      expect((await restored.watchEntries().first).map((e) => e.entry.note).toSet(), nasty.toSet());
      expect(await restored.watchCategories().first, hasLength(15), reason: 'no table was touched');
    });

    test('in a spreadsheet export, anything that could run as a formula is neutralised', () async {
      const risky = ['=1+1', '+1', '-1', '@SUM(A1)', '\t=1', '\r=1'];
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      for (final n in risky) {
        await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-20', note: n);
      }
      final csv = buildCsv(await db.watchEntries().first);
      for (final n in risky) {
        expect(csv.contains(',$n\r\n'), isFalse, reason: '"$n" must not start a cell unprotected');
        expect(csv.contains(",\"'$n\"") || csv.contains(",'$n"), isTrue, reason: '"$n" gets a leading apostrophe');
      }
    });
  });
}
