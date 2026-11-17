import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/app/theme.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/logic/periods.dart';
import 'package:hisab/features/guide/guide_logic.dart';
import 'package:hisab/features/guide/tutorial_player.dart';
import 'package:hisab/features/guide/tutorials.dart';
import 'package:hisab/l10n/l10n.dart';
import 'package:hisab/l10n/text.dart' show LanguageScope;

import 'support/harness.dart';

/// Widget tests do not load the app's fonts, and the stand-in font draws every Bengali letter as a
/// full-width square. Load the real ones so layouts are measured as on a phone.
Future<void> loadAppFonts() async {
  for (final family in ['HindSiliguri', 'NotoSansBengali']) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/$family-$weight.ttf'.replaceAll('HindSiliguri-', 'HindSiliguri-')).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    }
    await loader.load();
  }
}

void main() {
  // ---- the translator ----
  group('Bengali translator', () {
    setUp(() {
      L10n.setLanguage(AppLanguage.bn);
      L10n.setBengaliDigits(true);
    });
    tearDown(() {
      L10n.setLanguage(AppLanguage.en);
      L10n.setBengaliDigits(true);
    });

    test('English is left exactly as it is', () {
      L10n.setLanguage(AppLanguage.en);
      expect(tr('Spent today'), 'Spent today');
      expect(tr('Restored 12 entries.'), 'Restored 12 entries.');
    });

    test('whole texts, then texts with numbers and names inside', () {
      expect(tr('Spent today'), 'আজকের খরচ');
      expect(tr('Restored 12 entries.'), '১২টি এন্ট্রি ফিরিয়ে আনা হয়েছে।');
      // the pieces can change order, and names inside are translated too
      expect(tr('৳5,400 left of ৳30,000 budget'), '৳৩০,০০০ বাজেটের মধ্যে ৳৫,৪০০ বাকি');
      expect(tr('Over your Food budget'), 'আপনার খাবার বাজেট ছাড়িয়ে গেছে');
      expect(tr('Dhar due: Rahim'), 'ধার বাকি: রহিম');
    });

    test('date words become Bengali, and so do the digits', () {
      expect(tr('Tuesday, 17 November'), 'মঙ্গলবার, ১৭ নভেম্বর');
      expect(tr('Sat, 14 Nov 2026'), 'শনি, ১৪ নভেম্বর ২০২৬');
      expect(tr('10:00 PM'), 'বিকাল ১০:০০');
    });

    test('a list and a dotted line are translated piece by piece', () {
      expect(tr('Food · Cash'), 'খাবার · নগদ টাকা');
      expect(tr('12 entries, 2 budgets'), '১২টি এন্ট্রি, ২টি বাজেট');
    });

    test('Bengali or English digits, as the user chooses', () {
      expect(tr('৳1,25,000'), '৳১,২৫,০০০');
      L10n.setBengaliDigits(false);
      expect(tr('Restored 12 entries.'), '12টি এন্ট্রি ফিরিয়ে আনা হয়েছে।');
    });

    test('a text with no translation is shown in English, never blank', () {
      expect(tr('Something nobody translated'), 'Something nobody translated');
      expect(tr(''), '');
    });

    test('leading and trailing spaces are kept', () {
      expect(tr(' entries '), ' টি এন্ট্রি ');
    });
  });

  // ---- the calendar's arithmetic ----
  group('periodOffset', () {
    final today = DateTime(2026, 11, 17); // a Tuesday; the week runs Saturday 14th to Friday 20th

    test('days', () {
      expect(periodOffset(PeriodType.day, today, today), 0);
      expect(periodOffset(PeriodType.day, DateTime(2026, 11, 10), today), -7);
    });

    test('weeks run Saturday to Friday', () {
      expect(periodOffset(PeriodType.week, DateTime(2026, 11, 14), today), 0); // Saturday
      expect(periodOffset(PeriodType.week, DateTime(2026, 11, 13), today), -1); // the Friday before
      expect(periodOffset(PeriodType.week, DateTime(2026, 11, 7), today), -1);
      expect(periodOffset(PeriodType.week, DateTime(2026, 11, 6), today), -2);
    });

    test('months and years', () {
      expect(periodOffset(PeriodType.month, DateTime(2026, 10, 5), today), -1);
      expect(periodOffset(PeriodType.month, DateTime(2025, 11, 30), today), -12);
      expect(periodOffset(PeriodType.year, DateTime(2024, 3, 1), today), -2);
    });

    test('it agrees with shiftPeriod', () {
      for (final type in PeriodType.values) {
        for (final offset in [0, -1, -5, -30]) {
          final period = shiftPeriod(periodFor(type, today), offset);
          expect(periodOffset(type, period.start, today), offset, reason: '$type $offset');
          expect(periodOffset(type, period.end, today), offset, reason: '$type $offset (end)');
        }
      }
    });
  });

  // ---- what to show at start-up ----
  group('guide at start-up', () {
    test('a brand-new user gets the tour, an updated user gets what is new, nobody gets both or neither twice', () {
      expect(decideGuideAction(tourPending: true, lastSeen: currentVersionLabel, current: currentVersionLabel), GuideAction.tour);
      expect(decideGuideAction(tourPending: false, lastSeen: null, current: currentVersionLabel), GuideAction.whatsNew);
      expect(decideGuideAction(tourPending: false, lastSeen: '1.1.0+14', current: currentVersionLabel), GuideAction.whatsNew);
      expect(decideGuideAction(tourPending: false, lastSeen: currentVersionLabel, current: currentVersionLabel), GuideAction.none);
    });

    test('every tutorial has steps, a title and a section, and the codes round-trip', () {
      for (final t in tutorials) {
        expect(t.steps, isNotEmpty);
        expect(t.title, isNotEmpty);
        expect(t.section, inInclusiveRange(0, tutorialSections.length - 1));
        expect(tutorialIdsFromCodes(tutorialCode(t.id)), [t.id]);
      }
      expect(tutorialIdsFromCodes('add,home'), [TutorialId.add, TutorialId.home]);
      expect(tutorialIdsFromCodes('nonsense'), [TutorialId.add]);
      expect(tourTutorials, everyElement(isIn(TutorialId.values)));
    });
  });

  group('on the phone', () {
    late Harness h;
    setUp(() => h = Harness());
    tearDown(() {
      L10n.setLanguage(AppLanguage.en);
      L10n.setBengaliDigits(true);
    });

    String today() => dayKey(DateTime.now());

    testWidgets('the language button switches the whole app and back, and remembers it', (tester) async {
      await h.pumpApp(tester);
      expect(find.text('Spent today'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget); // the button names the other language

      await tester.tap(find.text('বাংলা'));
      await h.settle(tester);
      expect(find.text('আজকের খরচ'), findsOneWidget);
      expect(find.text('Spent today'), findsNothing);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('হোম'), findsOneWidget); // the bottom bar

      await tester.tap(find.text('English'));
      await h.settle(tester);
      expect(find.text('Spent today'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('a saved Bengali choice opens in Bengali, with Bengali digits', (tester) async {
      await h.pumpApp(tester, prefs: {'language': 'bn'});
      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 38000, categoryId: food.id, date: today());
      expect(find.text('৳৩৮০'), findsWidgets);
      expect(find.text('খাবার'), findsWidgets);
      await h.closeApp(tester);
    });

    testWidgets('English digits can be chosen in Bengali', (tester) async {
      await h.pumpApp(tester, prefs: {'language': 'bn', 'bengaliDigits': false});
      final food = await h.category(tester, 'Food');
      await h.addEntry(tester, amount: 38000, categoryId: food.id, date: today());
      expect(find.text('৳380'), findsWidgets);
      await h.closeApp(tester);
    });

    testWidgets('More has the Language and text choices, which are saved', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);
      await tester.scrollUntilVisible(find.text('Language and text'), 300);
      await tester.ensureVisible(find.text('Extra large'));
      await tester.pump();
      await tester.tap(find.text('Extra large'));
      await h.settle(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('textSize'), 1.5);

      await tester.ensureVisible(find.text('বাংলা'));
      await tester.pump();
      await tester.tap(find.text('বাংলা').last);
      await h.settle(tester);
      expect((await SharedPreferences.getInstance()).getString('language'), 'bn');
      await h.closeApp(tester);
    });

    testWidgets('an updated app shows what is new once, then never again', (tester) async {
      await h.pumpApp(tester, guideSeen: false);
      expect(find.text("What's new in Hisab 2.0"), findsOneWidget);
      expect(find.text('Hisab now speaks Bengali'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await h.settle(tester);
      expect(find.text('Jump to any date'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await h.settle(tester);
      expect(find.text("What's new in Hisab 2.0"), findsNothing);
      expect(find.text('Spent today'), findsOneWidget);
      await h.closeApp(tester);

      // The next start: the version is remembered, so nothing opens.
      h = Harness();
      await h.pumpApp(tester, prefs: {lastSeenVersionKey: currentVersionLabel});
      expect(find.text("What's new in Hisab 2.0"), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('a new user is offered the tour; Show me around plays it', (tester) async {
      await h.pumpApp(tester, prefs: {tourPendingKey: true});
      expect(find.text('Show me around'), findsOneWidget);
      expect(find.text("What's new in Hisab 2.0"), findsNothing);

      await tester.tap(find.text('Show me around'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Add an expense or income'), findsOneWidget);
      expect(find.text('Quick tour · 1 of 4'), findsOneWidget);
      expect(find.text('Tap the + button at the bottom of the screen.'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(milliseconds: 500));
      await h.closeApp(tester);
    });

    testWidgets('the tutorial player plays by itself, steps with the buttons, and replays', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);
      await tester.scrollUntilVisible(find.text('Help and tutorials'), 300);
      await tester.ensureVisible(find.text('Help and tutorials'));
      await tester.pump();
      await tester.tap(find.text('Help and tutorials'));
      await h.settle(tester);
      await tester.tap(find.text('Add an expense or income'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Step 1 / 3'), findsOneWidget);

      // it moves on by itself after five seconds
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Step 2 / 3'), findsOneWidget);

      // pausing holds the step; the buttons move through the steps
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Step 2 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Next'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Step 3 / 3'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Step 2 / 3'), findsOneWidget);

      // play on to the end: the big button becomes Replay
      await tester.tap(find.byTooltip('Play'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 6));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byTooltip('Replay'), findsOneWidget);
      await tester.tap(find.byTooltip('Replay'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Step 1 / 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(milliseconds: 500));
      await h.closeApp(tester);
    });

    testWidgets('every tutorial plays every step without a layout error, in both languages and themes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      for (final language in [AppLanguage.en, AppLanguage.bn]) {
        L10n.setLanguage(language);
        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final t in tutorials) {
            await tester.pumpWidget(
              LanguageScope(
                language: language,
                bengaliDigits: true,
                child: MaterialApp(
                  theme: buildTheme(brightness, bengali: language == AppLanguage.bn),
                  home: TutorialPlayerScreen(ids: [t.id]),
                ),
              ),
            );
            for (var i = 0; i < t.steps.length; i++) {
              await tester.pump(const Duration(milliseconds: 700));
              final error = tester.takeException();
              expect(error, isNull, reason: '${t.id} step ${i + 1} ($language, $brightness): $error');
              await tester.pump(const Duration(seconds: 5));
            }
            await tester.pump(const Duration(seconds: 5));
          }
        }
      }
      // leave the player so its timers are cancelled
      await tester.pumpWidget(const SizedBox());
      await h.closeApp(tester);
    });

    testWidgets('the ? button in a feature opens that feature\'s tutorial', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('Reports'));
      await h.settle(tester);
      await tester.tap(find.byTooltip('Help'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Read your Reports'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(milliseconds: 500));
      await h.closeApp(tester);
    });

    testWidgets('Reports: the calendar jumps to a month, and Today comes back', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('Reports'));
      await h.settle(tester);
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await h.settle(tester);
      expect(find.text('Go to date'), findsWidgets);

      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Month')));
      await h.settle(tester);
      await tester.tap(find.text('Jan'));
      await h.settle(tester);
      expect(find.text('January ${DateTime.now().year}'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await h.settle(tester);
      await tester.tap(find.text('Today'));
      await h.settle(tester);
      expect(find.text('January ${DateTime.now().year}'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('History: Week is a choice, and the calendar picks a day', (tester) async {
      await h.pumpApp(tester);
      final food = await h.category(tester, 'Food');
      final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 10);
      await h.addEntry(tester, amount: 9000, categoryId: food.id, date: today(), note: 'Tea today');
      await h.addEntry(tester, amount: 20000, categoryId: food.id, date: dayKey(lastMonth), note: 'Old lunch');

      await tester.tap(find.text('History'));
      await h.settle(tester);
      await tester.tap(find.text('Week'));
      await h.settle(tester);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Tea today'), findsOneWidget);
      expect(find.text('Old lunch'), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await h.settle(tester);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Day')));
      await h.settle(tester);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.byTooltip('Previous')));
      await h.settle(tester);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('10')));
      await h.settle(tester);
      expect(find.text('Old lunch'), findsOneWidget);
      expect(find.text('Tea today'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('Bengali: no English text is left on the main screens', (tester) async {
      await loadAppFonts();
      await h.pumpApp(tester, prefs: {'language': 'bn', ...homeNoticesOn, 'homeDetail': 'budget'});
      final food = await h.category(tester, 'Food');
      final salary = await h.category(tester, 'Salary', type: EntryType.income);
      await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 3000000));
      await h.addEntry(tester, amount: 38000, categoryId: food.id, date: today(), note: 'Lunch');
      await h.addEntry(tester, type: EntryType.income, amount: 4500000, categoryId: salary.id, date: today());
      final goal = await h.real(tester, () => h.db.addGoal(name: 'Laptop', targetPoisha: 6000000, colorValue: 0xFF4C8DF6, deadline: '2030-01-01'));
      await h.write(tester, () => h.db.addDeposit(goalId: goal, amountPoisha: 3600000, date: today()));
      await h.write(tester, () => h.db.addDhar(person: 'Rahim', direction: DharDirection.lent, amountPoisha: 200000, date: today(), dueDate: today()));
      await h.write(tester, () => h.db.addRecurring(title: 'Wi-Fi', type: EntryType.expense, amountPoisha: 110000, categoryId: food.id, dayOfMonth: 1));

      final english = <String>{};
      void scan(String where) {
        final problem = tester.takeException();
        if (problem != null) english.add('LAYOUT ERROR on $where: $problem');
        for (final w in tester.widgetList<Text>(find.byType(Text))) {
          final t = w.data ?? w.textSpan?.toPlainText() ?? '';
          // Text a person typed (names, notes) and a few fixed words are allowed to stay in English.
          final cleaned = t.replaceAll(RegExp('Lunch|Laptop|Rahim|Wi-Fi|English|CSV|Hisab|GitHub|github\\.com/[A-Za-z0-9/]+|Google|PIN|Drive|Redmi|Xiaomi|POCO|Oppo|Vivo|Realme|Autostart|Android|Rocket|bKash'), '');
          if (RegExp('[A-Za-z]{3,}').hasMatch(cleaned)) english.add('$where: $t');
        }
      }

      scan('home');
      for (final tab in ['History', 'Reports']) {
        await tester.tap(find.text(tr(tab)));
        await h.settle(tester);
        scan(tab);
      }
      await tester.tap(find.text(tr('More')));
      await h.settle(tester);
      scan('more');
      await tester.scrollUntilVisible(find.text(tr('Help and about')), 400);
      scan('more (lower)');

      expect(english, isEmpty, reason: 'English text found in Bengali mode:\n${english.join('\n')}');
      await h.closeApp(tester);
    });
  });
}
