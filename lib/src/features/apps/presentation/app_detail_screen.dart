import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../../config/presentation/config_panel.dart';
import '../../releases/data/releases_repository.dart';
import '../../releases/domain/release.dart';
import '../../releases/presentation/releases_controller.dart';
import '../../releases/presentation/start_release_sheet.dart';
import '../../releases/presentation/widgets/release_row.dart';
import '../data/apps_repository.dart';
import '../domain/app_project.dart';
import 'app_settings_panel.dart';

/// One application: its releases, its generated config, its settings.
class AppDetailScreen extends ConsumerWidget {
  const AppDetailScreen({required this.appId, this.tab, super.key});

  final String appId;

  /// `releases` (default), `config` or `settings`, from the query string so
  /// the address survives a reload.
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final app = ref.watch(appByIdProvider(appId));
    final isLoading = ref.watch(appsStreamProvider).isLoading;

    if (app == null) {
      return PageBody(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.search_off,
                message: l10n.notFoundMessage,
                action: FilledButton(
                  onPressed: () => context.goNamed(AppRoute.apps.name),
                  child: Text(l10n.navApps),
                ),
              ),
      );
    }

    final initialIndex = switch (tab) {
      'config' => 1,
      'settings' => 2,
      _ => 0,
    };

    return PageBody(
      child: DefaultTabController(
        length: 3,
        initialIndex: initialIndex,
        animationDuration: Duration.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              onBack: () => context.goNamed(AppRoute.apps.name),
              title: Text(app.name),
              subtitle: Text('${app.repoUrl} · ${app.branch}'),
              actions: [
                if (app.hasAndroid)
                  AppPill(label: Platform.android.label, icon: Icons.android),
                if (app.hasIos)
                  AppPill(label: Platform.ios.label, icon: Icons.apple),
                FilledButton.icon(
                  onPressed: () => _startRelease(context, app),
                  icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                  label: Text(l10n.startRelease),
                ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              // The tab only changes the body below; the address bar keeps
              // up without building a new page.
              onTap: (index) {
                final name = const ['releases', 'config', 'settings'][index];
                GoRouter.of(context).replaceNamed(
                  AppRoute.appDetail.name,
                  pathParameters: {'appId': app.id},
                  queryParameters: {'tab': name},
                );
              },
              tabs: [
                Tab(text: l10n.tabReleases),
                Tab(text: l10n.tabConfig),
                Tab(text: l10n.tabSettings),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Expanded(
              child: _TabBody(
                children: [
                  _ReleasesTab(app: app),
                  ConfigPanel(app: app),
                  AppSettingsPanel(app: app),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _startRelease(
    BuildContext context,
    AppProject app,
  ) async {
    final id = await showStartReleaseSheet(context, app);
    if (id == null || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.releaseQueued)));
    context.goNamed(
      AppRoute.release.name,
      pathParameters: {'appId': app.id, 'releaseId': id},
    );
  }
}

class _ReleasesTab extends ConsumerWidget {
  const _ReleasesTab({required this.app});

  final AppProject app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final releases = ref.watch(releasesOfAppProvider(app.id));

    if (releases.isEmpty) {
      return AppCard(
        child: EmptyState(
          icon: Icons.rocket_outlined,
          title: l10n.noReleasesYet,
          message: l10n.noReleasesForApp,
          action: FilledButton.icon(
            onPressed: () => AppDetailScreen._startRelease(context, app),
            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            label: Text(l10n.startRelease),
          ),
        ),
      );
    }

    final queued = [
      for (final r in releases)
        if (r.status == ReleaseStatus.queued) r,
    ];
    final hasBar = queued.isNotEmpty;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      itemCount: releases.length + (hasBar ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
      itemBuilder: (context, index) {
        if (hasBar && index == 0) {
          return _QueueBar(app: app, queued: queued);
        }
        final release = releases[index - (hasBar ? 1 : 0)];
        return ReleaseRow(
          release: release,
          onTap: () => context.goNamed(
            AppRoute.release.name,
            pathParameters: {'appId': app.id, 'releaseId': release.id},
          ),
          onRemove: () => _remove(context, ref, [release.id]),
        );
      },
    );
  }
}

Future<void> _remove(
  BuildContext context,
  WidgetRef ref,
  List<String> releaseIds,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final text = context.l10n.queueRemoved(releaseIds.length);
  final ok = await ref
      .read(releasesControllerProvider.notifier)
      .removeFromQueue(releaseIds);
  if (ok) messenger.showSnackBar(SnackBar(content: Text(text)));
}

/// How many releases of this app wait, and one tap to drop the older pushes
/// the newest ones make pointless, or the whole line.
class _QueueBar extends ConsumerWidget {
  const _QueueBar({required this.app, required this.queued});

  final AppProject app;
  final List<Release> queued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final older = olderQueued(queued);
    final isBusy = ref.watch(releasesControllerProvider).isLoading;

    final keepLatest = FilledButton.icon(
      onPressed: older.isEmpty || isBusy
          ? null
          : () => _remove(context, ref, [for (final r in older) r.id]),
      icon: const Icon(Icons.filter_list, size: 18),
      label: Text(l10n.queueKeepLatest),
    );
    final clear = TextButton(
      onPressed: isBusy ? null : () => _clear(context, ref),
      child: Text(l10n.queueClear),
    );

    return AppCard(
      borderColor: older.isEmpty ? null : theme.colorScheme.primary,
      child: Wrap(
        spacing: Gap.lg,
        runSpacing: Gap.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.queueWaiting(queued.length),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  older.isEmpty
                      ? l10n.queueAllLatest
                      : l10n.queueOlder(older.length),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              clear,
              const SizedBox(width: Gap.sm),
              keepLatest,
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.queueClearTitle),
        content: Text(l10n.queueClearBody(queued.length, app.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.queueClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _remove(context, ref, [for (final r in queued) r.id]);
  }
}

/// The selected tab only, switched in one frame. The others keep their
/// state (an edited settings form survives a look at the releases).
class _TabBody extends StatelessWidget {
  const _TabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          IndexedStack(index: controller.index, children: children),
    );
  }
}
