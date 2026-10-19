import 'package:flutter/material.dart';

/// Teal Mist palette. Values match the design plan.
abstract final class TealMist {
  // Light
  static const primary = Color(0xFF157A6E);
  static const primarySoft = Color(0xFFD5EFEA);
  static const background = Color(0xFFF4F7F6);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF17211F);
  static const muted = Color(0xFF5E6E6A);
  static const line = Color(0xFFE3EAE8);
  static const spending = Color(0xFFD85C4C);
  static const income = Color(0xFF2E9E6B);
  static const highlight = Color(0xFFF0A43A);

  // Dark
  static const primaryDark = Color(0xFF5CC8B8);
  static const primarySoftDark = Color(0xFF1D3A36);
  static const backgroundDark = Color(0xFF0F1514);
  static const cardDark = Color(0xFF172120);
  static const textDark = Color(0xFFE6EEEC);
  static const mutedDark = Color(0xFF93A5A1);
  static const lineDark = Color(0xFF22302D);
  static const spendingDark = Color(0xFFF08A7C);
  static const incomeDark = Color(0xFF6FD39E);
  static const highlightDark = Color(0xFFF4B860);
}

/// Category colours stay the same in light and dark mode so they are easy to remember.
abstract final class CategoryColors {
  static const food = Color(0xFFF29E4C);
  static const bazar = Color(0xFF78B159);
  static const transport = Color(0xFF4C8DF6);
  static const bills = Color(0xFF9B7BE0);
  static const rent = Color(0xFFC08457);
  static const shopping = Color(0xFFE86A9A);
  static const health = Color(0xFF3DB39E);
  static const education = Color(0xFFE9B949);
  static const entertainment = Color(0xFFF2766B);
  static const others = Color(0xFF94A3A0);

  static const all = [
    food, bazar, transport, bills, rent, shopping, health, education, entertainment, others,
  ];
}

/// Colours that Material's ColorScheme has no slot for.
@immutable
class HisabColors extends ThemeExtension<HisabColors> {
  const HisabColors({
    required this.spending,
    required this.income,
    required this.highlight,
    required this.card,
    required this.muted,
  });

  final Color spending;
  final Color income;
  final Color highlight;
  final Color card;
  final Color muted;

  static const light = HisabColors(
    spending: TealMist.spending,
    income: TealMist.income,
    highlight: TealMist.highlight,
    card: TealMist.card,
    muted: TealMist.muted,
  );

  static const dark = HisabColors(
    spending: TealMist.spendingDark,
    income: TealMist.incomeDark,
    highlight: TealMist.highlightDark,
    card: TealMist.cardDark,
    muted: TealMist.mutedDark,
  );

  @override
  HisabColors copyWith({Color? spending, Color? income, Color? highlight, Color? card, Color? muted}) {
    return HisabColors(
      spending: spending ?? this.spending,
      income: income ?? this.income,
      highlight: highlight ?? this.highlight,
      card: card ?? this.card,
      muted: muted ?? this.muted,
    );
  }

  @override
  HisabColors lerp(HisabColors? other, double t) {
    if (other == null) return this;
    return HisabColors(
      spending: Color.lerp(spending, other.spending, t)!,
      income: Color.lerp(income, other.income, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension HisabThemeX on BuildContext {
  HisabColors get hisab => Theme.of(this).extension<HisabColors>()!;
}

const _fontFamily = 'HindSiliguri';

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: TealMist.primary,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? TealMist.primaryDark : TealMist.primary,
    onPrimary: isDark ? TealMist.backgroundDark : Colors.white,
    primaryContainer: isDark ? TealMist.primarySoftDark : TealMist.primarySoft,
    onPrimaryContainer: isDark ? const Color(0xFFBFEDE5) : const Color(0xFF0B3F39),
    secondary: isDark ? TealMist.highlightDark : TealMist.highlight,
    onSecondary: const Color(0xFF2B1A00),
    error: isDark ? TealMist.spendingDark : TealMist.spending,
    surface: isDark ? TealMist.backgroundDark : TealMist.background,
    onSurface: isDark ? TealMist.textDark : TealMist.text,
    onSurfaceVariant: isDark ? TealMist.mutedDark : TealMist.muted,
    surfaceContainerLowest: isDark ? TealMist.backgroundDark : TealMist.card,
    surfaceContainerLow: isDark ? TealMist.cardDark : TealMist.card,
    surfaceContainer: isDark ? TealMist.cardDark : TealMist.card,
    outline: isDark ? TealMist.mutedDark : TealMist.muted,
    outlineVariant: isDark ? TealMist.lineDark : TealMist.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [isDark ? HisabColors.dark : HisabColors.light],
  );

  final cardColor = isDark ? TealMist.cardDark : TealMist.card;

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}
