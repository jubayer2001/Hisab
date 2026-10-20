import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings_providers.dart';
import 'backup.dart';
import 'providers.dart';

/// Making a backup of, and restoring from a backup into, the app as a whole: the database
/// plus the few settings that travel with it (name and reminder).
///
/// Shared by the backup file buttons and the Google account backup.
class BackupActions {
  const BackupActions(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>> create() {
    final reminder = _ref.read(reminderSettingsProvider);
    return createBackup(_ref.read(databaseProvider), settings: {
      'userName': _ref.read(userNameProvider),
      'reminderEnabled': reminder.enabled,
      'reminderMinutes': reminder.minutes,
    });
  }

  Future<int> entryCount() async {
    final db = _ref.read(databaseProvider);
    return (await db.select(db.entries).get()).length;
  }

  /// Replaces everything on this phone with [backup], then brings back its settings.
  Future<void> restore(BackupContents backup) async {
    await restoreBackup(_ref.read(databaseProvider), backup);

    final s = backup.settings;
    if (s['userName'] is String) _ref.read(userNameProvider.notifier).set(s['userName'] as String);
    if (s['reminderEnabled'] is bool) {
      _ref.read(reminderSettingsProvider.notifier).setEnabled(s['reminderEnabled'] as bool);
    }
    if (s['reminderMinutes'] is int) {
      final m = s['reminderMinutes'] as int;
      _ref.read(reminderSettingsProvider.notifier).setTime(TimeOfDay(hour: m ~/ 60, minute: m % 60));
    }
  }
}

final backupActionsProvider = Provider<BackupActions>((ref) => BackupActions(ref));
