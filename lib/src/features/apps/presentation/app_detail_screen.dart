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

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      itemCount: releases.length,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
      itemBuilder: (context, index) {
        final release = releases[index];
        return ReleaseRow(
          release: release,
          onTap: () => context.goNamed(
            AppRoute.release.name,
            pathParameters: {'appId': app.id, 'releaseId': release.id},
          ),
        );
      },
    );
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
