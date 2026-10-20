import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/logic/reports.dart';

class DonutSlice {
  const DonutSlice({required this.value, required this.color});

  final double value;
  final Color color;
}

/// A ring split into coloured slices, with [center] shown in the hole.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.trackColor,
    this.size = 150,
    this.thickness = 22,
    this.center,
  });

  final List<DonutSlice> slices;
  final Color trackColor;
  final double size;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices, trackColor: trackColor, thickness: thickness),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.trackColor, required this.thickness});

  final List<DonutSlice> slices;
  final Color trackColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    // The empty ring, visible when there is nothing to show.
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);

    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;

    // A small gap between slices, except when there is only one slice.
    final gap = slices.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.value / total * math.pi * 2;
      if (sweep > gap) {
        canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint..color = s.color);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.trackColor != trackColor || old.thickness != thickness;
}

/// Vertical bars with a label under each. Tap a bar to select it.
class SpendBarChart extends StatelessWidget {
  const SpendBarChart({
    super.key,
    required this.bars,
    required this.color,
    required this.labelStyle,
    this.selectedIndex,
    this.onSelected,
    this.height = 170,
    this.labelEvery = 1,
  });

  final List<BarData> bars;
  final Color color;
  final TextStyle labelStyle;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelected;
  final double height;

  /// Label every Nth bar (a month has too many bars to label them all).
  final int labelEvery;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = bars.isEmpty ? 1.0 : constraints.maxWidth / bars.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            if (onSelected == null || bars.isEmpty) return;
            final i = (d.localPosition.dx / slot).floor().clamp(0, bars.length - 1);
            onSelected!(i == selectedIndex ? null : i);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _BarPainter(
              bars: bars,
              color: color,
              labelStyle: labelStyle,
              selectedIndex: selectedIndex,
              labelEvery: labelEvery,
            ),
          ),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bars,
    required this.color,
    required this.labelStyle,
    required this.selectedIndex,
    required this.labelEvery,
  });

  final List<BarData> bars;
  final Color color;
  final TextStyle labelStyle;
  final int? selectedIndex;
  final int labelEvery;

  static const _labelHeight = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final chartHeight = size.height - _labelHeight;
    final maxAmount = bars.fold<int>(1, (m, b) => math.max(m, b.amount));
    final slot = size.width / bars.length;
    final barWidth = math.min(slot * 0.62, 28.0);

    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final centerX = slot * i + slot / 2;
      final selected = selectedIndex == i;
      final faded = selectedIndex != null && !selected;

      final h = b.amount == 0 ? 3.0 : math.max(4.0, b.amount / maxAmount * chartHeight);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - barWidth / 2, chartHeight - h, barWidth, h),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(1.5),
        bottomRight: const Radius.circular(1.5),
      );
      final paint = Paint()
        ..color = b.amount == 0
            ? color.withValues(alpha: 0.16)
            : color.withValues(alpha: faded ? 0.35 : 1.0);
      canvas.drawRRect(rect, paint);

      // With labelEvery 5 the labels read 1, 5, 10, 15 ... like a calendar.
      final showLabel = labelEvery == 1 || i == 0 || (i + 1) % labelEvery == 0 || selected;
      if (showLabel) {
        final tp = TextPainter(
          text: TextSpan(
            text: b.label,
            style: selected ? labelStyle.copyWith(fontWeight: FontWeight.w700, color: color) : labelStyle,
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: slot * labelEvery);
        tp.paint(canvas, Offset(centerX - tp.width / 2, chartHeight + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.bars != bars ||
      old.color != color ||
      old.selectedIndex != selectedIndex ||
      old.labelEvery != labelEvery ||
      old.labelStyle != labelStyle;
}
