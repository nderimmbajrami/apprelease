import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/brand_mark.dart';

/// The chrome behind signing in and registering.
///
/// On a desk it is two panes: what the product does on the left, the form on
/// the right. On a phone the pitch folds away and only the form is left.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 940;
            final form = _FormPane(
              title: title,
              subtitle: subtitle,
              showBrand: !isWide,
              children: children,
            );
            if (!isWide) return form;
            return Row(
              children: [
                const Expanded(flex: 5, child: _PitchPane()),
                Expanded(flex: 6, child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The left half: the promise, in three lines, on the website's dark navy.
class _PitchPane extends StatelessWidget {
  const _PitchPane();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.ink,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 56, 48, 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLockup(size: 40, light: true),
                    const SizedBox(height: Gap.xxl),
                    Text(
                      l10n.appTagline,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 40,
                        height: 1.08,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    Text(
                      l10n.authPitch,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .72),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: Gap.xxl),
                    for (final point in [
                      l10n.authPoint1,
                      l10n.authPoint2,
                      l10n.authPoint3,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 19,
                              color: AppColors.mintDark,
                            ),
                            const SizedBox(width: Gap.sm),
                            Expanded(
                              child: Text(
                                point,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: .82),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: Gap.lg),
                    Text(
                      l10n.authFooterNote,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The right half: heading and the form itself.
class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.showBrand,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBrand) ...[
                const Center(child: BrandLockup(size: 36)),
                const SizedBox(height: Gap.xl),
              ],
              Container(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Radii.xl),
                  border: Border.all(color: theme.colorScheme.outline),
                  boxShadow: isLight ? AppColors.cardShadow : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: Gap.lg),
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The spinner inside a busy button.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 16,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  );
}
