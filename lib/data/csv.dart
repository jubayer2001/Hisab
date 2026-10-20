import 'db/app_database.dart';

/// A spreadsheet file of every entry, oldest first, that opens in Excel or Google Sheets.
///
/// Amounts are plain numbers in Taka ("250.50", no ৳ and no thousands commas) so a sheet
/// can add them up. The file starts with a UTF-8 byte order mark, which makes Excel read
/// Bangla text correctly.
String buildCsv(List<EntryWithCategory> entries) {
  final sorted = [...entries]..sort((a, b) {
      final byDate = a.entry.date.compareTo(b.entry.date);
      return byDate != 0 ? byDate : a.entry.id.compareTo(b.entry.id);
    });

  final rows = <List<String>>[
    ['Date', 'Type', 'Category', 'Amount (Taka)', 'Payment method', 'Note'],
    for (final e in sorted)
      [
        e.entry.date,
        e.entry.type,
        _safeText(e.category.name),
        _takaPlain(e.entry.amountPoisha),
        _safeText(e.entry.paymentMethod ?? ''),
        _safeText(e.entry.note ?? ''),
      ],
  ];

  return '﻿${rows.map((r) => r.map(_quote).join(',')).join('\r\n')}\r\n';
}

String _takaPlain(int poisha) {
  final taka = poisha ~/ 100;
  final rest = poisha % 100;
  return '$taka.${rest.toString().padLeft(2, '0')}';
}

/// A cell that starts with = + - @ (or a tab or carriage return, which spreadsheets also treat as
/// a way in) would be run as a formula by Excel, so it gets a leading apostrophe. Only text typed
/// by the user needs this, not numbers.
String _safeText(String value) {
  if (value.isNotEmpty && '=+-@\t\r'.contains(value[0])) return "'$value";
  return value;
}

String _quote(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
