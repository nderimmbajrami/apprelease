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
import '../../releases/presentation/widgets/release_row.dart';

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
    final appNames = {for (final app in apps) app.id: app.name};

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
          for (final release in releases.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: ReleaseRow(
                release: release,
                appName: appNames[release.appId],
                onTap: () => context.goNamed(
                  AppRoute.release.name,
                  pathParameters: {
                    'appId': release.appId,
                    'releaseId': release.id,
                  },
                ),
              ),
            ),
      ],
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
