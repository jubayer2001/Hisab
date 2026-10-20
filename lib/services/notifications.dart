import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// What the user chose in a notification.
abstract final class ReminderAction {
  static const add = 'add';
  static const noSpend = 'nospend';
}

/// Schedules and shows the nightly "did you log today's expenses?" reminder.
///
/// A notification's text is fixed when it is scheduled, so instead of one repeating
/// alarm we schedule the next [_days] evenings separately and re-schedule whenever the
/// day's entries change. That lets tonight's message say what was already logged, and
/// lets us skip tonight when the day is already marked "No spending".
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'daily_reminder';
  static const _channelName = 'Daily reminder';
  static const _firstId = 1000;
  static const _days = 14;
  static const _testId = 999;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static String _actionFrom(NotificationResponse? r) {
    final id = r?.actionId;
    return (id == null || id.isEmpty) ? ReminderAction.add : id;
  }

  /// [onAction] receives [ReminderAction.add] or [ReminderAction.noSpend].
  Future<void> init({required void Function(String action) onAction}) async {
    tzdata.initializeTimeZones();
    // Bangladesh has no daylight saving, so a fixed zone keeps "10 PM" meaning 10 PM.
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_hisab')),
      onDidReceiveNotificationResponse: (response) => onAction(_actionFrom(response)),
    );
  }

  /// The action that launched the app from a closed state, if any.
  Future<String?> launchAction() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return _actionFrom(details.notificationResponse);
  }

  // ---- Permissions ---------------------------------------------------------

  Future<bool> notificationsAllowed() async => await _android?.areNotificationsEnabled() ?? false;

  Future<bool> requestPermission() async => await _android?.requestNotificationsPermission() ?? false;

  Future<bool> canUseExactAlarms() async => await _android?.canScheduleExactNotifications() ?? true;

  Future<void> requestExactAlarms() async => _android?.requestExactAlarmsPermission();

  // ---- Notifications -------------------------------------------------------

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'A nightly reminder to add your expenses',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: [
            AndroidNotificationAction(
              ReminderAction.add,
              'Add expense',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              ReminderAction.noSpend,
              'No spending today',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
      );

  static const title = "Did you log today's expenses?";
  static const genericBody = "Take a minute to add what you spent today.";

  /// Shows a reminder immediately, so the user can check that notifications arrive.
  Future<void> showTest() {
    return _plugin.show(
      id: _testId,
      title: title,
      body: 'This is a test reminder. Your real one arrives at the time you chose.',
      notificationDetails: _details,
    );
  }

  static const _dharIdBase = 20000;
  static const _dharIdRange = 10000;
  static const _dharChannelId = 'dhar_due';

  /// Schedules a 9 AM reminder on the due date of each open dhar entry, replacing the
  /// previous set, so settled or deleted entries stop reminding.
  Future<void> syncDharReminders(List<DharReminder> reminders) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _dharIdBase && p.id < _dharIdBase + _dharIdRange) await _plugin.cancel(id: p.id);
    }
    if (reminders.isEmpty || !await notificationsAllowed()) return;

    final mode = await canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dharChannelId,
        'Dhar due dates',
        channelDescription: 'Reminders when money you lent or borrowed is due',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    for (final r in reminders) {
      final when = tz.TZDateTime(tz.local, r.due.year, r.due.month, r.due.day, 9);
      if (when.isBefore(now)) continue;
      await _plugin.zonedSchedule(
        id: _dharIdBase + (r.id % _dharIdRange),
        title: r.title,
        body: r.body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
      );
    }
  }

  /// Replaces every pending reminder with the next [_days] evenings.
  ///
  /// [todayBody] is tonight's message, or null to skip tonight (day already settled).
  Future<void> syncReminders({
    required bool enabled,
    required int minutes,
    required String? todayBody,
  }) async {
    for (var i = 0; i < _days; i++) {
      await _plugin.cancel(id: _firstId + i);
    }
    if (!enabled || !await notificationsAllowed()) return;

    final mode = await canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < _days; i++) {
      final when = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, minutes ~/ 60, minutes % 60);
      if (when.isBefore(now)) continue;
      if (i == 0 && todayBody == null) continue;
      await _plugin.zonedSchedule(
        id: _firstId + i,
        title: title,
        body: i == 0 ? todayBody : genericBody,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: mode,
      );
    }
  }
}

/// A reminder for a dhar entry that falls due.
class DharReminder {
  const DharReminder({required this.id, required this.title, required this.body, required this.due});

  final int id;
  final String title;
  final String body;
  final DateTime due;
}

/// "10:00 PM" style label for a reminder time.
String formatReminderTime(BuildContext context, int minutes) {
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);
}
