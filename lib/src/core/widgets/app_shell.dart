import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../routing/app_routes.dart';
import '../config/app_config.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';

/// One entry in the navigation.
class NavItem {
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.matches = const [],
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final AppRoute route;

  /// Extra path prefixes that light this entry up — a release still belongs
  /// to Applications.
  final List<String> matches;
}

/// The frame every signed-in screen sits in: navigation down the left, the
/// account across the top, the page in the middle. On a phone the rail
/// becomes a bar along the bottom.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  /// Marks the content area, so a test can tell the page apart from the
  /// navigation around it.
  static const pageKey = ValueKey('shell-page');

  final Widget child;

  static List<NavItem> items(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: l10n.navDashboard,
        route: AppRoute.home,
      ),
      NavItem(
        icon: Icons.apps_outlined,
        selectedIcon: Icons.apps,
        label: l10n.navApps,
        route: AppRoute.apps,
        matches: const ['/apps'],
      ),
      NavItem(
        icon: Icons.key_outlined,
        selectedIcon: Icons.key,
        label: l10n.navCredentials,
        route: AppRoute.credentials,
        matches: const ['/credentials'],
      ),
      NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
        route: AppRoute.settings,
        matches: const ['/settings'],
      ),
    ];
  }

  static int selectedIndex(BuildContext context, List<NavItem> items) {
    final location = GoRouterState.of(context).uri.path;
    for (final (index, item) in items.indexed) {
      if (item.route == AppRoute.home) continue;
      if (location == item.route.path ||
          item.matches.any(location.startsWith)) {
        return index;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = AppShell.items(context);
    final selected = selectedIndex(context, items);
    final isCompact = context.isCompact;
    final page = KeyedSubtree(key: pageKey, child: child);

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: Gap.lg,
          title: const BrandLockup(size: 28),
          actions: const [_DocsButton(), _AccountMenu(), SizedBox(width: 6)],
        ),
        body: page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (index) =>
              context.goNamed(items[index].route.name),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Rail(items: items, selected: selected),
          const VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                const Divider(),
                Expanded(child: page),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.items, required this.selected});

  final List<NavItem> items;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: 236,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.lg, Gap.xl),
            child: BrandLockup(),
          ),
          for (final (index, item) in items.indexed) ...[
            if (index == 1)
              _RailLabel(l10n.sectionBuild)
            else if (index == 3)
              _RailLabel(l10n.sectionTeam),
            _RailEntry(item: item, isSelected: index == selected),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              l10n.authFooterNote,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  const _RailLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.lg, Gap.xs),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({required this.item, required this.isSelected});

  final NavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 2),
      child: Material(
        color: isSelected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => context.goNamed(item.route.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: const Row(
        children: [
          Spacer(),
          _DocsButton(),
          SizedBox(width: Gap.sm),
          _AccountMenu(),
        ],
      ),
    );
  }
}

class _DocsButton extends StatelessWidget {
  const _DocsButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => launchUrl(
        Uri.parse(AppConfig.docsUrl),
        mode: LaunchMode.externalApplication,
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 18),
      label: Text(context.l10n.openDocs),
    );
  }
}

/// Avatar with the account menu.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      tooltip: user?.email ?? '',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'settings') context.goNamed(AppRoute.settings.name);
        if (value == 'signOut') {
          ref.read(authControllerProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '', style: theme.textTheme.titleSmall),
              Text(user?.email ?? '', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'settings', child: Text(l10n.navSettings)),
        PopupMenuItem(value: 'signOut', child: Text(l10n.signOut)),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          user?.initials ?? '?',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
