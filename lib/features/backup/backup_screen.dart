import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../data/backup.dart';
import '../../data/csv.dart';
import '../../data/providers.dart';
import '../../core/widgets/app_card.dart';
import '../../services/file_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs [action] with the buttons disabled, turning any failure into a message.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupException catch (e) {
      if (mounted) _say(e.message);
    } catch (_) {
      if (mounted) _say('Something went wrong. Nothing was changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveBackup() => _run(() async {
        final db = ref.read(databaseProvider);
        final reminder = ref.read(reminderSettingsProvider);
        final backup = await createBackup(db, settings: {
          'userName': ref.read(userNameProvider),
          'reminderEnabled': reminder.enabled,
          'reminderMinutes': reminder.minutes,
        });
        final saved = await ref.read(fileServiceProvider).saveBytes(
              fileName: backupFileName(DateTime.now()),
              bytes: encodeBackup(backup),
              mimeType: 'application/json',
            );
        if (!saved) return;
        ref.read(lastBackupProvider.notifier).markNow();
        if (mounted) _say('Backup saved. Keep it somewhere safe, like Google Drive.');
      });

  Future<void> _exportCsv() => _run(() async {
        final entries = await ref.read(databaseProvider).watchEntries().first;
        final bytes = Uint8List.fromList(utf8.encode(buildCsv(entries)));
        final saved = await ref.read(fileServiceProvider).saveBytes(
              fileName: 'hisab-entries-${dayKey(DateTime.now())}.csv',
              bytes: bytes,
              mimeType: 'text/csv',
            );
        if (saved && mounted) _say('Saved ${entries.length} entries as a spreadsheet file.');
      });

  Future<void> _restore() => _run(() async {
        final db = ref.read(databaseProvider);
        final bytes = await ref.read(fileServiceProvider).pickFileBytes();
        if (bytes == null) return;

        final backup = parseBackup(bytes, currentSchemaVersion: db.schemaVersion);
        final current = (await db.select(db.entries).get()).length;
        if (!mounted) return;
        final confirmed = await _confirmReplace(backup, current);
        if (!confirmed) return;

        await restoreBackup(db, backup);

        // Bring back the name and reminder that were saved with the data.
        final s = backup.settings;
        if (s['userName'] is String) ref.read(userNameProvider.notifier).set(s['userName'] as String);
        if (s['reminderEnabled'] is bool) {
          ref.read(reminderSettingsProvider.notifier).setEnabled(s['reminderEnabled'] as bool);
        }
        if (s['reminderMinutes'] is int) {
          final m = s['reminderMinutes'] as int;
          ref.read(reminderSettingsProvider.notifier).setTime(TimeOfDay(hour: m ~/ 60, minute: m % 60));
        }
        if (mounted) _say('Restored ${backup.entryCount} entries.');
      });

  Future<bool> _confirmReplace(BackupContents backup, int currentEntries) async {
    final when = backup.exportedAt;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace your data?'),
        content: Text(
          'This backup${when == null ? '' : ' from ${DateFormat('d MMM y').format(when)}'} has '
          '${backup.entryCount} entries. This phone has $currentEntries.\n\n'
          'Restoring replaces everything on this phone with the backup. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.hisab.spending, minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final last = ref.watch(lastBackupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup and restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Your data lives only on this phone. A backup file lets you move to a new phone, or get everything back after a reset.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          const SectionTitle('Save a backup'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  last == null ? 'No backup yet' : 'Last backup: ${DateFormat('d MMM y, h:mm a').format(last)}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Saves your entries, budgets, goals, dhar and settings in one file. Keep a copy in Google Drive or send it to yourself.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _saveBackup,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Save backup file'),
                ),
              ],
            ),
          ),
          const SectionTitle('Restore'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a backup file made by Hisab. Everything currently on this phone is replaced, and you are asked first.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restore from a backup file'),
                ),
              ],
            ),
          ),
          const SectionTitle('Spreadsheet'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Every expense and income as a CSV file you can open in Excel or Google Sheets. This is for reading only. It cannot be restored into Hisab.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
                  onPressed: _busy ? null : _exportCsv,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Export to CSV'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
