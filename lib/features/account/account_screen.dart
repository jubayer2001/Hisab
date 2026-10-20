import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/profile_providers.dart';
import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/google_button.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/sheet.dart';
import '../../data/backup.dart';
import '../../data/backup_actions.dart';
import '../../data/csv.dart';
import '../../data/erase.dart';
import '../../data/providers.dart';
import '../../services/cloud_backup.dart';
import '../../services/cloud_sync.dart';
import '../../services/file_service.dart';
import '../backup/google_connect.dart';

/// Who you are, and where your data is: the profile, the Google backup, the personal details
/// and the backup files, all in one place.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
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
    } on CloudException catch (e) {
      if (mounted) _say(e.message);
    } catch (_) {
      if (mounted) _say('Something went wrong. Nothing was changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- backup files -------------------------------------------------------------------

  Future<void> _saveBackup() => _run(() async {
        final backup = await ref.read(backupActionsProvider).create();
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

  Future<void> _restoreFromFile() => _run(() async {
        final db = ref.read(databaseProvider);
        final bytes = await ref.read(fileServiceProvider).pickFileBytes();
        if (bytes == null) return;

        final backup = parseBackup(bytes, currentSchemaVersion: db.schemaVersion);
        final current = await ref.read(backupActionsProvider).entryCount();
        if (!mounted) return;
        final confirmed = await _confirmReplace(backup, current);
        if (!confirmed) return;

        await ref.read(backupActionsProvider).restore(backup);
        if (mounted) _say('Restored ${backup.entryCount} entries.');
      });

  // ---- Google -------------------------------------------------------------------------

  Future<void> _signIn() => _run(() async {
        final sync = ref.read(cloudSyncProvider.notifier);
        if (ref.read(cloudSyncProvider).status == CloudStatus.needsSignIn) {
          await sync.signInAgain();
          if (mounted) _say('Signed in again.');
        } else {
          await connectGoogle(context, ref);
        }
      });

  Future<void> _backUpNow() => _run(() async {
        await ref.read(cloudSyncProvider.notifier).backupNow();
        if (mounted) _say('Backed up to your Google account.');
      });

  Future<void> _restoreFromGoogle() => _run(() async {
        final sync = ref.read(cloudSyncProvider.notifier);
        final found = await sync.fetchCloud();
        if (found == null) {
          if (mounted) _say('There is no backup in your Google account yet.');
          return;
        }
        final current = await ref.read(backupActionsProvider).entryCount();
        if (!mounted) return;
        final confirmed = await _confirmReplace(found.backup, current, from: 'Google account');
        if (!confirmed) return;
        await sync.restoreFromCloud(found.backup);
        if (mounted) _say('Restored ${found.backup.entryCount} entries.');
      });

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of Google?'),
        content: const Text(
          'Hisab stops backing up. Your data stays on this phone, and the copy already in your Google account is kept.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(cloudSyncProvider.notifier).signOut();
  }

  Future<bool> _confirmReplace(BackupContents backup, int currentEntries, {String from = 'backup'}) async {
    final when = backup.exportedAt;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace your data?'),
        content: Text(
          'This $from${when == null ? '' : ' from ${DateFormat('d MMM y').format(when)}'} has '
          '${backup.entryCount} entries. This phone has $currentEntries.\n\n'
          'Restoring replaces everything on this phone with it. This cannot be undone.',
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

  Future<void> _undoErase() => _run(() async {
        final ok = await confirmDestructive(
          context,
          title: 'Undo the erase?',
          message: 'Everything you had before erasing comes back. Anything you added since is replaced.',
          confirmLabel: 'Bring it back',
        );
        if (!ok) return;
        final restored = await ref.read(eraseActionsProvider).undo();
        if (mounted) _say(restored ? 'Everything is back.' : 'That saved copy is no longer available.');
      });

  Future<void> _editProfile() => showAppSheet<void>(context, builder: (_) => const AboutYouSheet());

  // ---- screen -------------------------------------------------------------------------

  String _when(DateTime d) {
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? 'today at ${DateFormat('h:mm a').format(d)}' : DateFormat('d MMM y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final name = ref.watch(userNameProvider);
    final cloud = ref.watch(cloudSyncProvider);
    final googleReady = ref.watch(cloudBackupServiceProvider).isConfigured;
    final lastFile = ref.watch(lastBackupProvider);
    final profileIndex = ref.watch(profileColorProvider);
    final overall = ref.watch(budgetsProvider).value?.where((b) => b.categoryId == null).firstOrNull;
    final incomeTotal = ref.watch(monthlyIncomeTotalProvider);
    final erased = ref.watch(eraseSnapshotProvider).value;

    final (statusText, statusIcon, statusGood) = switch (cloud.status) {
      _ when !cloud.signedIn => ('Not signed in', Icons.cloud_off_rounded, false),
      CloudStatus.working => ('Backing up…', Icons.cloud_sync_rounded, true),
      CloudStatus.waiting => ('Waiting for internet', Icons.cloud_off_rounded, false),
      CloudStatus.needsSignIn => ('Sign in again', Icons.cloud_off_rounded, false),
      CloudStatus.failed => ('Backup problem', Icons.cloud_off_rounded, false),
      CloudStatus.idle when cloud.lastBackup != null => ('Backed up ${_when(cloud.lastBackup!)}', Icons.cloud_done_rounded, true),
      CloudStatus.idle => ('Not backed up yet', Icons.cloud_queue_rounded, false),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ProfileAvatar(size: 76, onTap: _editProfile),
                const SizedBox(height: 10),
                Text(name.isEmpty ? 'Add your name' : name, style: theme.textTheme.titleLarge),
                if (cloud.signedIn) ...[
                  const SizedBox(height: 2),
                  Text(cloud.email!, style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                ],
                if (googleReady) ...[
                  const SizedBox(height: 8),
                  _StatusChip(text: statusText, icon: statusIcon, good: statusGood),
                  if (cloud.signedIn && cloud.message != null && cloud.status != CloudStatus.idle)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        cloud.message!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (erased != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: colors.income.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history_rounded, color: colors.income),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You erased your data on ${DateFormat('d MMM').format(erased.createdAt)}',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Changed your mind? You can undo it until ${DateFormat('d MMM').format(erased.createdAt.add(eraseUndoWindow))}. After that the saved copy is deleted for good.',
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(onPressed: _busy ? null : _undoErase, child: const Text('Undo erase')),
                  ),
                ],
              ),
            ),
          ],
          if (googleReady && !cloud.signedIn) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.highlight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.highlight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'Right now your data exists only on this phone. ',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: 'If you delete the app or lose the phone, it cannot be recovered.'),
                      ]),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GoogleSignInButton(onPressed: _busy ? null : _signIn),
          ],
          if (googleReady && cloud.signedIn) ...[
            const SectionTitle('Google backup'),
            _CardList(children: [
              SwitchListTile(
                value: cloud.auto,
                onChanged: _busy ? null : ref.read(cloudSyncProvider.notifier).setAuto,
                title: const Text('Back up automatically'),
                subtitle: const Text('After changes, whenever you are online'),
              ),
              if (cloud.status == CloudStatus.needsSignIn)
                _Row(icon: Icons.login_rounded, title: 'Sign in again', onTap: _busy ? null : _signIn)
              else
                _Row(icon: Icons.cloud_upload_outlined, title: 'Back up now', onTap: _busy ? null : _backUpNow),
              _Row(icon: Icons.cloud_download_outlined, title: 'Restore from Google', onTap: _busy ? null : _restoreFromGoogle),
            ]),
          ],
          const SectionTitle('About you'),
          _CardList(children: [
            _Row(
              icon: Icons.person_outline_rounded,
              title: 'Name',
              value: name.isEmpty ? 'Not set' : name,
              onTap: _editProfile,
            ),
            _Row(
              icon: Icons.speed_rounded,
              title: 'Monthly budget',
              value: overall == null ? 'Not set' : formatTaka(overall.amountPoisha),
              onTap: _editProfile,
            ),
            _Row(
              icon: Icons.payments_outlined,
              title: 'Monthly income',
              value: incomeTotal == 0 ? 'Not set' : formatTaka(incomeTotal),
              onTap: () => context.push('/recurring'),
            ),
            _Row(
              icon: Icons.palette_outlined,
              title: 'Profile colour',
              trailing: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: profileIndex == 0 ? theme.colorScheme.primary : profileColors[profileIndex],
                  shape: BoxShape.circle,
                ),
              ),
              onTap: _editProfile,
            ),
          ]),
          const SectionTitle('Your data'),
          _CardList(children: [
            _Row(
              icon: Icons.save_alt_rounded,
              title: 'Save a backup file',
              subtitle: lastFile == null ? 'No backup yet' : 'Last saved ${DateFormat('d MMM y').format(lastFile)}',
              onTap: _busy ? null : _saveBackup,
            ),
            _Row(icon: Icons.restore_rounded, title: 'Restore from a file', onTap: _busy ? null : _restoreFromFile),
            _Row(icon: Icons.table_chart_outlined, title: 'Export to CSV', onTap: _busy ? null : _exportCsv),
          ]),
          if (googleReady && cloud.signedIn) ...[
            const SizedBox(height: 16),
            Center(child: TextButton(onPressed: _busy ? null : _signOut, child: const Text('Sign out'))),
            Text(
              'Signing out keeps your data on this phone and your copy in Google Drive.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
          const SizedBox(height: 40),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _busy ? null : () => context.push('/erase'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.spending.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: colors.spending),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Erase all data', style: theme.textTheme.titleMedium?.copyWith(color: colors.spending)),
                          Text(
                            'Delete every expense, income and record and start fresh',
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.icon, required this.good});

  final String text;
  final IconData icon;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final colors = context.hisab;
    final tint = good ? colors.income : colors.highlight;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.hisab.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 56, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.value, this.trailing, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (value != null
              ? Text(value!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary))
              : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );
  }
}

/// One short sheet for everything personal: name, monthly budget and profile colour.
class AboutYouSheet extends ConsumerStatefulWidget {
  const AboutYouSheet({super.key});

  @override
  ConsumerState<AboutYouSheet> createState() => _AboutYouSheetState();
}

class _AboutYouSheetState extends ConsumerState<AboutYouSheet> {
  late final TextEditingController _name;
  late final TextEditingController _budget;
  late int _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(userNameProvider));
    final overall = ref.read(budgetsProvider).value?.where((b) => b.categoryId == null).firstOrNull;
    _budget = TextEditingController(text: overall == null ? '' : amountToText(overall.amountPoisha));
    _color = ref.read(profileColorProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    ref.read(userNameProvider.notifier).set(_name.text);
    ref.read(profileColorProvider.notifier).set(_color);

    final amount = readAmount(_budget);
    final existing = (await db.watchBudgets().first).where((b) => b.categoryId == null).firstOrNull;
    if (amount != null) {
      await db.setBudget(categoryId: null, amountPoisha: amount);
    } else if (existing != null && _budget.text.trim().isEmpty) {
      await db.removeBudget(existing.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SheetScaffold(
      footer: FilledButton(onPressed: _save, child: const Text('Save')),
      children: [
        const SheetHeader('About you'),
        TextField(
          controller: _name,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: fieldDecoration(context, label: 'Name (leave empty to hide it)'),
        ),
        const SizedBox(height: 12),
        AmountField(controller: _budget, label: 'Monthly budget (optional)'),
        const SizedBox(height: 16),
        Text('Profile colour', style: theme.textTheme.bodyMedium?.copyWith(color: context.hisab.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (var i = 0; i < profileColors.length; i++)
              Semantics(
                button: true,
                selected: i == _color,
                label: 'Profile colour ${i + 1}',
                child: GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: i == 0 ? scheme.primary : profileColors[i],
                      shape: BoxShape.circle,
                      border: i == _color ? Border.all(color: scheme.onSurface, width: 2.5) : null,
                    ),
                    child: i == _color ? Icon(Icons.check_rounded, size: 20, color: i == 0 ? scheme.onPrimary : Colors.white) : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
