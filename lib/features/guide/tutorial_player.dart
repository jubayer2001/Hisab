import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import '../../app/theme.dart';
import '../../l10n/text.dart';
import 'guide_widgets.dart';
import 'tutorials.dart';

/// Plays one or more tutorials: an animated guide of the real screens. A finger moves to the right
/// button and presses it, with one sentence per step. It can be paused, stepped back or forward,
/// and replayed. [tour] says this is the quick tour (several tutorials back to back).
class TutorialPlayerScreen extends StatefulWidget {
  const TutorialPlayerScreen({super.key, required this.ids, this.tour = false});

  final List<TutorialId> ids;
  final bool tour;

  @override
  State<TutorialPlayerScreen> createState() => _TutorialPlayerScreenState();
}

typedef _Step = ({Tutorial tutorial, int index, TutorialStep step});

class _TutorialPlayerScreenState extends State<TutorialPlayerScreen> with SingleTickerProviderStateMixin {
  /// The mini screens are laid out on this fixed canvas and scaled to fit, so they never overflow.
  static const _canvas = Size(360, 440);

  late final List<_Step> _steps = [
    for (final id in widget.ids)
      for (var i = 0; i < tutorialById(id).steps.length; i++)
        (tutorial: tutorialById(id), index: i, step: tutorialById(id).steps[i]),
  ];

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: Tutorial.stepSeconds),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _advance();
    });

  /// One target key per step: while one step fades into the next both are on screen, and a
  /// GlobalKey may only be used once.
  late final List<GlobalKey> _targetKeys = List.generate(_steps.length, (_) => GlobalKey());
  final _stageKey = GlobalKey();
  Timer? _moveTimer;
  Timer? _tapTimer;

  int _i = 0;
  bool _playing = true;
  bool _finished = false;
  bool _glow = false;
  Offset? _pointer;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _tapTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  void _begin() {
    _moveTimer?.cancel();
    _tapTimer?.cancel();
    _glow = false;
    _pointer = null;
    _finished = false;
    if (_playing) {
      _progress.forward(from: 0);
    } else {
      _progress.value = 0;
    }
    // Let the new mini screen be laid out, then send the finger to its target and press it.
    _moveTimer = Timer(const Duration(milliseconds: 350), _placePointer);
    _tapTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _glow = true);
    });
  }

  void _placePointer() {
    if (!mounted) return;
    final target = _targetKeys[_i].currentContext?.findRenderObject();
    final stage = _stageKey.currentContext?.findRenderObject();
    if (target is! RenderBox || stage is! RenderBox || !target.attached || !stage.attached) return;
    final center = stage.globalToLocal(target.localToGlobal(target.size.center(Offset.zero)));
    setState(() => _pointer = center);
  }

  void _advance() {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
      _begin();
    } else {
      setState(() {
        _finished = true;
        _playing = false;
      });
    }
  }

  void _goTo(int index) {
    setState(() => _i = index.clamp(0, _steps.length - 1));
    _begin();
  }

  void _togglePlay() {
    if (_finished) {
      setState(() => _playing = true);
      _goTo(0);
      return;
    }
    setState(() => _playing = !_playing);
    if (_playing) {
      _progress.forward();
    } else {
      _progress.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.hisab;
    final current = _steps[_i];
    final tutorialNumber = widget.ids.indexOf(current.tutorial.id) + 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: tr('Close'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.tutorial.title, style: theme.textTheme.titleMedium, maxLines: 2),
                        Text(
                          widget.tour ? 'Quick tour · $tutorialNumber of ${widget.ids.length}' : 'Tutorial',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                key: _stageKey,
                margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      // The guide always uses the normal text size, so the mini screens keep their shape.
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: TutorialScope(
                            key: ValueKey(_i),
                            targetKey: _targetKeys[_i],
                            glowing: _glow,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: _canvas.width,
                                height: _canvas.height,
                                child: Builder(builder: current.step.scene),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_pointer != null)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        left: _pointer!.dx - 14,
                        top: _pointer!.dy - 8,
                        child: IgnorePointer(child: _Finger(pressing: _glow)),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${current.index + 1} / ${current.tutorial.steps.length}',
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(current.step.caption, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _goTo(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: i == _i && !_finished
                                ? AnimatedBuilder(
                                    animation: _progress,
                                    builder: (_, _) => LinearProgressIndicator(
                                      value: _progress.value,
                                      minHeight: 6,
                                      backgroundColor: scheme.outlineVariant,
                                    ),
                                  )
                                : LinearProgressIndicator(
                                    value: i <= _i ? 1 : 0,
                                    minHeight: 6,
                                    backgroundColor: scheme.outlineVariant,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: tr('Back'),
                    iconSize: 30,
                    onPressed: _i == 0 ? null : () => _goTo(_i - 1),
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  const SizedBox(width: 14),
                  IconButton.filled(
                    tooltip: _finished ? tr('Replay') : (_playing ? tr('Pause') : tr('Play')),
                    iconSize: 38,
                    style: IconButton.styleFrom(minimumSize: const Size(68, 68)),
                    onPressed: _togglePlay,
                    icon: Icon(_finished ? Icons.replay_rounded : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                  ),
                  const SizedBox(width: 14),
                  IconButton.filledTonal(
                    tooltip: tr('Next'),
                    iconSize: 30,
                    onPressed: _i >= _steps.length - 1 ? null : () => _goTo(_i + 1),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The finger that presses things. When [pressing] a ring pulses under its tip.
class _Finger extends StatefulWidget {
  const _Finger({required this.pressing});

  final bool pressing;

  @override
  State<_Finger> createState() => _FingerState();
}

class _FingerState extends State<_Finger> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didUpdateWidget(_Finger old) {
    super.didUpdateWidget(old);
    if (widget.pressing && !old.pressing) _pulse.repeat();
    if (!widget.pressing) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = context.hisab.highlight;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Opacity(
                opacity: widget.pressing ? (1 - _pulse.value) * 0.9 : 0,
                child: Container(
                  width: 14 + 34 * _pulse.value,
                  height: 14 + 34 * _pulse.value,
                  margin: EdgeInsets.all(17 * (1 - _pulse.value)),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: highlight),
                ),
              ),
            ),
          ),
          Icon(
            Icons.touch_app_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
          ),
        ],
      ),
    );
  }
}
