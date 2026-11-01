import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import 'sheet.dart';

Future<Color?> showCategoryColorPicker(BuildContext context, {required Color initialColor}) =>
    showAppSheet<Color>(context, builder: (_) => CategoryColorPicker(initialColor: initialColor));

class CategoryColorPicker extends StatefulWidget {
  const CategoryColorPicker({super.key, required this.initialColor});
  final Color initialColor;

  @override
  State<CategoryColorPicker> createState() => _CategoryColorPickerState();
}

class _AdjustColour extends Intent {
  const _AdjustColour(this.hue, this.saturation);
  final double hue;
  final double saturation;
}

class _CategoryColorPickerState extends State<CategoryColorPicker> {
  late HSVColor _hsv;
  late Color _selected;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor).withAlpha(1);
    _selected = widget.initialColor;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _adjust(double hue, double saturation) => setState(() {
    _hsv = _hsv.withHue((_hsv.hue + hue) % 360).withSaturation((_hsv.saturation + saturation).clamp(0.0, 1.0));
    _selected = _hsv.toColor();
  });

  void _pick(Offset position, double size) {
    _focus.requestFocus();
    final delta = position - Offset(size / 2, size / 2);
    final hue = (math.atan2(delta.dx, -delta.dy) * 180 / math.pi + 360) % 360;
    setState(() {
      _hsv = _hsv.withHue(hue).withSaturation((delta.distance / (size / 2)).clamp(0.0, 1.0));
      _selected = _hsv.toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = context.hisab;
    return SheetScaffold(
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Done')),
          ),
        ],
      ),
      children: [
        const SheetHeader('Choose a colour'),
        const SizedBox(height: 8),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(220.0, constraints.maxWidth);
              final angle = _hsv.hue * math.pi / 180;
              final point = Offset(
                size / 2 + math.sin(angle) * _hsv.saturation * size / 2,
                size / 2 - math.cos(angle) * _hsv.saturation * size / 2,
              );
              return FocusableActionDetector(
                focusNode: _focus,
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustColour(-5, 0),
                  SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustColour(5, 0),
                  SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustColour(0, 0.05),
                  SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustColour(0, -0.05),
                },
                actions: {
                  _AdjustColour: CallbackAction<_AdjustColour>(
                    onInvoke: (intent) {
                      _adjust(intent.hue, intent.saturation);
                      return null;
                    },
                  ),
                },
                child: Semantics(
                  label: 'Colour wheel',
                  value: 'Hue ${_hsv.hue.round()}, saturation ${(_hsv.saturation * 100).round()} percent',
                  increasedValue:
                      'Hue ${((_hsv.hue + 5) % 360).round()}, saturation ${(_hsv.saturation * 100).round()} percent',
                  decreasedValue:
                      'Hue ${((_hsv.hue - 5) % 360).round()}, saturation ${(_hsv.saturation * 100).round()} percent',
                  onIncrease: () => _adjust(5, 0),
                  onDecrease: () => _adjust(-5, 0),
                  child: GestureDetector(
                    key: const ValueKey('category-colour-wheel'),
                    onPanDown: (d) => _pick(d.localPosition, size),
                    onPanUpdate: (d) => _pick(d.localPosition, size),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  transform: GradientRotation(-math.pi / 2),
                                  colors: const [
                                    Color(0xFFFF0000),
                                    Color(0xFFFFFF00),
                                    Color(0xFF00FF00),
                                    Color(0xFF00FFFF),
                                    Color(0xFF0000FF),
                                    Color(0xFFFF00FF),
                                    Color(0xFFFF0000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0)]),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 1 - _hsv.value),
                              ),
                            ),
                          ),
                          Positioned(
                            left: point.dx - 9,
                            top: point.dy - 9,
                            child: IgnorePointer(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 1, spreadRadius: 1)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              key: const ValueKey('selected-category-colour'),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _selected,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 10),
            Text('Selected colour', style: theme.textTheme.bodySmall?.copyWith(color: colors.muted)),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Brightness'),
        Slider(
          value: _hsv.value,
          label: '${(_hsv.value * 100).round()}%',
          onChanged: (value) => setState(() {
            _hsv = _hsv.withValue(value);
            _selected = _hsv.toColor();
          }),
        ),
      ],
    );
  }
}
