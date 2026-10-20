import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../services/notifications.dart';
import '../../services/reminder_providers.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from Android's settings: check the permissions again.
    _lifecycle = AppLifecycleListener(onResume: _refreshPermissions);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshPermissions() {
    ref.invalidate(notificationsAllowedProvider);
    ref.invalidate(exactAlarmsAllowedProvider);
    // Re-run the scheduler: the permission may have just been granted.
    ref.invalidate(reminderSyncProvider);
  }

  Future<void> _toggleReminder(bool on) async {
    final service = ref.read(notificationServiceProvider);
    ref.read(reminderSettingsProvider.notifier).setEnabled(on);
    if (on && !await service.notificationsAllowed()) {
      await service.requestPermission();
    }
    _refreshPermissions();
  }

  Future<void> _pickTime() async {
    final settings = ref.read(reminderSettingsProvider);
    final picked = await showTimePicker(context: context, initialTime: settings.time);
    if (picked != null) ref.read(reminderSettingsProvider.notifier).setTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final mode = ref.watch(themeModeProvider);
    final info = ref.watch(_packageInfoProvider).value;
    final reminder = ref.watch(reminderSettingsProvider);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final exactAllowed = ref.watch(exactAlarmsAllowedProvider).value ?? true;

    Widget section(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: theme.textTheme.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          section('Daily reminder'),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: reminder.enabled,
                  onChanged: _toggleReminder,
                  title: const Text('Remind me every evening'),
                  subtitle: const Text('Asks if you logged today\'s expenses'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  enabled: reminder.enabled,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Reminder time'),
                  trailing: Text(
                    formatReminderTime(context, reminder.minutes),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  onTap: _pickTime,
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Send a test reminder'),
                  subtitle: const Text('Check that notifications reach you'),
                  onTap: () => ref.read(notificationServiceProvider).showTest(),
                ),
              ],
            ),
          ),
          if (reminder.enabled && !allowed) ...[
            const SizedBox(height: 12),
            _Warning(
              text: 'Notifications are turned off for Hisab, so the reminder cannot appear.',
              action: 'Open settings',
              onPressed: AppSettings.openAppSettings,
            ),
          ],
          if (reminder.enabled && allowed && !exactAllowed) ...[
            const SizedBox(height: 12),
            _Warning(
              text: 'Allow "Alarms & reminders" so the reminder arrives at the exact minute.',
              action: 'Allow',
              onPressed: () async {
                await ref.read(notificationServiceProvider).requestExactAlarms();
                _refreshPermissions();
              },
            ),
          ],
          const SizedBox(height: 12),
          const _ReminderGuide(),
          section('Your data'),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              subtitle: const Text('Add, edit or hide expense and income categories'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/categories'),
            ),
          ),
          section('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
          section('About'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('Hisab'),
            subtitle: Text(info == null ? 'Expense tracker' : 'Version ${info.version} (${info.buildNumber})'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.code),
            title: Text('Source and downloads'),
            subtitle: Text('github.com/jubayer2001/Hisab'),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text, required this.action, required this.onPressed});

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.highlight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.highlight),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}

/// Steps that fix late or missing reminders on phones that stop background apps.
class _ReminderGuide extends StatelessWidget {
  const _ReminderGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    const steps = [
      'Open the Hisab app settings (button below).',
      'Turn on Autostart.',
      'Set Battery saver to No restrictions.',
      'Under Notifications, allow notifications and keep Daily reminder on.',
      'In the Recent apps screen, pull Hisab down or tap its lock icon so cleaners do not close it.',
    ];

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.help_outline_rounded),
          title: const Text('Reminder not arriving?'),
          subtitle: const Text('Xiaomi, Redmi, POCO, Oppo, Vivo, Realme'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'These phones stop background apps to save battery, which can delay or block the reminder. Do this once:',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 22, child: Text('${i + 1}.', style: theme.textTheme.bodyMedium)),
                    Expanded(child: Text(steps[i], style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: AppSettings.openAppSettings,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open Hisab app settings'),
            ),
          ],
        ),
      ),
    );
  }
}
