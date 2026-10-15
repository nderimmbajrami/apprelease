import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The AppRelease mark: a white arrow on a black tile, same as the website.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(size / 4.2),
      ),
      child: Icon(
        Icons.arrow_upward_rounded,
        size: size * .62,
        color: Colors.white,
      ),
    );
  }
}

/// Mark plus wordmark, for the shell and the auth pages.
class BrandLockup extends StatelessWidget {
  const BrandLockup({this.size = 32, this.light = false, super.key});

  final double size;

  /// White text, for the dark pane.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = light ? Colors.white : theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        const SizedBox(width: Gap.sm + 2),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              style: theme.textTheme.titleMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
              children: [
                const TextSpan(text: 'apprelease'),
                TextSpan(
                  text: '.store',
                  style: TextStyle(
                    color: ink.withValues(alpha: .5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
