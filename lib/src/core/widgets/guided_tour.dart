import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_spacing.dart';

/// One stop of a tour: the widget to point at and what to say about it.
class TourStep {
  const TourStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final String title;
  final String body;
}

/// Dims the screen, cuts a lit window around each step's widget and puts a
/// short explanation next to it. Steps whose widget is not on screen (the
/// sidebar on a phone, say) are skipped. Completes when the tour ends.
Future<void> showGuidedTour(BuildContext context, List<TourStep> steps) {
  final visible = [
    for (final s in steps)
      if (s.target.currentContext?.findRenderObject() is RenderBox) s,
  ];
  if (visible.isEmpty) return Future.value();
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  final done = Completer<void>();
  entry = OverlayEntry(
    builder: (_) => _TourOverlay(
      steps: visible,
      onClose: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onClose});

  final List<TourStep> steps;
  final VoidCallback onClose;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  var _index = 0;

  Rect _rectOf(TourStep step) {
    final box = step.target.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    final origin = box.localToGlobal(Offset.zero);
    return (origin & box.size).inflate(6);
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= widget.steps.length) {
      widget.onClose();
      return;
    }
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final step = widget.steps[_index];
    final hole = _rectOf(step);
    final last = _index == widget.steps.length - 1;

    const cardWidth = 340.0;
    const cardHeightGuess = 200.0;
    final below = hole.bottom + Gap.md + cardHeightGuess < size.height;
    final right = hole.right + Gap.md + cardWidth < size.width;
    // Beside a tall narrow target (the sidebar), below or above otherwise.
    final beside = hole.height > 40 && hole.width < 260 && right;
    final left = beside
        ? hole.right + Gap.md
        : (hole.left).clamp(Gap.lg, size.width - cardWidth - Gap.lg);
    final top = beside
        ? hole.top.clamp(Gap.lg, size.height - cardHeightGuess - Gap.lg)
        : below
        ? hole.bottom + Gap.md
        : math.max(Gap.lg, hole.top - Gap.md - cardHeightGuess);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // The scrim swallows taps: the tour is the only thing to answer.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: hole),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, rect, _) => CustomPaint(
                  painter: _ScrimPainter(
                    hole: rect ?? hole,
                    scrim: Colors.black.withValues(alpha: .62),
                    ring: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: left.toDouble(),
            top: top.toDouble(),
            width: math.min(cardWidth, size.width - 2 * Gap.lg),
            child: Container(
              padding: const EdgeInsets.all(Gap.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: scheme.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < widget.steps.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 4),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _index
                                ? scheme.primary
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        l10n.tourStepOf(_index + 1, widget.steps.length),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  Text(step.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(step.body, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: Gap.lg),
                  Row(
                    children: [
                      TextButton(
                        onPressed: widget.onClose,
                        child: Text(l10n.tourSkip),
                      ),
                      const Spacer(),
                      if (_index > 0)
                        TextButton(
                          onPressed: () => _go(-1),
                          child: Text(l10n.tourBack),
                        ),
                      const SizedBox(width: Gap.xs),
                      FilledButton(
                        onPressed: () => _go(1),
                        child: Text(last ? l10n.tourDone : l10n.tourNext),
                      ),
                    ],
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

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.scrim, required this.ring});

  final Rect hole;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(12));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(r);
    canvas.drawPath(path, Paint()..color = scrim);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.scrim != scrim || old.ring != ring;
}
