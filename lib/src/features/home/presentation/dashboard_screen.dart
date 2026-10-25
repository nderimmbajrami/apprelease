import 'dart:async';

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
import '../../../core/preferences/preferences_service.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/guided_tour.dart';
import '../../credentials/data/credentials_repository.dart';
import '../../credentials/domain/credential.dart';
import '../../credentials/presentation/add_credential_sheet.dart';
import '../../releases/domain/readiness.dart';
import '../../releases/presentation/start_release_sheet.dart';
import '../../releases/presentation/widgets/readiness_list.dart';
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
            credentials: credentials,
          ),
        ),
      ),
    );
  }
}

// What the guided tour points at on this page.
final _checklistAnchor = GlobalKey(debugLabel: 'tour-checklist');
final _addAppAnchor = GlobalKey(debugLabel: 'tour-add-app');
final _releasesAnchor = GlobalKey(debugLabel: 'tour-releases');

class _Dashboard extends ConsumerStatefulWidget {
  const _Dashboard({
    required this.apps,
    required this.releases,
    required this.credentials,
  });

  final List<AppProject> apps;
  final List<Release> releases;
  final List<Credential> credentials;

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  @override
  void initState() {
    super.initState();
    // First visit on this device: walk through the page once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(preferencesServiceProvider);
      if (!mounted || prefs.readTourSeen()) return;
      unawaited(prefs.writeTourSeen(true));
      unawaited(_tour());
    });
  }

  Future<void> _tour() {
    final l10n = context.l10n;
    return showGuidedTour(context, [
      TourStep(
        target: _checklistAnchor,
        title: l10n.tourChecklistTitle,
        body: l10n.tourChecklistBody,
      ),
      TourStep(
        target: _addAppAnchor,
        title: l10n.tourAddAppTitle,
        body: l10n.tourAddAppBody,
      ),
      if (tourAnchors[AppRoute.apps] case final key?)
        TourStep(
          target: key,
          title: l10n.tourAppsTitle,
          body: l10n.tourAppsBody,
        ),
      if (tourAnchors[AppRoute.credentials] case final key?)
        TourStep(
          target: key,
          title: l10n.tourCredentialsTitle,
          body: l10n.tourCredentialsBody,
        ),
      TourStep(
        target: _releasesAnchor,
        title: l10n.tourReleasesTitle,
        body: l10n.tourReleasesBody,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final apps = widget.apps;
    final releases = widget.releases;
    final credentials = widget.credentials;
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
              key: _addAppAnchor,
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
        _LaunchChecklist(
          anchor: _checklistAnchor,
          apps: apps,
          releases: releases,
          credentials: credentials,
          onTour: _tour,
        ),
        SectionTitle(
          key: _releasesAnchor,
          title: l10n.recentReleases,
          action: TextButton(
            onPressed: () => context.goNamed(AppRoute.apps.name),
            child: Text(l10n.viewAllApps),
          ),
        ),
        if (apps.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.rocket_outlined,
              title: l10n.noReleasesYet,
              message: l10n.noReleasesYetMessage,
            ),
          )
        else
          // One block per app: the newest release first, apps without
          // releases after them.
          for (final app in _appsByActivity(apps, releases))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: _AppReleases(
                app: app,
                credentials: credentials,
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

    final sorted = [...apps];
    sorted.sort((a, b) {
      final la = last(a), lb = last(b);
      if (la != null && lb != null) return lb.compareTo(la);
      if (la != null) return -1;
      if (lb != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}

/// An app's recent releases: where each platform stands now, then the last
/// few runs, then a way into the rest.
class _AppReleases extends StatelessWidget {
  const _AppReleases({
    required this.app,
    required this.releases,
    required this.credentials,
  });

  static const _shown = 4;

  final AppProject app;
  final List<Credential> credentials;

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
                  releases.isEmpty
                      ? l10n.appNoReleasesYet
                      : l10n.appReleasesSummary(
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

    // What would stop a release, per platform the app ships to.
    final blocked = [
      for (final platform in Platform.values)
        if (app.platforms.contains(platform))
          (platform, Readiness.missing(app, platform, credentials)),
    ].where((b) => b.$2.isNotEmpty).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: blocked.isNotEmpty
          ? scheme.error.withValues(alpha: .4)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (blocked.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (platform, missing) in blocked) ...[
                    Row(
                      children: [
                        PlatformIcon(platform, size: 22),
                        const SizedBox(width: Gap.sm),
                        Expanded(
                          child: Text(
                            l10n.appBlocked(platform.label, missing.length),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    ReadinessList(app: app, checks: missing, dense: true),
                    const SizedBox(height: Gap.sm),
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
          if (releases.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      blocked.isEmpty
                          ? l10n.appReadyFirstRelease
                          : l10n.appFixFirst,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  FilledButton.icon(
                    onPressed: () => showStartReleaseSheet(context, app),
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: Text(l10n.startRelease),
                  ),
                ],
              ),
            ),
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

/// From nothing to the first build in the stores, in order, with progress.
/// The next open step gets the filled button. Gone once everything is done.
class _LaunchChecklist extends StatelessWidget {
  const _LaunchChecklist({
    required this.apps,
    required this.releases,
    required this.credentials,
    required this.onTour,
    required this.anchor,
  });

  final List<AppProject> apps;
  final List<Release> releases;
  final List<Credential> credentials;
  final VoidCallback onTour;

  /// Where the tour points: the card itself, not the space around it.
  final GlobalKey anchor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    bool has(CredentialKind k) => credentials.any((c) => c.kind == k);
    final wantsAndroid = apps.isEmpty || apps.any((a) => a.hasAndroid);
    final wantsIos = apps.isEmpty || apps.any((a) => a.hasIos);
    final firstAndroid = apps.where((a) => a.hasAndroid).firstOrNull;
    // App settings that would fail a release: repository, package ids.
    bool settingsOk(AppProject a) => [
      for (final p in a.platforms) ...Readiness.checks(a, p, const []),
    ].where((c) => _settingItems.contains(c.item)).every((c) => c.ok);
    final badSettings = [
      for (final a in apps)
        if (!settingsOk(a)) a,
    ];
    final readyApp = apps
        .where(
          (a) => a.platforms.any((p) => Readiness.ready(a, p, credentials)),
        )
        .firstOrNull;

    final steps = <_Step>[
      _Step(
        icon: Icons.apps_outlined,
        title: l10n.launchApp,
        body: badSettings.isEmpty
            ? l10n.launchAppBody
            : l10n.launchAppFix(badSettings.first.name),
        done: apps.isNotEmpty && badSettings.isEmpty,
        action: badSettings.isEmpty
            ? l10n.addApplication
            : l10n.readyFixSettings,
        onTap: () => badSettings.isEmpty
            ? context.goNamed(AppRoute.appNew.name)
            : context.goNamed(
                AppRoute.appDetail.name,
                pathParameters: {'appId': badSettings.first.id},
                queryParameters: {'tab': 'settings'},
              ),
      ),
      if (wantsAndroid) ...[
        _Step(
          icon: Icons.key_outlined,
          title: l10n.readyKeystore,
          body: l10n.launchKeystoreBody,
          done: has(CredentialKind.androidKeystore),
          action: l10n.launchUpload,
          onTap: () => showAddCredentialSheet(
            context,
            kind: CredentialKind.androidKeystore,
            appId: firstAndroid?.id,
          ),
        ),
        _Step(
          icon: Icons.shop_outlined,
          title: l10n.readyGooglePlay,
          body: l10n.launchPlayBody,
          done: has(CredentialKind.googlePlayServiceAccount),
          action: l10n.launchConnect,
          onTap: () => showAddCredentialSheet(
            context,
            kind: CredentialKind.googlePlayServiceAccount,
          ),
        ),
      ],
      if (wantsIos)
        _Step(
          icon: Icons.apple,
          title: l10n.readyAppStoreConnect,
          body: l10n.launchAscBody,
          done: has(CredentialKind.appStoreConnectKey),
          action: l10n.launchConnect,
          onTap: () => showAddCredentialSheet(
            context,
            kind: CredentialKind.appStoreConnectKey,
          ),
        ),
      _Step(
        icon: Icons.rocket_launch_outlined,
        title: l10n.launchFirstRelease,
        body: readyApp == null
            ? l10n.launchFirstReleaseWaiting
            : l10n.launchFirstReleaseBody,
        done: releases.any((r) => r.status == ReleaseStatus.succeeded),
        action: l10n.startRelease,
        onTap: readyApp == null
            ? null
            : () => showStartReleaseSheet(context, readyApp),
      ),
    ];
    final done = steps.where((s) => s.done).length;
    if (done == steps.length) return const SizedBox.shrink();
    final next = steps.indexWhere((s) => !s.done);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      child: AppCard(
        key: anchor,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.xl,
                Gap.xl,
                Gap.lg,
                Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.launchTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.launchSubtitle(done, steps.length),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onTour,
                        icon: const Icon(Icons.tour_outlined, size: 18),
                        label: Text(l10n.tourTake),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: done / steps.length),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final (i, s) in steps.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: Gap.xl),
              _StepRow(step: s, number: i + 1, isNext: i == next),
            ],
          ],
        ),
      ),
    );
  }
}

const _settingItems = {
  ReadinessItem.repository,
  ReadinessItem.androidPackage,
  ReadinessItem.iosBundle,
};

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool done;
  final String action;
  final VoidCallback? onTap;
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.isNext,
  });

  final _Step step;
  final int number;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompact = context.isCompact;
    final badge = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step.done
            ? scheme.tertiary
            : isNext
            ? scheme.primary
            : scheme.surfaceContainerHigh,
      ),
      child: step.done
          ? Icon(Icons.check, size: 17, color: scheme.onTertiary)
          : Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isNext ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
    );
    final button = step.done
        ? Text(
            l10n.setupDoneLabel,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.tertiary),
          )
        : isNext
        ? FilledButton(onPressed: step.onTap, child: Text(step.action))
        : OutlinedButton(onPressed: step.onTap, child: Text(step.action));
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(step.icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                step.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  decoration: step.done ? TextDecoration.lineThrough : null,
                  color: step.done ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ],
        ),
        if (!step.done) ...[
          const SizedBox(height: 2),
          Text(step.body, style: theme.textTheme.bodySmall),
        ],
      ],
    );

    return Container(
      color: isNext ? scheme.primary.withValues(alpha: .05) : null,
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: Gap.md),
      child: isCompact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      if (!step.done) ...[
                        const SizedBox(height: Gap.sm),
                        button,
                      ],
                    ],
                  ),
                ),
                if (step.done) button,
              ],
            )
          : Row(
              children: [
                badge,
                const SizedBox(width: Gap.md),
                Expanded(child: text),
                const SizedBox(width: Gap.md),
                button,
              ],
            ),
    );
  }
}
