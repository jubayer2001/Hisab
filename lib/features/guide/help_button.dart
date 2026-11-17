import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../l10n/text.dart';
import 'tutorials.dart';

/// The ? button in the corner of a feature's screen: plays that feature's tutorial.
class HelpButton extends StatelessWidget {
  const HelpButton(this.id, {super.key});

  final TutorialId id;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr('Help'),
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => context.push('/tutorial?ids=${tutorialCode(id)}'),
    );
  }
}
