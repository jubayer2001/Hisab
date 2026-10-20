import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/google_button.dart';
import '../../core/widgets/sheet.dart';
import '../../data/db/tables.dart';
import '../../data/logic/auto_income.dart';
import '../../data/providers.dart';
import '../../services/cloud_backup.dart';
import '../../services/cloud_sync.dart';
import '../../services/reminder_providers.dart';
import '../backup/google_connect.dart';

/// A few short steps shown once, the first time the app opens: a name, an optional monthly
/// budget, an optional monthly income, the evening reminder, and (when Google sign-in is set
/// up) how to keep the data safe. Everything can be skipped and changed later.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// The steps before the backup step: name, budget, income, reminder.
  static const _setupSteps = 4;

  /// The last step (keeping data safe with Google) exists only when Google sign-in is set up.
  int get _pageCount => ref.read(cloudBackupServiceProvider).isConfigured ? _setupSteps + 1 : _setupSteps;

  final _pages = PageController();
  final _name = TextEditingController();
  final _budget = TextEditingController();
  final _incomeAmount = TextEditingController();
  int _page = 0;

  /// The monthly income being typed, and the ones already added with "Add another".
  int? _incomeCategoryId;
  int _incomeDay = 1;
  late bool _incomeReceived = _incomeDay <= dateOnly(DateTime.now()).day;
  final List<_IncomeDraft> _incomes = [];
  bool _reminderOn = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 22, minute: 0);
  bool _finishing = false;

  /// They chose to go on without a Google account (after being warned).
  bool _withoutAccount = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _budget.dispose();
    _incomeAmount.dispose();
    super.dispose();
  }

  void _go(int page) {
    FocusScope.of(context).unfocus();
    _pages.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  /// For someone who deleted the app or got a new phone: sign in and bring their data back.
  Future<void> _restoreFromGoogle() async {
    final result = await connectGoogle(context, ref);
    if (result == GoogleConnectResult.restored) {
      ref.read(onboardingDoneProvider.notifier).finish();
    }
  }

  /// The last step's Google button. Restoring brings the old data back, so there is nothing
  /// left to set up; signing in just unlocks "Get started".
  Future<void> _signInStep() async {
    final result = await connectGoogle(context, ref, quiet: true);
    if (!mounted) return;
    if (result == GoogleConnectResult.restored) {
      ref.read(onboardingDoneProvider.notifier).finish();
    } else if (result == GoogleConnectResult.linked) {
      setState(() => _withoutAccount = false);
    }
  }

  /// "Use without an account": one calm confirmation, then they can go on.
  Future<void> _skipAccount() async {
    final choice = await showAppSheet<bool>(context, builder: (_) => const _WithoutBackupSheet());
    if (!mounted || choice == null) return;
    if (choice) {
      await _signInStep();
    } else {
      setState(() => _withoutAccount = true);
    }
  }

  /// "Skip" at the top: jump over the setup steps, but never over the backup question.
  void _skipSetup() {
    if (_pageCount > _setupSteps && _page < _pageCount - 1) {
      _go(_pageCount - 1);
    } else {
      _finish();
    }
  }

  /// Saves what was entered (nothing is required) and opens the app.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    ref.read(userNameProvider.notifier).set(_name.text);

    final budget = readAmount(_budget);
    if (budget != null) {
      await ref.read(databaseProvider).setBudget(categoryId: null, amountPoisha: budget);
    }

    // Monthly income: the ones already added, plus the one being typed if it is complete.
    final pending = _currentIncome();
    final drafts = [..._incomes, ?pending];
    if (drafts.isNotEmpty) {
      final db = ref.read(databaseProvider);
      final today = ref.read(todayProvider);
      for (final d in drafts) {
        await createMonthlyIncome(
          db,
          today,
          title: d.title,
          amountPoisha: d.amountPoisha,
          categoryId: d.categoryId,
          dayOfMonth: d.day,
          receivedThisMonth: d.received,
        );
      }
    }

    ref.read(reminderSettingsProvider.notifier)
      ..setEnabled(_reminderOn)
      ..setTime(_reminderTime);

    if (_reminderOn) {
      // Ask for permission here, with the context of why, so the app does not ask again later.
      await ref.read(sharedPrefsProvider).setBool(reminderPermissionAskedKey, true);
      await ref.read(notificationServiceProvider).requestPermission();
    }

    ref.read(onboardingDoneProvider.notifier).finish();
  }

  /// On the backup step, "Get started" waits until they have signed in or chosen to go without.
  bool get _chosenBackup =>
      _pageCount == _setupSteps || _withoutAccount || ref.read(cloudSyncProvider).signedIn;

  /// What is typed in the income step as a finished income, or null if it is not complete.
  _IncomeDraft? _currentIncome() {
    final amount = readAmount(_incomeAmount);
    final categories = ref.read(pickableCategoriesProvider(EntryType.income));
    final category = categories.where((c) => c.id == (_incomeCategoryId ?? categories.firstOrNull?.id)).firstOrNull;
    if (amount == null || category == null) return null;
    return _IncomeDraft(
      title: category.name,
      categoryId: category.id,
      amountPoisha: amount,
      day: _incomeDay,
      received: _incomeReceived,
    );
  }

  void _addAnotherIncome() {
    final draft = _currentIncome();
    if (draft == null) return;
    setState(() {
      _incomes.add(draft);
      _incomeAmount.clear();
    });
  }

  /// The monthly income step: where it comes from, how much, and on which day.
  Widget _incomeStep(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final categories = ref.watch(pickableCategoriesProvider(EntryType.income));
    final selected = _incomeCategoryId ?? categories.firstOrNull?.id;
    final complete = _currentIncome() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_incomes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _incomes.length; i++)
                InputChip(
                  label: Text('${_incomes[i].title} ${formatTaka(_incomes[i].amountPoisha)}'),
                  onDeleted: () => setState(() => _incomes.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              ChoiceChip(
                label: Text(c.name),
                selected: c.id == selected,
                onSelected: (_) => setState(() => _incomeCategoryId = c.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AmountField(controller: _incomeAmount, label: 'Amount each month', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _incomeDay,
          decoration: fieldDecoration(context, label: 'It arrives on day'),
          items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('Day $d'))],
          onChanged: (v) => setState(() {
            _incomeDay = v ?? _incomeDay;
            _incomeReceived = _incomeDay <= dateOnly(DateTime.now()).day;
          }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _incomeReceived,
          onChanged: (v) => setState(() => _incomeReceived = v),
          title: const Text('Already received this month'),
          subtitle: Text(_incomeReceived ? 'Counts toward this month now' : 'The first one is next month'),
        ),
        TextButton.icon(
          onPressed: complete ? _addAnotherIncome : null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add another monthly income'),
        ),
        Text(
          'Hisab records it for you on that day every month. You can change or stop it any time in More.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }

  /// The backup step's choices: Google, or an account-free start with the risk spelled out.
  Widget _backupChoices(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final cloud = ref.watch(cloudSyncProvider);

    if (cloud.signedIn) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.income.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.income),
            const SizedBox(width: 12),
            Expanded(child: Text('Signed in as ${cloud.email}. Your data will be backed up.', style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleSignInButton(onPressed: _signInStep),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
          onPressed: _skipAccount,
          child: Text(
            'Use without an account',
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: _withoutAccount ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: colors.highlight.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.highlight),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Without an account, ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const TextSpan(text: 'your data lives only on this phone. If the app is deleted or the phone is lost, it cannot be recovered.'),
                  ]),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can sign in later from the profile icon on Home.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.hisab;
    final last = _page == _pageCount - 1;
    ref.watch(cloudSyncProvider); // so "Get started" lights up the moment they sign in

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                // On the backup step there is nothing left to skip.
                child: last && _pageCount > _setupSteps
                    ? const SizedBox(height: 48)
                    : TextButton(
                        onPressed: _finishing ? null : _skipSetup,
                        child: const Text('Skip'),
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _StepPage(
                    icon: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(28)),
                      alignment: Alignment.center,
                      child: Text(
                        takaSign,
                        style: theme.textTheme.displayMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: 'Welcome to Hisab',
                    body: 'A calm place to track what you spend, earn and save. Everything stays on your phone.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _name,
                          maxLength: 24,
                          textCapitalization: TextCapitalization.words,
                          decoration: fieldDecoration(context, label: 'What should we call you? (optional)'),
                        ),
                        if (ref.watch(cloudBackupServiceProvider).isConfigured) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                            onPressed: _finishing ? null : _restoreFromGoogle,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Already used Hisab? Restore from Google'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StepPage(
                    icon: _RoundIcon(Icons.speed_rounded, scheme),
                    title: 'Set a monthly budget',
                    body: 'Optional. Hisab shows how much is left each month and warns you when you reach 80%. You can change it any time in More.',
                    child: AmountField(controller: _budget, label: 'Monthly budget (optional)'),
                  ),
                  _StepPage(
                    icon: _RoundIcon(Icons.payments_outlined, scheme),
                    title: 'Your monthly income',
                    body: 'Optional. Hisab adds it for you every month, so your balance is right from day one. Other income can be added any time with the + button.',
                    child: _incomeStep(context),
                  ),
                  _StepPage(
                    icon: _RoundIcon(Icons.notifications_active_outlined, scheme),
                    title: 'An evening reminder',
                    body: 'A gentle nudge to add what you spent today, so nothing gets forgotten.',
                    child: Column(
                      children: [
                        Material(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _reminderOn,
                                onChanged: (v) => setState(() => _reminderOn = v),
                                title: const Text('Remind me every evening'),
                              ),
                              const Divider(indent: 16, endIndent: 16),
                              ListTile(
                                enabled: _reminderOn,
                                leading: const Icon(Icons.schedule_rounded),
                                title: const Text('Reminder time'),
                                trailing: Text(
                                  _reminderTime.format(context),
                                  style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary),
                                ),
                                onTap: _pickTime,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'On Xiaomi and Redmi phones, you may also need to allow Autostart. Hisab shows how in More, under "Reminder not arriving?".',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (_pageCount > _setupSteps)
                    _StepPage(
                      icon: _RoundIcon(Icons.cloud_done_outlined, scheme),
                      title: 'Keep your data safe',
                      body:
                          'Sign in with Google and Hisab keeps a private copy in your own Google Drive. If you ever delete the app or change phones, everything comes back.',
                      child: _backupChoices(context),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: _page == 0
                        ? null
                        : TextButton(onPressed: () => _go(_page - 1), child: const Text('Back')),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pageCount; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? scheme.primary : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 132,
                    child: FilledButton(
                      onPressed: _finishing
                          ? null
                          : last
                              ? (_chosenBackup ? _finish : null)
                              : () => _go(_page + 1),
                      child: Text(last ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon, this.scheme);

  final IconData icon;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
      child: Icon(icon, size: 42, color: scheme.primary),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.icon, required this.title, required this.body, required this.child});

  final Widget icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 28),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(color: context.hisab.muted)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Shown when someone chooses to start without a Google account.
/// Pops true for "sign in instead", false for "continue without a backup".
class _WithoutBackupSheet extends StatelessWidget {
  const _WithoutBackupSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    return SheetScaffold(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: colors.highlight.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.warning_amber_rounded, color: colors.highlight, size: 30),
        ),
        const SizedBox(height: 12),
        Text('Continue without a backup?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Your data will exist only on this phone. If you delete Hisab, reset the phone or lose it, your records are gone for good.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          'You can add your Google account any time from the profile icon on Home.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign in with Google')),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
          onPressed: () => Navigator.pop(context, false),
          child: Text('Continue without a backup', style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}


/// A monthly income typed in the welcome steps, saved when they finish.
class _IncomeDraft {
  const _IncomeDraft({
    required this.title,
    required this.categoryId,
    required this.amountPoisha,
    required this.day,
    required this.received,
  });

  final String title;
  final int categoryId;
  final int amountPoisha;
  final int day;
  final bool received;
}
