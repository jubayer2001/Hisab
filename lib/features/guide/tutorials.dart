// ignore_for_file: sort_child_properties_last
import 'package:flutter/material.dart' hide Text;

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text.dart';
import 'guide_widgets.dart';

enum TutorialId { add, home, history, reports, budgets, goals, recurring, dhar, backup, comfort }

/// One step: a sentence, and the mini screen it is about (the finger presses the [TapSpot] in it).
class TutorialStep {
  const TutorialStep(this.caption, this.scene);

  final String caption;
  final Widget Function(BuildContext context) scene;
}

class Tutorial {
  const Tutorial({required this.id, required this.title, required this.icon, required this.section, required this.steps});

  final TutorialId id;
  final String title;
  final IconData icon;

  /// Index into [tutorialSections].
  final int section;
  final List<TutorialStep> steps;

  /// How long one step is shown, seconds.
  static const stepSeconds = 5;

  int get seconds => steps.length * stepSeconds;
}

const tutorialSections = [
  'Getting started',
  'Look back',
  'Plan ahead',
  'Money with people',
  'Keep it safe',
  'Make it yours',
];

/// The quick tour offered to a new user: the four main things.
const tourTutorials = [TutorialId.add, TutorialId.home, TutorialId.history, TutorialId.reports];

const _homeStats = [('This month', '৳5,582'), ('Income', '৳5,602'), ('Balance', '৳20')];
const _food = Color(0xFFF29E4C);
const _bus = Color(0xFF4C8DF6);
const _bills = Color(0xFF9B7BE0);

Widget _lunch({bool tap = false}) =>
    MiniRow(color: _food, icon: Icons.restaurant_rounded, title: 'Lunch', subtitle: 'Food · Cash', trailing: '−৳380', tap: tap);

Widget _rickshaw() =>
    const MiniRow(color: _bus, icon: Icons.directions_bus_rounded, title: 'Rickshaw', subtitle: 'Transport · Cash', trailing: '−৳60');

Widget _amount(BuildContext context, {double size = 38}) => Center(
  child: Text(
    '৳380',
    style: Theme.of(context).textTheme.displaySmall?.copyWith(
      color: context.hisab.spending,
      fontWeight: FontWeight.w700,
      fontSize: size,
    ),
  ),
);

final List<Tutorial> tutorials = [
  Tutorial(
    id: TutorialId.add,
    title: 'Add an expense or income',
    icon: Icons.add_rounded,
    section: 0,
    steps: [
      TutorialStep(
        'Tap the + button at the bottom of the screen.',
        (c) => const MiniScene(
          children: [MiniHero(big: '৳0', stats: _homeStats), MiniChips(['Tea ৳20', 'Rickshaw ৳60'])],
          nav: MiniNav(on: 0, tap: 'add'),
        ),
      ),
      TutorialStep(
        'Type the amount, then choose what it was for.',
        (c) => MiniScene(
          children: [
            const MiniTitle('New expense'),
            _amount(c),
            const MiniCategoryGrid(tapIndex: 0),
            const MiniChips(['Today', 'Cash', 'Note (optional)']),
          ],
        ),
      ),
      TutorialStep(
        'Tap Save. It shows on Home straight away.',
        (c) => MiniScene(
          children: [const MiniTitle('New expense'), _amount(c, size: 32), const MiniKeys(), const MiniButton('Save ৳380', tap: true)],
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.home,
    title: 'Understand the Home page',
    icon: Icons.home_rounded,
    section: 0,
    steps: [
      TutorialStep(
        'The big number is what you spent today.',
        (c) => MiniScene(
          children: [const MiniHero(big: '৳440', stats: _homeStats, tapBig: true), _lunch(), _rickshaw()],
          nav: const MiniNav(on: 0),
        ),
      ),
      TutorialStep(
        'Tap Income or Balance to see where the money comes from.',
        (c) => const MiniScene(children: [MiniHero(big: '৳440', stats: _homeStats, tapStat: 1)], nav: MiniNav(on: 0)),
      ),
      TutorialStep(
        'Repeat something you buy often with a single tap.',
        (c) => const MiniScene(
          children: [MiniHero(big: '৳0'), MiniChips(['Tea ৳20', 'Rickshaw ৳60'], tapIndex: 0)],
          nav: MiniNav(on: 0),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.history,
    title: 'Look back in History',
    icon: Icons.receipt_long_rounded,
    section: 1,
    steps: [
      TutorialStep(
        'Search by note, category or amount.',
        (c) => MiniScene(
          children: [const MiniTitle('History'), const MiniField('Search note, category or amount', '', tap: true), _lunch(), _rickshaw()],
          nav: const MiniNav(on: 1),
        ),
      ),
      TutorialStep(
        'Choose Day, Week, Month or Year, then tap the date to pick any date from a calendar.',
        (c) => MiniScene(
          children: [
            const MiniTitle('History'),
            const MiniSeg(labels: ['All', 'Day', 'Week', 'Month', 'Year'], on: 3),
            const SizedBox(height: 6),
            const MiniDatePill('This month', tap: true),
            _lunch(),
          ],
          nav: const MiniNav(on: 1),
        ),
      ),
      TutorialStep(
        'Swipe an entry to delete it. You can always press Undo.',
        (c) => MiniScene(
          children: [const MiniTitle('History'), _lunch(tap: true), _rickshaw()],
          nav: const MiniNav(on: 1),
          overlay: const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 60), child: MiniToast('Entry deleted', 'Undo'))),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.reports,
    title: 'Read your Reports',
    icon: Icons.insert_chart_rounded,
    section: 1,
    steps: [
      TutorialStep(
        'Switch between Day, Week, Month and Year. Use the arrows to go back.',
        (c) => const MiniScene(
          children: [MiniTitle('Reports'), MiniSeg(labels: ['Day', 'Week', 'Month', 'Year'], on: 2, tapIndex: 1), SizedBox(height: 6), MiniHero(label: 'Spent', big: '৳14,240')],
          nav: MiniNav(on: 3),
        ),
      ),
      TutorialStep(
        'Tap the wheel or any category to see everything you spent on it.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Where it went'),
            MiniDonut(tap: true),
            MiniRow(color: Color(0xFFC08457), icon: Icons.home_rounded, title: 'Rent', trailing: '৳5,500 · 39%'),
            MiniRow(color: Color(0xFF78B159), icon: Icons.shopping_cart_rounded, title: 'Bazar', trailing: '৳2,390 · 17%'),
          ],
        ),
      ),
      TutorialStep(
        'Tap the date with the calendar icon to jump to a day, week, month or year.',
        (c) => const MiniScene(
          children: [MiniTitle('Go to date'), MiniSeg(labels: ['Day', 'Week', 'Month', 'Year'], on: 1), MiniCalendar(tapDay: 11)],
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.budgets,
    title: 'Set a budget',
    icon: Icons.speed_rounded,
    section: 2,
    steps: [
      TutorialStep(
        'Open More, then Budgets, and set how much you want to spend each month.',
        (c) => const MiniScene(
          children: [MiniTitle('Budgets'), MiniField('Spend at most, each month', '৳30,000'), MiniButton('Set monthly budget', tap: true)],
          nav: MiniNav(on: 4),
        ),
      ),
      TutorialStep(
        'Home shows how much you can spend each day to stay on budget.',
        (c) => const MiniScene(
          children: [MiniHero(big: '৳440', slotLabel: 'Daily allowance', slotValue: '৳1,253 / day', tapSlot: true)],
          nav: MiniNav(on: 0),
        ),
      ),
      TutorialStep(
        'At 80% you get a gentle warning, so you can slow down.',
        (c) => MiniScene(
          children: [
            const MiniHero(big: '৳440'),
            MiniNote(icon: Icons.warning_amber_rounded, color: c.hisab.highlight, text: 'Your monthly budget is 82% used', tap: true),
          ],
          nav: const MiniNav(on: 0),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.goals,
    title: 'Save for a goal',
    icon: Icons.savings_rounded,
    section: 2,
    steps: [
      TutorialStep(
        'Create a goal: give it a name, a target and, if you like, a date.',
        (c) => const MiniScene(
          children: [
            MiniTitle('New savings goal'),
            MiniField('What are you saving for?', 'New laptop'),
            MiniField('Target amount', '৳60,000'),
            MiniField('Deadline (optional)', 'Mar 2027'),
            MiniButton('Save', tap: true),
          ],
        ),
      ),
      TutorialStep(
        'Tap Add money whenever you set some aside.',
        (c) => const MiniScene(
          children: [MiniTitle('New laptop'), MiniGoal(), MiniButton('Add money', tap: true), MiniButton('Take out', tonal: true)],
        ),
      ),
      TutorialStep(
        'Your goals appear on Home, so you always see your progress.',
        (c) => MiniScene(
          children: [
            const MiniHero(big: '৳440'),
            Padding(padding: const EdgeInsets.only(top: 12), child: Text('Savings goals', style: Theme.of(c).textTheme.titleMedium)),
            const MiniGoal(tap: true),
          ],
          nav: const MiniNav(on: 0),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.recurring,
    title: 'Monthly bills and income',
    icon: Icons.event_repeat_rounded,
    section: 2,
    steps: [
      TutorialStep(
        'Add things that repeat every month, such as rent or salary.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Monthly bills & income'),
            MiniRow(color: Color(0xFFC08457), icon: Icons.home_rounded, title: 'House rent', subtitle: 'Day 8', trailing: '৳5,500'),
            MiniRow(color: Color(0xFF2E9E6B), icon: Icons.payments_rounded, title: 'Salary', subtitle: 'Day 1', trailing: '+৳45,000', trailingColor: Color(0xFF2E9E6B)),
            MiniButton('New monthly item', tap: true),
          ],
          nav: MiniNav(on: 4),
        ),
      ),
      TutorialStep(
        'When a bill is due, Home asks you to confirm it.',
        (c) => const MiniScene(
          children: [MiniHero(big: '৳0'), MiniNote(icon: Icons.receipt_long_rounded, color: _bills, text: 'Internet bill · due today', action: 'Add', tap: true)],
          nav: MiniNav(on: 0),
        ),
      ),
      TutorialStep(
        'Monthly income can add itself on its day. You can always change it.',
        (c) => MiniScene(
          children: [
            const MiniHero(big: '৳0'),
            MiniNote(icon: Icons.payments_outlined, color: c.hisab.income, text: 'Monthly income ৳45,000 added', action: 'Change', tap: true),
          ],
          nav: const MiniNav(on: 0),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.dhar,
    title: 'Dhar: money lent or borrowed',
    icon: Icons.handshake_rounded,
    section: 3,
    steps: [
      TutorialStep(
        'Write down money you lent or borrowed, and who it is with.',
        (c) => const MiniScene(
          children: [
            MiniTitle('New dhar entry'),
            MiniSeg(labels: ['I lent', 'I borrowed'], on: 0),
            MiniField('Who did you lend to?', 'Rahim'),
            MiniField('Amount', '৳2,000'),
            MiniButton('Save ৳2,000', tap: true),
          ],
        ),
      ),
      TutorialStep(
        'When some of it comes back, tap Money received and enter the part.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Dhar'),
            MiniRow(color: _food, icon: Icons.handshake_rounded, title: 'Rahim', subtitle: 'You lent ৳2,000', trailing: '৳2,000'),
            MiniButton('Money received', tap: true),
          ],
        ),
      ),
      TutorialStep(
        'Add a due date and the app reminds you.',
        (c) => MiniScene(
          children: [
            const MiniHero(big: '৳0'),
            MiniNote(icon: Icons.handshake_outlined, color: c.hisab.highlight, text: 'Dhar due: Rahim', tap: true),
          ],
          nav: const MiniNav(on: 0),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.backup,
    title: 'Keep your data safe',
    icon: Icons.cloud_sync_rounded,
    section: 4,
    steps: [
      TutorialStep(
        'Sign in with Google to keep a private backup that restores your data on a new phone.',
        (c) => MiniScene(
          children: [
            const MiniTitle('Backup and export'),
            MiniNote(icon: Icons.cloud_off_rounded, color: c.hisab.highlight, text: 'Your data is only on this phone'),
            const MiniButton('Sign in with Google', tap: true),
          ],
          nav: const MiniNav(on: 4),
        ),
      ),
      TutorialStep(
        'You can also save a backup file yourself at any time.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Backup and export'),
            MiniButton('Save a backup file', tap: true),
            MiniButton('Export to CSV', tonal: true),
            MiniButton('Restore from a file', tonal: true),
          ],
        ),
      ),
      TutorialStep(
        'To restore, pick the file. Nothing is replaced until you confirm.',
        (c) => MiniScene(
          children: const [MiniTitle('Restore from a file')],
          overlay: MiniSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Replace your data?', style: Theme.of(c).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Restoring replaces everything on this phone with it. This cannot be undone.', style: Theme.of(c).textTheme.bodySmall),
                const MiniButton('Replace', tap: true),
                const MiniButton('Cancel', tonal: true),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
  Tutorial(
    id: TutorialId.comfort,
    title: 'Make the app easier to read',
    icon: Icons.format_size_rounded,
    section: 5,
    steps: [
      TutorialStep(
        'Tap the language button at the top of Home to change the language. One tap switches it back.',
        (c) => MiniScene(
          children: [
            Row(
              children: [
                Expanded(child: Text('Tuesday, 17 November', style: Theme.of(c).textTheme.bodySmall)),
                MiniLanguagePill(L10n.isBengali ? 'English' : 'বাংলা', tap: true),
              ],
            ),
            const SizedBox(height: 10),
            const MiniHero(big: '৳440', stats: _homeStats),
          ],
          nav: const MiniNav(on: 0),
        ),
      ),
      TutorialStep(
        'In More, choose a bigger text size if small letters are hard to read.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Language and text'),
            MiniSeg(labels: ['English', 'বাংলা'], on: 0),
            MiniSeg(labels: ['Normal', 'Large', 'Extra large'], on: 0, tapIndex: 1),
          ],
          nav: MiniNav(on: 4),
        ),
      ),
      TutorialStep(
        'Switch off the notices you do not want to see on Home.',
        (c) => const MiniScene(
          children: [
            MiniTitle('Home notices'),
            MiniToggleRow('Show notices on Home', on: false, tap: true),
            MiniToggleRow('Budget warnings', on: true, dim: true),
            MiniToggleRow('Bills and Dhar due', on: true, dim: true),
          ],
          nav: MiniNav(on: 4),
        ),
      ),
    ],
  ),
];

Tutorial tutorialById(TutorialId id) => tutorials.firstWhere((t) => t.id == id);

List<Tutorial> tutorialsInSection(int section) => [for (final t in tutorials) if (t.section == section) t];

/// Short names used in the address of a tutorial screen, like `/tutorial?ids=add,home`.
const _codes = {
  TutorialId.add: 'add',
  TutorialId.home: 'home',
  TutorialId.history: 'history',
  TutorialId.reports: 'reports',
  TutorialId.budgets: 'budgets',
  TutorialId.goals: 'goals',
  TutorialId.recurring: 'recurring',
  TutorialId.dhar: 'dhar',
  TutorialId.backup: 'backup',
  TutorialId.comfort: 'comfort',
};

String tutorialCode(TutorialId id) => _codes[id]!;

List<TutorialId> tutorialIdsFromCodes(String? codes) {
  final ids = [
    for (final code in (codes ?? '').split(','))
      for (final e in _codes.entries)
        if (e.value == code) e.key,
  ];
  return ids.isEmpty ? [TutorialId.add] : ids;
}
