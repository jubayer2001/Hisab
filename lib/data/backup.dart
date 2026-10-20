import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DataClass;

import 'db/app_database.dart';

/// A problem with a backup file, worded for the person who picked it.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String _formatName = 'hisab-backup';

/// Bump when the layout of the file changes in a way an older app could not read.
const int backupFormatVersion = 1;

/// A backup bigger than this is refused before it is even read (a real one is a few hundred KB).
const int maxBackupBytes = 25 * 1024 * 1024;

/// More rows than this in one table cannot be a real personal tracker.
const int maxBackupRows = 500000;

/// A backup file that has been read and checked, ready to be restored.
class BackupContents {
  const BackupContents._(this._data);

  final Map<String, dynamic> _data;

  DateTime? get exportedAt => DateTime.tryParse(_data['exportedAt'] as String? ?? '');

  int get entryCount => (_data['entries'] as List).length;

  /// App settings saved with the data (name, reminder). Empty for a backup without them.
  Map<String, dynamic> get settings => (_data['settings'] as Map?)?.cast<String, dynamic>() ?? const {};

  /// The rows of one table. Backups made by an older version lack columns added later, so
  /// those are filled with the value they had before the column existed.
  List<Map<String, dynamic>> _table(String key) {
    final rows = [for (final r in (_data[key] as List?) ?? const []) Map<String, dynamic>.from(r as Map)];
    if (key != 'recurrings') return rows;
    return [
      for (final r in rows) {'autoAdd': false, ...r},
    ];
  }
}

/// Everything in the database, plus [settings], as a map ready to be saved as JSON.
Future<Map<String, dynamic>> createBackup(AppDatabase db, {Map<String, Object?> settings = const {}}) async {
  Future<List<Map<String, dynamic>>> rows<T extends DataClass>(Future<List<T>> query) async =>
      [for (final r in await query) r.toJson()];

  return {
    'format': _formatName,
    'formatVersion': backupFormatVersion,
    'schemaVersion': db.schemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'settings': settings,
    'categories': await rows(db.select(db.categories).get()),
    'entries': await rows(db.select(db.entries).get()),
    'dayStatuses': await rows(db.select(db.dayStatuses).get()),
    'budgets': await rows(db.select(db.budgets).get()),
    'recurrings': await rows(db.select(db.recurrings).get()),
    'savingsGoals': await rows(db.select(db.savingsGoals).get()),
    'goalDeposits': await rows(db.select(db.goalDeposits).get()),
    'dharRecords': await rows(db.select(db.dharRecords).get()),
    'dharPayments': await rows(db.select(db.dharPayments).get()),
  };
}

Uint8List encodeBackup(Map<String, dynamic> backup) => Uint8List.fromList(utf8.encode(jsonEncode(backup)));

/// "hisab-backup-2026-10-20.json"
String backupFileName(DateTime now) {
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'hisab-backup-${now.year}-$m-$d.json';
}

/// Reads and checks a backup file. Throws [BackupException] if it is not a usable Hisab
/// backup, or was made by a newer version of the app than this one.
BackupContents parseBackup(Uint8List bytes, {required int currentSchemaVersion}) {
  if (bytes.length > maxBackupBytes) {
    throw const BackupException('That file is too large to be a Hisab backup.');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const BackupException('That file is not a Hisab backup.');
  }

  if (decoded is! Map<String, dynamic> || decoded['format'] != _formatName) {
    throw const BackupException('That file is not a Hisab backup.');
  }
  final formatVersion = decoded['formatVersion'];
  final schemaVersion = decoded['schemaVersion'];
  if (formatVersion is! int || schemaVersion is! int) {
    throw const BackupException('That backup file is damaged.');
  }
  if (formatVersion > backupFormatVersion || schemaVersion > currentSchemaVersion) {
    throw const BackupException('That backup was made by a newer version of Hisab. Update the app first.');
  }
  for (final required in ['categories', 'entries']) {
    if (decoded[required] is! List) throw const BackupException('That backup file is damaged.');
  }
  _validateRows(decoded);
  return BackupContents._(decoded);
}

// ---- Checking every row ------------------------------------------------------------------
//
// A backup file is untrusted input: it can come from anywhere, and can be damaged or made up on
// purpose. Before anything is restored, every value is checked to be the right kind and a sensible
// size. A single bad value refuses the whole file, and the phone's data is left exactly as it is.

typedef _Rule = bool Function(Object? value);

final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _monthPattern = RegExp(r'^(\d{4})-(\d{2})$');

bool _isInt(Object? v) => v is int;
bool _isBool(Object? v) => v is bool;
_Rule _intIn(int low, int high) => (v) => v is int && v >= low && v <= high;
_Rule _text(int max, {bool allowEmpty = true}) =>
    (v) => v is String && v.length <= max && (allowEmpty || v.isNotEmpty);
_Rule _oneOf(Set<String> values) => (v) => v is String && values.contains(v);
_Rule _optional(_Rule rule) => (v) => v == null || rule(v);

bool _isDay(Object? v) {
  if (v is! String) return false;
  final m = _datePattern.firstMatch(v);
  if (m == null) return false;
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  return month >= 1 && month <= 12 && day >= 1 && day <= 31;
}

bool _isMonth(Object? v) {
  if (v is! String) return false;
  final m = _monthPattern.firstMatch(v);
  if (m == null) return false;
  final month = int.parse(m.group(2)!);
  return month >= 1 && month <= 12;
}

/// Money: whole poisha, never negative, and below ten billion Taka.
final _money = _intIn(0, 1000000000000000);

/// A money change that may take money out (a goal withdrawal).
final _signedMoney = _intIn(-1000000000000000, 1000000000000000);

final _types = {'expense', 'income'};

/// What each table's columns must look like. Columns not listed here are ignored, and columns
/// that older versions did not have may be missing (they are filled in on restore).
final Map<String, Map<String, _Rule>> _tableRules = {
  'categories': {
    'id': _isInt,
    'name': _text(40, allowEmpty: false),
    'type': _oneOf(_types),
    'iconKey': _text(40),
    'colorValue': _isInt,
    'sortOrder': _isInt,
    'isArchived': _isBool,
  },
  'entries': {
    'id': _isInt,
    'type': _oneOf(_types),
    'amountPoisha': _money,
    'categoryId': _isInt,
    'paymentMethod': _optional(_text(60)),
    'note': _optional(_text(2000)),
    'date': _isDay,
    'createdAt': _isInt,
    'recurringId': _optional(_isInt),
  },
  'dayStatuses': {'date': _isDay, 'noSpend': _isBool},
  'budgets': {'id': _isInt, 'categoryId': _optional(_isInt), 'amountPoisha': _money},
  'recurrings': {
    'id': _isInt,
    'title': _text(40, allowEmpty: false),
    'type': _oneOf(_types),
    'amountPoisha': _money,
    'categoryId': _isInt,
    'dayOfMonth': _intIn(1, 31),
    'isActive': _isBool,
    'lastHandledMonth': _optional(_isMonth),
    'autoAdd': _optional(_isBool),
    'startMonth': _optional(_isMonth),
  },
  'savingsGoals': {
    'id': _isInt,
    'name': _text(40, allowEmpty: false),
    'targetPoisha': _money,
    'deadline': _optional(_isDay),
    'colorValue': _isInt,
  },
  'goalDeposits': {'id': _isInt, 'goalId': _isInt, 'amountPoisha': _signedMoney, 'date': _isDay},
  'dharRecords': {
    'id': _isInt,
    'person': _text(40, allowEmpty: false),
    'direction': _oneOf({'lent', 'borrowed'}),
    'amountPoisha': _money,
    'date': _isDay,
    'dueDate': _optional(_isDay),
    'note': _optional(_text(2000)),
    'settled': _isBool,
  },
  'dharPayments': {'id': _isInt, 'dharId': _isInt, 'amountPoisha': _money, 'date': _isDay},
};

void _validateRows(Map<String, dynamic> data) {
  const damaged = BackupException('That backup file is damaged.');
  for (final entry in _tableRules.entries) {
    final rows = data[entry.key];
    if (rows == null) continue; // an older backup may not have this table
    if (rows is! List || rows.length > maxBackupRows) throw damaged;
    for (final row in rows) {
      if (row is! Map) throw damaged;
      for (final column in entry.value.entries) {
        if (!column.value(row[column.key])) throw damaged;
      }
    }
  }
  // The settings travel with the data but are only ever read as a few known keys of known types.
  final settings = data['settings'];
  if (settings != null && settings is! Map) throw damaged;
}


/// Replaces everything in the database with the contents of [backup].
///
/// All or nothing: if anything goes wrong the database is left exactly as it was.
Future<void> restoreBackup(AppDatabase db, BackupContents backup) async {
  try {
    await db.transaction(() async {
      // Children before parents, so no row ever points at something already deleted.
      await db.delete(db.dharPayments).go();
      await db.delete(db.dharRecords).go();
      await db.delete(db.goalDeposits).go();
      await db.delete(db.savingsGoals).go();
      await db.delete(db.budgets).go();
      await db.delete(db.recurrings).go();
      await db.delete(db.entries).go();
      await db.delete(db.dayStatuses).go();
      await db.delete(db.categories).go();

      // Parents before children.
      await db.batch((b) {
        b.insertAll(db.categories, [for (final j in backup._table('categories')) Category.fromJson(j)]);
        b.insertAll(db.entries, [for (final j in backup._table('entries')) Entry.fromJson(j)]);
        b.insertAll(db.dayStatuses, [for (final j in backup._table('dayStatuses')) DayStatuse.fromJson(j)]);
        b.insertAll(db.budgets, [for (final j in backup._table('budgets')) Budget.fromJson(j)]);
        b.insertAll(db.recurrings, [for (final j in backup._table('recurrings')) Recurring.fromJson(j)]);
        b.insertAll(db.savingsGoals, [for (final j in backup._table('savingsGoals')) SavingsGoal.fromJson(j)]);
        b.insertAll(db.goalDeposits, [for (final j in backup._table('goalDeposits')) GoalDeposit.fromJson(j)]);
        b.insertAll(db.dharRecords, [for (final j in backup._table('dharRecords')) DharRecord.fromJson(j)]);
        b.insertAll(db.dharPayments, [for (final j in backup._table('dharPayments')) DharPayment.fromJson(j)]);
      });
    });
  } on BackupException {
    rethrow;
  } catch (_) {
    throw const BackupException('That backup could not be restored. Your current data was not changed.');
  }
}
