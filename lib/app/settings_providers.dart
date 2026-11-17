import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/logic/home_logic.dart' show HomeDetail;
import '../l10n/l10n.dart';
import 'version.dart';

/// Loaded once in main() and injected with an override.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  /// Saved as fixed words, not as the enum's own name: a release build scrambles code names
  /// (--obfuscate), and a saved setting must mean the same thing in every build.
  static const _codes = {ThemeMode.system: 'system', ThemeMode.light: 'light', ThemeMode.dark: 'dark'};

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPrefsProvider).getString(_key);
    return _codes.entries.firstWhere((e) => e.value == saved, orElse: () => const MapEntry(ThemeMode.system, 'system')).key;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, _codes[mode]!);
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

/// The cards Home can show above the summary and below it. Each can be hidden on its own.
enum HomeNotice { backup, income, budget, bills }

/// Which Home notices are visible. They are all hidden until [enabled] is switched on in
/// More; the per-kind choices are remembered for when it is.
class HomeNotices {
  const HomeNotices({required this.enabled, required this.kinds});

  final bool enabled;
  final Set<HomeNotice> kinds;

  bool shows(HomeNotice kind) => enabled && kinds.contains(kind);

  HomeNotices copyWith({bool? enabled, Set<HomeNotice>? kinds}) =>
      HomeNotices(enabled: enabled ?? this.enabled, kinds: kinds ?? this.kinds);
}

class HomeNoticesNotifier extends Notifier<HomeNotices> {
  static const _enabledKey = 'homeNotices';

  /// Fixed words rather than enum names, so a saved choice survives obfuscated release builds.
  static const _keys = {
    HomeNotice.backup: 'homeNoticeBackup',
    HomeNotice.income: 'homeNoticeIncome',
    HomeNotice.budget: 'homeNoticeBudget',
    HomeNotice.bills: 'homeNoticeBills',
  };

  @override
  HomeNotices build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return HomeNotices(
      enabled: prefs.getBool(_enabledKey) ?? false,
      kinds: {
        for (final e in _keys.entries)
          if (prefs.getBool(e.value) ?? true) e.key,
      },
    );
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    ref.read(sharedPrefsProvider).setBool(_enabledKey, value);
  }

  void setKind(HomeNotice kind, bool value) {
    final kinds = {...state.kinds};
    value ? kinds.add(kind) : kinds.remove(kind);
    state = state.copyWith(kinds: kinds);
    ref.read(sharedPrefsProvider).setBool(_keys[kind]!, value);
  }
}

final homeNoticesProvider = NotifierProvider<HomeNoticesNotifier, HomeNotices>(
  HomeNoticesNotifier.new,
);

/// What the user wants beside "Spent today" on Home. The default, nothing, leaves Home as it was.
class HomeDetailNotifier extends Notifier<HomeDetail> {
  static const _key = 'homeDetail';

  /// Fixed words rather than enum names, so a saved choice survives obfuscated release builds.
  static const _codes = {
    HomeDetail.none: 'none',
    HomeDetail.budget: 'budget',
    HomeDetail.week: 'week',
    HomeDetail.average: 'average',
    HomeDetail.bill: 'bill',
  };

  @override
  HomeDetail build() {
    final saved = ref.watch(sharedPrefsProvider).getString(_key);
    return _codes.entries.firstWhere((e) => e.value == saved, orElse: () => const MapEntry(HomeDetail.none, 'none')).key;
  }

  void set(HomeDetail detail) {
    state = detail;
    ref.read(sharedPrefsProvider).setString(_key, _codes[detail]!);
  }
}

final homeDetailProvider = NotifierProvider<HomeDetailNotifier, HomeDetail>(HomeDetailNotifier.new);

/// English or Bengali. Saved as fixed words, like the other settings.
class LanguageNotifier extends Notifier<AppLanguage> {
  static const _key = 'language';

  @override
  AppLanguage build() {
    final language = ref.watch(sharedPrefsProvider).getString(_key) == 'bn' ? AppLanguage.bn : AppLanguage.en;
    L10n.setLanguage(language);
    return language;
  }

  void set(AppLanguage language) {
    L10n.setLanguage(language);
    state = language;
    ref.read(sharedPrefsProvider).setString(_key, language == AppLanguage.bn ? 'bn' : 'en');
  }

  void toggle() => set(state == AppLanguage.bn ? AppLanguage.en : AppLanguage.bn);
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

/// How big the text is everywhere: 1 (normal), 1.25 (large) or 1.5 (extra large).
class TextSizeNotifier extends Notifier<double> {
  static const _key = 'textSize';
  static const options = [1.0, 1.25, 1.5];

  @override
  double build() {
    final saved = ref.watch(sharedPrefsProvider).getDouble(_key);
    return options.contains(saved) ? saved! : 1.0;
  }

  void set(double value) {
    state = value;
    ref.read(sharedPrefsProvider).setDouble(_key, value);
  }
}

final textSizeProvider = NotifierProvider<TextSizeNotifier, double>(TextSizeNotifier.new);

/// In Bengali: show Bengali digits (১২৩, the default) or English ones (123).
class BengaliDigitsNotifier extends Notifier<bool> {
  static const _key = 'bengaliDigits';

  @override
  bool build() {
    final on = ref.watch(sharedPrefsProvider).getBool(_key) ?? true;
    L10n.setBengaliDigits(on);
    return on;
  }

  void set(bool value) {
    L10n.setBengaliDigits(value);
    state = value;
    ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final bengaliDigitsProvider = NotifierProvider<BengaliDigitsNotifier, bool>(BengaliDigitsNotifier.new);

/// Remembers that the notification permission question was already shown once.
const reminderPermissionAskedKey = 'reminderPermissionAsked';

/// The version whose "what's new" this phone has already shown, as `2.0.0+15`. Missing on an
/// install that was updated from an older version.
const lastSeenVersionKey = 'lastSeenVersion';

/// Set when the welcome steps have just been finished: the next screen offers the quick tour.
const tourPendingKey = 'tourPending';

/// The running version, the way [lastSeenVersionKey] stores it.
const currentVersionLabel = '$appVersion+$appBuildNumber';

/// True once the welcome screens have been completed or skipped.
const onboardingDoneKey = 'onboardingDone';

class OnboardingDoneNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(onboardingDoneKey) ?? false;

  void finish() {
    state = true;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setBool(onboardingDoneKey, true);
    // A brand-new user is offered the quick tour (not "what's new", which is for people updating).
    prefs.setString(lastSeenVersionKey, currentVersionLabel);
    prefs.setBool(tourPendingKey, true);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDoneNotifier, bool>(OnboardingDoneNotifier.new);

/// The name shown in the Home greeting. Empty when the user did not give one.
class UserNameNotifier extends Notifier<String> {
  static const _key = 'userName';

  @override
  String build() => ref.watch(sharedPrefsProvider).getString(_key) ?? '';

  void set(String name) {
    final clean = name.trim();
    state = clean;
    ref.read(sharedPrefsProvider).setString(_key, clean);
  }
}

final userNameProvider = NotifierProvider<UserNameNotifier, String>(UserNameNotifier.new);

/// When the last backup file was saved (millisecondsSinceEpoch), or null if never.
class LastBackupNotifier extends Notifier<DateTime?> {
  static const _key = 'lastBackupAt';

  @override
  DateTime? build() {
    final ms = ref.watch(sharedPrefsProvider).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void markNow() {
    final now = DateTime.now();
    state = now;
    ref.read(sharedPrefsProvider).setInt(_key, now.millisecondsSinceEpoch);
  }
}

final lastBackupProvider = NotifierProvider<LastBackupNotifier, DateTime?>(LastBackupNotifier.new);
