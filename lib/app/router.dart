import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
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
    // Opens on top of the tab bar.
    GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
  ],
);
