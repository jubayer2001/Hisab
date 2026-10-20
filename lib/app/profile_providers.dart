import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../services/cloud_backup.dart';
import '../services/cloud_sync.dart';
import 'settings_providers.dart';
import 'theme.dart';

/// The colours the profile icon can have. The first is the app's own teal; the rest come
/// from the category palette so they already match the rest of the app.
const profileColors = <Color>[
  TealMist.primary,
  CategoryColors.transport,
  CategoryColors.bills,
  CategoryColors.shopping,
  CategoryColors.food,
  CategoryColors.bazar,
];

class ProfileColorNotifier extends Notifier<int> {
  static const _key = 'profileColor';

  @override
  int build() {
    final saved = ref.watch(sharedPrefsProvider).getInt(_key) ?? 0;
    return saved >= 0 && saved < profileColors.length ? saved : 0;
  }

  void set(int index) {
    state = index;
    ref.read(sharedPrefsProvider).setInt(_key, index);
  }
}

final profileColorProvider = NotifierProvider<ProfileColorNotifier, int>(ProfileColorNotifier.new);

/// Where the person's data is safe, shown as a small badge on the profile icon.
enum BackupBadge {
  /// Google backup is not part of this build, so there is nothing to show.
  none,

  /// Not signed in: the data exists only on this phone.
  unprotected,

  /// Signed in and the cloud copy is up to date.
  protectedByGoogle,

  /// Signed in, but the latest changes could not be uploaded yet.
  waiting,
}

final backupBadgeProvider = Provider<BackupBadge>((ref) {
  if (!ref.watch(cloudBackupServiceProvider).isConfigured) return BackupBadge.none;
  final cloud = ref.watch(cloudSyncProvider);
  if (!cloud.signedIn) return BackupBadge.unprotected;
  switch (cloud.status) {
    case CloudStatus.waiting:
    case CloudStatus.failed:
    case CloudStatus.needsSignIn:
      return BackupBadge.waiting;
    case CloudStatus.idle:
    case CloudStatus.working:
      return BackupBadge.protectedByGoogle;
  }
});

/// "Not now" on the Home reminder hides it for this long.
const cloudNudgeSnooze = Duration(days: 7);

class CloudNudgeNotifier extends Notifier<DateTime?> {
  static const _key = 'cloudNudgeUntil';

  @override
  DateTime? build() {
    final ms = ref.watch(sharedPrefsProvider).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void snooze() {
    final until = DateTime.now().add(cloudNudgeSnooze);
    state = until;
    ref.read(sharedPrefsProvider).setInt(_key, until.millisecondsSinceEpoch);
  }
}

final cloudNudgeProvider = NotifierProvider<CloudNudgeNotifier, DateTime?>(CloudNudgeNotifier.new);

/// Whether Home should show the card asking to sign in: only when signing in is possible,
/// nobody is signed in, there is something worth protecting, and it was not dismissed lately.
final showCloudNudgeProvider = Provider<bool>((ref) {
  if (ref.watch(backupBadgeProvider) != BackupBadge.unprotected) return false;
  final entries = ref.watch(allEntriesProvider).value ?? const [];
  if (entries.isEmpty) return false;
  final until = ref.watch(cloudNudgeProvider);
  return until == null || DateTime.now().isAfter(until);
});
