import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/security_providers.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/db/database_security.dart';
import '../../services/cloud_backup.dart';
import '../../services/cloud_sync.dart';

/// Where the person's money details are, who can see them, and the switches that protect them.
/// Written for someone who just wants to know "is my income safe in here?".
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busy = false;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLock(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(appLockControllerProvider.notifier).setEnabled(on);
      if (!ok && mounted) {
        _say('The app lock was not turned on. Make sure your phone has a screen lock (a PIN, pattern or fingerprint) and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final lockOn = ref.watch(appLockEnabledProvider);
    final delay = ref.watch(lockDelayProvider);
    final secure = ref.watch(secureWindowProvider);
    final encryption = ref.watch(encryptionStateProvider);
    final cloud = ref.watch(cloudSyncProvider);
    final googleReady = ref.watch(cloudBackupServiceProvider).isConfigured;

    Widget fact({required IconData icon, required String title, required String body, Color? tint}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tint ?? theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your income, spending and balance are yours alone. They stay on this phone, nobody at Hisab can see them, and nothing is shared or sold.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Protect this phone'),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: lockOn,
                  onChanged: _busy ? null : _toggleLock,
                  title: const Text('App lock'),
                  subtitle: const Text('Ask for your fingerprint, face, PIN or pattern to open Hisab'),
                ),
                if (lockOn) ...[
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lock again', style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<LockDelay>(
                            showSelectedIcon: false,
                            segments: [for (final d in LockDelay.values) ButtonSegment(value: d, label: Text(d.label, textAlign: TextAlign.center))],
                            selected: {delay},
                            onSelectionChanged: (s) => ref.read(lockDelayProvider.notifier).set(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile(
                  value: secure,
                  onChanged: (v) => ref.read(secureWindowProvider.notifier).set(v),
                  title: const Text('Hide in recent apps and screenshots'),
                  subtitle: const Text('Your numbers stay out of the app switcher, screenshots and screen recordings'),
                ),
              ],
            ),
          ),
          const SectionTitle('Where your data is'),
          AppCard(
            child: Column(
              children: [
                if (encryption == EncryptionState.encrypted)
                  fact(
                    icon: Icons.phone_android_rounded,
                    title: 'On this phone, encrypted',
                    body: 'Everything is stored encrypted. The key is kept in your phone\'s secure storage and cannot be read out of it, so the data file is unreadable if someone copies it.',
                  )
                else
                  fact(
                    icon: Icons.phone_android_rounded,
                    tint: colors.highlight,
                    title: 'On this phone',
                    body: 'This phone could not provide secure storage for a key, so your data is stored without extra encryption. Android still keeps it private to Hisab.',
                  ),
                const Divider(),
                if (!googleReady)
                  fact(
                    icon: Icons.cloud_off_outlined,
                    title: 'Nowhere else',
                    body: 'Nothing is sent anywhere. Hisab works fully offline.',
                  )
                else if (cloud.signedIn)
                  fact(
                    icon: Icons.cloud_done_outlined,
                    title: 'A copy in your Google Drive',
                    body: 'Backed up to a hidden folder of ${cloud.email}\'s Google Drive that only Hisab can open. Hisab cannot see your other files, and nobody at Hisab can see this copy.',
                  )
                else
                  fact(
                    icon: Icons.cloud_off_outlined,
                    title: 'Not backed up to Google',
                    body: 'Nothing leaves this phone. Signing in with Google is optional and adds a private copy in your own Drive.',
                  ),
                const Divider(),
                fact(
                  icon: Icons.save_alt_rounded,
                  title: 'Backup files you save',
                  body: 'A backup file or CSV is readable by anyone who gets it, so keep it somewhere private.',
                ),
              ],
            ),
          ),
          const SectionTitle('What Hisab never does'),
          AppCard(
            child: Column(
              children: [
                fact(icon: Icons.block_rounded, title: 'No ads, no tracking, no analytics', body: 'Nothing about how you use the app is collected.'),
                const Divider(),
                fact(icon: Icons.person_off_outlined, title: 'No account with us', body: 'There is no Hisab server. The developer cannot see your data, your backup or your Google account.'),
                const Divider(),
                fact(icon: Icons.delete_outline_rounded, title: 'You stay in control', body: 'Delete one entry, or erase everything from Account. Uninstalling removes all data from this phone.'),
              ],
            ),
          ),
          const SectionTitle('Permissions, in plain words'),
          AppCard(
            child: Column(
              children: [
                fact(icon: Icons.notifications_outlined, title: 'Notifications and alarms', body: 'For your daily reminder, at the minute you choose, and after the phone restarts.'),
                const Divider(),
                fact(icon: Icons.language_rounded, title: 'Internet', body: 'Only used for the optional Google backup, and only to Google over a secure connection.'),
                const Divider(),
                fact(icon: Icons.fingerprint_rounded, title: 'Fingerprint or screen lock', body: 'Only to check it is you when the app lock is on. Hisab never sees your fingerprint.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'The full privacy policy is in the project on GitHub: github.com/jubayer2001/Hisab, in docs/PRIVACY.md. Found a security problem? Please report it there, see SECURITY.md.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
