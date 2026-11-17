import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/text.dart';
import 'tutorials.dart';

/// Offered once to a brand-new user, right after the welcome steps: a quick tour of the main things.
class TourOfferScreen extends StatelessWidget {
  const TourOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(30)),
                  child: Icon(Icons.school_rounded, size: 56, color: scheme.onPrimary),
                ),
                const SizedBox(height: 20),
                Text('Welcome to Hisab', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(
                  'Take a quick tour of the main things. It takes about 2 minutes and you can pause any time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: context.hisab.muted, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Show me around'),
                    onPressed: () =>
                        context.pushReplacement('/tutorial?ids=${tourTutorials.map(tutorialCode).join(',')}&tour=1'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Not now')),
                const SizedBox(height: 10),
                Text(
                  'You can watch any tutorial later in More → Help and tutorials.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.hisab.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
