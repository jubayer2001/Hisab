import 'package:drift/drift.dart';

/// Values stored in the `type` columns.
abstract final class EntryType {
  static const expense = 'expense';
  static const income = 'income';
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// [EntryType.expense] or [EntryType.income].
  TextColumn get type => text()();
  TextColumn get iconKey => text()();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Hidden from the pickers but kept so old entries still show their category.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();

  /// Whole poisha (1 Taka = 100 poisha), never a floating point number.
  IntColumn get amountPoisha => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();

  /// "yyyy-MM-dd", see dates.dart.
  TextColumn get date => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Schema version 3: the monthly income ([Recurrings.autoAdd]) that added this entry by
  /// itself, or null for anything the person typed in.
  IntColumn get recurringId => integer().nullable()();

  /// Schema 4: a real expense paid from a goal's reserved money. Keeping the
  /// link on the expense makes edit/delete/Undo update the reservation once.
  IntColumn get savingsGoalId => integer().nullable().references(SavingsGoals, #id, onDelete: KeyAction.setNull)();
}

/// A day the user confirmed they spent nothing. Keeps the logging streak alive.
class DayStatuses extends Table {
  TextColumn get date => text()();
  BoolColumn get noSpend => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

// ---- Added in schema version 2 (v0.3 and v0.4) ------------------------------

/// A monthly spending limit. [categoryId] null means the overall monthly budget.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get amountPoisha => integer()();
}

/// A bill or income that repeats every month (rent, Wi-Fi, salary).
class Recurrings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 40)();
  TextColumn get type => text()();
  IntColumn get amountPoisha => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();

  /// 1 to 31. In shorter months the last day of the month is used.
  IntColumn get dayOfMonth => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// "yyyy-MM" of the month the user last confirmed or skipped this item.
  TextColumn get lastHandledMonth => text().nullable()();

  /// Schema version 3. Monthly income that records itself on its day, instead of waiting
  /// to be confirmed. Bills always keep asking first.
  BoolColumn get autoAdd => boolean().withDefault(const Constant(false))();

  /// Schema version 3, "yyyy-MM": the first month an automatic item may be added for, so a
  /// new salary is never filled in backwards into months before it was set up.
  TextColumn get startMonth => text().nullable()();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get targetPoisha => integer()();

  /// "yyyy-MM-dd", optional.
  TextColumn get deadline => text().nullable()();
  IntColumn get colorValue => integer()();
}

/// Money moved into a goal (positive) or taken back out (negative). Saved money is
/// tracked here and never counted as spending.
class GoalDeposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  IntColumn get amountPoisha => integer()();
  TextColumn get date => text()();
}

/// Money lent to someone ("lent") or borrowed from someone ("borrowed"). Dhar is never
/// counted as spending or income.
class DharRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get person => text().withLength(min: 1, max: 40)();
  TextColumn get direction => text()();
  IntColumn get amountPoisha => integer()();
  TextColumn get date => text()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get settled => boolean().withDefault(const Constant(false))();
}

/// A part payment on a dhar record (money given back or received back).
class DharPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dharId => integer().references(DharRecords, #id)();
  IntColumn get amountPoisha => integer()();
  TextColumn get date => text()();
}

abstract final class DharDirection {
  static const lent = 'lent';
  static const borrowed = 'borrowed';
}

// ---- Added in schema version 3 ------------------------------------------------

/// A safety copy of everything, made just before "Erase all data" and kept for a week so
/// the erase can be undone. It lives in the database itself, so it is protected exactly like
/// the rest of the data, and it is never included in backups.
class EraseSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The same JSON a backup file holds.
  TextColumn get payload => text()();
}
