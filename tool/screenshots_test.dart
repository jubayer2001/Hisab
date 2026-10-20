// Makes the README screenshots from the real app screens, filled with made-up sample data.
// Nothing here comes from anyone's phone.
//
// Run from the project root:  flutter test tool/screenshots_test.dart
// The pictures are written to docs/screenshots/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/app.dart';
import 'package:hisab/app/settings_providers.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/features/add_entry/add_entry_sheet.dart';

import '../test/support/harness.dart';

const _outDir = 'docs/screenshots';

/// Tests draw text and icons with placeholder boxes unless the real fonts are loaded.
Future<void> _loadFonts() async {
  final hind = FontLoader('HindSiliguri');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/HindSiliguri-$f.ttf').readAsBytesSync();
    hind.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  await hind.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'E:/dev/flutter';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
  await loader.load();
}

/// The big + in the bottom bar (Home also has small + icons on its Quick add chips).
Finder get _navAddButton =>
    find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.add_rounded && w.size == 26);

void main() {
  testWidgets('README screenshots', (tester) async {
    await _loadFonts();
    Directory(_outDir).createSync(recursive: true);
    // Tests behave as if a keyboard is attached and draw a focus ring; a phone does not.
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

    final h = Harness();
    final now = DateTime.now();
    String day(int back) => dayKey(DateTime(now.year, now.month, now.day - back));

    Future<void> shot(String name) async {
      await h.settle(tester);
      // A new screen focuses its first button, which draws a focus ring in tests (a phone
      // shows none). Drop the focus after the screen has settled, then draw one more frame.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final renderView = tester.binding.renderViews.first;
      final layer = renderView.debugLayer! as OffsetLayer;
      final bytes = await tester.runAsync(() async {
        final image = await layer.toImage(renderView.paintBounds, pixelRatio: 1.6);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_outDir/$name.png').writeAsBytesSync(bytes!);
    }

    await h.pumpApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(HisabApp)));
    container.read(userNameProvider.notifier).set('Tania');

    // ---- Sample data (all made up) -------------------------------------------------
    final cats = await h.categories(tester);
    int id(String name, [String type = EntryType.expense]) => cats.firstWhere((c) => c.name == name && c.type == type).id;
    Future<void> spend(String cat, int taka, int back, [String? note]) =>
        h.addEntry(tester, amount: taka * 100, categoryId: id(cat), date: day(back), note: note);

    await h.addEntry(
      tester,
      type: EntryType.income,
      amount: 4500000,
      categoryId: id('Salary', EntryType.income),
      date: dayKey(DateTime(now.year, now.month, 1)),
      note: 'Monthly salary',
    );
    for (var back = 0; back < 12; back++) {
      await spend('Food', 20, back, 'Tea');
      if (back == 0) {
        await spend('Food', 180, back, 'Lunch');
        await spend('Transport', 60, back, 'Rickshaw');
        await spend('Bills & Recharge', 199, back, 'Mobile recharge');
      } else {
        await spend('Food', 150 + (back * 17) % 90, back, back.isEven ? 'Lunch' : 'Dinner');
        await spend('Transport', 40 + (back * 13) % 40, back, 'Rickshaw');
      }
    }
    await spend('Bazar', 1450, 3, 'Groceries');
    await spend('Shopping', 1850, 6, 'Shirt');
    await spend('Health', 350, 8, 'Medicine');
    await spend('Entertainment', 400, 9, 'Cinema');
    await spend('Food', 1600, 4, 'Family dinner');

    await h.write(tester, () => h.db.setBudget(categoryId: null, amountPoisha: 2500000));
    await h.write(tester, () => h.db.setBudget(categoryId: id('Food'), amountPoisha: 600000));
    await h.write(tester, () => h.db.setBudget(categoryId: id('Shopping'), amountPoisha: 500000));
    await h.write(
      tester,
      () => h.db.addRecurring(
        title: 'Wi-Fi',
        type: EntryType.expense,
        amountPoisha: 100000,
        categoryId: id('Bills & Recharge'),
        dayOfMonth: 1,
      ),
    );
    final eid = await h.write(
      tester,
      () => h.db.addGoal(
        name: 'Eid shopping',
        targetPoisha: 1000000,
        colorValue: 0xFFE86A9A,
        deadline: dayKey(DateTime(now.year, now.month + 5, now.day)),
      ),
    );
    await h.write(tester, () => h.db.addDeposit(goalId: eid, amountPoisha: 350000, date: day(10)));
    final phone = await h.write(
      tester,
      () => h.db.addGoal(
        name: 'New phone',
        targetPoisha: 3000000,
        colorValue: 0xFF4C8DF6,
        deadline: dayKey(DateTime(now.year, now.month + 8, now.day)),
      ),
    );
    await h.write(tester, () => h.db.addDeposit(goalId: phone, amountPoisha: 1200000, date: day(15)));
    final rahim = await h.write(
      tester,
      () => h.db.addDhar(
        person: 'Rahim',
        direction: DharDirection.lent,
        amountPoisha: 150000,
        date: day(20),
        dueDate: day(-2),
        note: 'For books',
      ),
    );
    await h.write(tester, () => h.db.addDharPayment(dharId: rahim, amountPoisha: 50000, date: day(5)));
    await h.write(
      tester,
      () => h.db.addDhar(
        person: 'Karim',
        direction: DharDirection.borrowed,
        amountPoisha: 80000,
        date: day(8),
        dueDate: day(-12),
      ),
    );

    // ---- The pictures --------------------------------------------------------------
    await shot('home');

    await tester.tap(_navAddButton);
    await h.settle(tester);
    final sheet = find.byType(AddEntrySheet);
    for (final d in '250'.split('')) {
      await tester.tap(find.descendant(of: sheet, matching: find.text(d)).last);
      await tester.pump();
    }
    await tester.tap(find.descendant(of: sheet, matching: find.text('Food')));
    await tester.pump();
    await tester.tap(find.text('bKash'));
    await tester.pump();
    await shot('add-expense');
    await tester.tapAt(const Offset(190, 20)); // the dimmed area above the sheet closes it
    await h.settle(tester);

    await tester.tap(find.text('Reports'));
    await h.settle(tester);
    await shot('reports');

    await h.openFromMore(tester, 'Budgets');
    await shot('budgets');
    await tester.pageBack();
    await h.settle(tester);

    // Going back from Budgets lands on the More tab, which lists the other tools.
    await tester.tap(find.text('Savings goals'));
    await h.settle(tester);
    await shot('goals');
    await tester.pageBack();
    await h.settle(tester);

    await tester.tap(find.text('Dhar'));
    await h.settle(tester);
    await shot('dhar');
    await tester.pageBack();
    await h.settle(tester);

    container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.tap(find.text('Home'));
    await h.settle(tester);
    await shot('home-dark');

    await h.closeApp(tester);
  });
}
