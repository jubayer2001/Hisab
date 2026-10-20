import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

/// A database laid out exactly as v0.2 created it (schema version 1), with data in it,
/// the way it sits on a phone that has been used for a while.
NativeDatabase _version1Database() {
  return NativeDatabase.memory(
    setup: (raw) {
      raw.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          icon_key TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0
        )''');
      raw.execute('''
        CREATE TABLE entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          type TEXT NOT NULL,
          amount_poisha INTEGER NOT NULL,
          category_id INTEGER NOT NULL REFERENCES categories (id),
          payment_method TEXT NULL,
          note TEXT NULL,
          date TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
        )''');
      raw.execute('''
        CREATE TABLE day_statuses (
          date TEXT NOT NULL,
          no_spend INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (date)
        )''');

      raw.execute("INSERT INTO categories (name, type, icon_key, color_value, sort_order, is_archived) "
          "VALUES ('Food', 'expense', 'food', 4294942284, 0, 0)");
      raw.execute("INSERT INTO categories (name, type, icon_key, color_value, sort_order, is_archived) "
          "VALUES ('Salary', 'income', 'salary', 4281442923, 1, 0)");
      raw.execute("INSERT INTO categories (name, type, icon_key, color_value, sort_order, is_archived) "
          "VALUES ('Old hobby', 'expense', 'dots', 4287997887, 2, 1)");
      raw.execute("INSERT INTO entries (type, amount_poisha, category_id, payment_method, note, date) "
          "VALUES ('expense', 18000, 1, 'bKash', 'Lunch', '2026-10-19')");
      raw.execute("INSERT INTO entries (type, amount_poisha, category_id, payment_method, note, date) "
          "VALUES ('expense', 25050, 1, NULL, NULL, '2026-10-20')");
      raw.execute("INSERT INTO entries (type, amount_poisha, category_id, payment_method, note, date) "
          "VALUES ('income', 2000000, 2, NULL, 'October salary', '2026-10-01')");
      raw.execute("INSERT INTO day_statuses (date, no_spend) VALUES ('2026-10-18', 1)");

      raw.execute('PRAGMA user_version = 1');
    },
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(_version1Database()));
  tearDown(() => db.close());

  test('upgrading from v0.2 keeps every entry, category and no-spend day', () async {
    final entries = await db.watchEntries().first;
    expect(entries, hasLength(3));
    expect(entries.map((e) => e.entry.amountPoisha), containsAll([18000, 25050, 2000000]));

    final lunch = entries.firstWhere((e) => e.entry.note == 'Lunch');
    expect(lunch.entry.paymentMethod, 'bKash');
    expect(lunch.entry.date, '2026-10-19');
    expect(lunch.category.name, 'Food');
    expect(lunch.isExpense, isTrue);

    final salary = entries.firstWhere((e) => e.entry.type == EntryType.income);
    expect(salary.entry.amountPoisha, 2000000);
    expect(salary.category.name, 'Salary');

    final categories = await db.watchCategories().first;
    expect(categories, hasLength(3)); // not re-seeded with the defaults
    expect(categories.firstWhere((c) => c.name == 'Old hobby').isArchived, isTrue);

    expect(await db.watchNoSpendDays().first, {'2026-10-18'});
  });

  test('the new tables work after the upgrade', () async {
    final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');

    await db.setBudget(categoryId: null, amountPoisha: 2500000);
    await db.setBudget(categoryId: food.id, amountPoisha: 800000);
    await db.setBudget(categoryId: food.id, amountPoisha: 900000); // replaces, not duplicates
    final budgets = await db.watchBudgets().first;
    expect(budgets, hasLength(2));
    expect(budgets.firstWhere((b) => b.categoryId == food.id).amountPoisha, 900000);
    expect(budgets.firstWhere((b) => b.categoryId == null).amountPoisha, 2500000);

    final recurringId = await db.addRecurring(
      title: 'Rent',
      type: EntryType.expense,
      amountPoisha: 800000,
      categoryId: food.id,
      dayOfMonth: 1,
    );
    expect((await db.watchRecurrings().first).single.id, recurringId);

    final goalId = await db.addGoal(name: 'Eid shopping', targetPoisha: 1000000, colorValue: 0xFFE86A9A);
    await db.addDeposit(goalId: goalId, amountPoisha: 200000, date: '2026-10-20');
    expect((await db.watchDeposits().first).single.amountPoisha, 200000);

    final dharId = await db.addDhar(
      person: 'Rahim',
      direction: DharDirection.lent,
      amountPoisha: 100000,
      date: '2026-10-20',
    );
    await db.addDharPayment(dharId: dharId, amountPoisha: 40000, date: '2026-10-21');
    expect((await db.watchDhar().first).single.settled, isFalse);
    await db.addDharPayment(dharId: dharId, amountPoisha: 60000, date: '2026-10-22');
    expect((await db.watchDhar().first).single.settled, isTrue);
  });

  test('a fresh install creates every table and the default categories', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    final categories = await fresh.watchCategories().first;
    expect(categories, hasLength(15));
    await fresh.setBudget(categoryId: null, amountPoisha: 100);
    expect(await fresh.watchBudgets().first, hasLength(1));
  });

  test('removing a category also drops its budget, and hides it when a recurring bill uses it', () async {
    final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
    await db.setBudget(categoryId: food.id, amountPoisha: 500000);
    await db.addRecurring(
      title: 'Tea subscription',
      type: EntryType.expense,
      amountPoisha: 10000,
      categoryId: food.id,
      dayOfMonth: 5,
    );

    await db.removeCategory(food.id);

    expect(await db.watchBudgets().first, isEmpty);
    expect((await db.watchCategories().first).firstWhere((c) => c.id == food.id).isArchived, isTrue);
  });

  test('deleting a goal or a dhar record also deletes what hangs off it', () async {
    final goalId = await db.addGoal(name: 'Laptop', targetPoisha: 5000000, colorValue: 0xFF4C8DF6);
    await db.addDeposit(goalId: goalId, amountPoisha: 100000, date: '2026-10-20');
    await db.deleteGoal(goalId);
    expect(await db.watchGoals().first, isEmpty);
    expect(await db.watchDeposits().first, isEmpty);

    final dharId = await db.addDhar(
      person: 'Karim',
      direction: DharDirection.borrowed,
      amountPoisha: 50000,
      date: '2026-10-20',
    );
    await db.addDharPayment(dharId: dharId, amountPoisha: 10000, date: '2026-10-21');
    await db.deleteDhar(dharId);
    expect(await db.watchDhar().first, isEmpty);
    expect(await db.watchDharPayments().first, isEmpty);
  });
}
