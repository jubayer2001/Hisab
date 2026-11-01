import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/funds.dart';
import 'package:hisab/data/logic/periods.dart';
import 'package:hisab/data/logic/reports.dart';
import 'package:hisab/data/summary.dart';

void main() {
  late AppDatabase db;
  late int food, salary, eid, emergency;
  final november = DateTime(2026, 11, 1);

  Future<Funds> funds([DateTime? date]) async => computeFunds(
    entries: await db.select(db.entries).get(),
    deposits: await db.select(db.goalDeposits).get(),
    asOf: date ?? november,
  );
  Future<void> seed() async {
    final categories = await db.watchCategories().first;
    food = categories.firstWhere((c) => c.name == 'Food').id;
    salary = categories.firstWhere((c) => c.name == 'Salary').id;
    await db.addEntry(type: EntryType.income, amountPoisha: 3000000, categoryId: salary, date: '2026-10-01');
    await db.addEntry(type: EntryType.expense, amountPoisha: 2200000, categoryId: food, date: '2026-10-31');
    eid = await db.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A);
    emergency = await db.addGoal(name: 'Emergency', targetPoisha: 2000000, colorValue: 0xFF3DB39E);
    await db.allocateGoal(goalId: eid, amountPoisha: 300000, date: '2026-10-31');
    await db.allocateGoal(goalId: emergency, amountPoisha: 200000, date: '2026-10-31');
    await db.addEntry(type: EntryType.income, amountPoisha: 3000000, categoryId: salary, date: '2026-11-01');
    await db.addEntry(type: EntryType.expense, amountPoisha: 500000, categoryId: food, date: '2026-11-01');
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seed();
  });
  tearDown(() => db.close());

  test('October balance carries through empty months and the year boundary without new income', () async {
    final all = await db.watchEntries().first;
    final october = computeSummary(all, DateTime(2026, 10, 31));
    expect(october.balance, 800000);
    final current = computeSummary(all, november);
    expect(current.balance, 3300000);
    expect(current.monthIncome, 3000000);
    expect(current.monthExpense, 500000);
    for (final date in [DateTime(2026, 12, 1), DateTime(2027, 1, 1)]) {
      final next = computeSummary(all, date);
      expect(next.balance, 3300000);
      expect(next.monthIncome, 0);
    }
    expect(await db.select(db.entries).get(), hasLength(4));
  });

  test('historical edits, future entries and negative balances are handled by date', () async {
    final old = (await db.select(db.entries).get()).firstWhere((e) => e.date == '2026-10-31');
    await db.updateEntry(old.copyWith(amountPoisha: 3100000));
    final all = await db.watchEntries().first;
    // October ends ৳1,000 short. It is still shown as a shortfall in October itself...
    expect(computeSummary(all, DateTime(2026, 10, 31)).balance, -100000);
    // ...but only saved money moves on, so November starts from 0, not from -৳1,000.
    expect(computeSummary(all, november).balance, 2500000);
    await db.addEntry(type: EntryType.income, amountPoisha: 9900000, categoryId: salary, date: '2027-01-01');
    expect((await funds()).total, 2500000);
    expect(computeSummary(await db.watchEntries().first, november).balance, 2500000);
  });

  test('year totals aggregate transactions and never add repeated carried balances', () async {
    final report = buildReport(
      all: await db.watchEntries().first,
      deposits: await db.watchDeposits().first,
      period: periodFor(PeriodType.year, november),
      now: november,
    );
    expect(report.income, 6000000);
    expect(report.expense, 2700000);
    expect(report.bars.map((b) => b.amount).reduce((a, b) => a + b), report.expense);
    expect(report.bars[9].amount, 2200000);
    expect(report.bars[10].amount, 500000);
    expect(report.recordedMonths, {10, 11});
    expect(report.funds.total, 3300000);
    expect(report.funds.reserved, 500000);
    final previous = buildReport(
      all: await db.watchEntries().first,
      deposits: await db.watchDeposits().first,
      period: periodFor(PeriodType.month, DateTime(2026, 10, 31)),
      now: november,
    );
    expect(previous.funds.total, 800000);
    expect(previous.funds.available, 300000);
  });

  test('allocating and releasing goals never create income or spending', () async {
    await db.allocateGoal(goalId: eid, amountPoisha: 100000, date: '2026-11-01');
    expect((await funds()).total, 3300000);
    expect((await funds()).available, 2700000);
    await db.allocateGoal(goalId: eid, amountPoisha: -50000, date: '2026-11-01');
    expect((await funds()).reserved, 550000);
    expect((await funds()).available, 2750000);
    expect(await db.select(db.entries).get(), hasLength(4));
  });

  test('unfunded, oversized and concurrent reservations cannot reuse the same money', () async {
    await expectLater(
      db.allocateGoal(goalId: eid, amountPoisha: 2800001, date: '2026-11-01'),
      throwsA(isA<SavingsException>()),
    );
    await expectLater(
      db.allocateGoal(goalId: eid, amountPoisha: -300001, date: '2026-11-01'),
      throwsA(isA<SavingsException>()),
    );
    final outcomes = await Future.wait(
      [eid, emergency].map((goal) async {
        try {
          await db.allocateGoal(goalId: goal, amountPoisha: 2000000, date: '2026-11-01');
          return true;
        } on SavingsException {
          return false;
        }
      }),
    );
    expect(outcomes.where((v) => v), hasLength(1));
    expect((await funds()).available, 800000);
  });

  test('spend/edit/delete/Undo consume goal allocation and cash exactly once', () async {
    final id = await db.spendFromGoal(goalId: eid, amountPoisha: 250000, categoryId: food, date: '2026-11-01');
    expect((await funds()).total, 3050000);
    expect((await funds()).reserved, 250000);
    expect((await funds()).available, 2800000);
    var expense = await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle();
    await expectLater(
      db.updateEntry(expense.copyWith(savingsGoalId: const Value(null))),
      throwsA(isA<SavingsException>()),
    );
    await expectLater(db.updateEntry(expense.copyWith(amountPoisha: 300001)), throwsA(isA<SavingsException>()));
    await db.updateEntry(expense.copyWith(amountPoisha: 200000));
    expense = await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle();
    expect((await funds()).total, 3100000);
    expect((await funds()).reserved, 300000);
    await db.deleteEntries([id]);
    expect((await funds()).total, 3300000);
    expect((await funds()).reserved, 500000);
    await db.restoreEntries([expense]);
    expect((await funds()).total, 3100000);
    expect((await funds()).available, 2800000);
  });

  test('deleting a goal retains real expenses; Undo can retain an expense after its goal is gone', () async {
    final id = await db.spendFromGoal(goalId: eid, amountPoisha: 50000, categoryId: food, date: '2026-11-01');
    final expense = await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle();
    await db.deleteGoal(eid);
    final retained = await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle();
    expect(retained.savingsGoalId, isNull);
    expect((await funds()).total, 3250000);
    expect((await funds()).reserved, 200000);
    await db.deleteEntry(id);
    await db.restoreEntry(expense);
    expect((await funds()).total, 3250000);
    expect((await db.select(db.entries).get()).last.savingsGoalId, isNull);
  });

  test('backups preserve goal-spending links, custom colours, symbols and allocations', () async {
    final custom = await db.addCategory(
      name: 'Donation',
      type: EntryType.expense,
      iconKey: 'donation',
      colorValue: 0xFF1299AA,
    );
    await db.spendFromGoal(goalId: eid, amountPoisha: 50000, categoryId: custom, date: '2026-11-01');
    final backup = await createBackup(db);
    await db.eraseEverything();
    await restoreBackup(db, parseBackup(encodeBackup(backup), currentSchemaVersion: db.schemaVersion));
    expect((await funds()).total, 3250000);
    expect((await funds()).reserved, 450000);
    final linked = (await db.select(db.entries).get()).singleWhere((e) => e.savingsGoalId != null);
    expect(linked.savingsGoalId, eid);
    final category = (await db.watchCategories().first).singleWhere((c) => c.id == custom);
    expect(category.iconKey, 'donation');
    expect(category.colorValue, 0xFF1299AA);
  });

  test('old v1.0 backups without the new column still restore', () async {
    final backup = await createBackup(db);
    backup['schemaVersion'] = 3;
    for (final row in backup['entries'] as List) {
      (row as Map).remove('savingsGoalId');
    }
    await restoreBackup(db, parseBackup(encodeBackup(backup), currentSchemaVersion: db.schemaVersion));
    expect((await funds()).total, 3300000);
    expect((await funds()).reserved, 500000);
  });

  test('an invalid goal reference in a backup rolls back the whole restore', () async {
    final backup = await createBackup(db);
    (backup['entries'] as List).last['savingsGoalId'] = 999999;
    await expectLater(
      restoreBackup(db, parseBackup(encodeBackup(backup), currentSchemaVersion: db.schemaVersion)),
      throwsA(isA<BackupException>()),
    );
    expect((await funds()).total, 3300000);
    expect((await db.select(db.entries).get()).every((e) => e.savingsGoalId == null), isTrue);
  });

  test('income cannot be marked as goal spending in a backup or an edit', () async {
    final backup = await createBackup(db);
    (backup['entries'] as List).first['savingsGoalId'] = eid;
    expect(
      () => parseBackup(encodeBackup(backup), currentSchemaVersion: db.schemaVersion),
      throwsA(isA<BackupException>()),
    );
    final id = await db.spendFromGoal(goalId: eid, amountPoisha: 50000, categoryId: food, date: '2026-11-01');
    final entry = await (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle();
    await expectLater(
      db.updateEntry(entry.copyWith(type: EntryType.income, savingsGoalId: Value(eid))),
      throwsA(isA<SavingsException>()),
    );
  });

  group('only saved money carries forward', () {
    late AppDatabase fresh;
    late int cat, pay;
    setUp(() async {
      fresh = AppDatabase(NativeDatabase.memory());
      final cats = await fresh.watchCategories().first;
      cat = cats.firstWhere((c) => c.name == 'Food').id;
      pay = cats.firstWhere((c) => c.name == 'Salary').id;
    });
    tearDown(() => fresh.close());

    Future<void> spend(String date, int taka) =>
        fresh.addEntry(type: EntryType.expense, amountPoisha: taka * 100, categoryId: cat, date: date);
    Future<void> earn(String date, int taka) =>
        fresh.addEntry(type: EntryType.income, amountPoisha: taka * 100, categoryId: pay, date: date);
    Future<int> balanceOn(DateTime day) async => computeSummary(await fresh.watchEntries().first, day).balance;

    test('no income in October and ৳2,000 spent: November starts from 0, not -৳2,000', () async {
      await spend('2026-10-15', 2000);
      expect(await balanceOn(DateTime(2026, 10, 31)), -200000, reason: 'still a shortfall inside October');
      expect(await balanceOn(DateTime(2026, 11, 1)), 0);
      expect(await balanceOn(DateTime(2026, 11, 20)), 0);
      expect((await fresh.select(fresh.entries).get()), hasLength(1), reason: 'the spending itself stays recorded');
    });

    test('a shortfall in the new month still shows inside that month', () async {
      await spend('2026-10-15', 2000);
      await spend('2026-11-03', 500);
      expect(await balanceOn(DateTime(2026, 11, 3)), -50000);
      expect(await balanceOn(DateTime(2026, 12, 1)), 0, reason: 'and does not move on either');
    });

    test('saved money keeps carrying through months with no entries and across the year end', () async {
      await earn('2026-10-01', 5000);
      await spend('2026-10-20', 1000);
      for (final day in [DateTime(2026, 11, 15), DateTime(2026, 12, 31), DateTime(2027, 1, 1), DateTime(2027, 6, 1)]) {
        expect(await balanceOn(day), 400000, reason: day.toString());
      }
    });

    test('a bad month uses up the savings but never goes below zero', () async {
      await earn('2026-09-01', 3000);
      await spend('2026-10-10', 5000); // 3,000 saved, 5,000 spent: net -2,000
      await earn('2026-11-01', 1000);
      expect(await balanceOn(DateTime(2026, 10, 31)), -200000);
      expect(await balanceOn(DateTime(2026, 11, 2)), 100000, reason: '0 carried + 1,000 earned');
    });

    test('a chain of months: save, overspend, save again', () async {
      await earn('2026-08-01', 1000); // +1,000 -> carry 1,000
      await spend('2026-09-05', 4000); // net -3,000 -> carry 0
      await earn('2026-10-01', 2500);
      await spend('2026-10-09', 500); // +2,000 -> carry 2,000
      await earn('2026-11-01', 100);
      expect(await balanceOn(DateTime(2026, 9, 30)), -300000);
      expect(await balanceOn(DateTime(2026, 10, 31)), 200000);
      expect(await balanceOn(DateTime(2026, 11, 2)), 210000);
    });

    test('later entries are ignored, and an earlier month counts as it was on its last day', () async {
      await earn('2026-10-01', 1000);
      await spend('2026-11-20', 300);
      expect(await balanceOn(DateTime(2026, 11, 10)), 100000, reason: 'the ৳300 is in the future');
      expect(await balanceOn(DateTime(2026, 11, 20)), 70000);
    });

    test('goal reservations are still part of the balance, not extra money', () async {
      await earn('2026-10-01', 5000);
      final goal = await fresh.addGoal(name: 'Eid', targetPoisha: 1000000, colorValue: 0xFFE86A9A);
      await fresh.allocateGoal(goalId: goal, amountPoisha: 100000, date: '2026-10-20');
      final f = computeFunds(
        entries: await fresh.select(fresh.entries).get(),
        deposits: await fresh.select(fresh.goalDeposits).get(),
        asOf: DateTime(2026, 11, 5),
      );
      expect(f.total, 500000);
      expect(f.reserved, 100000);
      expect(f.available, 400000);
    });

    test('Reports: a past shortfall month shows the shortfall, and the next month starts from 0', () async {
      await spend('2026-10-15', 2000);
      final all = await fresh.watchEntries().first;
      final october = buildReport(all: all, deposits: const [], period: periodFor(PeriodType.month, DateTime(2026, 10, 15)), now: DateTime(2026, 11, 10));
      final novemberReport = buildReport(all: all, deposits: const [], period: periodFor(PeriodType.month, DateTime(2026, 11, 10)), now: DateTime(2026, 11, 10));
      expect(october.funds.total, -200000);
      expect(novemberReport.funds.total, 0);
      expect(novemberReport.expense, 0, reason: 'the October spending is not repeated in November');
    });
  });
}

