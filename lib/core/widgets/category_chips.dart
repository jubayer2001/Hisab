import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../category_style.dart';

/// Pick one category from a list, shown as wrapped chips with the category's icon.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in categories)
          ChoiceChip(
            avatar: Icon(iconForKey(c.iconKey), size: 18, color: Color(c.colorValue)),
            label: Text(c.name),
            selected: c.id == selectedId,
            showCheckmark: false,
            onSelected: (_) => onSelected(c.id),
          ),
      ],
    );
  }
}
