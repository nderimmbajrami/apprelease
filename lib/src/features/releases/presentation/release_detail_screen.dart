import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final runnerOnline = ref.watch(runnerOnlineProvider).value ?? true;

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
              Text(l10n.waitingForRunner, style: theme.textTheme.bodySmall),
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
        if (release.status == ReleaseStatus.queued && !runnerOnline) ...[
          const SizedBox(height: Gap.lg),
          const _NoRunnerCard(),
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
class _NoRunnerCard extends StatelessWidget {
  const _NoRunnerCard();

  static const command =
      'cd ~/Documents/GitHub/apprelease/runner\ndart run bin/runner.dart';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      borderColor: scheme.onSurface.withValues(alpha: .4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 20, color: scheme.onSurface),
              const SizedBox(width: Gap.sm),
              Text(l10n.noRunnerTitle, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(l10n.noRunnerBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Gap.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: Gap.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectionArea(
                    child: Text(command, style: theme.textTheme.mono),
                  ),
                ),
                IconButton(
                  tooltip: l10n.copy,
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: command));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(l10n.noRunnerFoot, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
