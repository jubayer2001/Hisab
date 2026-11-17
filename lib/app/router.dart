import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/account/erase_screen.dart';
import '../features/budgets/budgets_screen.dart';
import '../features/dhar/dhar_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/guide/help_screen.dart';
import '../features/guide/tour_offer_screen.dart';
import '../features/guide/tutorial_player.dart';
import '../features/guide/tutorials.dart';
import '../features/guide/whats_new_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/security/privacy_screen.dart';
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
    GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
    GoRoute(path: '/erase', builder: (context, state) => const EraseScreen()),
    GoRoute(path: '/privacy', builder: (context, state) => const PrivacyScreen()),
    GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
    GoRoute(path: '/whats-new', builder: (context, state) => const WhatsNewScreen()),
    GoRoute(path: '/tour', builder: (context, state) => const TourOfferScreen()),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => TutorialPlayerScreen(
        ids: tutorialIdsFromCodes(state.uri.queryParameters['ids']),
        tour: state.uri.queryParameters['tour'] == '1',
      ),
    ),
  ],
);
