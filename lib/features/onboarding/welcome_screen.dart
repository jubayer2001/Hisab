import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings_providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/widgets/amount_field.dart';
import '../../data/providers.dart';
import '../../services/reminder_providers.dart';

/// Three short steps shown once, the first time the app opens: a name, an optional
/// monthly budget, and the evening reminder. Everything can be skipped and changed later.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _pageCount = 3;

  final _pages = PageController();
  final _name = TextEditingController();
  final _budget = TextEditingController();
  int _page = 0;
  bool _reminderOn = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 22, minute: 0);
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _budget.dispose();
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

  /// Saves what was entered (nothing is required) and opens the app.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    ref.read(userNameProvider.notifier).set(_name.text);

    final budget = readAmount(_budget);
    if (budget != null) {
      await ref.read(databaseProvider).setBudget(categoryId: null, amountPoisha: budget);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.hisab;
    final last = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: TextButton(
                  onPressed: _finishing ? null : _finish,
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
                    child: TextField(
                      controller: _name,
                      maxLength: 24,
                      textCapitalization: TextCapitalization.words,
                      decoration: fieldDecoration(context, label: 'What should we call you? (optional)'),
                    ),
                  ),
                  _StepPage(
                    icon: _RoundIcon(Icons.speed_rounded, scheme),
                    title: 'Set a monthly budget',
                    body: 'Optional. Hisab shows how much is left each month and warns you when you reach 80%. You can change it any time in More.',
                    child: AmountField(controller: _budget, label: 'Monthly budget (optional)'),
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
                      onPressed: _finishing ? null : (last ? _finish : () => _go(_page + 1)),
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
