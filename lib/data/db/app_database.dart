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

@DriftDatabase(tables: [Categories, Entries, DayStatuses])
class AppDatabase extends _$AppDatabase {
  /// Pass an in-memory executor in tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'hisab'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
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

  Future<int> entryCountForCategory(int categoryId) async {
    final count = entries.id.count();
    final row = await (selectOnly(entries)
          ..addColumns([count])
          ..where(entries.categoryId.equals(categoryId)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Deletes a category nobody uses, or hides it when old entries still refer to it.
  Future<void> removeCategory(int id) async {
    if (await entryCountForCategory(id) == 0) {
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
}
