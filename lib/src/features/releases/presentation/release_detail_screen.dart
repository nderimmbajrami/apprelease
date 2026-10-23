import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../../apps/data/apps_repository.dart';
import '../../apps/domain/app_project.dart';
import '../data/releases_repository.dart';
import '../domain/release.dart';
import 'releases_controller.dart';
import 'start_release_sheet.dart';
import 'widgets/log_view.dart';
import 'widgets/platform_icon.dart';
import 'widgets/status_pill.dart';
import 'widgets/step_timeline.dart';

/// One release: its state, the steps and the live log.
class ReleaseDetailScreen extends ConsumerWidget {
  const ReleaseDetailScreen({
    required this.appId,
    required this.releaseId,
    super.key,
  });

  final String appId;
  final String releaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final release = ref.watch(releaseStreamProvider(releaseId));
    final app = ref.watch(appByIdProvider(appId));

    return PageBody(
      child: AsyncValueWidget(
        value: release,
        data: (release) {
          if (release == null) {
            return EmptyState(
              icon: Icons.search_off,
              message: l10n.notFoundMessage,
            );
          }
          return _ReleaseView(release: release, appName: app?.name ?? '');
        },
      ),
    );
  }
}

class _ReleaseView extends ConsumerWidget {
  const _ReleaseView({required this.release, required this.appName});

  final Release release;
  final String appName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = context.isCompact;
    final log = ref.watch(releaseLogProvider(release.id));
    final app = ref.watch(appByIdProvider(release.appId));
    final queue = release.status == ReleaseStatus.queued
        ? ref.watch(releaseQueueProvider(release.id)).value
        : null;

    final steps = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.releaseSteps, style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.lg),
          StepTimeline(steps: release.steps),
        ],
      ),
    );

    final logPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.releaseLog, style: theme.textTheme.titleSmall),
            const Spacer(),
            if (release.status == ReleaseStatus.queued)
              Text(l10n.queueShort, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: Gap.md),
        SizedBox(
          height: isCompact ? 360 : 520,
          child: LogView(
            lines: log.value ?? const [],
            follow: release.status.isActive,
          ),
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        PageHeader(
          onBack: () => context.goNamed(
            AppRoute.appDetail.name,
            pathParameters: {'appId': release.appId},
          ),
          leading: PlatformIcon(release.platform, size: 40),
          title: Text('$appName · ${release.versionLabel}'),
          subtitle: Text(
            [
              l10n.releaseNumber(release.number),
              trackLabel(context, release.track),
              l10n.releaseStartedBy(release.startedByName),
              formatDateTime(release.createdAt),
            ].join(' · '),
          ),
          actions: [
            StatusPill(release.status),
            if (release.status.isActive)
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(releasesControllerProvider.notifier)
                    .cancelRelease(release.id),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(l10n.cancelRelease),
              )
            else if (app != null)
              FilledButton.icon(
                onPressed: () async {
                  final id = await showStartReleaseSheet(context, app);
                  if (id != null && context.mounted) {
                    context.goNamed(
                      AppRoute.release.name,
                      pathParameters: {'appId': app.id, 'releaseId': id},
                    );
                  }
                },
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l10n.rerunRelease),
              ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            if (release.commit.isNotEmpty)
              AppPill(
                label: '${release.branch} @ ${release.commit}',
                icon: Icons.commit,
                isMono: true,
              ),
            if (release.duration != null)
              AppPill(
                label: formatDuration(release.duration!),
                icon: Icons.timer_outlined,
                isMono: true,
              ),
            for (final artifact in release.artifacts)
              AppPill(
                label: artifact,
                icon: Icons.inventory_2_outlined,
                tone: PillTone.success,
                isMono: true,
              ),
          ],
        ),
        if (release.status == ReleaseStatus.queued && queue != null) ...[
          const SizedBox(height: Gap.lg),
          _QueueCard(info: queue, platform: release.platform),
        ],
        if (release.errorMessage != null) ...[
          const SizedBox(height: Gap.lg),
          AppCard(
            borderColor: theme.colorScheme.error.withValues(alpha: .5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    release.errorMessage!,
                    style: theme.textTheme.mono.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Gap.xl),
        if (isCompact) ...[
          steps,
          const SizedBox(height: Gap.xl),
          logPanel,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: steps),
              const SizedBox(width: Gap.xl),
              Expanded(child: logPanel),
            ],
          ),
      ],
    );
  }
}

/// Shown while a release is queued and no runner has reported in: what a
/// runner is, and the two lines that start one.
/// The customer's place in line, or an honest word that the build machines
/// are away. Nothing here asks the customer to do anything.
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.info, required this.platform});

  final QueueInfo info;
  final Platform platform;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final offline = info.machinesOffline;
    final minutes = (info.estimatedWait.inSeconds / 60).ceil();
    final title = offline
        ? l10n.queueOfflineTitle
        : info.ahead == 0 && minutes == 0
        ? l10n.queueStartingTitle
        : l10n.queueInLineTitle(info.ahead + 1);
    final body = offline
        ? l10n.queueOfflineBody
        : minutes == 0
        ? l10n.queueStartingBody
        : l10n.queueInLineBody(
            info.ahead,
            minutes,
            platform == Platform.ios ? 'iOS' : 'Android',
          );

    return AppCard(
      borderColor: offline ? scheme.error.withValues(alpha: .5) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            offline ? Icons.cloud_off_outlined : Icons.hourglass_top_rounded,
            size: 20,
            color: offline ? scheme.error : scheme.primary,
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
