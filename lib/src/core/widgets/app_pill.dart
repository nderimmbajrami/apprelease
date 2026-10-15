import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

enum PillTone { neutral, accent, success, warning, danger }

/// A small status badge: release state, platform, track.
class AppPill extends StatelessWidget {
  const AppPill({
    required this.label,
    this.icon,
    this.tone = PillTone.neutral,
    this.isMono = false,
    this.pulse = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final PillTone tone;
  final bool isMono;

  /// A small animated dot in place of the icon — "this is happening now".
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (background, foreground) = switch (tone) {
      PillTone.neutral => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
      ),
      PillTone.accent => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PillTone.success => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PillTone.warning => (
        theme.brightness == Brightness.light
            ? const Color(0xFFFFF1DB)
            : const Color(0xFF3A2A0C),
        theme.brightness == Brightness.light
            ? const Color(0xFF9A4B00)
            : const Color(0xFFFBBF24),
      ),
      PillTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            _PulseDot(color: foreground),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style:
                  (isMono
                          ? theme.textTheme.monoStrong
                          : theme.textTheme.labelMedium)
                      ?.copyWith(color: foreground, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: .35, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
