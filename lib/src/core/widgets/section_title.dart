import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A small heading over a group of cards, with an optional action on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?action,
        ],
      ),
    );
  }
}
