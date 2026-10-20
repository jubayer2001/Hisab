import 'dart:io';

import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/sqlite3.dart';

/// Whether the data on disk is encrypted.
enum EncryptionState {
  /// The database file is encrypted with the phone's key.
  encrypted,

  /// The phone could not provide a key, so the data is stored as it was before (it is still
  /// protected by Android's private app storage, just not encrypted on top).
  unavailable,
}

/// The database file is encrypted but the key does not open it, or there is no key at all.
/// This should never happen on a healthy phone (for example it can follow a lock-screen reset
/// that cleared the Keystore). The person is offered a clean start, or a restore from a backup.
class DatabaseLockedException implements Exception {
  const DatabaseLockedException(this.message);

  final String message;

  @override
  String toString() => message;
}

final _hexKey = RegExp(r'^[0-9a-f]{64}$');

String _checkedKey(String keyHex) {
  if (!_hexKey.hasMatch(keyHex)) throw ArgumentError('The database key must be 64 lowercase hex characters.');
  return keyHex;
}

/// Gives a newly opened connection its key. Used as drift's `setup`, so it runs for every
/// connection before anything else touches the database. A null key means "no encryption".
void applyDatabaseKey(CommonDatabase db, String? keyHex) {
  if (keyHex == null) return;
  db.execute("PRAGMA hexkey = '${_checkedKey(keyHex)}'");
}

bool _readable(CommonDatabase db) {
  try {
    db.select('SELECT count(*) FROM sqlite_master');
    return true;
  } on SqliteException {
    return false;
  }
}

/// The first 16 bytes of a plain SQLite file say "SQLite format 3". An encrypted one is noise.
bool _looksPlain(File file) {
  final raf = file.openSync();
  try {
    final head = raf.readSync(16);
    return String.fromCharCodes(head).startsWith('SQLite format 3');
  } finally {
    raf.closeSync();
  }
}

/// Row counts of every table, to prove nothing changed while encrypting.
Map<String, int> _tableCounts(CommonDatabase db) {
  final tables = db
      .select("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
      .map((r) => r['name'] as String)
      .toList();
  return {for (final t in tables) t: db.select('SELECT count(*) AS n FROM "${t.replaceAll('"', '""')}"').first['n'] as int};
}

/// Overwrites a file with zeros and deletes it, so a safety copy of the old unencrypted data
/// does not linger.
void _shred(File file) {
  if (!file.existsSync()) return;
  try {
    final length = file.lengthSync();
    final raf = file.openSync(mode: FileMode.write);
    try {
      const chunk = 64 * 1024;
      final zeros = List<int>.filled(chunk, 0);
      var left = length;
      while (left > 0) {
        final n = left < chunk ? left : chunk;
        raf.writeFromSync(zeros, 0, n);
        left -= n;
      }
      raf.flushSync();
    } finally {
      raf.closeSync();
    }
  } finally {
    file.deleteSync();
  }
}

/// Makes the database file at [path] ready to open: encrypts it in place if it is still plain,
/// and checks that the key opens it if it is already encrypted.
///
/// Encrypting keeps a safety copy of the old file until the new one has been opened again and
/// every table has the same number of rows. If anything goes wrong the old file is put back.
///
/// With a null [keyHex] (the phone could not provide a key) a plain database is left as it is,
/// and an encrypted one throws [DatabaseLockedException].
EncryptionState prepareDatabase(String path, String? keyHex) {
  final file = File(path);
  final safety = File('$path.premigrate');

  // A crash in the middle of an earlier encryption: if the main file is unusable, go back to the copy.
  if (safety.existsSync()) {
    var mainIsFine = file.existsSync() && file.lengthSync() > 0;
    if (mainIsFine) {
      final probe = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        if (!_readable(probe)) {
          if (keyHex != null) probe.execute("PRAGMA hexkey = '${_checkedKey(keyHex)}'");
          mainIsFine = _readable(probe);
        }
      } finally {
        probe.close();
      }
    }
    if (mainIsFine) {
      _shred(safety);
    } else {
      safety.copySync(path);
      _shred(safety);
    }
  }

  if (!file.existsSync() || file.lengthSync() == 0) {
    // New install: drift creates the file and applyDatabaseKey encrypts it from the first byte.
    return keyHex == null ? EncryptionState.unavailable : EncryptionState.encrypted;
  }

  final plain = _looksPlain(file);
  if (!plain) {
    if (keyHex == null) throw const DatabaseLockedException('The data is encrypted and the key is missing.');
    final probe = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      applyDatabaseKey(probe, keyHex);
      if (!_readable(probe)) throw const DatabaseLockedException('The key does not open the data.');
    } finally {
      probe.close();
    }
    return EncryptionState.encrypted;
  }

  if (keyHex == null) return EncryptionState.unavailable;
  _encryptInPlace(path, _checkedKey(keyHex));
  return EncryptionState.encrypted;
}

void _encryptInPlace(String path, String keyHex) {
  final file = File(path);
  final safety = File('$path.premigrate');
  file.copySync(safety.path);

  try {
    late final Map<String, int> before;
    final db = sqlite3.open(path);
    try {
      // Fold any pending writes into the main file, so the copy above and the rekey see everything.
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      before = _tableCounts(db);
      db.execute("PRAGMA hexrekey = '$keyHex'");
    } finally {
      db.close();
    }

    if (_looksPlain(file)) throw StateError('The file is still plain after encrypting.');

    final check = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      applyDatabaseKey(check, keyHex);
      final after = _tableCounts(check);
      if (after.length != before.length || before.entries.any((e) => after[e.key] != e.value)) {
        throw StateError('The encrypted copy does not match the original.');
      }
    } finally {
      check.close();
    }
  } catch (_) {
    // Put the original back, exactly as it was, and tell the caller.
    safety.copySync(path);
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final extra = File('$path$suffix');
      if (extra.existsSync()) extra.deleteSync();
    }
    _shred(safety);
    rethrow;
  }
  _shred(safety);
}

/// Deletes the database and its side files. Used when the data cannot be opened and the person
/// chooses to start fresh.
void deleteDatabaseFiles(String path) {
  for (final suffix in const ['', '-wal', '-shm', '-journal', '.premigrate']) {
    final f = File('$path$suffix');
    if (f.existsSync()) _shred(f);
  }
}
