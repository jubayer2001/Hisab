import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/database_security.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const _key = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _otherKey = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hisab-sec-');
    path = p.join(dir.path, 'hisab.sqlite');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A real Hisab database file, without encryption, holding some entries (one in Bangla).
  Future<void> makePlainDatabase() async {
    final db = AppDatabase(NativeDatabase(File(path)));
    final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
    await db.addEntry(type: EntryType.expense, amountPoisha: 18000, categoryId: food.id, date: '2026-10-19', note: 'দুপুরের খাবার');
    await db.addEntry(type: EntryType.expense, amountPoisha: 25050, categoryId: food.id, date: '2026-10-20', note: 'Secret salary note');
    await db.setBudget(categoryId: null, amountPoisha: 2500000);
    await db.close();
  }

  Future<List<String?>> notesWithKey(String? key) async {
    final db = AppDatabase(NativeDatabase(File(path), setup: (raw) => applyDatabaseKey(raw, key)));
    try {
      return (await db.watchEntries().first).map((e) => e.entry.note).toList();
    } finally {
      await db.close();
    }
  }

  bool fileLooksPlain() => String.fromCharCodes(File(path).readAsBytesSync().take(16).toList()).startsWith('SQLite format 3');

  bool fileContains(String text) {
    final bytes = File(path).readAsBytesSync();
    final needle = Uint8List.fromList(text.codeUnits);
    outer:
    for (var i = 0; i <= bytes.length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  group('encrypting an existing database', () {
    test('a plain database is encrypted in place and everything is still there', () async {
      await makePlainDatabase();
      expect(fileLooksPlain(), isTrue);
      expect(fileContains('Secret salary note'), isTrue, reason: 'before: readable by anyone with the file');

      expect(prepareDatabase(path, _key), EncryptionState.encrypted);

      expect(fileLooksPlain(), isFalse);
      expect(fileContains('Secret salary note'), isFalse, reason: 'after: not readable from the file');
      expect(fileContains('SQLite format'), isFalse);
      expect(await notesWithKey(_key), containsAll(['দুপুরের খাবার', 'Secret salary note']));
    });

    test('the safety copy of the old file is gone afterwards', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);
      expect(File('$path.premigrate').existsSync(), isFalse);
      expect(dir.listSync().map((e) => p.basename(e.path)).toList()..sort(), ['hisab.sqlite']);
    });

    test('doing it again changes nothing', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);
      final once = File(path).readAsBytesSync();
      expect(prepareDatabase(path, _key), EncryptionState.encrypted);
      expect(File(path).readAsBytesSync(), once);
      expect(await notesWithKey(_key), hasLength(2));
    });

    test('without the key, or with a wrong one, the data cannot be read', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);

      await expectLater(notesWithKey(null), throwsA(anything));
      await expectLater(notesWithKey(_otherKey), throwsA(anything));
      expect(await notesWithKey(_key), hasLength(2), reason: 'and the right key still works');
    });

    test('the data survives being written to after encryption', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);

      final db = AppDatabase(NativeDatabase(File(path), setup: (raw) => applyDatabaseKey(raw, _key)));
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await db.addEntry(type: EntryType.income, amountPoisha: 4500000, categoryId: food.id, date: '2026-11-01', note: 'Brand new row');
      await db.close();

      expect(await notesWithKey(_key), contains('Brand new row'));
      expect(fileContains('Brand new row'), isFalse);
    });
  });

  group('new installs', () {
    test('a missing file counts as encrypted-to-be, and what gets written is encrypted', () async {
      expect(prepareDatabase(path, _key), EncryptionState.encrypted);

      final db = AppDatabase(NativeDatabase(File(path), setup: (raw) => applyDatabaseKey(raw, _key)));
      final food = (await db.watchCategories().first).firstWhere((c) => c.name == 'Food');
      await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-20', note: 'Fresh install note');
      await db.close();

      expect(fileLooksPlain(), isFalse);
      expect(fileContains('Fresh install note'), isFalse);
      expect(await notesWithKey(_key), ['Fresh install note']);
    });

    test('an empty file is treated as new', () async {
      File(path).writeAsBytesSync(const []);
      expect(prepareDatabase(path, _key), EncryptionState.encrypted);
    });
  });

  group('when the phone cannot provide a key', () {
    test('a plain database is left exactly as it is, and the app says encryption is unavailable', () async {
      await makePlainDatabase();
      final before = File(path).readAsBytesSync();

      expect(prepareDatabase(path, null), EncryptionState.unavailable);

      expect(File(path).readAsBytesSync(), before);
      expect(await notesWithKey(null), hasLength(2));
    });

    test('an already encrypted database cannot be opened, and the app says so rather than guessing', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);
      expect(() => prepareDatabase(path, null), throwsA(isA<DatabaseLockedException>()));
    });

    test('a wrong key for an encrypted database is reported as locked, and the file is untouched', () async {
      await makePlainDatabase();
      prepareDatabase(path, _key);
      final before = File(path).readAsBytesSync();
      expect(() => prepareDatabase(path, _otherKey), throwsA(isA<DatabaseLockedException>()));
      expect(File(path).readAsBytesSync(), before);
    });
  });

  group('safety', () {
    test('a key that is not 64 hex characters is refused, so it can never be used to inject SQL', () async {
      await makePlainDatabase();
      expect(() => prepareDatabase(path, "'; DROP TABLE entries; --"), throwsArgumentError);
      expect(() => prepareDatabase(path, 'abc'), throwsArgumentError);
      expect(() => prepareDatabase(path, _key.toUpperCase()), throwsArgumentError);
      expect(await notesWithKey(null), hasLength(2), reason: 'nothing was changed');
    });

    test('if encrypting fails, the original file is put back exactly and nothing is left behind', () {
      // Starts like a SQLite file but is not one, so reading it fails half way.
      final bogus = Uint8List.fromList([...'SQLite format 3\u0000'.codeUnits, ...List<int>.filled(4096, 7)]);
      File(path).writeAsBytesSync(bogus);

      expect(() => prepareDatabase(path, _key), throwsA(anything));

      expect(File(path).readAsBytesSync(), bogus);
      expect(dir.listSync().map((e) => p.basename(e.path)).toList(), ['hisab.sqlite']);
    });

    test('a crash during an earlier encryption: an unusable main file is replaced by the safety copy', () async {
      await makePlainDatabase();
      File(path).copySync('$path.premigrate');
      File(path).writeAsBytesSync(Uint8List.fromList(List<int>.generate(8192, (i) => (i * 31) % 251))); // garbage

      expect(prepareDatabase(path, _key), EncryptionState.encrypted);
      expect(File('$path.premigrate').existsSync(), isFalse);
      expect(await notesWithKey(_key), containsAll(['দুপুরের খাবার', 'Secret salary note']));
    });

    test('a leftover safety copy next to a healthy database is simply removed', () async {
      await makePlainDatabase();
      File(path).copySync('$path.premigrate');
      prepareDatabase(path, _key);
      expect(File('$path.premigrate').existsSync(), isFalse);
      expect(await notesWithKey(_key), hasLength(2));
    });

    test('deleting the database removes the file and every side file', () async {
      await makePlainDatabase();
      for (final s in const ['-wal', '-shm', '-journal', '.premigrate']) {
        File('$path$s').writeAsStringSync('x');
      }
      deleteDatabaseFiles(path);
      expect(dir.listSync(), isEmpty);
    });
  });

  test('the encrypted build of SQLite is the one in use', () {
    // sqlite3mc answers this; plain SQLite does not know the pragma and returns nothing.
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    final result = db.select('PRAGMA cipher');
    expect(result, isNotEmpty, reason: 'built with SQLite3 Multiple Ciphers (see hooks in pubspec.yaml)');
  });
}
