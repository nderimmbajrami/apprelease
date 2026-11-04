import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'brand_mark.dart';

/// What the console shows until the session is known: the same mark and bar
/// as the splash in index.html, so the hand-over from HTML to Flutter is
/// invisible, and nothing else flashes before the right screen.
class StartingScreen extends StatelessWidget {
  const StartingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 48),
            const SizedBox(height: Gap.lg),
            Text.rich(
              TextSpan(
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
            const SizedBox(height: Gap.xl),
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: ink.withValues(alpha: .08),
                  color: ink.withValues(alpha: .6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
