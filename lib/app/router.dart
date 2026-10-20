import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budgets/budgets_screen.dart';
import '../features/dhar/dhar_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/categories_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_shell.dart';

/// One router per app instance (not a global), so each start, and each test, begins on Home.
final routerProvider = Provider<GoRouter>((ref) {
  final router = _buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ]),
      ],
    ),
    // These open on top of the tab bar.
    GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
    GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen()),
    GoRoute(path: '/recurring', builder: (context, state) => const RecurringScreen()),
    GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
    GoRoute(path: '/dhar', builder: (context, state) => const DharScreen()),
  ],
);
