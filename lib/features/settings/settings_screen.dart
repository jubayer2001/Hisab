import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/profile_providers.dart';
import '../../app/settings_providers.dart';
import '../../app/version.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/widgets/level_bar.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/sheet.dart';
import '../../data/logic/home_logic.dart';
import '../../l10n/l10n.dart';
import '../../data/providers.dart';
import '../../services/cloud_sync.dart';
import '../../services/notifications.dart';
import '../../services/reminder_providers.dart';
import '../../l10n/text.dart';

/// The "More" tab: the money tools with a live number on each, then reminders, appearance
/// and help. The profile is the small icon in the corner and opens Account.
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
    // Re-run the schedulers: the permission may have just been granted.
    ref.invalidate(reminderSyncProvider);
    ref.invalidate(dharReminderSyncProvider);
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

  /// What the "Backup and export" row says about where the data is.
  String _backupLine(BackupBadge badge, CloudSyncState cloud, DateTime? lastFile) {
    switch (badge) {
      case BackupBadge.protectedByGoogle:
        final at = cloud.lastBackup;
        return at == null ? 'Signed in with Google' : 'Backed up ${DateFormat('d MMM, h:mm a').format(at)}';
      case BackupBadge.waiting:
        return 'Waiting to back up';
      case BackupBadge.unprotected:
        return 'Only on this phone. Tap to sign in';
      case BackupBadge.none:
        return lastFile == null ? 'No backup yet' : 'Last backup: ${DateFormat('d MMM y').format(lastFile)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final mode = ref.watch(themeModeProvider);
    final reminder = ref.watch(reminderSettingsProvider);
    final notices = ref.watch(homeNoticesProvider);
    final homeDetail = ref.watch(homeDetailProvider);
    final language = ref.watch(languageProvider);
    final textSize = ref.watch(textSizeProvider);
    final bengaliDigits = ref.watch(bengaliDigitsProvider);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final exactAllowed = ref.watch(exactAlarmsAllowedProvider).value ?? true;
    final lastFile = ref.watch(lastBackupProvider);
    final badge = ref.watch(backupBadgeProvider);
    final cloud = ref.watch(cloudSyncProvider);

    final overall = ref.watch(budgetStatusesProvider).where((s) => s.isOverall).firstOrNull;
    final activeGoals = ref.watch(goalProgressProvider).where((g) => !g.isDone).toList();
    final anyGoals = ref.watch(goalProgressProvider).isNotEmpty;
    final dhar = ref.watch(dharTotalsProvider);
    final dueBills = ref.watch(dueRecurringsProvider).length;
    final incomeTotal = ref.watch(monthlyIncomeTotalProvider);
    final billCount = ref.watch(recurringsProvider).value?.where((r) => r.isActive).length ?? 0;
    final categoryCount = ref.watch(categoriesProvider).value?.where((c) => !c.isArchived).length ?? 0;

    Widget section(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: theme.textTheme.titleMedium),
        );

    Widget card(List<Widget> rows) => Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(indent: 72, endIndent: 16),
                rows[i],
              ],
            ],
          ),
        );

    Text soft(String text, {Color? color}) =>
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color ?? colors.muted));

    // ---- the four money tools, each with a live line ----
    final budgetLive = overall == null
        ? soft('Set a monthly limit')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              overall.remaining >= 0
                  ? Text.rich(TextSpan(children: [
                      TextSpan(text: formatTaka(overall.remaining), style: theme.textTheme.titleSmall),
                      TextSpan(text: ' left this month', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                    ]))
                  : Text(
                      '${formatTaka(-overall.remaining)} over budget',
                      style: theme.textTheme.titleSmall?.copyWith(color: colors.spending),
                    ),
              const SizedBox(height: 6),
              _MiniBar(value: overall.fraction, color: budgetLevelColor(context, overall.level)),
            ],
          );

    final goalLive = activeGoals.isEmpty
        ? soft(anyGoals ? 'All goals reached' : 'Save for something')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${activeGoals.first.goal.name} ', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                  TextSpan(text: '${(activeGoals.first.fraction * 100).floor()}%', style: theme.textTheme.titleSmall),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _MiniBar(value: activeGoals.first.fraction, color: theme.colorScheme.primary),
            ],
          );

    final dharLive = dhar.toReceive > 0
        ? Text.rich(TextSpan(children: [
            TextSpan(text: 'Owed to you ', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
            TextSpan(text: formatTaka(dhar.toReceive), style: theme.textTheme.titleSmall),
          ]))
        : dhar.toPay > 0
            ? Text.rich(TextSpan(children: [
                TextSpan(text: 'You owe ', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                TextSpan(text: formatTaka(dhar.toPay), style: theme.textTheme.titleSmall),
              ]))
            : soft('Money you lent or borrowed');

    final billsLive = dueBills > 0
        ? Text.rich(TextSpan(children: [
            TextSpan(text: dueBills == 1 ? '1 bill' : '$dueBills bills', style: theme.textTheme.titleSmall),
            TextSpan(text: ' due now', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
          ]))
        : incomeTotal > 0
            ? Text.rich(TextSpan(children: [
                TextSpan(text: 'Income ', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
                TextSpan(text: formatTaka(incomeTotal), style: theme.textTheme.titleSmall),
                TextSpan(text: ' a month', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
              ]))
            : soft(billCount > 0 ? '$billCount set up' : 'Salary, rent, Wi-Fi');

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 20), child: Center(child: ProfileAvatar())),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          section('Money tools'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ToolCard(
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF157A6E),
                    title: 'Budgets',
                    route: '/budgets',
                    live: budgetLive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolCard(
                    icon: Icons.savings_outlined,
                    color: CategoryColors.education,
                    title: 'Savings goals',
                    route: '/goals',
                    live: goalLive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ToolCard(
                    icon: Icons.handshake_outlined,
                    color: CategoryColors.food,
                    title: 'Dhar',
                    route: '/dhar',
                    live: dharLive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolCard(
                    icon: Icons.event_repeat_rounded,
                    color: CategoryColors.bills,
                    title: 'Monthly bills & income',
                    route: '/recurring',
                    live: billsLive,
                  ),
                ),
              ],
            ),
          ),
          section('Organise'),
          card([
            _ListRow(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: '$categoryCount categories',
              onTap: () => context.push('/categories'),
            ),
            _ListRow(
              icon: Icons.cloud_sync_outlined,
              title: 'Backup and export',
              subtitle: _backupLine(badge, cloud, lastFile),
              onTap: () => context.push('/account'),
            ),
          ]),
          section('Daily reminder'),
          card([
            SwitchListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              secondary: const _IconBox(Icons.notifications_active_outlined),
              value: reminder.enabled,
              onChanged: _toggleReminder,
              title: const Text('Remind me every evening'),
              subtitle: const Text('Asks if you logged today\'s expenses'),
            ),
            ListTile(
              enabled: reminder.enabled,
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              leading: const _IconBox(Icons.schedule_rounded),
              title: const Text('Reminder time'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatReminderTime(context, reminder.minutes),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              onTap: _pickTime,
            ),
          ]),
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
          section('Home notices'),
          card([
            SwitchListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              secondary: const _IconBox(Icons.home_outlined),
              value: notices.enabled,
              onChanged: ref.read(homeNoticesProvider.notifier).setEnabled,
              title: const Text('Show notices on Home'),
              subtitle: const Text(
                'Backup, income, budget, bills and Dhar reminders',
              ),
            ),
            for (final (kind, icon, title, subtitle) in const [
              (
                HomeNotice.backup,
                Icons.cloud_off_rounded,
                'Backup reminder',
                'When your data is only on this phone',
              ),
              (
                HomeNotice.income,
                Icons.payments_outlined,
                'Monthly income note',
                'When your monthly income is added',
              ),
              (
                HomeNotice.budget,
                Icons.warning_amber_rounded,
                'Budget warnings',
                'When a budget is nearly used or over',
              ),
              (
                HomeNotice.bills,
                Icons.handshake_outlined,
                'Bills and Dhar due',
                'Things waiting for you to confirm or collect',
              ),
            ])
              SwitchListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                secondary: _IconBox(icon),
                value: notices.kinds.contains(kind),
                onChanged: notices.enabled
                    ? (v) => ref
                          .read(homeNoticesProvider.notifier)
                          .setKind(kind, v)
                    : null,
                title: Text(title),
                subtitle: Text(subtitle),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: soft(
              'Hidden notices are not lost. Budgets, Monthly bills & income and Dhar still show everything that is due.',
            ),
          ),
          section('Spent today card'),
          card([
            _ListRow(
              icon: Icons.insert_chart_outlined_rounded,
              title: 'Show beside "Spent today"',
              subtitle: _homeDetailChoices.firstWhere((c) => c.detail == homeDetail).title,
              onTap: () => showAppSheet<void>(context, builder: (_) => const _HomeDetailSheet()),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: soft('Choose one extra detail for the empty space on Home\'s top card, or nothing.'),
          ),
          section('Language and text'),
          card([
            _ChoiceRow(
              icon: Icons.translate_rounded,
              title: 'Language',
              subtitle: 'Changes every screen in the app',
              child: SegmentedButton<AppLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: AppLanguage.en, label: m.Text('English')),
                  ButtonSegment(value: AppLanguage.bn, label: m.Text('বাংলা')),
                ],
                selected: {language},
                onSelectionChanged: (s) => ref.read(languageProvider.notifier).set(s.first),
              ),
            ),
            _ChoiceRow(
              icon: Icons.format_size_rounded,
              title: 'Text size',
              subtitle: 'Bigger text is easier to read',
              child: SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('Normal')),
                  ButtonSegment(value: 1.25, label: Text('Large')),
                  ButtonSegment(value: 1.5, label: Text('Extra large')),
                ],
                selected: {textSize},
                onSelectionChanged: (s) => ref.read(textSizeProvider.notifier).set(s.first),
              ),
            ),
            _ChoiceRow(
              icon: Icons.pin_outlined,
              title: 'Numbers',
              subtitle: 'Choose Bengali or English numerals',
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: m.Text('বাংলা ১২৩')),
                  ButtonSegment(value: false, label: m.Text('English 123')),
                ],
                selected: {bengaliDigits},
                onSelectionChanged: (s) => ref.read(bengaliDigitsProvider.notifier).set(s.first),
              ),
            ),
          ]),
          section('Appearance'),
          Row(
            children: [
              for (final (value, label, icon) in const [
                (ThemeMode.system, 'System', Icons.phone_android_rounded),
                (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              ]) ...[
                if (value != ThemeMode.system) const SizedBox(width: 8),
                Expanded(
                  child: _ThemeChoice(
                    icon: icon,
                    label: label,
                    selected: mode == value,
                    onTap: () => ref.read(themeModeProvider.notifier).set(value),
                  ),
                ),
              ],
            ],
          ),
          section('Help and about'),
          const _ReminderGuide(),
          const SizedBox(height: 12),
          card([
            _ListRow(
              icon: Icons.school_outlined,
              title: 'Help and tutorials',
              subtitle: 'Tutorials for every feature, and the tour',
              onTap: () => context.push('/help'),
            ),
            _ListRow(
              icon: Icons.verified_user_outlined,
              title: 'Privacy and security',
              subtitle: 'Where your data is, and how it is protected',
              onTap: () => context.push('/privacy'),
            ),
            _ListRow(
              icon: Icons.notifications_outlined,
              title: 'Send a test reminder',
              subtitle: 'Check that notifications reach you',
              onTap: () => ref.read(notificationServiceProvider).showTest(),
            ),
            const _ListRow(icon: Icons.info_outline, title: 'About Hisab', subtitle: 'Version $appVersion ($appBuildNumber)'),
            const _ListRow(icon: Icons.code, title: 'Source and downloads', subtitle: 'github.com/jubayer2001/Hisab'),
          ]),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: scheme.primary, size: 22),
    );
  }
}

/// What can be shown beside "Spent today", in the order the choice sheet lists them.
const _homeDetailChoices = <({HomeDetail detail, String title, String about})>[
  (detail: HomeDetail.none, title: 'Nothing', about: 'Home looks exactly as it always has'),
  (
    detail: HomeDetail.budget,
    title: 'Budget status',
    about: 'Daily allowance, a warning at 80%, or how far over (needs a monthly budget)',
  ),
  (detail: HomeDetail.week, title: 'This week', about: 'What you have spent since Saturday'),
  (detail: HomeDetail.average, title: 'Daily average', about: 'This month\'s spending divided by the days so far'),
  (detail: HomeDetail.bill, title: 'Bill due soon', about: 'A monthly bill that falls due within 3 days'),
];

/// Pick the one extra detail shown beside "Spent today" on Home. It only appears when it has
/// something to say, and "Nothing" (the default) leaves Home as it was.
class _HomeDetailSheet extends ConsumerWidget {
  const _HomeDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(homeDetailProvider);
    return SheetScaffold(
      footer: FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      children: [
        const SheetHeader('Beside "Spent today"'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'One detail at a time. It appears only when it has something to say.',
            style: theme.textTheme.bodySmall?.copyWith(color: context.hisab.muted),
          ),
        ),
        for (final choice in _homeDetailChoices)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: current == choice.detail,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                current == choice.detail ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: current == choice.detail ? theme.colorScheme.primary : context.hisab.muted,
              ),
              title: Text(choice.title),
              subtitle: Text(choice.about),
              onTap: () {
                ref.read(homeDetailProvider.notifier).set(choice.detail);
                Navigator.pop(context);
              },
            ),
          ),
      ],
    );
  }
}

/// A setting with a title and a row of choices underneath it.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.icon, required this.title, required this.subtitle, required this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: context.hisab.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      leading: _IconBox(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// One of the four big tiles: a coloured icon, the tool's name, and a live line from the data.
class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.color, required this.title, required this.route, required this.live});

  final IconData icon;
  final Color color;
  final String title;
  final String route;
  final Widget live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: context.hisab.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              live,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 6,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(height: 2),
                Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
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
          leading: const _IconBox(Icons.help_outline_rounded),
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
