import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/text.dart';
import 'tutorials.dart';

/// More → Help and tutorials: the full tour, what's new, and one tutorial for every feature.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;

    Widget card(List<Widget> rows) => Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(indent: 72, endIndent: 16),
            rows[i],
          ],
        ],
      ),
    );

    Widget row({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Widget? trailing,
      bool strong = false,
    }) => ListTile(
      minTileHeight: 66,
      contentPadding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: strong ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: strong ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: trailing ??
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.play_arrow_rounded, color: theme.colorScheme.onPrimary),
          ),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Help and tutorials')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          card([
            row(
              icon: Icons.school_rounded,
              title: 'Play the full tour',
              subtitle: 'The main things, about 2 minutes',
              strong: true,
              onTap: () => context.push('/tutorial?ids=${tourTutorials.map(tutorialCode).join(',')}&tour=1'),
            ),
            row(
              icon: Icons.auto_awesome_rounded,
              title: "What's new in 2.0",
              subtitle: 'See the latest changes again',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/whats-new'),
            ),
          ]),
          for (var s = 0; s < tutorialSections.length; s++)
            if (tutorialsInSection(s).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(tutorialSections[s], style: theme.textTheme.titleMedium),
              ),
              card([
                for (final t in tutorialsInSection(s))
                  row(
                    icon: t.icon,
                    title: t.title,
                    subtitle: '${t.steps.length} steps · ${t.seconds} seconds',
                    onTap: () => context.push('/tutorial?ids=${tutorialCode(t.id)}'),
                  ),
              ]),
            ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
            child: Text(
              'The ? button in the corner of Reports, History, Budgets, Savings goals, Monthly bills, Dhar and Backup plays that screen\'s tutorial.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
