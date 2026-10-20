import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/settings_providers.dart';
import 'services/notifications.dart';
import 'services/reminder_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();

  // The container is created here (not by ProviderScope) so notification buttons can
  // reach the app's state even though the system calls them from outside the widget tree.
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
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
