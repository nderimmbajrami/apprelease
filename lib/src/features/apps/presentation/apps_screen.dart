import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../../releases/data/releases_repository.dart';
import '../data/apps_repository.dart';
import 'widgets/app_tile.dart';

/// Every application of the team.
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final apps = ref.watch(appsStreamProvider);
    final releases = ref.watch(releasesStreamProvider).value ?? const [];

    return PageBody(
      child: AsyncValueWidget(
        value: apps,
        data: (apps) => ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            PageHeader(
              title: Text(l10n.appsTitle),
              subtitle: Text(l10n.appsSubtitle(apps.length)),
              actions: [
                FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoute.appNew.name),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addApplication),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            if (apps.isEmpty)
              EmptyState(
                icon: Icons.apps_outlined,
                title: l10n.noAppsTitle,
                message: l10n.noAppsMessage,
                action: FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoute.appNew.name),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addApplication),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 640
                      ? 1
                      : constraints.maxWidth < 1000
                      ? 2
                      : 3;
                  final tiles = [
                    for (final app in apps)
                      AppTile(
                        app: app,
                        lastRelease: releases
                            .where((r) => r.appId == app.id)
                            .firstOrNull,
                        onTap: () => context.goNamed(
                          AppRoute.appDetail.name,
                          pathParameters: {'appId': app.id},
                        ),
                      ),
                  ];
                  // A phone gets a plain column: the tiles size themselves
                  // to their text, and nothing can overflow a fixed cell.
                  if (columns == 1) {
                    return Column(
                      children: [
                        for (final tile in tiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Gap.md),
                            child: tile,
                          ),
                      ],
                    );
                  }
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Gap.md,
                    crossAxisSpacing: Gap.md,
                    childAspectRatio: 1.75,
                    children: tiles,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
