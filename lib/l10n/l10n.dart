import 'bn_dates.dart';
import 'bn_strings.dart';

/// The languages the app can show.
enum AppLanguage { en, bn }

/// Turns the app's English texts into Bengali, when Bengali is chosen.
///
/// Every text in the app is written in English in the code. [tr] looks the whole text up (and
/// the texts with numbers or names in them by template, like "Restored {} entries."), then
/// swaps English month and weekday words, then writes the digits the way the user chose. In
/// English nothing changes. A text with no translation yet is shown in English, never blank.
class L10n {
  L10n._();

  static AppLanguage language = AppLanguage.en;

  /// In Bengali: show ১২৩ (true) or 123 (false).
  static bool bengaliDigits = true;

  static final Map<String, String> _cache = {};

  static bool get isBengali => language == AppLanguage.bn;

  static void setLanguage(AppLanguage value) {
    if (language == value) return;
    language = value;
    _cache.clear();
  }

  static void setBengaliDigits(bool value) {
    if (bengaliDigits == value) return;
    bengaliDigits = value;
    _cache.clear();
  }

  /// The text as it should be shown now.
  static String tr(String text) {
    if (!isBengali || text.isEmpty) return text;
    return _cache.putIfAbsent(text, () => _translate(text));
  }

  static String _translate(String text) {
    final core = text.trim();
    if (core.isEmpty) return text;
    final start = text.indexOf(core);
    final lead = text.substring(0, start);
    final trail = text.substring(start + core.length);
    var out = _lookup(core);
    out = swapDateWords(out);
    if (bengaliDigits) out = toBengaliDigits(out);
    return '$lead$out$trail';
  }

  static String _lookup(String core) {
    final exact = bnExact[core];
    if (exact != null) return exact;

    // A line joined with " · " is translated piece by piece, so a broad template (like "{} of {}")
    // cannot swallow the whole line. Only templates that themselves contain " · " match it whole.
    final dotted = core.contains(' · ');
    for (final t in _templates) {
      if (dotted && !t.dotted) continue;
      final m = t.pattern.firstMatch(core);
      if (m == null) continue;
      var result = t.bengali;
      for (var i = 1; i <= m.groupCount; i++) {
        final piece = _piece(m.group(i)!);
        // `{1}`, `{2}`... place a piece by number (to reorder); a plain `{}` takes the next free one.
        result = result.contains('{$i}')
            ? result.replaceAll('{$i}', piece)
            : result.replaceFirstMapped(RegExp(r'\{#?\}'), (_) => piece);
      }
      return result;
    }

    if (core.contains(' · ')) return core.split(' · ').map(_piece).join(' · ');
    if (core.contains(', ')) return core.split(', ').map(_piece).join(', ');
    return core;
  }

  /// A part of a longer text: translated if it is text, left alone if it is an amount or a number.
  static String _piece(String piece) {
    if (!RegExp(r'[A-Za-z]{2}').hasMatch(piece)) return piece;
    return _lookup(piece.trim());
  }

  static final List<_Template> _templates = [
    for (final e in bnTemplates.entries) _Template.from(e.key, e.value),
  ];
}

class _Template {
  _Template(this.pattern, this.bengali, {required this.dotted});

  factory _Template.from(String english, String bengali) {
    final escaped = RegExp.escape(english)
        .replaceAll(RegExp.escape('{}'), '(.+?)')
        .replaceAll(RegExp.escape('{#}'), r'(\d[\d,]*)');
    return _Template(RegExp('^$escaped\$', dotAll: true), bengali, dotted: english.contains(' · '));
  }

  final RegExp pattern;
  final String bengali;

  /// The English template itself contains " · ".
  final bool dotted;
}

const _asciiDigits = '0123456789';
const _bengaliDigits = '০১২৩৪৫৬৭৮৯';

String toBengaliDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = _asciiDigits.indexOf(c);
    b.write(i < 0 ? c : _bengaliDigits[i]);
  }
  return b.toString();
}

/// Shorthand used all over the app for texts that are not shown through [Text].
String tr(String text) => L10n.tr(text);
