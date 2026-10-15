import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// A number worth knowing at a glance: releases this month, success rate.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.icon,
    this.tone,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone ?? theme.colorScheme.onSurface;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            value,
            style: theme.textTheme.mono.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
