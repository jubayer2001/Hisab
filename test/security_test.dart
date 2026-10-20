import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/security_providers.dart';
import 'package:hisab/features/security/lock_gate.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/core/widgets/profile_avatar.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/database_security.dart';
import 'package:hisab/data/providers.dart';
import 'package:hisab/services/app_lock.dart';
import 'package:hisab/services/native_security.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  // ---- the lock's logic, without any screen ---------------------------------------------

  group('app lock logic', () {
    late FakeAppLockService phone;
    late DateTime clock;

    Future<ProviderContainer> start({Map<String, Object> prefs = const {}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      final p = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(p),
        appLockServiceProvider.overrideWithValue(phone),
        databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(() async {
        await c.read(databaseProvider).close();
        c.dispose();
      });
      c.read(appLockControllerProvider.notifier).now = () => clock;
      return c;
    }

    setUp(() {
      phone = FakeAppLockService();
      clock = DateTime(2026, 11, 20, 10);
    });

    test('off by default, and nothing ever locks while it is off', () async {
      final c = await start();
      final lock = c.read(appLockControllerProvider.notifier);
      expect(c.read(appLockControllerProvider).locked, isFalse);
      lock.onLeft();
      clock = clock.add(const Duration(hours: 5));
      lock.onReturned();
      expect(c.read(appLockControllerProvider).locked, isFalse);
    });

    test('a cold start with the lock on is locked', () async {
      final c = await start(prefs: {appLockKey: true});
      expect(c.read(appLockControllerProvider).locked, isTrue);
    });

    test('unlocking works only if the phone says yes', () async {
      final c = await start(prefs: {appLockKey: true});
      final lock = c.read(appLockControllerProvider.notifier);

      phone.answers.addAll([false, false, true]);
      expect(await lock.unlock(), isFalse);
      expect(c.read(appLockControllerProvider).locked, isTrue);
      expect(await lock.unlock(), isFalse);
      expect(c.read(appLockControllerProvider).locked, isTrue);
      expect(await lock.unlock(), isTrue);
      expect(c.read(appLockControllerProvider).locked, isFalse);
      expect(phone.prompts, hasLength(3));
    });

    test('locks again only after the chosen time away', () async {
      final c = await start(prefs: {appLockKey: true, appLockDelayKey: LockDelay.oneMinute.code});
      final lock = c.read(appLockControllerProvider.notifier);
      await lock.unlock();

      lock.onLeft();
      clock = clock.add(const Duration(seconds: 59));
      lock.onReturned();
      expect(c.read(appLockControllerProvider).locked, isFalse, reason: 'back within a minute');

      lock.onLeft();
      clock = clock.add(const Duration(seconds: 61));
      lock.onReturned();
      expect(c.read(appLockControllerProvider).locked, isTrue, reason: 'away over a minute');
    });

    test('"Immediately" locks the moment the app is left, so the screen is covered on return', () async {
      final c = await start(prefs: {appLockKey: true, appLockDelayKey: LockDelay.immediately.code});
      final lock = c.read(appLockControllerProvider.notifier);
      await lock.unlock();

      lock.onLeft();
      expect(c.read(appLockControllerProvider).locked, isTrue);
    });

    test('five minutes means five', () async {
      final c = await start(prefs: {appLockKey: true, appLockDelayKey: LockDelay.fiveMinutes.code});
      final lock = c.read(appLockControllerProvider.notifier);
      await lock.unlock();
      lock.onLeft();
      clock = clock.add(const Duration(minutes: 4, seconds: 59));
      lock.onReturned();
      expect(c.read(appLockControllerProvider).locked, isFalse);
      lock.onLeft();
      clock = clock.add(const Duration(minutes: 5));
      lock.onReturned();
      expect(c.read(appLockControllerProvider).locked, isTrue);
    });

    test('while the phone\'s own prompt is open, leaving and returning does not lock again', () async {
      final c = await start(prefs: {appLockKey: true, appLockDelayKey: LockDelay.immediately.code});
      final lock = c.read(appLockControllerProvider.notifier);
      phone.answers.add(true);
      final pending = lock.unlock();
      expect(c.read(appLockControllerProvider).prompting, isTrue);
      lock.onLeft(); // the prompt covers the app
      lock.onReturned();
      await pending;
      expect(c.read(appLockControllerProvider).locked, isFalse);
      expect(c.read(appLockControllerProvider).prompting, isFalse);
    });

    test('turning it on needs a screen lock on the phone, and proof it works', () async {
      final c = await start();
      final lock = c.read(appLockControllerProvider.notifier);

      phone.available = false;
      expect(await lock.setEnabled(true), isFalse);
      expect(c.read(appLockEnabledProvider), isFalse);

      phone.available = true;
      phone.answers.add(false); // cancelled the confirmation
      expect(await lock.setEnabled(true), isFalse);
      expect(c.read(appLockEnabledProvider), isFalse, reason: 'not turned on, so nobody can lock themselves out');

      expect(await lock.setEnabled(true), isTrue);
      expect(c.read(appLockEnabledProvider), isTrue);
      expect(c.read(appLockControllerProvider).locked, isFalse, reason: 'they just proved it is them');
    });

    test('turning it off unlocks and forgets', () async {
      final c = await start(prefs: {appLockKey: true});
      final lock = c.read(appLockControllerProvider.notifier);
      expect(await lock.setEnabled(false), isTrue);
      expect(c.read(appLockEnabledProvider), isFalse);
      expect(c.read(appLockControllerProvider).locked, isFalse);
    });

    test('the delay and the lock are remembered', () async {
      final c = await start();
      c.read(lockDelayProvider.notifier).set(LockDelay.fiveMinutes);
      c.read(appLockEnabledProvider.notifier).set(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(appLockDelayKey), 'fiveMinutes');
      expect(prefs.getBool(appLockKey), isTrue);
    });

    test('an unknown saved delay falls back to one minute', () async {
      final c = await start(prefs: {appLockDelayKey: 'whenever'});
      expect(c.read(lockDelayProvider), LockDelay.oneMinute);
    });
  });

  // ---- the screens ----------------------------------------------------------------------

  group('app lock on screen', () {
    late Harness h;
    setUp(() => h = Harness());

    /// Android brings an app back from the background through these states, in this order.
    void comeBack(WidgetTester tester) {
      for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    testWidgets('a locked cold start shows only the lock screen and asks the phone to unlock', (tester) async {
      h.lock.answers.add(false); // the person cancels the prompt
      await h.pumpApp(tester, prefs: {appLockKey: true});

      expect(find.text('Hisab is locked'), findsOneWidget);
      expect(find.text('Spent today'), findsNothing, reason: 'nothing of the app shows through');
      expect(find.text('Good morning'), findsNothing);
      expect(h.lock.prompts, ['Unlock Hisab'], reason: 'the phone\'s prompt opened by itself');
      await h.closeApp(tester);
    });

    testWidgets('after a cancelled prompt, "Unlock" tries again and opens the app', (tester) async {
      h.lock.answers.add(false);
      await h.pumpApp(tester, prefs: {appLockKey: true});
      expect(find.text('Hisab is locked'), findsOneWidget);

      h.lock.answers.add(true);
      await tester.tap(find.text('Unlock'));
      await h.settle(tester);

      expect(find.text('Hisab is locked'), findsNothing);
      expect(find.text('Spent today'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('a wrong fingerprint keeps it locked', (tester) async {
      h.lock.defaultAnswer = false;
      await h.pumpApp(tester, prefs: {appLockKey: true});
      await tester.tap(find.text('Unlock'));
      await h.settle(tester);
      expect(find.text('Hisab is locked'), findsOneWidget);
      expect(find.text('Spent today'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('with the lock off, the app opens straight away and no prompt appears', (tester) async {
      await h.pumpApp(tester);
      expect(find.text('Spent today'), findsOneWidget);
      expect(h.lock.prompts, isEmpty);
      await h.closeApp(tester);
    });

    testWidgets('leaving the app locks it at once, the lock screen is up when it returns, and unlocking restores the same screen', (tester) async {
      await h.pumpApp(tester, prefs: {appLockKey: true, appLockDelayKey: LockDelay.immediately.code});
      expect(find.text('Spent today'), findsOneWidget);

      // Go to History first, so we can see the screen is kept.
      await tester.tap(find.text('History'));
      await h.settle(tester);

      // While the app is in the background Flutter draws nothing, so check the state itself.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final container = ProviderScope.containerOf(tester.element(find.byType(AppLockGate)));
      expect(container.read(appLockControllerProvider).locked, isTrue, reason: 'locked the moment it is left');

      // It comes back and the person cancels the prompt: only the lock screen shows.
      h.lock.answers.add(false);
      comeBack(tester);
      await h.settle(tester);
      expect(find.text('Hisab is locked'), findsOneWidget);
      expect(find.text('Search note, category or amount'), findsNothing, reason: 'nothing of History shows through');
      expect(h.lock.prompts, hasLength(2));

      // Unlocking brings back exactly where they were.
      await tester.tap(find.text('Unlock'));
      await h.settle(tester);
      expect(find.text('Hisab is locked'), findsNothing);
      expect(find.text('Search note, category or amount'), findsOneWidget, reason: 'back on History, nothing lost');
      await h.closeApp(tester);
    });

    testWidgets('with a one-minute delay a quick trip away does not lock it', (tester) async {
      await h.pumpApp(tester, prefs: {appLockKey: true, appLockDelayKey: LockDelay.oneMinute.code});
      final container = ProviderScope.containerOf(tester.element(find.byType(AppLockGate)));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      comeBack(tester);
      await h.settle(tester);

      expect(container.read(appLockControllerProvider).locked, isFalse);
      expect(find.text('Spent today'), findsOneWidget);
      expect(h.lock.prompts, hasLength(1), reason: 'only the first, cold-start prompt');
      await h.closeApp(tester);
    });
  });

  group('the Privacy and security page', () {
    late Harness h;
    setUp(() => h = Harness());

    Future<void> openPrivacy(WidgetTester tester) async {
      await tester.tap(find.text('More'));
      await h.settle(tester);
      await tester.scrollUntilVisible(find.text('Privacy and security'), 300);
      await tester.ensureVisible(find.text('Privacy and security'));
      await tester.pump();
      await tester.tap(find.text('Privacy and security'));
      await h.settle(tester);
    }

    testWidgets('it explains where the data is, in plain words', (tester) async {
      await h.pumpApp(tester);
      await openPrivacy(tester);

      expect(find.textContaining('Your income, spending and balance are yours alone'), findsOneWidget);
      expect(find.text('On this phone, encrypted'), findsOneWidget);
      expect(find.text('Nowhere else'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('No account with us'), 300);
      expect(find.text('No ads, no tracking, no analytics'), findsOneWidget);
      expect(find.text('No account with us'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('it is honest when the phone could not encrypt', (tester) async {
      await h.pumpApp(tester, encryption: EncryptionState.unavailable);
      await openPrivacy(tester);

      expect(find.text('On this phone, encrypted'), findsNothing);
      expect(find.textContaining('without extra encryption'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('with Google available but not signed in, it says nothing leaves the phone', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await openPrivacy(tester);
      expect(find.text('Not backed up to Google'), findsOneWidget);
      expect(find.text('Nowhere else'), findsNothing);
      await h.closeApp(tester);
    });

    testWidgets('signed in, it names the account and says only Hisab can open the copy', (tester) async {
      h.cloud.configured = true;
      await h.pumpApp(tester);
      await tester.tap(find.byType(ProfileAvatar));
      await h.settle(tester);
      await tester.tap(find.text('Sign in with Google'));
      await h.settle(tester);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await h.settle(tester);

      await openPrivacy(tester);
      expect(find.text('A copy in your Google Drive'), findsOneWidget);
      expect(find.textContaining('person@example.com'), findsOneWidget);
      expect(find.textContaining('only Hisab can open'), findsOneWidget);
      await h.closeApp(tester);
    });

    testWidgets('the screens are hidden from screenshots by default, and the switch turns that off and on', (tester) async {
      await h.pumpApp(tester);
      await openPrivacy(tester);

      final tile = find.widgetWithText(SwitchListTile, 'Hide in recent apps and screenshots');
      expect(tester.widget<SwitchListTile>(tile).value, isTrue, reason: 'on by default');

      await tester.tap(tile);
      await h.settle(tester);
      expect(h.nativeSecurity.secureCalls.last, isFalse);
      expect((await SharedPreferences.getInstance()).getBool(secureWindowKey), isFalse);

      await tester.tap(tile);
      await h.settle(tester);
      expect(h.nativeSecurity.secureCalls.last, isTrue);
      await h.closeApp(tester);
    });

    testWidgets('turning the app lock on asks the phone first, and shows the delay choices', (tester) async {
      await h.pumpApp(tester);
      await openPrivacy(tester);

      final tile = find.widgetWithText(SwitchListTile, 'App lock');
      expect(find.text('Lock again'), findsNothing);

      await tester.tap(tile);
      await h.settle(tester);
      expect(h.lock.prompts, ['Confirm it is you to turn on the app lock']);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      expect(find.text('Lock again'), findsOneWidget);
      expect(find.text('After 1 minute'), findsOneWidget);

      await tester.tap(find.text('After 5 minutes'));
      await h.settle(tester);
      expect((await SharedPreferences.getInstance()).getString(appLockDelayKey), 'fiveMinutes');
      await h.closeApp(tester);
    });

    testWidgets('no screen lock on the phone: it explains instead of locking them out', (tester) async {
      h.lock.available = false;
      await h.pumpApp(tester);
      await openPrivacy(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await h.settle(tester);
      expect(find.textContaining('Make sure your phone has a screen lock'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'App lock')).value, isFalse);
      await h.closeApp(tester);
    });

    testWidgets('a cancelled confirmation leaves the lock off', (tester) async {
      h.lock.answers.add(false);
      await h.pumpApp(tester);
      await openPrivacy(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await h.settle(tester);
      expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'App lock')).value, isFalse);
      await h.closeApp(tester);
    });
  });

  test('the secure-window setting defaults to on and is passed to the phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeNativeSecurity();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      nativeSecurityProvider.overrideWithValue(fake),
    ]);
    addTearDown(c.dispose);

    expect(c.read(secureWindowProvider), isTrue);
    await c.read(secureWindowProvider.notifier).set(false);
    expect(c.read(secureWindowProvider), isFalse);
    expect(fake.secureCalls, [false]);
  });
}
