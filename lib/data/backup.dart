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

/// A backup file that has been read and checked, ready to be restored.
class BackupContents {
  const BackupContents._(this._data);

  final Map<String, dynamic> _data;

  DateTime? get exportedAt => DateTime.tryParse(_data['exportedAt'] as String? ?? '');

  int get entryCount => (_data['entries'] as List).length;

  /// App settings saved with the data (name, reminder). Empty for a backup without them.
  Map<String, dynamic> get settings => (_data['settings'] as Map?)?.cast<String, dynamic>() ?? const {};

  List<Map<String, dynamic>> _table(String key) =>
      ((_data[key] as List?) ?? const []).cast<Map<String, dynamic>>();
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
  return BackupContents._(decoded);
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
