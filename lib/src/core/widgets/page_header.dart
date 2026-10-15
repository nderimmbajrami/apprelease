import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Back button, title block and actions. Below the compact breakpoint the
/// actions drop to their own line instead of squeezing the title.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.leading,
    super.key,
  });

  static const _compactWidth = 760.0;

  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _compactWidth;
        final actionBar = Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: actions,
        );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.headlineSmall,
              child: title,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodySmall,
                child: subtitle!,
              ),
            ],
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null || leading != null)
                Row(
                  children: [
                    if (onBack != null) BackChip(onPressed: onBack!),
                    if (leading != null) ...[
                      if (onBack != null) const SizedBox(width: Gap.sm),
                      leading!,
                    ],
                  ],
                ),
              const SizedBox(height: Gap.sm),
              titleBlock,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Gap.md),
                actionBar,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null) ...[
              BackChip(onPressed: onBack!),
              const SizedBox(width: Gap.md),
            ],
            if (leading != null) ...[leading!, const SizedBox(width: Gap.md)],
            Expanded(child: titleBlock),
            if (actions.isNotEmpty) Flexible(child: actionBar),
          ],
        );
      },
    );
  }
}

/// A square outlined back button.
class BackChip extends StatelessWidget {
  const BackChip({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 40),
          foregroundColor: scheme.onSurfaceVariant,
        ),
        child: const Icon(Icons.arrow_back, size: 18),
      ),
    );
  }
}
