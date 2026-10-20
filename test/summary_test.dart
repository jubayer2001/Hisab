import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/app_database.dart';
import 'package:hisab/data/db/tables.dart';
import 'package:hisab/data/summary.dart';

const _food = Category(
  id: 1, name: 'Food', type: EntryType.expense, iconKey: 'food', colorValue: 0xFFF29E4C, sortOrder: 0, isArchived: false,
);
const _transport = Category(
  id: 2, name: 'Transport', type: EntryType.expense, iconKey: 'bus', colorValue: 0xFF4C8DF6, sortOrder: 1, isArchived: false,
);
const _salary = Category(
  id: 11, name: 'Salary', type: EntryType.income, iconKey: 'salary', colorValue: 0xFF2E9E6B, sortOrder: 10, isArchived: false,
);

var _nextId = 1;

EntryWithCategory _entry(
  Category c,
  int poisha,
  String date, {
  String? note,
  DateTime? createdAt,
}) {
  final id = _nextId++;
  return EntryWithCategory(
    Entry(
      id: id,
      type: c.type,
      amountPoisha: poisha,
      categoryId: c.id,
      paymentMethod: null,
      note: note,
      date: date,
      createdAt: createdAt ?? DateTime(2026, 10, 1).add(Duration(minutes: id)),
    ),
    c,
  );
}

void main() {
  final now = DateTime(2026, 10, 20, 21, 30);

  group('dates', () {
    test('dayKey and parseDayKey round-trip', () {
      expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
      expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
      expect(monthKey(DateTime(2026, 10, 20)), '2026-10');
    });

    test('friendlyDay', () {
      expect(friendlyDay(DateTime(2026, 10, 20), now: now), 'Today');
      expect(friendlyDay(DateTime(2026, 10, 19), now: now), 'Yesterday');
      expect(friendlyDay(DateTime(2026, 10, 14), now: now), 'Wed, 14 Oct');
      expect(friendlyDay(DateTime(2025, 12, 31), now: now), 'Wed, 31 Dec 2025');
    });
  });

  group('computeSummary', () {
    test('splits today and month, expenses and income', () {
      final summary = computeSummary([
        _entry(_food, 18000, '2026-10-20'),
        _entry(_transport, 6000, '2026-10-20'),
        _entry(_food, 25000, '2026-10-03'),
        _entry(_salary, 5000000, '2026-10-01'),
        _entry(_food, 99900, '2026-09-30'), // last month, ignored
      ], now);

      expect(summary.todayExpense, 24000);
      expect(summary.todayCount, 2);
      expect(summary.monthExpense, 49000);
      expect(summary.monthIncome, 5000000);
      expect(summary.monthBalance, 4951000);
    });

    test('empty list is all zeros', () {
      final summary = computeSummary([], now);
      expect(summary.todayExpense, 0);
      expect(summary.monthBalance, 0);
    });

    test('balance goes negative when spending exceeds income', () {
      final summary = computeSummary([_entry(_food, 10000, '2026-10-02')], now);
      expect(summary.monthBalance, -10000);
    });
  });

  group('computeQuickAdds', () {
    test('needs at least two repeats and sorts by frequency', () {
      final quick = computeQuickAdds([
        _entry(_food, 1000, '2026-10-19', note: 'Tea'),
        _entry(_food, 1000, '2026-10-18', note: 'Tea'),
        _entry(_food, 1000, '2026-10-17', note: 'Tea'),
        _entry(_transport, 5000, '2026-10-19', note: 'Rickshaw'),
        _entry(_transport, 5000, '2026-10-18', note: 'Rickshaw'),
        _entry(_food, 25000, '2026-10-19'), // only once, not offered
      ], now);

      expect(quick.map((q) => q.label), ['Tea', 'Rickshaw']);
      expect(quick.first.amountPoisha, 1000);
    });

    test('uses the category name when there is no note', () {
      final quick = computeQuickAdds([
        _entry(_transport, 3000, '2026-10-19'),
        _entry(_transport, 3000, '2026-10-18'),
      ], now);
      expect(quick.single.label, 'Transport');
      expect(quick.single.note, isNull);
    });

    test('ignores income and old entries', () {
      final quick = computeQuickAdds([
        _entry(_salary, 100000, '2026-10-19'),
        _entry(_salary, 100000, '2026-10-18'),
        _entry(_food, 1000, '2026-05-01', note: 'Tea'),
        _entry(_food, 1000, '2026-05-02', note: 'Tea'),
      ], now);
      expect(quick, isEmpty);
    });

    test('limits to three suggestions', () {
      final entries = <EntryWithCategory>[];
      for (final amount in [1000, 2000, 3000, 4000]) {
        entries
          ..add(_entry(_food, amount, '2026-10-19'))
          ..add(_entry(_food, amount, '2026-10-18'));
      }
      expect(computeQuickAdds(entries, now), hasLength(3));
    });
  });
}
