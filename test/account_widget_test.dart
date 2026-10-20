import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/profile_providers.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/widgets/profile_avatar.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  Future<void> addToday(WidgetTester tester) async {
    final food = await h.category(tester, 'Food');
    await h.addEntry(tester, amount: 4000, categoryId: food.id, date: dayKey(DateTime.now()), note: 'Lunch');
  }

  ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  group('Home: the profile icon and the backup reminder', () {
    testWidgets('without Google sign-in in the build there is an icon but no badge and no card', (tester) async {
      await h.pumpApp(tester);
      await addToday(tester);

      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
      expect(find.text('Your data is only on this phone'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('not signed in: amber badge, and a card once there is data worth protecting', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);

      // Nothing to protect yet: the badge is there, the card is not.
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
      expect(find.text('Your data is only on this phone'), findsNothing);

      await addToday(tester);
      expect(find.text('Your data is only on this phone'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('"Not now" hides the card but keeps the badge, and it stays hidden', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await addToday(tester);

      await tester.tap(find.text('Not now'));
      await h.settle(tester);
      expect(find.text('Your data is only on this phone'), findsNothing);
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);

      // It is remembered for a week.
      final until = containerOf(tester).read(cloudNudgeProvider)!;
      expect(until.isAfter(DateTime.now().add(const Duration(days: 6))), isTrue);
      await h.closeApp(tester);
    });

    testWidgets('"Sign in" on the card signs in, and the badge turns into a tick', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await addToday(tester);

      await tester.tap(find.text('Sign in'));
      await h.settle(tester);

      expect(h.cloud.uploads, 1);
      expect(find.text('Your data is only on this phone'), findsNothing);
      expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the icon shows the first letter of the name', (tester) async {
      await h.pumpApp(tester);
      containerOf(tester).read(userNameProvider.notifier).set('tania');
      await h.settle(tester);

      expect(find.descendant(of: find.byType(ProfileAvatar), matching: find.text('T')), findsOneWidget);
      await h.closeApp(tester);
    });
  });

  group('Account', () {
    testWidgets('not signed in: a clear warning and a sign-in button', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);

      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.textContaining('your data exists only on this phone', findRichText: true, skipOffstage: false), findsWidgets);
      expect(find.text('Sign in with Google'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('without Google in the build, the Account screen has no sign-in and still works', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);

      expect(find.text('Sign in with Google'), findsNothing);
      expect(find.text('Not signed in'), findsNothing);
      expect(find.text('Save a backup file'), findsOneWidget);
      expect(find.text('Export to CSV'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the monthly budget and profile colour can be changed from the sheet', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);

      expect(find.widgetWithText(ListTile, 'Monthly budget'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Monthly budget'));
      await h.settle(tester);
      await typeInto(tester, 'Monthly budget (optional)', '30000');
      await tester.tap(find.bySemanticsLabel('Profile colour 3').first, warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      final budgets = await h.real(tester, () => h.db.watchBudgets().first);
      expect(budgets.single.categoryId, isNull);
      expect(budgets.single.amountPoisha, 3000000);
      expect(find.text('৳30,000'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('clearing the budget field removes the monthly budget', (tester) async {
      await h.pumpApp(tester);
      await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 2500000));
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Monthly budget'));
      await h.settle(tester);
      await typeInto(tester, 'Monthly budget (optional)', '');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await h.settle(tester);

      expect(await h.real(tester, () => h.db.watchBudgets().first), isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('signed in: shows the email and the backup controls', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);

      expect(find.text('person@example.com'), findsOneWidget);
      expect(find.text('Back up automatically'), findsOneWidget);
      expect(find.text('Back up now'), findsOneWidget);
      expect(find.text('Restore from Google'), findsOneWidget);
      expect(find.text('Not signed in'), findsNothing);
      await h.closeApp(tester);
    });
  });

  group('More', () {
    testWidgets('the four money tools show live numbers, and open when tapped', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);

      expect(find.text('Set a monthly limit'), findsOneWidget);
      expect(find.text('Save for something'), findsOneWidget);
      expect(find.text('Money you lent or borrowed'), findsOneWidget);
      expect(find.text('Salary, rent, Wi-Fi'), findsOneWidget);

      await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 2500000));
      expect(find.textContaining('left this month'), findsOneWidget);
      expect(find.text('Set a monthly limit'), findsNothing);

      await tester.tap(find.text('Budgets'));
      await h.settle(tester);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Budgets')), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the profile icon in the corner opens Account, and so does "Backup and export"', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);

      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      expect(find.text('Account'), findsOneWidget);
      await tester.pageBack();
      await h.settle(tester);

      await tester.tap(find.text('Backup and export'));
      await h.settle(tester);
      expect(find.text('Account'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the backup row says where the data is', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);
      expect(find.text('Only on this phone. Tap to sign in'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('light, dark and system are big choices', (tester) async {
      await h.pumpApp(tester);
      await tester.tap(find.text('More'));
      await h.settle(tester);

      await tester.scrollUntilVisible(find.text('Dark'), 300);
      await tester.ensureVisible(find.text('Dark')); // it can be built yet still sit under the tab bar
      await tester.pump();
      await tester.tap(find.text('Dark'));
      await h.settle(tester);
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);

      await tester.tap(find.text('Light'));
      await h.settle(tester);
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.light);
      await h.closeApp(tester);
    });
  });

  group('Welcome: keeping the data safe', () {
    Future<void> toLastStep(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await h.settle(tester);
      }
      expect(find.text('Keep your data safe'), findsOneWidget);
    }

    bool getStartedEnabled(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Get started')).onPressed != null;

    testWidgets('without Google in the build there is no backup step', (tester) async {
      await h.pumpApp(tester, onboarded: false);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await h.settle(tester);
      }
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Keep your data safe'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('a last step asks, and "Get started" waits for a choice', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester, onboarded: false);
      await toLastStep(tester);

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Use without an account'), findsOneWidget);
      expect(find.textContaining('your data lives only on this phone', findRichText: true), findsOneWidget);
      expect(getStartedEnabled(tester), isFalse);
      expect(find.text('Skip'), findsNothing, reason: 'nothing left to skip on the last step');
      await h.closeApp(tester);
    });

    testWidgets('"Skip" at the start jumps to the backup question, not past it', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester, onboarded: false);

      await tester.tap(find.text('Skip'));
      await h.settle(tester);
      expect(find.text('Keep your data safe'), findsOneWidget);
      expect(find.text('Spent today'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('going without an account needs a confirmation, then the app opens', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester, onboarded: false);
      await toLastStep(tester);

      await tester.tap(find.text('Use without an account'));
      await h.settle(tester);
      expect(find.text('Continue without a backup?'), findsOneWidget);
      expect(find.textContaining('your records are gone for good'), findsOneWidget);

      await tester.tap(find.text('Continue without a backup'));
      await h.settle(tester);
      expect(getStartedEnabled(tester), isTrue);

      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await h.settle(tester);
      expect(find.text('Spent today'), findsOneWidget);
      expect(h.cloud.uploads, 0, reason: 'no account means nothing is ever sent');
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget, reason: 'the badge keeps reminding them');
      await h.closeApp(tester);
    });

    testWidgets('the confirmation can send them to sign in instead', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester, onboarded: false);
      await toLastStep(tester);

      await tester.tap(find.text('Use without an account'));
      await h.settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in with Google'));
      await h.settle(tester);

      expect(find.textContaining('Signed in as person@example.com'), findsWidgets);
      expect(getStartedEnabled(tester), isTrue);
      await h.closeApp(tester);
    });

    testWidgets('signing in on the last step unlocks "Get started" and backs the phone up', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester, onboarded: false);
      await toLastStep(tester);

      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);
      expect(find.textContaining('Signed in as person@example.com. Your data will be backed up.'), findsOneWidget);
      expect(getStartedEnabled(tester), isTrue);

      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await h.settle(tester);
      expect(find.text('Spent today'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(h.cloud.uploads, 1);
      await h.closeApp(tester);
    });
  });
}
