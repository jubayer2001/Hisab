/// Money helpers. All amounts are stored as whole poisha (1 Taka = 100 poisha)
/// so totals never pick up floating point rounding errors.
library;

const String takaSign = '৳';

/// Formats [poisha] as Taka with South Asian (lakh/crore) grouping.
///
/// formatTaka(12500000)  -> ৳1,25,000
/// formatTaka(25050)     -> ৳250.50
/// formatTaka(-18000)    -> -৳180
///
/// Poisha are shown only when the amount is not a whole number of Taka,
/// unless [alwaysShowPoisha] is true.
String formatTaka(int poisha, {bool alwaysShowPoisha = false, bool withSign = true}) {
  final negative = poisha < 0;
  final abs = poisha.abs();
  final taka = abs ~/ 100;
  final rest = abs % 100;

  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  if (withSign) buffer.write(takaSign);
  buffer.write(groupLakh(taka));
  if (rest != 0 || alwaysShowPoisha) {
    buffer.write('.');
    buffer.write(rest.toString().padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Groups a non-negative whole number the South Asian way:
/// last three digits, then pairs. 12500000 -> 1,25,00,000
String groupLakh(int value) {
  assert(value >= 0);
  final digits = value.toString();
  if (digits.length <= 3) return digits;

  final last3 = digits.substring(digits.length - 3);
  var head = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (head.length > 2) {
    parts.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) parts.insert(0, head);
  return '${parts.join(',')},$last3';
}

/// Parses user input like "250", "250.5" or "1,250.75" into poisha.
/// Returns null for empty or invalid input. Extra decimals beyond two are rejected.
int? parseTakaToPoisha(String input) {
  final cleaned = input.replaceAll(',', '').replaceAll(takaSign, '').trim();
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final taka = int.parse(match.group(1)!);
  final frac = (match.group(2) ?? '').padRight(2, '0');
  return taka * 100 + int.parse(frac);
}
