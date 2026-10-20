import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in main() and injected with an override.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// The nightly reminder: on or off, and the time of day in minutes after midnight.
class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.minutes});

  static const defaultMinutes = 22 * 60; // 10:00 PM

  final bool enabled;
  final int minutes;

  TimeOfDay get time => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  ReminderSettings copyWith({bool? enabled, int? minutes}) =>
      ReminderSettings(enabled: enabled ?? this.enabled, minutes: minutes ?? this.minutes);
}

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _enabledKey = 'reminderEnabled';
  static const _minutesKey = 'reminderMinutes';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      minutes: prefs.getInt(_minutesKey) ?? ReminderSettings.defaultMinutes,
    );
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    ref.read(sharedPrefsProvider).setBool(_enabledKey, value);
  }

  void setTime(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    state = state.copyWith(minutes: minutes);
    ref.read(sharedPrefsProvider).setInt(_minutesKey, minutes);
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(ReminderSettingsNotifier.new);

/// Remembers that the notification permission question was already shown once.
const reminderPermissionAskedKey = 'reminderPermissionAsked';
