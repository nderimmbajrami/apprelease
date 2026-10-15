import 'package:flutter/material.dart';

import '../../../apps/domain/app_project.dart';

/// A small tile with the platform's glyph.
class PlatformIcon extends StatelessWidget {
  const PlatformIcon(this.platform, {this.size = 32, super.key});

  final Platform platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(size / 3.6),
      ),
      child: Icon(
        platform == Platform.android ? Icons.android : Icons.apple,
        size: size * .6,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
