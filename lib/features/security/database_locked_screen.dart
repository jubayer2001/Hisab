import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../data/db/database_security.dart';

/// Shown instead of the app when the encrypted data cannot be opened. This should never happen
/// on a healthy phone. It can follow a reset of the phone's secure storage (for example after the
/// screen lock was removed on some phones). Nothing is guessed or overwritten: the person is told
/// what happened and can either close the app, or choose to start fresh.
class DatabaseLockedApp extends StatelessWidget {
  const DatabaseLockedApp({super.key, required this.databasePath, required this.reason});

  final String databasePath;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hisab',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: _LockedScreen(databasePath: databasePath, reason: reason),
    );
  }
}

class _LockedScreen extends StatefulWidget {
  const _LockedScreen({required this.databasePath, required this.reason});

  final String databasePath;
  final String reason;

  @override
  State<_LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<_LockedScreen> {
  bool _done = false;

  Future<void> _startFresh() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete the locked data?'),
        content: const Text(
          'This permanently deletes the data on this phone that Hisab cannot open. If you signed in with Google or saved a backup file, you can restore from it afterwards. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.hisab.spending, minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete and start fresh'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    deleteDatabaseFiles(widget.databasePath);
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline_rounded, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(_done ? 'Ready to start fresh' : 'Hisab cannot open your data', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                _done
                    ? 'The locked data was deleted. Close Hisab and open it again. On the welcome screen you can restore from Google, or from a backup file you saved.'
                    : 'Your data is encrypted to keep it private, and the key that opens it is no longer available on this phone. Nothing has been changed or deleted. If you signed in with Google or saved a backup file, you can start fresh and restore from it.',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 8),
              Text(widget.reason, style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
              const Spacer(),
              if (_done)
                FilledButton(onPressed: () => SystemNavigator.pop(), child: const Text('Close Hisab'))
              else ...[
                FilledButton(onPressed: () => SystemNavigator.pop(), child: const Text('Close Hisab')),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                  onPressed: _startFresh,
                  child: Text('Delete locked data and start fresh', style: TextStyle(color: colors.spending)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
