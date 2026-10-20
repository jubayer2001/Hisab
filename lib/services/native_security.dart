import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The key could not be read or created (the phone's secure storage failed or refused).
class NativeSecurityException implements Exception {
  const NativeSecurityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The two things only Android itself can do for Hisab's security: keep the database key in
/// the phone's hardware-backed Keystore, and keep the screen out of screenshots and the
/// recent-apps picture.
///
/// A small interface so tests can use a fake instead of the real phone.
abstract class NativeSecurity {
  /// The 256-bit database key as 64 lowercase hex characters. Created on first use and the same
  /// every time after. Throws [NativeSecurityException] if the phone cannot provide it.
  Future<String> databaseKeyHex();

  /// Hides (true) or shows (false) the app in screenshots and the recent-apps picture.
  Future<void> setSecureWindow(bool on);

  Future<bool> isSecureWindow();
}

class MethodChannelNativeSecurity implements NativeSecurity {
  const MethodChannelNativeSecurity();

  static const _channel = MethodChannel('hisab/security');

  @override
  Future<String> databaseKeyHex() async {
    try {
      final key = await _channel.invokeMethod<String>('databaseKey');
      if (key == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
        throw const NativeSecurityException('The phone returned an unusable key.');
      }
      return key;
    } on PlatformException catch (e) {
      throw NativeSecurityException('The phone could not provide the key (${e.code}).');
    } on MissingPluginException {
      throw const NativeSecurityException('Secure storage is not available here.');
    }
  }

  @override
  Future<void> setSecureWindow(bool on) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } on PlatformException {
      // Not fatal: the screen simply stays as it was.
    } on MissingPluginException {
      // Running in a test or on another platform.
    }
  }

  @override
  Future<bool> isSecureWindow() async {
    try {
      return await _channel.invokeMethod<bool>('isSecure') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}

final nativeSecurityProvider = Provider<NativeSecurity>((ref) => const MethodChannelNativeSecurity());
