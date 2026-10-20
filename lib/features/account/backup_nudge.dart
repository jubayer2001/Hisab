import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/profile_providers.dart';
import '../../app/theme.dart';
import '../backup/google_connect.dart';

/// A gentle card on Home for someone who has data but no Google backup. "Not now" hides it
/// for a week; the amber badge on the profile icon stays until they sign in.
class BackupNudge extends ConsumerWidget {
  const BackupNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.hisab;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      decoration: BoxDecoration(
        color: colors.highlight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.cloud_off_rounded, color: colors.highlight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your data is only on this phone', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Delete the app and it is gone. Sign in with Google to keep a safe copy.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => connectGoogle(context, ref),
                      child: const Text('Sign in'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: colors.muted),
                      onPressed: () => ref.read(cloudNudgeProvider.notifier).snooze(),
                      child: const Text('Not now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
