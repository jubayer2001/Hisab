import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import 'database_security.dart';

import 'default_categories.dart';
import 'tables.dart';
import '../../core/dates.dart';
import '../logic/funds.dart';

part 'app_database.g.dart';

/// An entry together with its category, which is what every list on screen needs.
class EntryWithCategory {
  const EntryWithCategory(this.entry, this.category);

  final Entry entry;
  final Category category;

  bool get isExpense => entry.type == EntryType.expense;
}

class SavingsException implements Exception {
  const SavingsException(this.message);
  final String message;
  @override
  String toString() => message;
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
    EraseSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an in-memory executor in tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'hisab'));

  /// The real database: a file in the app's private storage, encrypted with [keyHex] (64 hex
  /// characters). A null key opens it unencrypted, for a phone that cannot provide one.
  /// Call `prepareDatabase` on [path] first, so an old unencrypted file is converted.
  AppDatabase.onDisk({required String path, String? keyHex})
    : super(
        driftDatabase(
          name: 'hisab',
          native: DriftNativeOptions(databasePath: () async => path, setup: _withKey(keyHex)),
        ),
      );

  /// A top-level-style closure that only captures the key (a string), so it can be handed to
  /// the background isolate the database runs in.
  static void Function(CommonDatabase) _withKey(String? keyHex) =>
      (db) => applyDatabaseKey(db, keyHex);

  /// 1: entries, categories, no-spend days (v0.2).
  /// 2: budgets, recurring bills, savings goals, dhar (v0.3 and v0.4).
  /// 3: monthly income that adds itself, and the erase-all safety copy (v1.0).
  /// 4: expenses paid from a savings goal (v1.1).
  ///
  /// Never edit an old step below: phones already hold data written by it.
  @override
  int get schemaVersion => 4;

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
      if (from < 3) {
        await m.addColumn(entries, entries.recurringId);
        // A database coming from version 1 just had `recurrings` created above, already
        // with these columns. Only version 2 phones have the old table to extend.
        if (from >= 2) {
          await m.addColumn(recurrings, recurrings.autoAdd);
          await m.addColumn(recurrings, recurrings.startMonth);
        }
        await m.createTable(eraseSnapshots);
      }
      if (from < 4) {
        await m.addColumn(entries, entries.savingsGoalId);
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
    final query = select(entries).join([innerJoin(categories, categories.id.equalsExp(entries.categoryId))])
      ..orderBy([OrderingTerm.desc(entries.date), OrderingTerm.desc(entries.createdAt), OrderingTerm.desc(entries.id)]);
    return query.watch().map(
      (rows) => [for (final r in rows) EntryWithCategory(r.readTable(entries), r.readTable(categories))],
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

  Future<void> updateEntry(Entry entry) => transaction(() async {
    final previous = await (select(entries)..where((e) => e.id.equals(entry.id))).getSingle();
    // A goal expense keeps its reservation link through ordinary History edits.
    if (previous.savingsGoalId != entry.savingsGoalId) {
      throw const SavingsException('The savings goal cannot be changed here.');
    }
    if (entry.savingsGoalId != null) {
      if (entry.type != EntryType.expense) throw const SavingsException('Goal spending must remain an expense.');
      if (entry.amountPoisha != previous.amountPoisha || entry.date != previous.date) {
        await _checkGoalSpend(entry.savingsGoalId!, entry.amountPoisha, entry.date, excludingEntry: entry.id);
      }
    }
    await update(entries).replace(entry);
  });

  Future<void> deleteEntry(int id) => (delete(entries)..where((e) => e.id.equals(id))).go();

  /// Deletes several entries at once (all or nothing).
  Future<void> deleteEntries(Iterable<int> ids) {
    final list = ids.toList();
    if (list.isEmpty) return Future.value();
    return (delete(entries)..where((e) => e.id.isIn(list))).go();
  }

  /// Puts back an entry that was just deleted (used by "Undo"), keeping its id.
  Future<void> restoreEntry(Entry entry) async {
    final restored = await _restorableEntry(entry);
    await into(entries).insert(restored, mode: InsertMode.insertOrReplace);
  }

  Future<Entry> _restorableEntry(Entry entry) async {
    if (entry.savingsGoalId == null) return entry;
    final goal = await (select(savingsGoals)..where((g) => g.id.equals(entry.savingsGoalId!))).getSingleOrNull();
    return goal == null ? entry.copyWith(savingsGoalId: const Value(null)) : entry;
  }

  /// Puts back several deleted entries (all or nothing).
  Future<void> restoreEntries(Iterable<Entry> items) {
    return transaction(() async {
      for (final e in items) {
        await restoreEntry(e);
      }
    });
  }

  // ---- Categories ----------------------------------------------------------

  Stream<List<Category>> watchCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.id)])).watch();
  }

  Future<int> addCategory({
    required String name,
    required String type,
    required String iconKey,
    required int colorValue,
  }) async {
    final maxOrder = await (selectOnly(
      categories,
    )..addColumns([categories.sortOrder.max()])).map((r) => r.read(categories.sortOrder.max())).getSingle();
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
    final row =
        await (selectOnly(entries)
              ..addColumns([count])
              ..where(entries.categoryId.equals(categoryId)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> _recurringCountForCategory(int categoryId) async {
    final count = recurrings.id.count();
    final row =
        await (selectOnly(recurrings)
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
      await (update(
        categories,
      )..where((c) => c.id.equals(id))).write(const CategoriesCompanion(isArchived: Value(true)));
    }
  }

  // ---- "No spending today" -------------------------------------------------

  Stream<Set<String>> watchNoSpendDays() {
    return (select(
      dayStatuses,
    )..where((d) => d.noSpend.equals(true))).watch().map((rows) => {for (final r in rows) r.date});
  }

  Future<void> setNoSpend(String date, bool value) {
    if (!value) return (delete(dayStatuses)..where((d) => d.date.equals(date))).go();
    return into(dayStatuses)
        .insertOnConflictUpdate(DayStatusesCompanion.insert(date: date, noSpend: const Value(true)));
  }

  // ---- Budgets -------------------------------------------------------------

  Stream<List<Budget>> watchBudgets() => select(budgets).watch();

  /// Sets (or replaces) the budget for a category, or the overall one when [categoryId] is null.
  Future<void> setBudget({required int? categoryId, required int amountPoisha}) async {
    final existing = await (select(
      budgets,
    )..where((b) => categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId))).getSingleOrNull();
    if (existing == null) {
      await into(budgets).insert(BudgetsCompanion.insert(categoryId: Value(categoryId), amountPoisha: amountPoisha));
    } else {
      await update(budgets).replace(existing.copyWith(amountPoisha: amountPoisha));
    }
  }

  Future<void> removeBudget(int id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  // ---- Recurring bills -----------------------------------------------------

  Stream<List<Recurring>> watchRecurrings() {
    return (select(
      recurrings,
    )..orderBy([(r) => OrderingTerm.asc(r.dayOfMonth), (r) => OrderingTerm.asc(r.id)])).watch();
  }

  Future<int> addRecurring({
    required String title,
    required String type,
    required int amountPoisha,
    required int categoryId,
    required int dayOfMonth,
    bool autoAdd = false,
    String? startMonth,
  }) {
    return into(recurrings).insert(
      RecurringsCompanion.insert(
        title: title,
        type: type,
        amountPoisha: amountPoisha,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        autoAdd: Value(autoAdd),
        startMonth: Value(startMonth),
      ),
    );
  }

  Future<void> updateRecurring(Recurring item) => update(recurrings).replace(item);

  Future<void> deleteRecurring(int id) => (delete(recurrings)..where((r) => r.id.equals(id))).go();

  /// Puts back a recurring item that was just deleted (used by "Undo"), keeping its id.
  Future<void> restoreRecurring(Recurring item) => into(recurrings).insert(item, mode: InsertMode.insertOrReplace);

  Future<void> markRecurringHandled(int id, String month) {
    return (update(
      recurrings,
    )..where((r) => r.id.equals(id))).write(RecurringsCompanion(lastHandledMonth: Value(month)));
  }

  // ---- Savings goals -------------------------------------------------------

  Stream<List<SavingsGoal>> watchGoals() => (select(savingsGoals)..orderBy([(g) => OrderingTerm.asc(g.id)])).watch();

  Stream<List<GoalDeposit>> watchDeposits() {
    return (select(goalDeposits)..orderBy([(d) => OrderingTerm.desc(d.date), (d) => OrderingTerm.desc(d.id)])).watch();
  }

  Future<int> addGoal({required String name, required int targetPoisha, required int colorValue, String? deadline}) {
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
    return into(goalDeposits)
        .insert(GoalDepositsCompanion.insert(goalId: goalId, amountPoisha: amountPoisha, date: date));
  }

  Future<void> deleteDeposit(int id) => (delete(goalDeposits)..where((d) => d.id.equals(id))).go();

  /// Read from the database at the moment of an action, even when a tab's
  /// Riverpod providers are paused. The transaction also prevents double taps
  /// or concurrent allocations from reserving the same money twice.
  Future<int> allocateGoal({required int goalId, required int amountPoisha, required String date}) =>
      transaction(() async {
        if (amountPoisha == 0) throw const SavingsException('Enter an amount greater than zero.');
        final goal = await (select(savingsGoals)..where((g) => g.id.equals(goalId))).getSingleOrNull();
        if (goal == null) throw const SavingsException('This goal no longer exists.');
        final all = await select(entries).get();
        final deposits = await select(goalDeposits).get();
        final asOf = parseDayKey(date);
        if (amountPoisha > 0) {
          final funds = computeFunds(entries: all, deposits: deposits, asOf: asOf);
          if (amountPoisha > funds.available) throw const SavingsException('Not enough available balance.');
        } else if (-amountPoisha > reservedForGoal(goalId: goalId, entries: all, deposits: deposits, asOf: asOf)) {
          throw const SavingsException('This is more than the goal’s saved amount.');
        }
        return addDeposit(goalId: goalId, amountPoisha: amountPoisha, date: date);
      });

  Future<void> _checkGoalSpend(int goalId, int amount, String date, {int? excludingEntry}) async {
    if (amount <= 0) throw const SavingsException('Enter an amount greater than zero.');
    final all = (await select(entries).get()).where((e) => e.id != excludingEntry).toList();
    final deposits = await select(goalDeposits).get();
    final asOf = parseDayKey(date);
    if (amount > reservedForGoal(goalId: goalId, entries: all, deposits: deposits, asOf: asOf)) {
      throw const SavingsException('This is more than the goal’s saved amount.');
    }
    if (amount > computeFunds(entries: all, deposits: deposits, asOf: asOf).total) {
      throw const SavingsException('Your balance no longer covers this amount.');
    }
  }

  Future<int> spendFromGoal({
    required int goalId,
    required int amountPoisha,
    required int categoryId,
    required String date,
  }) => transaction(() async {
    final goal = await (select(savingsGoals)..where((g) => g.id.equals(goalId))).getSingleOrNull();
    if (goal == null) throw const SavingsException('This goal no longer exists.');
    final category = await (select(categories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (category == null || category.type != EntryType.expense || category.isArchived) {
      throw const SavingsException('Choose an expense category.');
    }
    await _checkGoalSpend(goalId, amountPoisha, date);
    return into(entries).insert(
      EntriesCompanion.insert(
        type: EntryType.expense,
        amountPoisha: amountPoisha,
        categoryId: categoryId,
        date: date,
        note: Value(goal.name),
        savingsGoalId: Value(goalId),
      ),
    );
  });

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
    return (update(dharRecords)..where((r) => r.id.equals(id))).write(DharRecordsCompanion(settled: Value(settled)));
  }

  /// Records a part payment. When the payments reach the full amount, the record is
  /// marked settled automatically.
  Future<void> addDharPayment({required int dharId, required int amountPoisha, required String date}) {
    return transaction(() async {
      await into(dharPayments)
          .insert(DharPaymentsCompanion.insert(dharId: dharId, amountPoisha: amountPoisha, date: date));
      final record = await (select(dharRecords)..where((r) => r.id.equals(dharId))).getSingle();
      final sum = dharPayments.amountPoisha.sum();
      final paid =
          await (selectOnly(dharPayments)
                ..addColumns([sum])
                ..where(dharPayments.dharId.equals(dharId)))
              .map((r) => r.read(sum) ?? 0)
              .getSingle();
      if (paid >= record.amountPoisha) await setDharSettled(dharId, true);
    });
  }

  Future<void> deleteDharPayment(int id) => (delete(dharPayments)..where((p) => p.id.equals(id))).go();

  // ---- Erase all data ------------------------------------------------------

  /// Deletes everything the person entered and puts the default categories back. The safety
  /// copies in [eraseSnapshots] are kept. Settings are not stored here, so they are not touched.
  Future<void> eraseEverything() {
    return transaction(() async {
      // Children before parents, so nothing ever points at a row that is already gone.
      await delete(dharPayments).go();
      await delete(dharRecords).go();
      await delete(goalDeposits).go();
      await delete(savingsGoals).go();
      await delete(budgets).go();
      await delete(recurrings).go();
      await delete(entries).go();
      await delete(dayStatuses).go();
      await delete(categories).go();
      await _seedCategories();
    });
  }

  Stream<EraseSnapshot?> watchEraseSnapshot() {
    return (select(eraseSnapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.id)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Keeps [payload] as the one safety copy, replacing any earlier one.
  Future<void> saveEraseSnapshot(String payload) {
    return transaction(() async {
      await delete(eraseSnapshots).go();
      await into(eraseSnapshots).insert(EraseSnapshotsCompanion.insert(payload: payload));
    });
  }

  Future<void> deleteEraseSnapshots() => delete(eraseSnapshots).go();

  /// Removes safety copies older than [keepFor]. Returns how many were removed.
  Future<int> purgeOldEraseSnapshots(Duration keepFor, {DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(keepFor);
    return (delete(eraseSnapshots)..where((s) => s.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
