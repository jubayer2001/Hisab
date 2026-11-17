import 'package:flutter/material.dart' hide Text;
import '../../l10n/text.dart';

class SummaryStat {
  const SummaryStat(this.label, this.value, {this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;
}

/// The row of figures at the bottom of the teal summary cards (Home and Reports).
///
/// It follows the width it is given instead of assuming one phone:
/// * normal: equal columns; one-line labels when they all fit, otherwise every label gets two
///   lines (measured, so it follows the phone's width and font) and the figures stay level;
/// * narrow (or a large system font): full-width rows, label left and figure right.
class SummaryStats extends StatelessWidget {
  const SummaryStats({super.key, required this.stats});

  final List<SummaryStat> stats;

  /// Below this inner width (logical pixels) the figures become full-width rows.
  static const columnsFrom = 250.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final soft = on.withValues(alpha: 0.82);
    final line = on.withValues(alpha: 0.25);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: soft);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: on,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // A bigger system font needs more room, so it counts as a narrower card.
    final fontScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / (fontScale > 1 ? fontScale : 1);

        if (width < columnsFrom) {
          return Column(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) Divider(color: line, height: 1),
                InkWell(
                  onTap: stats[i].onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(stats[i].label, style: labelStyle),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(stats[i].value, style: valueStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // Measure instead of guessing: if any label would not fit on one line in its column (it
        // differs by phone and font), every label gets two lines, so none is cut off and the
        // figures below still share one line.
        final columnWidth = (constraints.maxWidth - (stats.length - 1)) / stats.length - 8;
        final scaler = MediaQuery.textScalerOf(context);
        TextPainter painter(String text) => TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final oneLine = stats.every((s) => painter(s.label).width <= columnWidth);
        final lineHeight = painter('A').height;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) VerticalDivider(color: line, width: 1, thickness: 1),
                Expanded(
                  child: InkWell(
                    onTap: stats[i].onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Every label has the same height, so the figures share one line.
                          Container(
                            alignment: Alignment.bottomCenter,
                            constraints: BoxConstraints(minHeight: oneLine ? 0 : 2 * lineHeight),
                            child: Text(
                              stats[i].label,
                              textAlign: TextAlign.center,
                              maxLines: oneLine ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(stats[i].value, style: valueStyle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
