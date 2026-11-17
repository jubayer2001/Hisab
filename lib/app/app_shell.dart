import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/dates.dart';
import '../data/erase.dart';
import '../data/providers.dart';
import '../features/add_entry/add_entry_sheet.dart';
import '../features/guide/guide_logic.dart';
import '../services/notifications.dart';
import '../services/reminder_providers.dart';
import 'settings_providers.dart';
import '../l10n/text.dart';

/// Bottom navigation: Home, History, [+], Reports, Settings.
/// The middle item opens the add sheet instead of switching tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const _addIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // An erase can only be undone for a week; after that its safety copy is removed.
      unawaited(ref.read(eraseActionsProvider).purgeExpired());
      // A notification button pressed while the app was closed (or open) lands here.
      ref.listenManual<String?>(notificationActionProvider, (_, action) {
        if (action != null) _handleAction(action);
      }, fireImmediately: true);
      await _askForNotificationPermissionOnce();
      await _showGuideOnce();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(todayProvider.notifier).refresh();
  }

  /// A new user is offered the quick tour; someone who just updated sees what's new. Each is
  /// shown once: it is marked as seen before it opens.
  Future<void> _showGuideOnce() async {
    if (!mounted) return;
    final prefs = ref.read(sharedPrefsProvider);
    final action = decideGuideAction(
      tourPending: prefs.getBool(tourPendingKey) ?? false,
      lastSeen: prefs.getString(lastSeenVersionKey),
      current: currentVersionLabel,
    );
    if (action == GuideAction.none) return;
    await prefs.remove(tourPendingKey);
    await prefs.setString(lastSeenVersionKey, currentVersionLabel);
    if (!mounted) return;
    context.push(action == GuideAction.tour ? '/tour' : '/whats-new');
  }

  Future<void> _askForNotificationPermissionOnce() async {
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(reminderPermissionAskedKey) ?? false) return;
    await prefs.setBool(reminderPermissionAskedKey, true);
    await ref.read(notificationServiceProvider).requestPermission();
    ref.invalidate(notificationsAllowedProvider);
    // Re-run the schedulers now that the permission may have been granted.
    ref.invalidate(reminderSyncProvider);
    ref.invalidate(dharReminderSyncProvider);
  }

  Future<void> _handleAction(String action) async {
    ref.read(notificationActionProvider.notifier).clear();
    if (!mounted) return;
    if (action == ReminderAction.noSpend) {
      await ref.read(databaseProvider).setNoSpend(dayKey(ref.read(todayProvider)), true);
      if (!mounted) return;
      // After something was already spent today the day is "done", not "empty".
      final spentToday = ref.read(todayEntriesProvider).any((e) => e.isExpense);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(spentToday ? 'No more spending today' : 'Marked as no spending today')),
        );
    } else {
      showAddEntrySheet(context);
    }
  }

  int get _navIndex =>
      widget.shell.currentIndex < _addIndex ? widget.shell.currentIndex : widget.shell.currentIndex + 1;

  void _onSelected(int index) {
    if (index == _addIndex) {
      showAddEntrySheet(context);
      return;
    }
    final branch = index < _addIndex ? index : index - 1;
    widget.shell.goBranch(branch, initialLocation: branch == widget.shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Keeps tonight's reminder text in step with what has been logged, and the 9 AM
    // reminders for dhar due dates in step with the dhar list.
    ref.watch(reminderSyncProvider);
    ref.watch(dharReminderSyncProvider);
    // Monthly income that is due adds itself.
    ref.watch(autoIncomeSyncProvider);
    // The bar's labels are plain strings, so rebuild it when the language or digit style changes.
    ref.watch(languageProvider);
    ref.watch(bengaliDigitsProvider);

    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: tr('Home')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: tr('History')),
          NavigationDestination(icon: const _AddButton(), label: tr('Add')),
          NavigationDestination(icon: const Icon(Icons.insert_chart_outlined), selectedIcon: const Icon(Icons.insert_chart), label: tr('Reports')),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: tr('More')),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(14)),
      child: Icon(Icons.add_rounded, color: scheme.onPrimary, size: 26),
    );
  }
}
