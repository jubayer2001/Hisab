import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text.dart';
import 'guide_widgets.dart';
import 'tutorials.dart';

class _Slide {
  const _Slide({required this.title, required this.text, required this.tutorial, required this.art});

  final String title;
  final String text;
  final TutorialId tutorial;
  final Widget Function(BuildContext context) art;
}

final List<_Slide> _slides = [
  _Slide(
    title: 'Hisab now speaks Bengali',
    text: 'Tap the language button at the top of Home. You can also make the text bigger in More.',
    tutorial: TutorialId.comfort,
    art: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniLanguagePill(L10n.isBengali ? 'English' : 'বাংলা'),
        const SizedBox(height: 14),
        const MiniHero(big: '৳440', label: 'Spent today'),
      ],
    ),
  ),
  _Slide(
    title: 'Jump to any date',
    text: 'In Reports and History, tap the date to open a small calendar. Pick a day, week, month or year.',
    tutorial: TutorialId.reports,
    art: (c) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [MiniSeg(labels: ['Day', 'Week', 'Month', 'Year'], on: 1), MiniCalendar()],
    ),
  ),
  _Slide(
    title: 'See what each category cost',
    text: 'Tap the wheel or a category in Reports to list everything you spent on it.',
    tutorial: TutorialId.reports,
    art: (c) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniDonut(size: 100),
        MiniRow(color: Color(0xFFC08457), icon: Icons.home_rounded, title: 'Rent', trailing: '৳5,500 · 39%'),
      ],
    ),
  ),
  _Slide(
    title: 'Your savings goals on Home',
    text: 'Create a goal and its progress shows on Home.',
    tutorial: TutorialId.goals,
    art: (c) => const MiniGoal(),
  ),
  _Slide(
    title: 'Make Home your own',
    text: 'Hide the notices you do not need, or choose one extra detail beside "Spent today".',
    tutorial: TutorialId.comfort,
    art: (c) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniToggleRow('Show notices on Home', on: false),
        SizedBox(height: 8),
        MiniHero(big: '৳440', slotLabel: 'This week', slotValue: '৳1,240'),
      ],
    ),
  ),
];

/// Shown once after an update: the main new things, one card each, with a link to watch how.
class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.hisab;
    final last = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "What's new in Hisab 2.0",
                      style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Close'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The pictures are small mock screens: keep them at the normal text size.
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: slide.art(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(slide.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(slide.text, style: theme.textTheme.bodyLarge?.copyWith(color: colors.muted)),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => context.push('/tutorial?ids=${tutorialCode(slide.tutorial)}'),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Watch how'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  if (!last) TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Skip')),
                  Expanded(
                    child: FilledButton(onPressed: _next, child: Text(last ? 'Got it' : 'Next')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
