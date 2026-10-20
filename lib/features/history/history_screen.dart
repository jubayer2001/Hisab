import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entry_tile.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _type; // null = all

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(EntryWithCategory e) {
    if (_type != null && e.entry.type != _type) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      e.category.name,
      e.entry.note ?? '',
      e.entry.paymentMethod ?? '',
      formatTaka(e.entry.amountPoisha),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final async = ref.watch(allEntriesProvider);
    final today = ref.watch(todayProvider);

    final all = async.value ?? const <EntryWithCategory>[];
    final filtered = all.where(_matches).toList();

    // Flat list: a header row for each day followed by that day's entries.
    final spentByDay = <String, int>{};
    for (final e in filtered) {
      if (e.isExpense) spentByDay.update(e.entry.date, (s) => s + e.entry.amountPoisha, ifAbsent: () => e.entry.amountPoisha);
    }
    final rows = <Object>[];
    String? currentDay;
    for (final e in filtered) {
      if (e.entry.date != currentDay) {
        currentDay = e.entry.date;
        rows.add(_DayHeader(day: parseDayKey(currentDay), spent: spentByDay[currentDay] ?? 0));
      }
      rows.add(e);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search note, category or amount',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: colors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: EntryType.expense, label: Text('Expenses')),
                  ButtonSegment(value: EntryType.income, label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
          ),
          Expanded(
            child: async.isLoading && all.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyState(
                        icon: all.isEmpty ? Icons.receipt_long_outlined : Icons.search_off_rounded,
                        title: all.isEmpty ? 'Nothing here yet' : 'No matches',
                        message: all.isEmpty
                            ? 'Every expense and income you add will be listed here, grouped by day.'
                            : 'Try a different word or clear the filter.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          if (row is _DayHeader) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      friendlyDay(row.day, now: today),
                                      style: theme.textTheme.titleSmall?.copyWith(color: colors.muted),
                                    ),
                                  ),
                                  if (row.spent > 0)
                                    Text(
                                      'Spent ${formatTaka(row.spent)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                                    ),
                                ],
                              ),
                            );
                          }
                          final item = row as EntryWithCategory;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SwipeToDeleteTile(item: item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader {
  const _DayHeader({required this.day, required this.spent});

  final DateTime day;
  final int spent;
}
