import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../routing/app_routes.dart';
import '../../apps/data/apps_repository.dart';
import '../../apps/domain/app_project.dart';
import '../../credentials/data/credentials_repository.dart';
import '../../releases/data/releases_repository.dart';
import '../../releases/domain/release.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_pill.dart';
import '../../releases/presentation/widgets/platform_icon.dart';
import '../../releases/presentation/widgets/status_pill.dart';

/// What shipped, what is shipping, what failed.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appsStreamProvider);
    final releases = ref.watch(releasesStreamProvider);
    final credentials = ref.watch(credentialsStreamProvider).value ?? const [];

    return PageBody(
      child: AsyncValueWidget(
        value: apps,
        data: (apps) => AsyncValueWidget(
          value: releases,
          data: (releases) => _Dashboard(
            apps: apps,
            releases: releases,
            hasCredentials: credentials.isNotEmpty,
          ),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.apps,
    required this.releases,
    required this.hasCredentials,
  });

  final List<AppProject> apps;
  final List<Release> releases;
  final bool hasCredentials;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final thisMonth = releases
        .where(
          (r) => r.createdAt.year == now.year && r.createdAt.month == now.month,
        )
        .toList();
    final finished = releases.where(
      (r) =>
          r.status == ReleaseStatus.succeeded ||
          r.status == ReleaseStatus.failed,
    );
    final succeeded = finished
        .where((r) => r.status == ReleaseStatus.succeeded)
        .length;
    final rate = finished.isEmpty
        ? '–'
        : '${(succeeded / finished.length * 100).round()} %';
    final running = releases.where((r) => r.status.isActive).length;
    final scheme = Theme.of(context).colorScheme;

    final tiles = [
      StatTile(
        label: l10n.statApps,
        value: '${apps.length}',
        icon: Icons.apps_outlined,
      ),
      StatTile(
        label: l10n.statReleasesMonth,
        value: '${thisMonth.length}',
        icon: Icons.rocket_launch_outlined,
      ),
      StatTile(
        label: l10n.statSuccessRate,
        value: rate,
        icon: Icons.verified_outlined,
        tone: finished.isEmpty ? null : scheme.tertiary,
      ),
      StatTile(
        label: l10n.statRunning,
        value: '$running',
        icon: Icons.bolt_outlined,
        tone: running > 0 ? scheme.primary : null,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        PageHeader(
          title: Text(l10n.dashboardTitle),
          subtitle: Text(l10n.dashboardSubtitle),
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.goNamed(AppRoute.appNew.name),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addApplication),
            ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 560 ? 2 : 4;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Gap.md,
              crossAxisSpacing: Gap.md,
              childAspectRatio: columns == 2 ? 1.7 : 2.2,
              children: tiles,
            );
          },
        ),
        const SizedBox(height: Gap.xxl),
        if (apps.isEmpty || !hasCredentials || releases.isEmpty) ...[
          SectionTitle(title: l10n.gettingStarted),
          _GettingStarted(
            hasApp: apps.isNotEmpty,
            hasCredentials: hasCredentials,
            hasRelease: releases.isNotEmpty,
          ),
          const SizedBox(height: Gap.xxl),
        ],
        SectionTitle(
          title: l10n.recentReleases,
          action: TextButton(
            onPressed: () => context.goNamed(AppRoute.apps.name),
            child: Text(l10n.viewAllApps),
          ),
        ),
        if (releases.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.rocket_outlined,
              title: l10n.noReleasesYet,
              message: l10n.noReleasesYetMessage,
            ),
          )
        else
          // One block per app, the app with the newest release first.
          for (final app in _appsByActivity(apps, releases))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: _AppReleases(
                app: app,
                releases: [
                  for (final r in releases)
                    if (r.appId == app.id) r,
                ],
              ),
            ),
      ],
    );
  }

  static List<AppProject> _appsByActivity(
    List<AppProject> apps,
    List<Release> releases,
  ) {
    DateTime? last(AppProject a) {
      for (final r in releases) {
        if (r.appId == a.id) return r.createdAt;
      }
      return null;
    }

    final withReleases = [
      for (final a in apps)
        if (last(a) != null) a,
    ];
    withReleases.sort((a, b) => last(b)!.compareTo(last(a)!));
    return withReleases;
  }
}

/// An app's recent releases: where each platform stands now, then the last
/// few runs, then a way into the rest.
class _AppReleases extends StatelessWidget {
  const _AppReleases({required this.app, required this.releases});

  static const _shown = 4;

  final AppProject app;

  /// Newest first.
  final List<Release> releases;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompact = context.isCompact;
    final latest = <Platform, Release>{};
    for (final r in releases) {
      latest.putIfAbsent(r.platform, () => r);
    }
    void open(Release r) => context.goNamed(
      AppRoute.release.name,
      pathParameters: {'appId': app.id, 'releaseId': r.id},
    );

    final title = InkWell(
      borderRadius: BorderRadius.circular(Radii.sm),
      onTap: () => context.goNamed(
        AppRoute.appDetail.name,
        pathParameters: {'appId': app.id},
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(Radii.sm + 2),
            ),
            child: Text(
              app.name.isEmpty ? '?' : app.name[0].toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
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
                  l10n.appReleasesSummary(
                    releases.length,
                    formatAgo(releases.first.createdAt),
                  ),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Where each store stands right now.
    final chips = [
      for (final platform in Platform.values)
        if (latest[platform] case final r?)
          InkWell(
            borderRadius: BorderRadius.circular(Radii.sm),
            onTap: () => open(r),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlatformIcon(platform, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isCompact
                          ? r.versionLabel
                          : '${r.versionLabel} · ${trackLabel(context, r.track)}',
                      style: theme.textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(r.status),
                ],
              ),
            ),
          ),
    ];

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: Gap.md),
                Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: chips),
              ],
            )
          : Row(
              children: [
                Expanded(child: title),
                for (final chip in chips) ...[
                  const SizedBox(width: Gap.sm),
                  chip,
                ],
              ],
            ),
    );

    Widget row(Release r) => InkWell(
      onTap: () => open(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.sm + 2,
        ),
        child: Row(
          children: [
            PlatformIcon(r.platform, size: 26),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: r.versionLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: [
                        '',
                        '#${r.number}',
                        trackLabel(context, r.track),
                        if (!isCompact && r.commit.isNotEmpty) r.commit,
                        formatAgo(r.createdAt),
                      ].join(' · '),
                    ),
                  ],
                ),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Gap.sm),
            if (!isCompact && r.duration != null) ...[
              AppPill(label: formatDuration(r.duration!), isMono: true),
              const SizedBox(width: Gap.sm),
            ],
            StatusPill(r.status),
          ],
        ),
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          for (final r in releases.take(_shown)) row(r),
          if (releases.length > _shown) ...[
            const Divider(height: 1),
            TextButton(
              onPressed: () => context.goNamed(
                AppRoute.appDetail.name,
                pathParameters: {'appId': app.id},
              ),
              child: Text(l10n.allReleasesOfApp(releases.length)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Three steps with a tick for each one that is done.
class _GettingStarted extends StatelessWidget {
  const _GettingStarted({
    required this.hasApp,
    required this.hasCredentials,
    required this.hasRelease,
  });

  final bool hasApp;
  final bool hasCredentials;
  final bool hasRelease;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (l10n.stepAddApp, l10n.stepAddAppBody, hasApp, AppRoute.appNew),
      (
        l10n.stepAddCredentials,
        l10n.stepAddCredentialsBody,
        hasCredentials,
        AppRoute.credentials,
      ),
      (l10n.stepRelease, l10n.stepReleaseBody, hasRelease, AppRoute.apps),
    ];
    final cards = [
      for (final (index, step) in steps.indexed)
        _StepCard(
          number: index + 1,
          title: step.$1,
          body: step.$2,
          isDone: step.$3,
          onTap: () => context.goNamed(step.$4.name),
        ),
    ];
    if (context.isCompact) {
      return Column(
        children: [
          for (final (index, card) in cards.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? Gap.md : 0),
              child: card,
            ),
        ],
      );
    }
    // Equal heights across the row, whatever the text lengths.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, card) in cards.indexed) ...[
            if (index > 0) const SizedBox(width: Gap.md),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
    required this.isDone,
    required this.onTap,
  });

  final int number;
  final String title;
  final String body;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDone
                  ? scheme.tertiaryContainer
                  : scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: isDone
                ? Icon(Icons.check, size: 16, color: scheme.onTertiaryContainer)
                : Center(
                    child: Text(
                      '$number',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
