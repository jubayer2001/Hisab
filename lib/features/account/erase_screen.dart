import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/app_card.dart';
import '../../data/backup.dart';
import '../../data/backup_actions.dart';
import '../../data/erase.dart';
import '../../services/cloud_backup.dart';
import '../../services/cloud_sync.dart';
import '../../services/file_service.dart';

/// The word that has to be typed before anything is erased.
const eraseWord = 'ERASE';

/// "Erase all data": what will go, a backup shortcut, what to do about the Google copy, and a
/// typed confirmation. Nothing is erased until every step is done.
class EraseScreen extends ConsumerStatefulWidget {
  const EraseScreen({super.key});

  @override
  ConsumerState<EraseScreen> createState() => _EraseScreenState();
}

class _EraseScreenState extends ConsumerState<EraseScreen> {
  final _confirm = TextEditingController();
  EraseScope _scope = EraseScope.phoneAndGoogle;
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _typed => _confirm.text.trim().toUpperCase() == eraseWord;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveBackupFirst() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final backup = await ref.read(backupActionsProvider).create();
      final saved = await ref.read(fileServiceProvider).saveBytes(
            fileName: backupFileName(DateTime.now()),
            bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup))),
            mimeType: 'application/json',
          );
      if (saved) {
        ref.read(lastBackupProvider.notifier).markNow();
        if (mounted) _say('Backup saved. You can erase now.');
      }
    } catch (_) {
      if (mounted) _say('The backup could not be saved. Nothing was changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _erase() async {
    if (_busy || !_typed) return;
    setState(() => _busy = true);
    try {
      await ref.read(eraseActionsProvider).erase(scope: _scope);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go('/');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Everything was erased. You can undo this for 7 days from Account.'),
            duration: Duration(seconds: 6),
          ),
        );
    } on CloudException catch (e) {
      if (mounted) _say('${e.message} Nothing was erased.');
    } catch (_) {
      if (mounted) _say('Something went wrong. Nothing was erased.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _plural(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final counts = ref.watch(eraseCountsProvider);
    final cloud = ref.watch(cloudSyncProvider);

    final parts = [
      if (counts.entries > 0) _plural(counts.entries, 'entry', 'entries'),
      if (counts.budgets > 0) _plural(counts.budgets, 'budget', 'budgets'),
      if (counts.goals > 0) _plural(counts.goals, 'goal', 'goals'),
      if (counts.dhar > 0) _plural(counts.dhar, 'dhar record', 'dhar records'),
      if (counts.recurring > 0) _plural(counts.recurring, 'monthly item', 'monthly items'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Erase all data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.spending.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.spending),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: parts.isEmpty ? 'There is nothing to erase yet. ' : 'This will erase ${parts.join(', ')} ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: 'from this phone, and your categories go back to the defaults. Your name, profile colour and reminder settings are kept.',
                      ),
                    ]),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
            onPressed: _busy ? null : _saveBackupFirst,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save a backup file first'),
          ),
          if (cloud.signedIn) ...[
            const SectionTitle('Your Google copy'),
            _ScopeOption(
              selected: _scope == EraseScope.phoneAndGoogle,
              title: 'Erase from this phone and Google',
              body: 'Also deletes your backup in Google Drive. You stay signed in and start fresh.',
              onTap: () => setState(() => _scope = EraseScope.phoneAndGoogle),
            ),
            const SizedBox(height: 8),
            _ScopeOption(
              selected: _scope == EraseScope.phoneOnly,
              title: 'This phone only',
              body: 'Your Google copy stays safe. You are signed out so it cannot be overwritten.',
              onTap: () => setState(() => _scope = EraseScope.phoneOnly),
            ),
          ],
          const SectionTitle('Confirm'),
          TextField(
            controller: _confirm,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: fieldDecoration(context, label: 'Type $eraseWord to confirm'),
          ),
          const SizedBox(height: 8),
          Text(
            'For 7 days after erasing, Account offers "Undo erase". After that the saved copy is deleted for good.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: colors.spending, foregroundColor: Colors.white),
            onPressed: _typed && !_busy ? _erase : null,
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(_busy ? 'Working…' : 'Erase everything'),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.selected, required this.title, required this.body, required this.onTap});

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : context.hisab.card,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(body, style: theme.textTheme.bodySmall?.copyWith(color: context.hisab.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
