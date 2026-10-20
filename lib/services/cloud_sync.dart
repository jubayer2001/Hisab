import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings_providers.dart';
import '../data/backup.dart';
import '../data/backup_actions.dart';
import '../data/providers.dart';
import 'cloud_backup.dart';

enum CloudStatus {
  /// Nothing is happening.
  idle,

  /// A backup or restore is in progress.
  working,

  /// There is something to back up but the phone is offline. It is tried again later.
  waiting,

  /// Google no longer accepts the saved sign-in.
  needsSignIn,

  /// Something else went wrong. See [CloudSyncState.message].
  failed,
}

class CloudSyncState {
  const CloudSyncState({
    this.email,
    this.auto = true,
    this.lastBackup,
    this.status = CloudStatus.idle,
    this.message,
  });

  /// The Google account the data is backed up to. Null when nobody is signed in.
  final String? email;

  /// Whether changes are backed up on their own.
  final bool auto;

  /// When the cloud copy was last saved from this phone.
  final DateTime? lastBackup;

  final CloudStatus status;
  final String? message;

  bool get signedIn => email != null;

  CloudSyncState copyWith({
    String? email,
    bool clearEmail = false,
    bool? auto,
    DateTime? lastBackup,
    CloudStatus? status,
    String? message,
    bool clearMessage = false,
  }) =>
      CloudSyncState(
        email: clearEmail ? null : (email ?? this.email),
        auto: auto ?? this.auto,
        lastBackup: lastBackup ?? this.lastBackup,
        status: status ?? this.status,
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// What was found when someone signed in, so the screen can ask what to do about it.
class CloudProbe {
  const CloudProbe({required this.email, required this.cloud, required this.cloudModified, required this.phoneEntries});

  final String email;

  /// The backup already in the person's Google account, or null if there is none.
  final BackupContents? cloud;
  final DateTime? cloudModified;

  /// How many entries are on this phone right now.
  final int phoneEntries;
}

const _emailKey = 'cloudEmail';
const _autoKey = 'cloudAuto';
const _lastKey = 'cloudLastAt';
const _dirtyKey = 'cloudDirty';

/// Keeps a copy of the phone's data in the person's Google account.
///
/// The phone is always the working copy. The app never reads from the cloud while it runs and
/// never needs the internet. Signing in only adds a safety copy that survives deleting the app.
/// Changes are marked, then uploaded when possible: shortly after a change, when the app leaves
/// the screen or comes back, and every few minutes. If the phone is offline the change simply
/// waits, and the mark is saved so it survives closing the app.
class CloudSyncNotifier extends Notifier<CloudSyncState> {
  static const _debounce = Duration(seconds: 20);
  static const _retryEvery = Duration(minutes: 10);

  Timer? _debounceTimer;
  Timer? _retryTimer;
  StreamSubscription<void>? _changes;
  bool _busy = false;

  /// While true, database changes are the app's own restore, not something to upload.
  bool _quiet = false;

  CloudBackupService get _service => ref.read(cloudBackupServiceProvider);

  @override
  CloudSyncState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _retryTimer?.cancel();
      _changes?.cancel();
    });

    final prefs = ref.read(sharedPrefsProvider);
    final email = prefs.getString(_emailKey);
    final ms = prefs.getInt(_lastKey);
    final initial = CloudSyncState(
      email: email,
      auto: prefs.getBool(_autoKey) ?? true,
      lastBackup: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (email != null) {
      // Not inside build(): state is not ready yet.
      Future.microtask(_watch);
    }
    return initial;
  }

  bool get _dirty => ref.read(sharedPrefsProvider).getBool(_dirtyKey) ?? false;

  void _setDirty(bool value) => ref.read(sharedPrefsProvider).setBool(_dirtyKey, value);

  /// Starts noticing changes and retrying. Only while someone is signed in.
  void _watch() {
    _changes?.cancel();
    _changes = ref.read(databaseProvider).tableUpdates().map((_) {}).listen((_) {
      if (_quiet) return;
      _setDirty(true);
      if (state.signedIn && state.auto) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounce, maybeBackup);
      }
    });
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryEvery, (_) => maybeBackup());
    // A change made while offline, or just before the app was closed, is still waiting.
    if (_dirty) _debounceTimer = Timer(const Duration(seconds: 3), maybeBackup);
  }

  void _stopWatching() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _changes?.cancel();
    _changes = null;
  }

  // ---- signing in ---------------------------------------------------------------------

  /// Asks Google for an account, then looks at what is already saved there. Nothing on the
  /// phone or in the cloud is changed yet: the screen shows what was found and asks.
  Future<CloudProbe> signIn() async {
    final email = await _service.signIn();
    try {
      final cloud = await _service.download();
      return CloudProbe(
        email: email,
        cloud: cloud == null ? null : parseBackup(cloud.bytes, currentSchemaVersion: ref.read(databaseProvider).schemaVersion),
        cloudModified: cloud?.modified,
        phoneEntries: await ref.read(backupActionsProvider).entryCount(),
      );
    } on BackupException {
      await _service.signOut();
      rethrow;
    } on CloudException {
      await _service.signOut();
      rethrow;
    }
  }

  /// The person chose the data in their Google account: it replaces what is on the phone.
  Future<void> useCloudData(CloudProbe probe) async {
    final cloud = probe.cloud;
    if (cloud == null) return;
    _quiet = true;
    try {
      await ref.read(backupActionsProvider).restore(cloud);
      // Let the database's change notices (from the restore itself) pass by.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _quiet = false;
    }
    _setDirty(false);
    _link(probe.email, lastBackup: probe.cloudModified);
  }

  /// The person chose the data on this phone: it becomes the cloud copy.
  Future<void> usePhoneData(CloudProbe probe) async {
    _link(probe.email);
    _setDirty(true);
    await backupNow();
  }

  /// Google stopped accepting the saved sign-in: the same account signs in again, nothing else changes.
  Future<void> signInAgain() async {
    final email = await _service.signIn();
    if (email != state.email) {
      await _service.signOut();
      throw CloudException('Please choose ${state.email}, or sign out first to use another account.');
    }
    state = state.copyWith(status: CloudStatus.idle, clearMessage: true);
    _setDirty(true);
    await maybeBackup();
  }

  /// The person backed out after signing in.
  Future<void> cancelSignIn() => _service.signOut();

  void _link(String email, {DateTime? lastBackup}) {
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_emailKey, email);
    prefs.setBool(_autoKey, true);
    if (lastBackup != null) prefs.setInt(_lastKey, lastBackup.millisecondsSinceEpoch);
    state = CloudSyncState(email: email, lastBackup: lastBackup);
    _watch();
  }

  /// Stops backing up and forgets the account on this phone. The data on the phone and the
  /// copy in the cloud both stay as they are.
  Future<void> signOut() async {
    _stopWatching();
    await _service.signOut();
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_emailKey);
    await prefs.remove(_autoKey);
    await prefs.remove(_lastKey);
    await prefs.remove(_dirtyKey);
    state = const CloudSyncState();
  }

  void setAuto(bool value) {
    ref.read(sharedPrefsProvider).setBool(_autoKey, value);
    state = state.copyWith(auto: value);
    if (value && _dirty) maybeBackup();
  }

  // ---- backing up and restoring ---------------------------------------------------------

  /// Backs up if automatic backup is on and something changed since the last one.
  Future<void> maybeBackup() async {
    if (!state.signedIn || !state.auto || !_dirty) return;
    await backupNow(quiet: true);
  }

  /// Saves the phone's data to the cloud now. With [quiet], failures are not shown as errors
  /// (an offline phone just waits).
  Future<void> backupNow({bool quiet = false}) async {
    if (!state.signedIn || _busy) return;
    _busy = true;
    state = state.copyWith(status: CloudStatus.working, clearMessage: true);
    try {
      // Mark clean first: a change made during the upload marks it dirty again.
      _setDirty(false);
      final backup = await ref.read(backupActionsProvider).create();
      final when = await _service.upload(encodeBackup(backup));
      ref.read(sharedPrefsProvider).setInt(_lastKey, when.millisecondsSinceEpoch);
      state = state.copyWith(lastBackup: when, status: CloudStatus.idle, clearMessage: true);
    } on CloudException catch (e) {
      _setDirty(true);
      state = state.copyWith(
        status: e.needsSignIn
            ? CloudStatus.needsSignIn
            : e.offline
                ? CloudStatus.waiting
                : CloudStatus.failed,
        message: e.message,
      );
      if (!quiet && !e.offline && !e.needsSignIn) rethrow;
    } catch (_) {
      _setDirty(true);
      state = state.copyWith(status: CloudStatus.failed, message: 'The backup did not finish. It will be tried again.');
      if (!quiet) rethrow;
    } finally {
      _busy = false;
    }
  }

  /// The backup in the person's Google account, for the screen to show and confirm.
  /// Null if there is none.
  Future<({BackupContents backup, DateTime modified})?> fetchCloud() async {
    state = state.copyWith(status: CloudStatus.working, clearMessage: true);
    try {
      final cloud = await _service.download();
      state = state.copyWith(status: CloudStatus.idle);
      if (cloud == null) return null;
      final backup = parseBackup(cloud.bytes, currentSchemaVersion: ref.read(databaseProvider).schemaVersion);
      return (backup: backup, modified: cloud.modified);
    } on CloudException catch (e) {
      state = state.copyWith(
        status: e.needsSignIn ? CloudStatus.needsSignIn : CloudStatus.idle,
        message: e.needsSignIn ? e.message : null,
      );
      rethrow;
    } on BackupException {
      state = state.copyWith(status: CloudStatus.idle);
      rethrow;
    }
  }

  /// Replaces the phone's data with [backup], which came from [fetchCloud].
  Future<void> restoreFromCloud(BackupContents backup) async {
    _quiet = true;
    try {
      await ref.read(backupActionsProvider).restore(backup);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _quiet = false;
    }
    _setDirty(false);
  }

  /// Something changed that the database's change notices did not announce (for example an
  /// undone erase), so the cloud copy is out of date.
  void markChanged() {
    _setDirty(true);
    if (state.signedIn && state.auto) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounce, maybeBackup);
    }
  }

  /// The app has gone to the background or come back: a good moment to catch up.
  void onLifecycle() => maybeBackup();
}

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncState>(CloudSyncNotifier.new);
