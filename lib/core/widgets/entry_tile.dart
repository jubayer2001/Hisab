import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../features/add_entry/add_entry_sheet.dart';
import '../../features/add_entry/entry_actions.dart';

/// One expense or income row: category icon, title, small detail line and the amount.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.item, this.onTap});

  final EntryWithCategory item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final entry = item.entry;
    final note = (entry.note ?? '').trim();
    final hasNote = note.isNotEmpty;

    final details = [
      if (hasNote) item.category.name,
      if (entry.paymentMethod != null) entry.paymentMethod!,
    ].join(' · ');

    final amountColor = item.isExpense ? colors.spending : colors.income;
    final sign = item.isExpense ? '−' : '+';

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(item.category.colorValue),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(iconForKey(item.category.iconKey), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNote ? note : item.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${formatTaka(entry.amountPoisha)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [EntryTile] that opens the edit sheet on tap and deletes (with Undo) when swiped left.
class SwipeToDeleteTile extends ConsumerStatefulWidget {
  const SwipeToDeleteTile({super.key, required this.item});

  final EntryWithCategory item;

  @override
  ConsumerState<SwipeToDeleteTile> createState() => _SwipeToDeleteTileState();
}

class _SwipeToDeleteTileState extends ConsumerState<SwipeToDeleteTile> {
  // A dismissed Dismissible must leave the tree immediately; the list itself updates a
  // moment later when the database stream emits.
  bool _gone = false;

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final colors = context.hisab;

    return Dismissible(
      key: ValueKey('entry-${widget.item.entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: colors.spending, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _gone = true);
        deleteEntryWithUndo(context, ref, widget.item);
      },
      child: EntryTile(
        item: widget.item,
        onTap: () => showAddEntrySheet(context, editing: widget.item),
      ),
    );
  }
}
