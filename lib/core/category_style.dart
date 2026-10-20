import 'package:flutter/material.dart';

/// Icons a category can use. The key (not the icon) is what gets stored in the database,
/// so the list can grow without breaking saved data.
const Map<String, IconData> categoryIcons = {
  'food': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  'cart': Icons.shopping_cart_rounded,
  'bag': Icons.shopping_bag_rounded,
  'bus': Icons.directions_bus_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'bill': Icons.receipt_long_rounded,
  'phone': Icons.smartphone_rounded,
  'wifi': Icons.wifi_rounded,
  'bolt': Icons.bolt_rounded,
  'home': Icons.home_rounded,
  'heart': Icons.favorite_rounded,
  'book': Icons.menu_book_rounded,
  'school': Icons.school_rounded,
  'film': Icons.movie_rounded,
  'gift': Icons.card_giftcard_rounded,
  'salary': Icons.payments_rounded,
  'laptop': Icons.laptop_mac_rounded,
  'savings': Icons.savings_rounded,
  'dots': Icons.more_horiz_rounded,
};

IconData iconForKey(String key) => categoryIcons[key] ?? Icons.category_rounded;

/// Colours offered when creating or editing a category. The first ten match the
/// default expense categories from the design plan.
const List<Color> categoryPalette = [
  Color(0xFFF29E4C),
  Color(0xFF78B159),
  Color(0xFF4C8DF6),
  Color(0xFF9B7BE0),
  Color(0xFFC08457),
  Color(0xFFE86A9A),
  Color(0xFF3DB39E),
  Color(0xFFE9B949),
  Color(0xFFF2766B),
  Color(0xFF94A3A0),
  Color(0xFF2E9E6B),
  Color(0xFF5B8DEF),
];

/// Payment methods, shown as an optional choice when adding an expense.
const List<String> paymentMethods = ['Cash', 'bKash', 'Nagad', 'Rocket', 'Card', 'Bank'];
