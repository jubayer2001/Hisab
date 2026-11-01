import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/logic/auto_income.dart';
import 'package:hisab/data/logic/funds.dart';

// Schema 3 as shipped in 1.0. The fixture deliberately has rows in every table.
NativeDatabase _version3Database() => NativeDatabase.memory(
  setup: (raw) {
    for (final sql in [
      '''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL,
      type TEXT NOT NULL, icon_key TEXT NOT NULL, color_value INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0)''',
      '''CREATE TABLE entries (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, type TEXT NOT NULL,
      amount_poisha INTEGER NOT NULL, category_id INTEGER NOT NULL REFERENCES categories (id),
      payment_method TEXT NULL, note TEXT NULL, date TEXT NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)), recurring_id INTEGER NULL)''',
      'CREATE TABLE day_statuses (date TEXT NOT NULL PRIMARY KEY, no_spend INTEGER NOT NULL DEFAULT 0)',
      '''CREATE TABLE budgets (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      category_id INTEGER NULL REFERENCES categories (id), amount_poisha INTEGER NOT NULL)''',
      '''CREATE TABLE recurrings (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL,
      type TEXT NOT NULL, amount_poisha INTEGER NOT NULL, category_id INTEGER NOT NULL REFERENCES categories (id),
      day_of_month INTEGER NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, last_handled_month TEXT NULL,
      auto_add INTEGER NOT NULL DEFAULT 0, start_month TEXT NULL)''',
      '''CREATE TABLE savings_goals (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL,
      target_poisha INTEGER NOT NULL, deadline TEXT NULL, color_value INTEGER NOT NULL)''',
      '''CREATE TABLE goal_deposits (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      goal_id INTEGER NOT NULL REFERENCES savings_goals (id), amount_poisha INTEGER NOT NULL, date TEXT NOT NULL)''',
      '''CREATE TABLE dhar_records (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, person TEXT NOT NULL,
      direction TEXT NOT NULL, amount_poisha INTEGER NOT NULL, date TEXT NOT NULL, due_date TEXT NULL,
      note TEXT NULL, settled INTEGER NOT NULL DEFAULT 0)''',
      '''CREATE TABLE dhar_payments (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      dhar_id INTEGER NOT NULL REFERENCES dhar_records (id), amount_poisha INTEGER NOT NULL, date TEXT NOT NULL)''',
      '''CREATE TABLE erase_snapshots (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)), payload TEXT NOT NULL)''',
      "INSERT INTO categories VALUES (1, 'Food', 'expense', 'food', 4294942284, 0, 0)",
      "INSERT INTO categories VALUES (2, 'Salary', 'income', 'salary', 4281442923, 1, 0)",
      "INSERT INTO categories VALUES (3, 'Old hobby', 'expense', 'dots', 4287997887, 2, 1)",
      "INSERT INTO entries VALUES (1, 'income', 3000000, 2, 'Bank', 'October pay', '2026-10-01', 1790802000, 1)",
      "INSERT INTO entries VALUES (2, 'expense', 2200000, 1, 'bKash', 'Household', '2026-10-31', 1793394000, NULL)",
      "INSERT INTO day_statuses VALUES ('2026-10-25', 1)",
      'INSERT INTO budgets VALUES (1, NULL, 2500000)',
      "INSERT INTO recurrings VALUES (1, 'Salary', 'income', 3000000, 2, 1, 1, '2026-10', 1, '2026-09')",
      "INSERT INTO savings_goals VALUES (1, 'Laptop', 1000000, '2027-02-01', 4283207158)",
      "INSERT INTO goal_deposits VALUES (1, 1, 300000, '2026-10-31')",
      "INSERT INTO dhar_records VALUES (1, 'Rahim', 'lent', 100000, '2026-10-20', '2026-11-10', 'Tea', 0)",
      "INSERT INTO dhar_payments VALUES (1, 1, 40000, '2026-10-25')",
      "INSERT INTO erase_snapshots VALUES (1, 1793394000, 'existing safety copy')",
      'PRAGMA user_version = 3',
    ]) {
      raw.execute(sql);
    }
  },
);

void main() {
  test('upgrading a populated 1.0 database preserves every feature and adds goal-spending safely', () async {
    final db = AppDatabase(_version3Database());
    addTearDown(db.close);
    final backup = await createBackup(db);
    expect(backup['schemaVersion'], 4);
    final entries = await db.watchEntries().first;
    expect(entries, hasLength(2));
    expect(entries.every((e) => e.entry.savingsGoalId == null), isTrue);
    final income = entries.singleWhere((e) => !e.isExpense).entry;
    expect(income.recurringId, 1);
    expect(income.note, 'October pay');
    expect(income.paymentMethod, 'Bank');
    expect((await db.watchCategories().first).last.isArchived, isTrue);
    expect(await db.watchNoSpendDays().first, {'2026-10-25'});
    expect((await db.watchBudgets().first).single.amountPoisha, 2500000);
    final recurring = (await db.watchRecurrings().first).single;
    expect(recurring.autoAdd, isTrue);
    expect(recurring.startMonth, '2026-09');
    expect(recurring.lastHandledMonth, '2026-10');
    expect((await db.watchGoals().first).single.deadline, '2027-02-01');
    expect((await db.watchDeposits().first).single.amountPoisha, 300000);
    expect((await db.watchDhar().first).single.person, 'Rahim');
    expect((await db.watchDharPayments().first).single.amountPoisha, 40000);
    expect((await db.watchEraseSnapshot().first)!.payload, 'existing safety copy');

    final spend = await db.spendFromGoal(goalId: 1, amountPoisha: 50000, categoryId: 1, date: '2026-11-01');
    final linked = await (db.select(db.entries)..where((e) => e.id.equals(spend))).getSingle();
    expect(linked.savingsGoalId, 1);
    await db.deleteGoal(1);
    expect((await (db.select(db.entries)..where((e) => e.id.equals(spend))).getSingle()).savingsGoalId, isNull);
    // The old monthly-income link still prevents duplicate automatic salary.
    await applyAutoIncome(db, DateTime(2026, 11, 1));
    await applyAutoIncome(db, DateTime(2026, 11, 1));
    final all = await db.select(db.entries).get();
    expect(all.where((e) => e.recurringId == 1), hasLength(2));
    expect(computeFunds(entries: all, deposits: const [], asOf: DateTime(2026, 11, 1)).total, 3750000);
  });
}
