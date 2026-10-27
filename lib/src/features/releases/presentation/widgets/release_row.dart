import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pill.dart';
import '../../domain/release.dart';
import 'platform_icon.dart';
import 'status_pill.dart';

/// One release in a list: platform, version, track, state, when.
class ReleaseRow extends StatelessWidget {
  const ReleaseRow({
    required this.release,
    required this.onTap,
    this.appName,
    this.onRemove,
    super.key,
  });

  final Release release;
  final VoidCallback onTap;

  /// Shown on the dashboard, where releases of several apps mix.
  final String? appName;

  /// Takes a waiting release out of the queue. Shown while it waits.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = context.isCompact;
    // A push builds whatever version pubspec.yaml holds; until the runner
    // read it, the branch says more than a placeholder.
    final version = release.versionName == Release.autoVersion
        ? context.l10n.releaseLatestOn(release.branch)
        : release.versionLabel;
    final title = [?appName, version].join(' · ');
    final meta = [
      '#${release.number}',
      trackLabel(context, release.track),
      if (release.commit.isNotEmpty) release.commit,
      formatAgo(release.createdAt),
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          PlatformIcon(release.platform),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          if (!isCompact && release.duration != null) ...[
            AppPill(label: formatDuration(release.duration!), isMono: true),
            const SizedBox(width: Gap.sm),
          ],
          StatusPill(release.status),
          if (onRemove != null && release.status == ReleaseStatus.queued) ...[
            const SizedBox(width: Gap.xs),
            IconButton(
              onPressed: onRemove,
              tooltip: context.l10n.removeFromQueue,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
