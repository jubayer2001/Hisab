import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/security_providers.dart';
import 'app/settings_providers.dart';
import 'data/db/app_database.dart';
import 'data/db/database_security.dart';
import 'data/providers.dart';
import 'features/security/database_locked_screen.dart';
import 'services/native_security.dart';
import 'services/notifications.dart';
import 'services/reminder_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const security = MethodChannelNativeSecurity();

  // Open the database first. It is encrypted with a key kept in the phone's Keystore; an older
  // unencrypted database from before encryption existed is converted on the way in.
  final directory = await getApplicationDocumentsDirectory();
  final dbPath = p.join(directory.path, 'hisab.sqlite');
  String? key;
  try {
    key = await security.databaseKeyHex();
  } on NativeSecurityException {
    key = null;
  }

  EncryptionState encryption;
  try {
    encryption = prepareDatabase(dbPath, key);
  } on DatabaseLockedException catch (e) {
    // The data is encrypted and cannot be opened. Never guess: explain, and offer a clean start.
    runApp(DatabaseLockedApp(databasePath: dbPath, reason: e.message));
    return;
  } catch (_) {
    // Converting failed and the original was put back untouched. Carry on without encryption
    // this time; the next start tries again.
    key = null;
    encryption = EncryptionState.unavailable;
  }
  final database = AppDatabase.onDisk(path: dbPath, keyHex: key);
  // One line in the system log (no data, no key) so a check on the phone can confirm the state.
  debugPrint('Hisab: database ${encryption == EncryptionState.encrypted ? 'encrypted' : 'NOT encrypted'}');

  // The screen is hidden from screenshots and the recent-apps picture unless the person turned that off.
  await security.setSecureWindow(prefs.getBool(secureWindowKey) ?? true);

  final notifications = NotificationService();

  // The container is created here (not by ProviderScope) so notification buttons can
  // reach the app's state even though the system calls them from outside the widget tree.
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(database),
      encryptionStateProvider.overrideWithValue(encryption),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
  );

  await notifications.init(
    onAction: (action) => container.read(notificationActionProvider.notifier).set(action),
  );
  final launchAction = await notifications.launchAction();
  if (launchAction != null) container.read(notificationActionProvider.notifier).set(launchAction);

  runApp(UncontrolledProviderScope(container: container, child: const HisabApp()));
}
