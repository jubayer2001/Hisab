import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/csv.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

/// Puts a bit of everything in the database: entries, a custom and an archived category,
/// budgets, a recurring bill, a goal with deposits, and dhar with a part payment.
Future<void> _fill(AppDatabase db) async {
  final cats = await db.watchCategories().first;
  final food = cats.firstWhere((c) => c.name == 'Food');
  final salary = cats.firstWhere((c) => c.name == 'Salary');
  final rent = cats.firstWhere((c) => c.name == 'Rent');

  final custom = await db.addCategory(name: 'Tuition fee', type: EntryType.expense, iconKey: 'school', colorValue: 0xFF123456);
  await db.addEntry(type: EntryType.expense, amountPoisha: 18000, categoryId: food.id, date: '2026-10-19', paymentMethod: 'bKash', note: 'Lunch, with "friends"');
  await db.addEntry(type: EntryType.expense, amountPoisha: 250050, categoryId: custom, date: '2026-10-20');
  await db.addEntry(type: EntryType.income, amountPoisha: 2000000, categoryId: salary.id, date: '2026-10-01', note: 'October salary');
  await db.setNoSpend('2026-10-18', true);
  await db.removeCategory(rent.id); // unused, so it is deleted
  await db.setBudget(categoryId: null, amountPoisha: 2500000);
  await db.setBudget(categoryId: food.id, amountPoisha: 800000);
  await db.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 100000, categoryId: food.id, dayOfMonth: 5);
  final goal = await db.addGoal(name: 'Eid shopping', targetPoisha: 1000000, colorValue: 0xFFE86A9A, deadline: '2027-03-20');
  await db.addDeposit(goalId: goal, amountPoisha: 200000, date: '2026-10-20');
  await db.addDeposit(goalId: goal, amountPoisha: -50000, date: '2026-10-21');
  final dhar = await db.addDhar(person: 'Rahim', direction: DharDirection.lent, amountPoisha: 100000, date: '2026-10-01', dueDate: '2026-11-01', note: 'For books');
  await db.addDharPayment(dharId: dhar, amountPoisha: 40000, date: '2026-10-10');
}

/// All tables as plain JSON, to compare two databases.
Future<Map<String, Object?>> _snapshot(AppDatabase db) async {
  final b = await createBackup(db);
  return {for (final e in b.entries) if (e.key != 'exportedAt') e.key: e.value};
}

BackupContents _parse(Uint8List bytes) => parseBackup(bytes, currentSchemaVersion: 3);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('backup round trip', () {
    test('restoring into an empty database recreates everything exactly', () async {
      await _fill(db);
      final before = await _snapshot(db);
      final bytes = encodeBackup(await createBackup(db, settings: {'userName': 'Jubayer'}));

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final contents = _parse(bytes);
      await restoreBackup(fresh, contents);

      expect(await _snapshot(fresh), before);
      expect(contents.entryCount, 3);
      expect(contents.settings['userName'], 'Jubayer');
      expect(contents.exportedAt, isNotNull);
    });

    test('restoring replaces whatever was there before', () async {
      await _fill(db);
      final bytes = encodeBackup(await createBackup(db));
      final expected = await _snapshot(db);

      // Change things after the backup was made.
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await db.addEntry(type: EntryType.expense, amountPoisha: 99999, categoryId: food.id, date: '2026-10-22');
      await db.setBudget(categoryId: null, amountPoisha: 1);
      expect(await _snapshot(db), isNot(expected));

      await restoreBackup(db, _parse(bytes));
      expect(await _snapshot(db), expected);
    });

    test('ids keep working after a restore (new rows do not collide)', () async {
      await _fill(db);
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      await restoreBackup(fresh, _parse(encodeBackup(await createBackup(db))));

      final food = (await fresh.watchCategories().first).firstWhere((c) => c.name == 'Food');
      final id = await fresh.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-23');
      final ids = (await fresh.watchEntries().first).map((e) => e.entry.id).toList();
      expect(ids.toSet(), hasLength(4));
      expect(ids, contains(id));
    });

    test('a backup of an empty database restores to an empty one', () async {
      final bytes = encodeBackup(await createBackup(AppDatabase(NativeDatabase.memory())));
      await _fill(db);
      await restoreBackup(db, _parse(bytes));
      expect(await db.watchEntries().first, isEmpty);
      expect(await db.watchBudgets().first, isEmpty);
      expect(await db.watchCategories().first, hasLength(15)); // the defaults a new database starts with
    });
  });

  group('checking a backup file', () {
    Uint8List json(Object? value) => Uint8List.fromList(utf8.encode(jsonEncode(value)));

    test('rejects files that are not backups', () {
      expect(() => _parse(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<BackupException>()));
      expect(() => _parse(json([1, 2, 3])), throwsA(isA<BackupException>()));
      expect(() => _parse(json({'format': 'something-else'})), throwsA(isA<BackupException>()));
      expect(() => _parse(Uint8List(0)), throwsA(isA<BackupException>()));
    });

    test('rejects damaged backups', () {
      expect(
        () => _parse(json({'format': 'hisab-backup', 'formatVersion': 1, 'schemaVersion': 2})),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('damaged'))),
      );
      expect(
        () => _parse(json({'format': 'hisab-backup', 'formatVersion': 1, 'schemaVersion': 2, 'categories': [], 'entries': 'nope'})),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a backup from a newer version of the app', () {
      expect(
        () => _parse(json({'format': 'hisab-backup', 'formatVersion': 1, 'schemaVersion': 4, 'categories': [], 'entries': []})),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('newer version'))),
      );
      expect(
        () => _parse(json({'format': 'hisab-backup', 'formatVersion': 99, 'schemaVersion': 2, 'categories': [], 'entries': []})),
        throwsA(isA<BackupException>()),
      );
    });

    test('accepts a backup from an older schema that lacks the newer tables', () async {
      await restoreBackup(
        db,
        _parse(json({
          'format': 'hisab-backup', 'formatVersion': 1, 'schemaVersion': 1,
          'categories': [
            {'id': 1, 'name': 'Food', 'type': 'expense', 'iconKey': 'food', 'colorValue': 1, 'sortOrder': 0, 'isArchived': false},
          ],
          'entries': [
            {'id': 1, 'type': 'expense', 'amountPoisha': 500, 'categoryId': 1, 'paymentMethod': null, 'note': null, 'date': '2026-10-20', 'createdAt': 1790000000000},
          ],
        })),
      );
      expect((await db.watchEntries().first).single.entry.amountPoisha, 500);
      expect(await db.watchBudgets().first, isEmpty);
    });
  });

  test('a restore that cannot be completed leaves the current data untouched', () async {
    await _fill(db);
    final before = await _snapshot(db);

    // An entry that points at a category the backup does not contain.
    final broken = Uint8List.fromList(utf8.encode(jsonEncode({
      'format': 'hisab-backup', 'formatVersion': 1, 'schemaVersion': 2,
      'categories': [
        {'id': 1, 'name': 'Food', 'type': 'expense', 'iconKey': 'food', 'colorValue': 1, 'sortOrder': 0, 'isArchived': false},
      ],
      'entries': [
        {'id': 1, 'type': 'expense', 'amountPoisha': 500, 'categoryId': 77, 'paymentMethod': null, 'note': null, 'date': '2026-10-20', 'createdAt': 1790000000000},
      ],
    })));

    await expectLater(restoreBackup(db, _parse(broken)), throwsA(isA<BackupException>()));
    expect(await _snapshot(db), before);
  });

  test('backup file names carry the date', () {
    expect(backupFileName(DateTime(2026, 10, 5)), 'hisab-backup-2026-10-05.json');
    expect(backupFileName(DateTime(2026, 12, 31)), 'hisab-backup-2026-12-31.json');
  });

  group('CSV export', () {
    test('has a header, a byte order mark, and entries oldest first', () async {
      await _fill(db);
      final csv = buildCsv(await db.watchEntries().first);

      expect(csv.startsWith('﻿'), isTrue);
      final lines = csv.substring(1).trimRight().split('\r\n');
      expect(lines.first, 'Date,Type,Category,Amount (Taka),Payment method,Note');
      expect(lines.length, 4);
      expect(lines[1], startsWith('2026-10-01,income,Salary,20000.00,,October salary'));
      expect(lines[2], startsWith('2026-10-19,expense,Food,180.00,bKash,'));
      expect(lines[3], startsWith('2026-10-20,expense,Tuition fee,2500.50,,'));
    });

    test('quotes commas and quotes, and guards against formulas', () async {
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-20', note: 'Lunch, with "friends"');
      await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-21', note: '=SUM(A1:A9)');
      await db.addEntry(type: EntryType.expense, amountPoisha: 5, categoryId: food.id, date: '2026-10-22', note: 'Line one\nline two');

      final csv = buildCsv(await db.watchEntries().first);
      expect(csv, contains('"Lunch, with ""friends"""'));
      expect(csv, contains("'=SUM(A1:A9)"));
      expect(csv, contains('"Line one\nline two"'));
      expect(csv, contains(',0.05,')); // five poisha
    });

    test('an empty list is just the header', () {
      expect(buildCsv(const []).trimRight(), '﻿Date,Type,Category,Amount (Taka),Payment method,Note');
    });
  });
}
