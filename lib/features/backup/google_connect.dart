import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/backup.dart';
import '../../services/cloud_backup.dart';
import '../../services/cloud_sync.dart';

/// What came of asking someone to sign in with Google.
enum GoogleConnectResult {
  /// They did not finish (cancelled, offline, or chose to back out).
  none,

  /// Signed in, and the phone's data is now being backed up to their account.
  linked,

  /// Signed in, and the data from their Google account was brought onto the phone.
  restored,
}

String _when(DateTime? d) => d == null ? '' : DateFormat('d MMM y').format(d);

String _entries(int n) => n == 1 ? '1 entry' : '$n entries';

/// The whole sign-in conversation: Google's own screens, then (if there is already a backup in
/// the account) a question about which data to keep. Nothing is replaced without being asked.
///
/// With [quiet] the success messages are left out (the welcome screen shows its own, and a
/// message there would cover the "Get started" button). Problems are always shown.
Future<GoogleConnectResult> connectGoogle(BuildContext context, WidgetRef ref, {bool quiet = false}) async {
  final sync = ref.read(cloudSyncProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  void sayDone(String text) {
    if (!quiet) say(text);
  }

  final CloudProbe probe;
  try {
    probe = await sync.signIn();
  } on CloudException catch (e) {
    say(e.message);
    return GoogleConnectResult.none;
  } on BackupException catch (e) {
    say(e.message);
    return GoogleConnectResult.none;
  }
  if (!context.mounted) {
    await sync.cancelSignIn();
    return GoogleConnectResult.none;
  }

  // Nothing in the account yet: this phone's data becomes the first backup.
  final cloud = probe.cloud;
  if (cloud == null) {
    await sync.usePhoneData(probe);
    sayDone('Signed in as ${probe.email}. Your data is being backed up.');
    return GoogleConnectResult.linked;
  }

  final choice = await showDialog<_Choice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ChoiceDialog(probe: probe, cloud: cloud),
  );

  switch (choice) {
    case _Choice.cloud:
      try {
        await sync.useCloudData(probe);
      } on BackupException catch (e) {
        await sync.cancelSignIn();
        say(e.message);
        return GoogleConnectResult.none;
      }
      say('Restored ${_entries(cloud.entryCount)} from your Google account.');
      return GoogleConnectResult.restored;
    case _Choice.phone:
      await sync.usePhoneData(probe);
      sayDone('Signed in as ${probe.email}. This phone\'s data is being backed up.');
      return GoogleConnectResult.linked;
    case _Choice.cancel:
    case null:
      await sync.cancelSignIn();
      return GoogleConnectResult.none;
  }
}

enum _Choice { cloud, phone, cancel }

class _ChoiceDialog extends StatelessWidget {
  const _ChoiceDialog({required this.probe, required this.cloud});

  final CloudProbe probe;
  final BackupContents cloud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final phoneEmpty = probe.phoneEntries == 0;
    final cloudLine = 'Google account: ${_entries(cloud.entryCount)}'
        '${probe.cloudModified == null ? '' : ', saved ${_when(probe.cloudModified)}'}';

    return AlertDialog(
      title: Text(phoneEmpty ? 'Welcome back' : 'Which data do you want?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phoneEmpty
              ? 'There is already a Hisab backup in ${probe.email}.'
              : 'There is already a Hisab backup in ${probe.email}, and this phone has data too.'),
          const SizedBox(height: 12),
          Text(cloudLine, style: theme.textTheme.titleSmall),
          Text('This phone: ${_entries(probe.phoneEntries)}', style: theme.textTheme.titleSmall),
          if (!phoneEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Whichever you choose replaces the other. The two are not mixed.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _Choice.cancel), child: const Text('Cancel')),
        if (!phoneEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, _Choice.phone),
            child: const Text('Use this phone'),
          ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, _Choice.cloud),
          child: Text(phoneEmpty ? 'Restore my data' : 'Use Google account'),
        ),
      ],
    );
  }
}
