import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/auto_income.dart';
import 'package:hisab/data/logic/planning.dart';

/// A database laid out exactly as v0.3/v0.4 created it (schema version 2), with data in it.
NativeDatabase _version2Database() {
  return NativeDatabase.memory(
    setup: (raw) {
      raw.execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL,
          type TEXT NOT NULL, icon_key TEXT NOT NULL, color_value INTEGER NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0)''');
      raw.execute('''CREATE TABLE entries (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, type TEXT NOT NULL,
          amount_poisha INTEGER NOT NULL, category_id INTEGER NOT NULL REFERENCES categories (id),
          payment_method TEXT NULL, note TEXT NULL, date TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)))''');
      raw.execute('CREATE TABLE day_statuses (date TEXT NOT NULL, no_spend INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (date))');
      raw.execute('CREATE TABLE budgets (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, category_id INTEGER NULL REFERENCES categories (id), amount_poisha INTEGER NOT NULL)');
      raw.execute('''CREATE TABLE recurrings (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL
          CHECK (LENGTH(title) BETWEEN 1 AND 40), type TEXT NOT NULL, amount_poisha INTEGER NOT NULL,
          category_id INTEGER NOT NULL REFERENCES categories (id), day_of_month INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1, last_handled_month TEXT NULL)''');
      raw.execute('''CREATE TABLE savings_goals (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL,
          target_poisha INTEGER NOT NULL, deadline TEXT NULL, color_value INTEGER NOT NULL)''');
      raw.execute('CREATE TABLE goal_deposits (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, goal_id INTEGER NOT NULL REFERENCES savings_goals (id), amount_poisha INTEGER NOT NULL, date TEXT NOT NULL)');
      raw.execute('''CREATE TABLE dhar_records (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, person TEXT NOT NULL,
          direction TEXT NOT NULL, amount_poisha INTEGER NOT NULL, date TEXT NOT NULL, due_date TEXT NULL,
          note TEXT NULL, settled INTEGER NOT NULL DEFAULT 0)''');
      raw.execute('CREATE TABLE dhar_payments (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, dhar_id INTEGER NOT NULL REFERENCES dhar_records (id), amount_poisha INTEGER NOT NULL, date TEXT NOT NULL)');

      raw.execute("INSERT INTO categories (name, type, icon_key, color_value, sort_order) VALUES ('Food', 'expense', 'food', 4294942284, 0)");
      raw.execute("INSERT INTO categories (name, type, icon_key, color_value, sort_order) VALUES ('Salary', 'income', 'salary', 4281442923, 1)");
      raw.execute("INSERT INTO entries (type, amount_poisha, category_id, note, date) VALUES ('expense', 18000, 1, 'Lunch', '2026-10-19')");
      raw.execute("INSERT INTO entries (type, amount_poisha, category_id, note, date) VALUES ('income', 2000000, 2, 'October salary', '2026-10-01')");
      raw.execute("INSERT INTO recurrings (title, type, amount_poisha, category_id, day_of_month, last_handled_month) VALUES ('Salary', 'income', 4500000, 2, 1, '2026-09')");
      raw.execute("INSERT INTO recurrings (title, type, amount_poisha, category_id, day_of_month) VALUES ('Wi-Fi', 'expense', 100000, 1, 5)");
      raw.execute("INSERT INTO budgets (category_id, amount_poisha) VALUES (NULL, 2500000)");
      raw.execute('PRAGMA user_version = 2');
    },
  );
}

Recurring _item({
  String type = EntryType.income,
  int day = 1,
  bool auto = true,
  bool active = true,
  String? start,
  String? handled,
  int id = 1,
}) =>
    Recurring(
      id: id,
      title: 'Salary',
      type: type,
      amountPoisha: 4500000,
      categoryId: 1,
      dayOfMonth: day,
      isActive: active,
      lastHandledMonth: handled,
      autoAdd: auto,
      startMonth: start,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  incomeSetupTests();

  group('which months an automatic income is still owed for', () {
    test('this month, once its day has come, and not before', () {
      final item = _item(day: 10, start: '2026-11');
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 9)), isEmpty);
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 10)), [DateTime(2026, 11, 1)]);
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 28)), [DateTime(2026, 11, 1)]);
    });

    test('a month already handled is never owed again', () {
      final item = _item(start: '2026-10', handled: '2026-11');
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 20)), isEmpty);
    });

    test('opening the app after missing months fills them in, oldest first', () {
      final item = _item(start: '2026-08', handled: '2026-08');
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 3)), [
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 1),
        DateTime(2026, 11, 1),
      ]);
    });

    test('never fills in months before it was set up', () {
      final item = _item(start: '2026-11');
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 20)), [DateTime(2026, 11, 1)]);
    });

    test('without a start month only the current month counts', () {
      final item = _item(start: null);
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 20)), [DateTime(2026, 11, 1)]);
    });

    test('paused, bills and ask-first items are ignored', () {
      expect(pendingAutoIncomeMonths(_item(active: false, start: '2026-11'), DateTime(2026, 11, 20)), isEmpty);
      expect(pendingAutoIncomeMonths(_item(type: EntryType.expense, start: '2026-11'), DateTime(2026, 11, 20)), isEmpty);
      expect(pendingAutoIncomeMonths(_item(auto: false, start: '2026-11'), DateTime(2026, 11, 20)), isEmpty);
    });

    test('a nonsense start month is treated as "this month only"', () {
      final item = _item(start: 'garbage');
      expect(pendingAutoIncomeMonths(item, DateTime(2026, 11, 20)), [DateTime(2026, 11, 1)]);
    });

    test('never more than two years back', () {
      final item = _item(start: '2020-01');
      final months = pendingAutoIncomeMonths(item, DateTime(2026, 11, 20));
      expect(months, hasLength(maxAutoIncomeMonths));
      expect(months.last, DateTime(2026, 11, 1));
    });

    test('the due-list on Home never shows automatic income', () {
      final auto = _item(start: '2026-10');
      final ask = _item(auto: false, id: 2);
      expect(dueRecurrings([auto, ask], DateTime(2026, 11, 20)).map((r) => r.id), [2]);
    });
  });

  group('adding the income', () {
    late AppDatabase db;
    late int salaryCategory;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      salaryCategory = (await db.watchCategories().first).firstWhere((c) => c.name == 'Salary').id;
    });
    tearDown(() => db.close());

    Future<int> addSalary({int day = 1, String? start = '2026-11', bool auto = true}) => db.addRecurring(
          title: 'Salary',
          type: EntryType.income,
          amountPoisha: 4500000,
          categoryId: salaryCategory,
          dayOfMonth: day,
          autoAdd: auto,
          startMonth: start,
        );

    Future<List<Entry>> allEntries() async => (await db.watchEntries().first).map((e) => e.entry).toList();

    test('adds the entry on its day, dated that day, marked as automatic', () async {
      final id = await addSalary(day: 1);
      final added = await applyAutoIncome(db, DateTime(2026, 11, 1));

      expect(added, hasLength(1));
      final entry = (await allEntries()).single;
      expect(entry.date, '2026-11-01');
      expect(entry.amountPoisha, 4500000);
      expect(entry.type, EntryType.income);
      expect(entry.note, 'Salary');
      expect(entry.recurringId, id);
    });

    test('running it again and again adds nothing more', () async {
      await addSalary();
      await applyAutoIncome(db, DateTime(2026, 11, 1));
      await applyAutoIncome(db, DateTime(2026, 11, 1));
      await applyAutoIncome(db, DateTime(2026, 11, 20));
      expect(await allEntries(), hasLength(1));
    });

    test('opened late: dated the real day it was due, not the day the app opened', () async {
      await addSalary(day: 5);
      await applyAutoIncome(db, DateTime(2026, 11, 22));
      expect((await allEntries()).single.date, '2026-11-05');
    });

    test('not yet due: nothing is added', () async {
      await addSalary(day: 15);
      expect(await applyAutoIncome(db, DateTime(2026, 11, 14)), isEmpty);
      expect(await allEntries(), isEmpty);
    });

    test('catches up several months, one entry each, each on its own day', () async {
      await addSalary(day: 3, start: '2026-08');
      await applyAutoIncome(db, DateTime(2026, 11, 20));
      expect((await allEntries()).map((e) => e.date).toList()..sort(), ['2026-08-03', '2026-09-03', '2026-10-03', '2026-11-03']);
    });

    test('day 31 falls on the last day of a short month', () async {
      await addSalary(day: 31, start: '2026-02');
      await applyAutoIncome(db, DateTime(2026, 2, 28));
      expect((await allEntries()).single.date, '2026-02-28');
    });

    test('deleting the automatic entry does not bring it back ("didn\'t receive it")', () async {
      await addSalary();
      await applyAutoIncome(db, DateTime(2026, 11, 1));
      await db.deleteEntry((await allEntries()).single.id);
      await applyAutoIncome(db, DateTime(2026, 11, 20));
      expect(await allEntries(), isEmpty);

      // ...but December still arrives.
      await applyAutoIncome(db, DateTime(2026, 12, 1));
      expect((await allEntries()).single.date, '2026-12-01');
    });

    test('changing the amount later affects only the coming months', () async {
      final id = await addSalary();
      await applyAutoIncome(db, DateTime(2026, 11, 1));
      final item = (await db.watchRecurrings().first).single;
      await db.updateRecurring(item.copyWith(amountPoisha: 5000000));
      await applyAutoIncome(db, DateTime(2026, 12, 1));

      final entries = await allEntries();
      expect(entries.firstWhere((e) => e.date == '2026-11-01').amountPoisha, 4500000);
      expect(entries.firstWhere((e) => e.date == '2026-12-01').amountPoisha, 5000000);
      expect(entries.every((e) => e.recurringId == id), isTrue);
    });

    test('two engines running at once neither deadlock nor add twice', () async {
      final today = DateTime(2026, 11, 20);
      await Future.wait([
        createMonthlyIncome(db, today,
            title: 'Salary', amountPoisha: 100, categoryId: salaryCategory, dayOfMonth: 1, receivedThisMonth: true),
        applyAutoIncome(db, today),
        applyAutoIncome(db, today),
      ]).timeout(const Duration(seconds: 10));
      expect(await allEntries(), hasLength(1));
    });

    test('ask-first items are left for the person to confirm', () async {
      await addSalary(auto: false);
      expect(await applyAutoIncome(db, DateTime(2026, 11, 20)), isEmpty);
    });
  });

  group('deleting several entries', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('all of them go, the rest stay, and undo puts them back with the same ids', () async {
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food').id;
      final ids = <int>[];
      for (var i = 1; i <= 4; i++) {
        ids.add(await db.addEntry(type: EntryType.expense, amountPoisha: i * 100, categoryId: food, date: '2026-10-2$i'));
      }
      final before = await db.watchEntries().first;
      final doomed = before.where((e) => ids.take(3).contains(e.entry.id)).map((e) => e.entry).toList();

      await db.deleteEntries(ids.take(3));
      expect((await db.watchEntries().first).map((e) => e.entry.id), [ids.last]);

      await db.restoreEntries(doomed);
      expect((await db.watchEntries().first).map((e) => e.entry.id).toSet(), ids.toSet());
    });

    test('deleting nothing is fine', () async {
      await db.deleteEntries(const []);
    });
  });

  group('erase all data', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> fill() async {
      final cats = await db.watchCategories().first;
      final food = cats.firstWhere((c) => c.name == 'Food');
      await db.addCategory(name: 'My own', type: EntryType.expense, iconKey: 'dots', colorValue: 0xFF123456);
      await db.addEntry(type: EntryType.expense, amountPoisha: 5000, categoryId: food.id, date: '2026-10-20', note: 'Lunch');
      await db.setNoSpend('2026-10-19', true);
      await db.setBudget(categoryId: null, amountPoisha: 2500000);
      await db.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 100000, categoryId: food.id, dayOfMonth: 1);
      final goal = await db.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A);
      await db.addDeposit(goalId: goal, amountPoisha: 1000, date: '2026-10-20');
      final dhar = await db.addDhar(person: 'Rahim', direction: DharDirection.lent, amountPoisha: 5000, date: '2026-10-20');
      await db.addDharPayment(dharId: dhar, amountPoisha: 1000, date: '2026-10-21');
    }

    test('everything is gone and the default categories are back', () async {
      await fill();
      await db.eraseEverything();

      expect(await db.watchEntries().first, isEmpty);
      expect(await db.watchNoSpendDays().first, isEmpty);
      expect(await db.watchBudgets().first, isEmpty);
      expect(await db.watchRecurrings().first, isEmpty);
      expect(await db.watchGoals().first, isEmpty);
      expect(await db.watchDeposits().first, isEmpty);
      expect(await db.watchDhar().first, isEmpty);
      expect(await db.watchDharPayments().first, isEmpty);

      final categories = await db.watchCategories().first;
      expect(categories, hasLength(15));
      expect(categories.any((c) => c.name == 'My own'), isFalse);
    });

    test('the safety copy survives the erase, and undo brings everything back', () async {
      await fill();
      final snapshot = encodeBackup(await createBackup(db));
      await db.saveEraseSnapshot(utf8.decode(snapshot));
      await db.eraseEverything();

      expect(await db.watchEraseSnapshot().first, isNotNull);

      final saved = (await db.watchEraseSnapshot().first)!;
      final contents = parseBackup(Uint8List.fromList(utf8.encode(saved.payload)), currentSchemaVersion: db.schemaVersion);
      await restoreBackup(db, contents);
      await db.deleteEraseSnapshots();

      expect((await db.watchEntries().first).single.entry.note, 'Lunch');
      expect((await db.watchGoals().first).single.name, 'Eid');
      expect((await db.watchDhar().first).single.person, 'Rahim');
      expect((await db.watchCategories().first).any((c) => c.name == 'My own'), isTrue);
      expect(await db.watchEraseSnapshot().first, isNull);
    });

    test('only one safety copy is kept', () async {
      await db.saveEraseSnapshot('{"a":1}');
      await db.saveEraseSnapshot('{"b":2}');
      final all = await db.select(db.eraseSnapshots).get();
      expect(all, hasLength(1));
      expect(all.single.payload, '{"b":2}');
    });

    test('copies older than a week are removed, newer ones stay', () async {
      await db.saveEraseSnapshot('{"a":1}');
      expect(await db.purgeOldEraseSnapshots(const Duration(days: 7)), 0);
      expect(
        await db.purgeOldEraseSnapshots(const Duration(days: 7), now: DateTime.now().add(const Duration(days: 8))),
        1,
      );
      expect(await db.watchEraseSnapshot().first, isNull);
    });
  });

  group('upgrading a phone that already holds v0.4 data', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(_version2Database()));
    tearDown(() => db.close());

    test('nothing is lost, and the old recurring items keep behaving as before', () async {
      final entries = await db.watchEntries().first;
      expect(entries.map((e) => e.entry.note), containsAll(['Lunch', 'October salary']));
      expect(entries.every((e) => e.entry.recurringId == null), isTrue);

      final recurrings = await db.watchRecurrings().first;
      expect(recurrings, hasLength(2));
      expect(recurrings.every((r) => !r.autoAdd), isTrue, reason: 'old items keep asking first');
      expect(recurrings.firstWhere((r) => r.title == 'Salary').lastHandledMonth, '2026-09');
      expect((await db.watchBudgets().first).single.amountPoisha, 2500000);
    });

    test('the new features work straight after the upgrade', () async {
      final salary = (await db.watchCategories().first).firstWhere((c) => c.name == 'Salary').id;
      await db.addRecurring(
        title: 'Tuition', type: EntryType.income, amountPoisha: 800000, categoryId: salary,
        dayOfMonth: 10, autoAdd: true, startMonth: '2026-11',
      );
      expect(await applyAutoIncome(db, DateTime(2026, 11, 12)), hasLength(1));

      await db.saveEraseSnapshot('{}');
      expect(await db.watchEraseSnapshot().first, isNotNull);
    });
  });

  group('backups across versions', () {
    test('a backup made before monthly income existed still restores', () async {
      final old = AppDatabase(_version2Database());
      // The old app's backup has no autoAdd / startMonth / recurringId at all.
      final json = await createBackup(old);
      await old.close();
      for (final r in json['recurrings'] as List) {
        (r as Map).remove('autoAdd');
        r.remove('startMonth');
      }
      for (final e in json['entries'] as List) {
        (e as Map).remove('recurringId');
      }

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final contents = parseBackup(encodeBackup(json), currentSchemaVersion: fresh.schemaVersion);
      await restoreBackup(fresh, contents);

      final recurrings = await fresh.watchRecurrings().first;
      expect(recurrings, hasLength(2));
      expect(recurrings.every((r) => !r.autoAdd), isTrue);
      expect((await fresh.watchEntries().first), hasLength(2));
    });

    test('a backup that includes automatic income round-trips exactly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final salary = (await db.watchCategories().first).firstWhere((c) => c.name == 'Salary').id;
      await db.addRecurring(
        title: 'Salary', type: EntryType.income, amountPoisha: 4500000, categoryId: salary,
        dayOfMonth: 1, autoAdd: true, startMonth: '2026-11',
      );
      await applyAutoIncome(db, DateTime(2026, 11, 2));

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await restoreBackup(restored, parseBackup(encodeBackup(await createBackup(db)), currentSchemaVersion: db.schemaVersion));

      final item = (await restored.watchRecurrings().first).single;
      expect(item.autoAdd, isTrue);
      expect(item.startMonth, '2026-11');
      expect(item.lastHandledMonth, '2026-11');
      final entry = (await restored.watchEntries().first).single.entry;
      expect(entry.recurringId, item.id);
      // Restored, so it must not be added a second time.
      expect(await applyAutoIncome(restored, DateTime(2026, 11, 20)), isEmpty);
    });
  });
}

void incomeSetupTests() {
  group('setting up a monthly income', () {
    late AppDatabase db;
    late int salary;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      salary = (await db.watchCategories().first).firstWhere((c) => c.name == 'Salary').id;
    });
    tearDown(() => db.close());

    Future<int> create(DateTime today, {int day = 1, required bool received}) => createMonthlyIncome(
          db, today,
          title: 'Salary', amountPoisha: 4500000, categoryId: salary, dayOfMonth: day, receivedThisMonth: received,
        );

    Future<List<Entry>> entries() async => (await db.watchEntries().first).map((e) => e.entry).toList();

    test('received, and its day has passed: added now, dated its day', () async {
      await create(DateTime(2026, 11, 20), day: 1, received: true);
      final e = (await entries()).single;
      expect(e.date, '2026-11-01');
      expect(e.recurringId, isNotNull);
    });

    test('received early, before its day: counts today, and is not added again on its day', () async {
      await create(DateTime(2026, 11, 5), day: 10, received: true);
      expect((await entries()).single.date, '2026-11-05');
      await applyAutoIncome(db, DateTime(2026, 11, 10));
      await applyAutoIncome(db, DateTime(2026, 11, 30));
      expect(await entries(), hasLength(1));
      // December still arrives.
      await applyAutoIncome(db, DateTime(2026, 12, 10));
      expect(await entries(), hasLength(2));
    });

    test('not received yet: nothing now, the first entry is next month', () async {
      await create(DateTime(2026, 11, 20), day: 1, received: false);
      expect(await entries(), isEmpty);
      await applyAutoIncome(db, DateTime(2026, 11, 30));
      expect(await entries(), isEmpty);
      await applyAutoIncome(db, DateTime(2026, 12, 1));
      expect((await entries()).single.date, '2026-12-01');
    });

    test('two incomes are independent', () async {
      await create(DateTime(2026, 11, 20), day: 1, received: true);
      await createMonthlyIncome(db, DateTime(2026, 11, 20),
          title: 'Tuition', amountPoisha: 800000, categoryId: salary, dayOfMonth: 10, receivedThisMonth: true);
      expect((await entries()).map((e) => e.note).toSet(), {'Salary', 'Tuition'});
      expect(monthlyIncomeTotal(await db.watchRecurrings().first), 5300000);
    });

    test('the total ignores paused items and bills', () async {
      await create(DateTime(2026, 11, 20), received: false);
      final item = (await db.watchRecurrings().first).single;
      await db.updateRecurring(item.copyWith(isActive: false));
      await db.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 100000, categoryId: salary, dayOfMonth: 1);
      expect(monthlyIncomeTotal(await db.watchRecurrings().first), 0);
    });
  });
}
