import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_backup.dart';
import '../services/cloud_sync.dart';
import 'backup.dart';
import 'backup_actions.dart';
import 'db/app_database.dart';
import 'providers.dart';

/// How long an erase can be undone.
const eraseUndoWindow = Duration(days: 7);

/// What to do about the copy in the person's Google account when erasing.
enum EraseScope {
  /// Erase the phone and also delete the Google Drive copy. They stay signed in and start fresh.
  phoneAndGoogle,

  /// Erase only the phone. The Google copy stays, and they are signed out so it cannot be overwritten.
  phoneOnly,
}

/// How much there is to erase, for the confirmation screen.
class EraseCounts {
  const EraseCounts({
    required this.entries,
    required this.budgets,
    required this.goals,
    required this.dhar,
    required this.recurring,
  });

  final int entries;
  final int budgets;
  final int goals;
  final int dhar;
  final int recurring;

  bool get isEmpty => entries + budgets + goals + dhar + recurring == 0;
}

/// The safety copy made by the last erase, while it can still be used.
final eraseSnapshotProvider = StreamProvider<EraseSnapshot?>((ref) {
  return ref.watch(databaseProvider).watchEraseSnapshot().map((s) {
    if (s == null) return null;
    return DateTime.now().difference(s.createdAt) > eraseUndoWindow ? null : s;
  });
});

final eraseCountsProvider = Provider<EraseCounts>((ref) {
  return EraseCounts(
    entries: ref.watch(allEntriesProvider).value?.length ?? 0,
    budgets: ref.watch(budgetsProvider).value?.length ?? 0,
    goals: ref.watch(goalsProvider).value?.length ?? 0,
    dhar: ref.watch(dharRecordsProvider).value?.length ?? 0,
    recurring: ref.watch(recurringsProvider).value?.length ?? 0,
  );
});

/// "Erase all data" and its undo.
class EraseActions {
  const EraseActions(this._ref);

  final Ref _ref;

  /// Erases everything the person entered. A safety copy is kept for a week first.
  ///
  /// If the Google copy is to be deleted too and that fails (no internet, for example), nothing
  /// at all is erased and the error is thrown, so the person can try again.
  Future<void> erase({required EraseScope scope}) async {
    final db = _ref.read(databaseProvider);
    final cloud = _ref.read(cloudSyncProvider);

    if (cloud.signedIn) {
      if (scope == EraseScope.phoneAndGoogle) {
        await _ref.read(cloudBackupServiceProvider).deleteBackup();
      } else {
        // Signed out first, so the emptied phone can never overwrite the Google copy.
        await _ref.read(cloudSyncProvider.notifier).signOut();
      }
    }

    final backup = await _ref.read(backupActionsProvider).create();
    await db.saveEraseSnapshot(utf8.decode(encodeBackup(backup)));
    await db.eraseEverything();
  }

  /// Brings back everything from the last erase, replacing anything added since.
  /// Returns false if there is no safety copy (or it has expired).
  Future<bool> undo() async {
    final db = _ref.read(databaseProvider);
    final snapshot = await db.watchEraseSnapshot().first;
    if (snapshot == null || DateTime.now().difference(snapshot.createdAt) > eraseUndoWindow) return false;

    final contents = parseBackup(Uint8List.fromList(utf8.encode(snapshot.payload)), currentSchemaVersion: db.schemaVersion);
    await _ref.read(backupActionsProvider).restore(contents);
    await db.deleteEraseSnapshots();
    _ref.read(cloudSyncProvider.notifier).markChanged();
    return true;
  }

  /// Removes safety copies older than a week. Run when the app starts.
  Future<void> purgeExpired() => _ref.read(databaseProvider).purgeOldEraseSnapshots(eraseUndoWindow);
}

final eraseActionsProvider = Provider<EraseActions>((ref) => EraseActions(ref));
