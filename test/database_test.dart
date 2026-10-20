import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<Category>> categories() => db.watchCategories().first;

  test('seeds default expense and income categories', () async {
    final all = await categories();
    expect(all.where((c) => c.type == EntryType.expense), hasLength(10));
    expect(all.where((c) => c.type == EntryType.income), hasLength(5));
    expect(all.first.name, 'Food');
  });

  test('adds, lists, updates, deletes and restores an entry', () async {
    final food = (await categories()).first;
    final id = await db.addEntry(
      type: EntryType.expense,
      amountPoisha: 25050,
      categoryId: food.id,
      date: '2026-10-20',
      paymentMethod: 'bKash',
      note: 'Dinner',
    );

    var list = await db.watchEntries().first;
    expect(list, hasLength(1));
    expect(list.single.entry.amountPoisha, 25050);
    expect(list.single.category.name, 'Food');
    expect(list.single.entry.paymentMethod, 'bKash');

    await db.updateEntry(list.single.entry.copyWith(amountPoisha: 30000));
    list = await db.watchEntries().first;
    expect(list.single.entry.amountPoisha, 30000);

    final deleted = list.single.entry;
    await db.deleteEntry(id);
    expect(await db.watchEntries().first, isEmpty);

    await db.restoreEntry(deleted);
    list = await db.watchEntries().first;
    expect(list.single.entry.id, id);
    expect(list.single.entry.amountPoisha, 30000);
  });

  test('lists newest day first', () async {
    final food = (await categories()).first;
    for (final date in ['2026-10-18', '2026-10-20', '2026-10-19']) {
      await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: date);
    }
    final dates = (await db.watchEntries().first).map((e) => e.entry.date).toList();
    expect(dates, ['2026-10-20', '2026-10-19', '2026-10-18']);
  });

  test('removeCategory deletes an unused category but only hides a used one', () async {
    final all = await categories();
    final food = all.firstWhere((c) => c.name == 'Food');
    final rent = all.firstWhere((c) => c.name == 'Rent');
    await db.addEntry(type: EntryType.expense, amountPoisha: 100, categoryId: food.id, date: '2026-10-20');

    await db.removeCategory(rent.id);
    await db.removeCategory(food.id);

    final after = await categories();
    expect(after.any((c) => c.id == rent.id), isFalse);
    expect(after.firstWhere((c) => c.id == food.id).isArchived, isTrue);
    // The old entry still shows its category.
    expect((await db.watchEntries().first).single.category.name, 'Food');
  });

  test('addCategory puts the new category last', () async {
    final id = await db.addCategory(
      name: 'Tuition fee',
      type: EntryType.expense,
      iconKey: 'school',
      colorValue: 0xFF123456,
    );
    final all = await categories();
    expect(all.last.id, id);
    expect(all.last.name, 'Tuition fee');
  });

  test('no-spend days can be marked and unmarked', () async {
    await db.setNoSpend('2026-10-20', true);
    await db.setNoSpend('2026-10-20', true); // marking twice is fine
    expect(await db.watchNoSpendDays().first, {'2026-10-20'});

    await db.setNoSpend('2026-10-20', false);
    expect(await db.watchNoSpendDays().first, isEmpty);
  });
}
