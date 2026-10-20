import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// An entry together with its category, which is what every list on screen needs.
class EntryWithCategory {
  const EntryWithCategory(this.entry, this.category);

  final Entry entry;
  final Category category;

  bool get isExpense => entry.type == EntryType.expense;
}

@DriftDatabase(
  tables: [
    Categories,
    Entries,
    DayStatuses,
    Budgets,
    Recurrings,
    SavingsGoals,
    GoalDeposits,
    DharRecords,
    DharPayments,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an in-memory executor in tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'hisab'));

  /// 1: entries, categories, no-spend days (v0.2).
  /// 2: budgets, recurring bills, savings goals, dhar (v0.3 and v0.4).
  ///
  /// Never edit an old step below: phones already hold data written by it.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(budgets);
            await m.createTable(recurrings);
            await m.createTable(savingsGoals);
            await m.createTable(goalDeposits);
            await m.createTable(dharRecords);
            await m.createTable(dharPayments);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedCategories() async {
    await batch((b) {
      var order = 0;
      b.insertAll(categories, [
        for (final c in defaultCategories)
          CategoriesCompanion.insert(
            name: c.name,
            type: c.type,
            iconKey: c.iconKey,
            colorValue: c.color.toARGB32(),
            sortOrder: Value(order++),
          ),
      ]);
    });
  }

  // ---- Entries -------------------------------------------------------------

  /// Every entry, newest day first. Lists, totals and reports are all built from this
  /// one stream, which is plenty fast for a personal tracker.
  Stream<List<EntryWithCategory>> watchEntries() {
    final query = select(entries).join([
      innerJoin(categories, categories.id.equalsExp(entries.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.desc(entries.date),
        OrderingTerm.desc(entries.createdAt),
        OrderingTerm.desc(entries.id),
      ]);
    return query.watch().map(
          (rows) => [
            for (final r in rows) EntryWithCategory(r.readTable(entries), r.readTable(categories)),
          ],
        );
  }

  Future<int> addEntry({
    required String type,
    required int amountPoisha,
    required int categoryId,
    required String date,
    String? paymentMethod,
    String? note,
  }) {
    return into(entries).insert(
      EntriesCompanion.insert(
        type: type,
        amountPoisha: amountPoisha,
        categoryId: categoryId,
        date: date,
        paymentMethod: Value(paymentMethod),
        note: Value(note),
      ),
    );
  }

  Future<void> updateEntry(Entry entry) => update(entries).replace(entry);

  Future<void> deleteEntry(int id) => (delete(entries)..where((e) => e.id.equals(id))).go();

  /// Puts back an entry that was just deleted (used by "Undo"), keeping its id.
  Future<void> restoreEntry(Entry entry) =>
      into(entries).insert(entry, mode: InsertMode.insertOrReplace);

  // ---- Categories ----------------------------------------------------------

  Stream<List<Category>> watchCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.id)]))
        .watch();
  }

  Future<int> addCategory({
    required String name,
    required String type,
    required String iconKey,
    required int colorValue,
  }) async {
    final maxOrder = await (selectOnly(categories)..addColumns([categories.sortOrder.max()]))
        .map((r) => r.read(categories.sortOrder.max()))
        .getSingle();
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        type: type,
        iconKey: iconKey,
        colorValue: colorValue,
        sortOrder: Value((maxOrder ?? 0) + 1),
      ),
    );
  }

  Future<void> updateCategory(Category category) => update(categories).replace(category);

  /// How many entries use this category.
  Future<int> entryCountForCategory(int categoryId) async {
    final count = entries.id.count();
    final row = await (selectOnly(entries)
          ..addColumns([count])
          ..where(entries.categoryId.equals(categoryId)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> _recurringCountForCategory(int categoryId) async {
    final count = recurrings.id.count();
    final row = await (selectOnly(recurrings)
          ..addColumns([count])
          ..where(recurrings.categoryId.equals(categoryId)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Deletes a category nobody uses, or hides it when entries or recurring bills still
  /// refer to it. Its budget is dropped either way.
  Future<void> removeCategory(int id) async {
    final inUse = await entryCountForCategory(id) + await _recurringCountForCategory(id);
    await (delete(budgets)..where((b) => b.categoryId.equals(id))).go();
    if (inUse == 0) {
      await (delete(categories)..where((c) => c.id.equals(id))).go();
    } else {
      await (update(categories)..where((c) => c.id.equals(id))).write(
        const CategoriesCompanion(isArchived: Value(true)),
      );
    }
  }

  // ---- "No spending today" -------------------------------------------------

  Stream<Set<String>> watchNoSpendDays() {
    return (select(dayStatuses)..where((d) => d.noSpend.equals(true)))
        .watch()
        .map((rows) => {for (final r in rows) r.date});
  }

  Future<void> setNoSpend(String date, bool value) {
    if (!value) return (delete(dayStatuses)..where((d) => d.date.equals(date))).go();
    return into(dayStatuses).insertOnConflictUpdate(
      DayStatusesCompanion.insert(date: date, noSpend: const Value(true)),
    );
  }

  // ---- Budgets -------------------------------------------------------------

  Stream<List<Budget>> watchBudgets() => select(budgets).watch();

  /// Sets (or replaces) the budget for a category, or the overall one when [categoryId] is null.
  Future<void> setBudget({required int? categoryId, required int amountPoisha}) async {
    final existing = await (select(budgets)
          ..where((b) => categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId)))
        .getSingleOrNull();
    if (existing == null) {
      await into(budgets).insert(
        BudgetsCompanion.insert(categoryId: Value(categoryId), amountPoisha: amountPoisha),
      );
    } else {
      await update(budgets).replace(existing.copyWith(amountPoisha: amountPoisha));
    }
  }

  Future<void> removeBudget(int id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  // ---- Recurring bills -----------------------------------------------------

  Stream<List<Recurring>> watchRecurrings() {
    return (select(recurrings)..orderBy([(r) => OrderingTerm.asc(r.dayOfMonth), (r) => OrderingTerm.asc(r.id)])).watch();
  }

  Future<int> addRecurring({
    required String title,
    required String type,
    required int amountPoisha,
    required int categoryId,
    required int dayOfMonth,
  }) {
    return into(recurrings).insert(
      RecurringsCompanion.insert(
        title: title,
        type: type,
        amountPoisha: amountPoisha,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
      ),
    );
  }

  Future<void> updateRecurring(Recurring item) => update(recurrings).replace(item);

  Future<void> deleteRecurring(int id) => (delete(recurrings)..where((r) => r.id.equals(id))).go();

  Future<void> markRecurringHandled(int id, String month) {
    return (update(recurrings)..where((r) => r.id.equals(id))).write(
      RecurringsCompanion(lastHandledMonth: Value(month)),
    );
  }

  // ---- Savings goals -------------------------------------------------------

  Stream<List<SavingsGoal>> watchGoals() => (select(savingsGoals)..orderBy([(g) => OrderingTerm.asc(g.id)])).watch();

  Stream<List<GoalDeposit>> watchDeposits() {
    return (select(goalDeposits)
          ..orderBy([(d) => OrderingTerm.desc(d.date), (d) => OrderingTerm.desc(d.id)]))
        .watch();
  }

  Future<int> addGoal({
    required String name,
    required int targetPoisha,
    required int colorValue,
    String? deadline,
  }) {
    return into(savingsGoals).insert(
      SavingsGoalsCompanion.insert(
        name: name,
        targetPoisha: targetPoisha,
        colorValue: colorValue,
        deadline: Value(deadline),
      ),
    );
  }

  Future<void> updateGoal(SavingsGoal goal) => update(savingsGoals).replace(goal);

  Future<void> deleteGoal(int id) {
    return transaction(() async {
      await (delete(goalDeposits)..where((d) => d.goalId.equals(id))).go();
      await (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
    });
  }

  /// A negative [amountPoisha] takes money back out of the goal.
  Future<int> addDeposit({required int goalId, required int amountPoisha, required String date}) {
    return into(goalDeposits).insert(
      GoalDepositsCompanion.insert(goalId: goalId, amountPoisha: amountPoisha, date: date),
    );
  }

  Future<void> deleteDeposit(int id) => (delete(goalDeposits)..where((d) => d.id.equals(id))).go();

  // ---- Dhar (lend and borrow) ----------------------------------------------

  Stream<List<DharRecord>> watchDhar() => (select(dharRecords)..orderBy([(d) => OrderingTerm.desc(d.id)])).watch();

  Stream<List<DharPayment>> watchDharPayments() {
    return (select(dharPayments)..orderBy([(p) => OrderingTerm.desc(p.date), (p) => OrderingTerm.desc(p.id)])).watch();
  }

  Future<int> addDhar({
    required String person,
    required String direction,
    required int amountPoisha,
    required String date,
    String? dueDate,
    String? note,
  }) {
    return into(dharRecords).insert(
      DharRecordsCompanion.insert(
        person: person,
        direction: direction,
        amountPoisha: amountPoisha,
        date: date,
        dueDate: Value(dueDate),
        note: Value(note),
      ),
    );
  }

  Future<void> updateDhar(DharRecord record) => update(dharRecords).replace(record);

  Future<void> deleteDhar(int id) {
    return transaction(() async {
      await (delete(dharPayments)..where((p) => p.dharId.equals(id))).go();
      await (delete(dharRecords)..where((r) => r.id.equals(id))).go();
    });
  }

  Future<void> setDharSettled(int id, bool settled) {
    return (update(dharRecords)..where((r) => r.id.equals(id))).write(
      DharRecordsCompanion(settled: Value(settled)),
    );
  }

  /// Records a part payment. When the payments reach the full amount, the record is
  /// marked settled automatically.
  Future<void> addDharPayment({required int dharId, required int amountPoisha, required String date}) {
    return transaction(() async {
      await into(dharPayments).insert(
        DharPaymentsCompanion.insert(dharId: dharId, amountPoisha: amountPoisha, date: date),
      );
      final record = await (select(dharRecords)..where((r) => r.id.equals(dharId))).getSingle();
      final sum = dharPayments.amountPoisha.sum();
      final paid = await (selectOnly(dharPayments)
            ..addColumns([sum])
            ..where(dharPayments.dharId.equals(dharId)))
          .map((r) => r.read(sum) ?? 0)
          .getSingle();
      if (paid >= record.amountPoisha) await setDharSettled(dharId, true);
    });
  }

  Future<void> deleteDharPayment(int id) => (delete(dharPayments)..where((p) => p.id.equals(id))).go();
}
