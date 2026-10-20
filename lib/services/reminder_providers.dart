import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings_providers.dart';
import '../core/dates.dart';
import '../core/money.dart';
import '../data/db/tables.dart';
import '../data/providers.dart';
import 'notifications.dart';

/// Overridden in main() with the service that was initialised before the app started.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationServiceProvider must be overridden in main()'),
);

/// The last notification button the user pressed, waiting for the UI to act on it.
class NotificationActionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String action) => state = action;

  void clear() => state = null;
}

final notificationActionProvider =
    NotifierProvider<NotificationActionNotifier, String?>(NotificationActionNotifier.new);

/// Keeps the 9 AM due-date reminders for open dhar entries in step with the list.
final dharReminderSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final records = ref.watch(dharRecordsProvider);
  final payments = ref.watch(dharPaymentsProvider);
  if (records.isLoading || payments.isLoading) return;

  final reminders = <DharReminder>[
    for (final v in ref.watch(dharViewsProvider))
      if (!v.isSettled && v.record.dueDate != null)
        DharReminder(
          id: v.record.id,
          title: v.isLent ? '${v.record.person} owes you ${formatTaka(v.remaining)}' : 'Pay back ${v.record.person}',
          body: v.isLent
              ? 'Due today. A good time to ask for it back.'
              : '${formatTaka(v.remaining)} is due today.',
          due: parseDayKey(v.record.dueDate!),
        ),
  ];
  unawaited(service.syncDharReminders(reminders));
});

/// Whether the system currently lets Hisab show notifications.
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationServiceProvider).notificationsAllowed(),
);

/// Whether reminders can fire at the exact minute (Android 14+ asks the user for this).
final exactAlarmsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationServiceProvider).canUseExactAlarms(),
);

/// Keeps the scheduled reminders in step with the settings and today's entries.
/// Watched once from the app shell; it does its work as a side effect.
final reminderSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(reminderSettingsProvider);
  final service = ref.watch(notificationServiceProvider);
  final entries = ref.watch(allEntriesProvider);
  final noSpend = ref.watch(noSpendDaysProvider);

  // Wait for the database so we never schedule a wrong message from empty data.
  if (entries.isLoading || noSpend.isLoading) return;

  final today = dayKey(ref.watch(todayProvider));
  final settled = noSpend.value?.contains(today) ?? false;
  final todayExpenses = (entries.value ?? const [])
      .where((e) => e.entry.date == today && e.entry.type == EntryType.expense)
      .fold<int>(0, (sum, e) => sum + e.entry.amountPoisha);

  final String? todayBody;
  if (settled) {
    todayBody = null;
  } else if (todayExpenses > 0) {
    todayBody = '${formatTaka(todayExpenses)} logged today. Anything else to add?';
  } else {
    todayBody = "You haven't added any expenses today. Did you spend anything?";
  }

  unawaited(
    service.syncReminders(enabled: settings.enabled, minutes: settings.minutes, todayBody: todayBody),
  );
});
