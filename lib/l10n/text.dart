import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Text;

import 'l10n.dart';

export 'l10n.dart' show tr;

/// Tells every [Text] below it that the language or the digit style changed, so they redraw.
class LanguageScope extends InheritedWidget {
  const LanguageScope({super.key, required this.language, required this.bengaliDigits, required super.child});

  final AppLanguage language;
  final bool bengaliDigits;

  static void watch(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LanguageScope>();

  @override
  bool updateShouldNotify(LanguageScope old) => language != old.language || bengaliDigits != old.bengaliDigits;
}

/// The app's text widget: exactly Flutter's [m.Text], except that in Bengali it shows the Bengali
/// translation of the English text it was given (see [L10n]). Every screen uses this one.
class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    LanguageScope.watch(context);
    final label = semanticsLabel == null ? null : L10n.tr(semanticsLabel!);
    if (textSpan != null) {
      return m.Text.rich(
        _span(textSpan!),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: label,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return m.Text(
      L10n.tr(data!),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: label,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  /// The same spans, with each piece of text translated on its own.
  static InlineSpan _span(InlineSpan span) {
    if (span is TextSpan) {
      return TextSpan(
        text: span.text == null ? null : L10n.tr(span.text!),
        children: span.children?.map(_span).toList(),
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }
    return span;
  }
}
