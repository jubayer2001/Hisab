import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/welcome_screen.dart';
import '../features/security/lock_gate.dart';
import '../services/cloud_sync.dart';
import 'router.dart';
import 'settings_providers.dart';
import 'theme.dart';

/// Puts the app lock over everything when it is on.
Widget _lockGate(BuildContext context, Widget? child) => AppLockGate(child: child ?? const SizedBox.shrink());

class HisabApp extends ConsumerWidget {
  const HisabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // First launch: the welcome steps, then the app itself.
    if (!ref.watch(onboardingDoneProvider)) {
      return _CloudSyncLifecycle(
        child: MaterialApp(
          title: 'Hisab',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeMode,
          builder: _lockGate,
          home: const WelcomeScreen(),
        ),
      );
    }

    return _CloudSyncLifecycle(
      child: MaterialApp.router(
        title: 'Hisab',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        builder: _lockGate,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}

/// Keeps the Google backup running for as long as the app is, and gives it a nudge whenever
/// the app leaves the screen or comes back, which are the best moments to upload a change.
class _CloudSyncLifecycle extends ConsumerStatefulWidget {
  const _CloudSyncLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_CloudSyncLifecycle> createState() => _CloudSyncLifecycleState();
}

class _CloudSyncLifecycleState extends ConsumerState<_CloudSyncLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      ref.read(cloudSyncProvider.notifier).onLifecycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watching keeps the sync alive while the app is open.
    ref.watch(cloudSyncProvider.select((s) => s.signedIn));
    return widget.child;
  }
}
