import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/security_providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';

/// Wraps the whole app. While the app lock is showing, nothing of the app is visible, tappable or
/// readable by a screen reader, and the phone's unlock prompt opens by itself.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A cold start with the lock on: ask straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptIfLocked());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _promptIfLocked() {
    if (!mounted) return;
    final lock = ref.read(appLockControllerProvider);
    if (lock.locked && !lock.prompting) ref.read(appLockControllerProvider.notifier).unlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appLockControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        controller.onLeft();
      case AppLifecycleState.resumed:
        controller.onReturned();
        _promptIfLocked();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockControllerProvider.select((s) => s.locked));
    return Stack(
      fit: StackFit.expand,
      children: [
        // Kept alive underneath so nothing is lost, but invisible, inert and hidden from screen readers.
        Offstage(
          offstage: locked,
          child: ExcludeSemantics(excluding: locked, child: widget.child),
        ),
        if (locked) const _LockScreen(),
      ],
    );
  }
}

class _LockScreen extends ConsumerWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final prompting = ref.watch(appLockControllerProvider.select((s) => s.prompting));

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(28)),
                alignment: Alignment.center,
                child: Text(
                  takaSign,
                  style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              Text('Hisab is locked', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Use your fingerprint, face, PIN or pattern to open it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: prompting ? null : () => ref.read(appLockControllerProvider.notifier).unlock(),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
