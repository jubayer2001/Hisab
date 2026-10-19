import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/add_entry/add_entry_sheet.dart';

/// Bottom navigation: Home, History, [+], Reports, Settings.
/// The middle item opens the add sheet instead of switching tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _addIndex = 2;

  int get _navIndex => shell.currentIndex < _addIndex ? shell.currentIndex : shell.currentIndex + 1;

  void _onSelected(BuildContext context, int index) {
    if (index == _addIndex) {
      showAddEntrySheet(context);
      return;
    }
    final branch = index < _addIndex ? index : index - 1;
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => _onSelected(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: _AddButton(), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.insert_chart_outlined), selectedIcon: Icon(Icons.insert_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
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
