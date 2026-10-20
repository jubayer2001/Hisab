import 'package:flutter/painting.dart';

import '../../app/theme.dart';
import 'tables.dart';

class DefaultCategory {
  const DefaultCategory(this.name, this.type, this.iconKey, this.color);

  final String name;
  final String type;
  final String iconKey;
  final Color color;
}

const defaultCategories = <DefaultCategory>[
  DefaultCategory('Food', EntryType.expense, 'food', CategoryColors.food),
  DefaultCategory('Bazar', EntryType.expense, 'cart', CategoryColors.bazar),
  DefaultCategory('Transport', EntryType.expense, 'bus', CategoryColors.transport),
  DefaultCategory('Bills & Recharge', EntryType.expense, 'bill', CategoryColors.bills),
  DefaultCategory('Rent', EntryType.expense, 'home', CategoryColors.rent),
  DefaultCategory('Shopping', EntryType.expense, 'bag', CategoryColors.shopping),
  DefaultCategory('Health', EntryType.expense, 'heart', CategoryColors.health),
  DefaultCategory('Education', EntryType.expense, 'book', CategoryColors.education),
  DefaultCategory('Entertainment', EntryType.expense, 'film', CategoryColors.entertainment),
  DefaultCategory('Others', EntryType.expense, 'dots', CategoryColors.others),
  DefaultCategory('Salary', EntryType.income, 'salary', Color(0xFF2E9E6B)),
  DefaultCategory('Tuition', EntryType.income, 'school', Color(0xFF5B8DEF)),
  DefaultCategory('Freelance', EntryType.income, 'laptop', Color(0xFF9B7BE0)),
  DefaultCategory('Gift', EntryType.income, 'gift', Color(0xFFE86A9A)),
  DefaultCategory('Others', EntryType.income, 'dots', Color(0xFF94A3A0)),
];
