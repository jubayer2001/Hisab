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
}

/// A day the user confirmed they spent nothing. Keeps the logging streak alive.
class DayStatuses extends Table {
  TextColumn get date => text()();
  BoolColumn get noSpend => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}
