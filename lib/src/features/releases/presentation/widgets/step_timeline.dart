import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/release.dart';

/// The pipeline as a vertical list of steps with their state and duration.
class StepTimeline extends StatelessWidget {
  const StepTimeline({required this.steps, super.key});

  final List<ReleaseStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, step) in steps.indexed)
          _StepTile(step: step, isLast: index == steps.length - 1),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.isLast});

  final ReleaseStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActive = step.status == StepStatus.running;
    final isDone = step.status == StepStatus.succeeded;
    final isFailed = step.status == StepStatus.failed;
    final isMuted =
        step.status == StepStatus.pending || step.status == StepStatus.skipped;

    final color = isFailed
        ? scheme.error
        : isDone
        ? scheme.tertiary
        : isActive
        ? scheme.primary
        : scheme.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _Dot(status: step.status, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isDone ? scheme.tertiary : scheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Gap.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      step.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isActive || isFailed
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isMuted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (step.duration != null) ...[
                    const SizedBox(width: Gap.sm),
                    Text(
                      formatDuration(step.duration!),
                      style: theme.textTheme.mono.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.status, required this.color});

  final StepStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 20,
      height: 20,
      child: switch (status) {
        StepStatus.running => Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
        ),
        StepStatus.succeeded => DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.check, size: 13, color: scheme.onTertiary),
        ),
        StepStatus.failed => DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.close, size: 13, color: scheme.onError),
        ),
        StepStatus.skipped => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.remove, size: 12, color: color),
        ),
        StepStatus.pending => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
      },
    );
  }
}
