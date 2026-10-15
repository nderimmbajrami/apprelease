import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pill.dart';
import '../../../releases/domain/release.dart';
import '../../../releases/presentation/widgets/status_pill.dart';
import '../../domain/app_project.dart';

/// One application in the grid.
class AppTile extends StatelessWidget {
  const AppTile({
    required this.app,
    required this.onTap,
    this.lastRelease,
    super.key,
  });

  final AppProject app;
  final Release? lastRelease;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AppAvatar(name: app.name),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${app.repoShortName} · ${app.branch}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              if (app.hasAndroid)
                AppPill(label: Platform.android.label, icon: Icons.android),
              if (app.hasIos)
                AppPill(label: Platform.ios.label, icon: Icons.apple),
              AppPill(label: app.projectType.label, tone: PillTone.accent),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastRelease == null
                      ? '${l10n.lastRelease}: ${l10n.never}'
                      : '${l10n.lastRelease}: ${lastRelease!.versionLabel} · ${formatAgo(lastRelease!.createdAt)}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lastRelease != null) StatusPill(lastRelease!.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppAvatar extends StatelessWidget {
  const _AppAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hue = (name.hashCode % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, .55, .5).toColor();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}
