import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database_security.dart';
import '../services/app_lock.dart';
import '../services/native_security.dart';
import 'settings_providers.dart';

/// Whether the data on disk is encrypted. Set in main() from how the database was opened.
final encryptionStateProvider = Provider<EncryptionState>((ref) => EncryptionState.encrypted);

// ---- Hide in screenshots and the recent-apps picture ---------------------------------------

const secureWindowKey = 'secureWindow';

class SecureWindowNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(secureWindowKey) ?? true;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPrefsProvider).setBool(secureWindowKey, on);
    await ref.read(nativeSecurityProvider).setSecureWindow(on);
  }
}

final secureWindowProvider = NotifierProvider<SecureWindowNotifier, bool>(SecureWindowNotifier.new);

// ---- App lock ------------------------------------------------------------------------------

const appLockKey = 'appLock';
const appLockDelayKey = 'appLockDelay';

/// How long Hisab may stay in the background before it asks for the phone's unlock again.
enum LockDelay {
  immediately('immediately', 'Immediately', Duration.zero),
  oneMinute('oneMinute', 'After 1 minute', Duration(minutes: 1)),
  fiveMinutes('fiveMinutes', 'After 5 minutes', Duration(minutes: 5));

  const LockDelay(this.code, this.label, this.after);

  /// What is saved. Fixed words, not the enum's own name, because a release build scrambles
  /// code names (--obfuscate) and a saved setting must mean the same thing in every build.
  final String code;
  final String label;
  final Duration after;
}

class AppLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(appLockKey) ?? false;

  void set(bool on) {
    state = on;
    ref.read(sharedPrefsProvider).setBool(appLockKey, on);
  }
}

final appLockEnabledProvider = NotifierProvider<AppLockEnabledNotifier, bool>(AppLockEnabledNotifier.new);

class LockDelayNotifier extends Notifier<LockDelay> {
  @override
  LockDelay build() {
    final saved = ref.watch(sharedPrefsProvider).getString(appLockDelayKey);
    return LockDelay.values.firstWhere((d) => d.code == saved, orElse: () => LockDelay.oneMinute);
  }

  void set(LockDelay delay) {
    state = delay;
    ref.read(sharedPrefsProvider).setString(appLockDelayKey, delay.code);
  }
}

final lockDelayProvider = NotifierProvider<LockDelayNotifier, LockDelay>(LockDelayNotifier.new);

/// Whether the lock screen is showing, and whether the phone's prompt is open right now.
class AppLockState {
  const AppLockState({required this.locked, this.prompting = false});

  final bool locked;
  final bool prompting;

  AppLockState copyWith({bool? locked, bool? prompting}) =>
      AppLockState(locked: locked ?? this.locked, prompting: prompting ?? this.prompting);
}

/// Locks the app on a cold start, and again when it has been away longer than the chosen delay.
/// What is behind the lock screen is not shown and cannot be read by a screen reader.
class AppLockController extends Notifier<AppLockState> {
  DateTime? _leftAt;

  /// How the clock is read. Overridden in tests.
  DateTime Function() now = DateTime.now;

  @override
  AppLockState build() {
    // A cold start is locked when the lock is on.
    return AppLockState(locked: ref.read(appLockEnabledProvider));
  }

  /// The app went to the background (or the phone's own prompt covered it).
  void onLeft() {
    if (!ref.read(appLockEnabledProvider) || state.prompting) return;
    _leftAt = now();
    // "Immediately" locks the moment the app is left, so the screen is covered before it returns.
    if (ref.read(lockDelayProvider) == LockDelay.immediately) {
      state = state.copyWith(locked: true);
    }
  }

  /// The app is back on screen.
  void onReturned() {
    if (!ref.read(appLockEnabledProvider) || state.locked || state.prompting) return;
    final left = _leftAt;
    _leftAt = null;
    if (left == null) return;
    if (now().difference(left) >= ref.read(lockDelayProvider).after) {
      state = state.copyWith(locked: true);
    }
  }

  /// Shows the phone's unlock prompt. Unlocks only if it is passed.
  Future<bool> unlock() async {
    if (state.prompting) return false;
    state = state.copyWith(prompting: true);
    final ok = await ref.read(appLockServiceProvider).authenticate('Unlock Hisab');
    state = AppLockState(locked: !ok && state.locked, prompting: false);
    if (ok) _leftAt = null;
    return ok;
  }

  /// Turns the lock on after proving it works (so nobody locks themselves out), or off.
  /// Returns false if it could not be turned on.
  Future<bool> setEnabled(bool on) async {
    if (!on) {
      ref.read(appLockEnabledProvider.notifier).set(false);
      state = const AppLockState(locked: false);
      return true;
    }
    final service = ref.read(appLockServiceProvider);
    if (!await service.isAvailable()) return false;
    if (!await service.authenticate('Confirm it is you to turn on the app lock')) return false;
    ref.read(appLockEnabledProvider.notifier).set(true);
    return true;
  }
}

final appLockControllerProvider = NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
