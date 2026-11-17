import 'package:flutter/material.dart' hide Text;

import '../../app/theme.dart';
import '../../core/widgets/charts.dart';
import '../../l10n/text.dart';

/// Tells the mini screens which spot the tutorial finger is about to press, and when to glow.
class TutorialScope extends InheritedWidget {
  const TutorialScope({
    super.key,
    required this.targetKey,
    required this.glowing,
    required super.child,
  });

  final GlobalKey targetKey;
  final bool glowing;

  static TutorialScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TutorialScope>();

  @override
  bool updateShouldNotify(TutorialScope old) =>
      glowing != old.glowing || targetKey != old.targetKey;
}

/// Marks the one place in a mini screen that the finger presses.
class TapSpot extends StatelessWidget {
  const TapSpot({super.key, required this.child, this.radius = 12});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scope = TutorialScope.maybeOf(context);
    if (scope == null) return child;
    return KeyedSubtree(
      key: scope.targetKey,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: scope.glowing
              ? Border.all(color: context.hisab.highlight, width: 3)
              : null,
        ),
        child: child,
      ),
    );
  }
}

Widget _maybeTap(bool tap, Widget child, {double radius = 12}) =>
    tap ? TapSpot(radius: radius, child: child) : child;

/// A mini app screen: [children] from the top, an optional bottom bar and an optional layer on top.
class MiniScene extends StatelessWidget {
  const MiniScene({super.key, required this.children, this.nav, this.overlay});

  final List<Widget> children;
  final Widget? nav;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, nav == null ? 10 : 58),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (nav != null) Positioned(left: 0, right: 0, bottom: 0, child: nav!),
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}

class MiniTitle extends StatelessWidget {
  const MiniTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// The teal summary card, simplified.
class MiniHero extends StatelessWidget {
  const MiniHero({
    super.key,
    required this.big,
    this.stats,
    this.slotLabel,
    this.slotValue,
    this.tapBig = false,
    this.tapStat,
    this.tapSlot = false,
    this.label = 'Spent today',
  });

  final String big;
  final String label;
  final List<(String, String)>? stats;
  final String? slotLabel;
  final String? slotValue;
  final bool tapBig;
  final int? tapStat;
  final bool tapSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final soft = on.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                    _maybeTap(
                      tapBig,
                      Text(
                        big,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: on,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (slotLabel != null)
                _maybeTap(
                  tapSlot,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: on.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          slotLabel!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: soft,
                          ),
                        ),
                        Text(
                          slotValue ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (stats != null) ...[
            Divider(color: on.withValues(alpha: 0.28), height: 18),
            Row(
              children: [
                for (var i = 0; i < stats!.length; i++)
                  Expanded(
                    child: _maybeTap(
                      tapStat == i,
                      Column(
                        children: [
                          Text(
                            stats![i].$1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: soft,
                            ),
                          ),
                          Text(
                            stats![i].$2,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: on,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MiniRow extends StatelessWidget {
  const MiniRow({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tap = false,
    this.trailingColor,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool tap;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _maybeTap(
        tap,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: trailingColor ?? colors.spending,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniSeg extends StatelessWidget {
  const MiniSeg({
    super.key,
    required this.labels,
    required this.on,
    this.tapIndex,
  });

  final List<String> labels;
  final int on;
  final int? tapIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _maybeTap(
                tapIndex == i,
                Container(
                  alignment: Alignment.center,
                  color: i == on ? scheme.primaryContainer : null,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: i == on ? FontWeight.w700 : FontWeight.w500,
                      color: i == on
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
                radius: 4,
              ),
            ),
        ],
      ),
    );
  }
}

class MiniButton extends StatelessWidget {
  const MiniButton(
    this.label, {
    super.key,
    this.tonal = false,
    this.tap = false,
  });

  final String label;
  final bool tonal;
  final bool tap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _maybeTap(
        tap,
        Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tonal ? scheme.primaryContainer : scheme.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tonal ? scheme.onPrimaryContainer : scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        radius: 13,
      ),
    );
  }
}

class MiniField extends StatelessWidget {
  const MiniField(this.label, this.value, {super.key, this.tap = false});

  final String label;
  final String value;
  final bool tap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _maybeTap(
        tap,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.hisab.muted,
                ),
              ),
              Text(value, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniChips extends StatelessWidget {
  const MiniChips(this.labels, {super.key, this.tapIndex});

  final List<String> labels;
  final int? tapIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            _maybeTap(
              tapIndex == i,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.hisab.card,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(labels[i], style: theme.textTheme.bodySmall),
              ),
              radius: 10,
            ),
        ],
      ),
    );
  }
}

class MiniNav extends StatelessWidget {
  const MiniNav({super.key, required this.on, this.tap});

  /// 0 Home, 1 History, 3 Reports, 4 More.
  final int on;

  /// Which bar item the finger presses: 'add', 'reports' or 'more'.
  final String? tap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(int index, IconData icon, String label, {String? key}) {
      final selected = index == on;
      return Expanded(
        child: Center(
          child: _maybeTap(
            tap != null && tap == key,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              // A fixed small size, scaled down if a font is taller than expected, so the bar never overflows.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected ? scheme.primary : context.hisab.muted,
                    ),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1.1,
                        color: selected ? scheme.primary : context.hisab.muted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            radius: 12,
          ),
        ),
      );
    }

    return Container(
      height: 52,
      color: context.hisab.card,
      child: Row(
        children: [
          item(0, Icons.home_rounded, 'Home'),
          item(1, Icons.receipt_long_rounded, 'History'),
          Expanded(
            child: Center(
              child: _maybeTap(
                tap == 'add',
                Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_rounded, color: scheme.onPrimary),
                ),
                radius: 12,
              ),
            ),
          ),
          item(3, Icons.insert_chart_rounded, 'Reports', key: 'reports'),
          item(4, Icons.grid_view_rounded, 'More', key: 'more'),
        ],
      ),
    );
  }
}

class MiniCategoryGrid extends StatelessWidget {
  const MiniCategoryGrid({super.key, this.tapIndex});

  final int? tapIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(Color, IconData, String)>[
      (const Color(0xFFF29E4C), Icons.restaurant_rounded, 'Food'),
      (const Color(0xFF78B159), Icons.shopping_cart_rounded, 'Bazar'),
      (const Color(0xFF4C8DF6), Icons.directions_bus_rounded, 'Transport'),
      (const Color(0xFF9B7BE0), Icons.receipt_long_rounded, 'Bills'),
      (const Color(0xFFE86A9A), Icons.shopping_bag_rounded, 'Shopping'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _maybeTap(
                tapIndex == i,
                Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: items[i].$1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(items[i].$2, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MiniKeys extends StatelessWidget {
  const MiniKeys({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final k in [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '.',
            '0',
            '⌫',
          ])
            Container(
              width: 104,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.hisab.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(k, style: theme.textTheme.titleMedium),
            ),
        ],
      ),
    );
  }
}

/// A month grid for the calendar tutorial and the "what's new" card (November 2026, weeks from Saturday).
class MiniCalendar extends StatelessWidget {
  const MiniCalendar({
    super.key,
    this.selected = 14,
    this.tapDay,
    this.today = 17,
  });

  final int selected;
  final int? tapDay;
  final int today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 1 November 2026 is a Sunday; with Saturday first it sits in the second column.
    const lead = 1;
    final cells = <Widget>[
      for (final l in ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'])
        Center(
          child: Text(
            l,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.hisab.muted,
            ),
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= 30; d++)
        _maybeTap(
          tapDay == d,
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: d == selected ? scheme.primary : null,
              shape: BoxShape.circle,
              border: d == today && d != selected
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '$d',
              style: theme.textTheme.bodySmall?.copyWith(
                color: d == selected
                    ? scheme.onPrimary
                    : (d > today
                          ? scheme.onSurface.withValues(alpha: 0.3)
                          : null),
                fontWeight: d == selected ? FontWeight.w700 : null,
              ),
            ),
          ),
          radius: 20,
        ),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      childAspectRatio: 1.25,
      children: cells,
    );
  }
}

class MiniDonut extends StatelessWidget {
  const MiniDonut({super.key, this.tap = false, this.size = 120});

  final bool tap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _maybeTap(
        tap,
        DonutChart(
          size: size,
          thickness: size * 0.18,
          trackColor: Theme.of(context).colorScheme.outlineVariant,
          slices: const [
            DonutSlice(value: 39, color: Color(0xFFC08457)),
            DonutSlice(value: 17, color: Color(0xFF78B159)),
            DonutSlice(value: 11, color: Color(0xFFF29E4C)),
            DonutSlice(value: 9, color: Color(0xFFE86A9A)),
            DonutSlice(value: 8, color: Color(0xFF9B7BE0)),
            DonutSlice(value: 7, color: Color(0xFFE9B949)),
            DonutSlice(value: 9, color: Color(0xFF3DB39E)),
          ],
        ),
        radius: size / 2,
      ),
    );
  }
}

class MiniGoal extends StatelessWidget {
  const MiniGoal({super.key, this.tap = false});

  final bool tap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    const color = Color(0xFF4C8DF6);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _maybeTap(
        tap,
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New laptop', style: theme.textTheme.titleSmall),
                        Text(
                          '৳36,000 of ৳60,000',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '60%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 6,
                  color: color,
                  backgroundColor: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet rising from the bottom of a mini screen, with the screen dimmed behind it.
class MiniSheet extends StatelessWidget {
  const MiniSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ],
    );
  }
}

class MiniToast extends StatelessWidget {
  const MiniToast(this.text, this.action, {super.key});

  final String text;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3533),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
          Text(
            action,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF5CC8B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniToggleRow extends StatelessWidget {
  const MiniToggleRow(
    this.label, {
    super.key,
    required this.on,
    this.tap = false,
    this.dim = false,
  });

  final String label;
  final bool on;
  final bool tap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.hisab.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              _maybeTap(
                tap,
                IgnorePointer(
                  child: Switch(value: on, onChanged: (_) {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniLanguagePill extends StatelessWidget {
  const MiniLanguagePill(this.label, {super.key, this.tap = false});

  final String label;
  final bool tap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return _maybeTap(
      tap,
      Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 18, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      radius: 18,
    );
  }
}

/// A pill showing a date, like the one above Reports and History.
class MiniDatePill extends StatelessWidget {
  const MiniDatePill(this.label, {super.key, this.tap = false});

  final String label;
  final bool tap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: _maybeTap(
        tap,
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: context.hisab.card,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: context.hisab.muted),
            ],
          ),
        ),
        radius: 22,
      ),
    );
  }
}

/// A row with a warning or note, like the notices on Home.
class MiniNote extends StatelessWidget {
  const MiniNote({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.tap = false,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool tap;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _maybeTap(
        tap,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.hisab.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
              if (action != null)
                Text(
                  action!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
