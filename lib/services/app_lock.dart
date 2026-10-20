import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Asking the phone to confirm that the person holding it is its owner, with their fingerprint,
/// face, PIN or pattern: whatever they already use to unlock the phone.
///
/// A small interface so tests can use a fake instead of the real phone.
abstract class AppLockService {
  /// Whether the phone has a screen lock (or biometrics) set up, so it can check anything at all.
  Future<bool> isAvailable();

  /// Shows the phone's own unlock prompt. True only if the person passed it.
  Future<bool> authenticate(String reason);
}

class PhoneAppLockService implements AppLockService {
  PhoneAppLockService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // The phone's PIN, pattern or password is accepted too, not only a fingerprint.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // Cancelled, too many attempts, no screen lock, or the prompt was interrupted: not unlocked.
      return false;
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) => PhoneAppLockService());
