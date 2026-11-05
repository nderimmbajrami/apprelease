import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/preferences/preferences_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../routing/app_routes.dart';
import '../../apps/domain/app_project.dart';
import '../../credentials/domain/credential.dart';
import '../../credentials/presentation/add_credential_sheet.dart';
import '../../credentials/presentation/credential_guide.dart';
import '../../releases/domain/readiness.dart';
import '../../releases/domain/release.dart';
import '../../releases/presentation/start_release_sheet.dart';

/// From nothing to an app in the stores, as numbered steps grouped by
/// store. A team that publishes on one store never sees the other's steps.
/// Each step says what it is for, what to have at hand and how long it
/// takes, and opens the form that does it. The same card serves the setup
/// page of a new account and the dashboard until everything is done.
class LaunchPlan extends ConsumerStatefulWidget {
  const LaunchPlan({
    required this.apps,
    required this.releases,
    required this.credentials,
    required this.title,
    this.note,
    this.onTour,
    this.anchor,
    this.hideWhenDone = false,
    super.key,
  });

  final List<AppProject> apps;
  final List<Release> releases;
  final List<Credential> credentials;
  final String title;

  /// A sentence under the title, for the setup page.
  final String? note;
  final VoidCallback? onTour;

  /// Where the guided tour points: the card itself.
  final GlobalKey? anchor;
  final bool hideWhenDone;

  @override
  ConsumerState<LaunchPlan> createState() => _LaunchPlanState();
}

/// One row of the plan.
class LaunchStep {
  const LaunchStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.action,
    required this.onTap,
    this.needs,
    this.minutes,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// What to have at hand before pressing the button.
  final String? needs;
  final int? minutes;
  final bool done;
  final String action;
  final VoidCallback? onTap;

  /// The step that publishes: the button carries the rocket.
  final bool primary;
}

class _Section {
  const _Section(this.title, this.icon, this.steps);

  final String title;
  final IconData icon;
  final List<LaunchStep> steps;
}

/// App settings that would fail a release at its first step.
const _settingItems = {
  ReadinessItem.repository,
  ReadinessItem.androidPackage,
  ReadinessItem.iosBundle,
};

class _LaunchPlanState extends ConsumerState<LaunchPlan> {
  /// The stores chosen before the first app exists; after that the apps
  /// say which stores they ship to.
  late Set<Platform> _chosen = {
    for (final name in ref.read(preferencesServiceProvider).readStores())
      if (Platform.values.any((p) => p.name == name))
        Platform.values.byName(name),
  };

  void _toggle(Platform platform) {
    final next = {..._chosen};
    if (next.contains(platform)) {
      if (next.length == 1) return; // One store at least.
      next.remove(platform);
    } else {
      next.add(platform);
    }
    setState(() => _chosen = next);
    ref.read(preferencesServiceProvider).writeStores({
      for (final p in next) p.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apps = widget.apps;
    final credentials = widget.credentials;
    final stores = apps.isEmpty
        ? _chosen
        : {for (final a in apps) ...a.platforms};
    bool has(CredentialKind k) => credentials.any((c) => c.kind == k);
    final firstAndroid = apps.where((a) => a.hasAndroid).firstOrNull;
    bool settingsOk(AppProject a) => [
      for (final p in a.platforms) ...Readiness.checks(a, p, const []),
    ].where((c) => _settingItems.contains(c.item)).every((c) => c.ok);
    final badSettings = [
      for (final a in apps)
        if (!settingsOk(a)) a,
    ];
    AppProject? readyFor(Platform p) => apps
        .where(
          (a) => a.platforms.contains(p) && Readiness.ready(a, p, credentials),
        )
        .firstOrNull;
    bool published(Platform p) => widget.releases.any(
      (r) => r.platform == p && r.status == ReleaseStatus.succeeded,
    );

    final sections = <_Section>[
      _Section(l10n.launchSectionApp, Icons.apps_outlined, [
        LaunchStep(
          icon: Icons.apps_outlined,
          title: l10n.launchApp,
          body: badSettings.isEmpty
              ? l10n.launchAppBody
              : l10n.launchAppFix(badSettings.first.name),
          needs: l10n.launchAppNeeds,
          minutes: 2,
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
      ]),
      if (stores.contains(Platform.android))
        _Section(l10n.launchSectionPlay, Icons.android, [
          LaunchStep(
            icon: Icons.key_outlined,
            title: l10n.readyKeystore,
            body: l10n.launchKeystoreBody,
            needs: l10n.launchKeystoreNeeds,
            minutes: 2,
            done: has(CredentialKind.androidKeystore),
            action: l10n.launchUpload,
            onTap: () => showAddCredentialSheet(
              context,
              kind: CredentialKind.androidKeystore,
              appId: firstAndroid?.id,
            ),
          ),
          LaunchStep(
            icon: Icons.shop_outlined,
            title: l10n.readyGooglePlay,
            body: l10n.launchPlayBody,
            needs: l10n.launchPlayNeeds,
            minutes: 5,
            done: has(CredentialKind.googlePlayServiceAccount),
            action: l10n.launchConnect,
            onTap: () => showAddCredentialSheet(
              context,
              kind: CredentialKind.googlePlayServiceAccount,
            ),
          ),
          _publish(
            context,
            Platform.android,
            readyFor(Platform.android),
            published(Platform.android),
          ),
        ]),
      if (stores.contains(Platform.ios))
        _Section(l10n.launchSectionAppStore, Icons.apple, [
          LaunchStep(
            icon: Icons.apple,
            title: l10n.readyAppStoreConnect,
            body: l10n.launchAscBody,
            needs: l10n.launchAscNeeds,
            minutes: 3,
            done: has(CredentialKind.appStoreConnectKey),
            action: l10n.launchConnect,
            onTap: () => showAddCredentialSheet(
              context,
              kind: CredentialKind.appStoreConnectKey,
            ),
          ),
          _publish(
            context,
            Platform.ios,
            readyFor(Platform.ios),
            published(Platform.ios),
          ),
        ]),
    ];
    final steps = [for (final s in sections) ...s.steps];
    final done = steps.where((s) => s.done).length;
    if (widget.hideWhenDone && done == steps.length) {
      return const SizedBox.shrink();
    }
    final next = steps.indexWhere((s) => !s.done);

    var number = 0;
    return AppCard(
      key: widget.anchor,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.lg, Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            l10n.setupProgress(done, steps.length),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (widget.note case final note?) ...[
                            const SizedBox(height: 4),
                            Text(note, style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    if (widget.onTour case final onTour?)
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
          if (apps.isEmpty) ...[
            // Which stores: decides the sections below and preselects the
            // platforms when the app is added.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.xl,
                Gap.md,
                Gap.xl,
                Gap.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: Gap.xs),
                        child: Text(
                          l10n.launchWhere,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      for (final platform in Platform.values)
                        FilterChip(
                          avatar: Icon(
                            platform == Platform.android
                                ? Icons.android
                                : Icons.apple,
                            size: 16,
                          ),
                          label: Text(
                            platform == Platform.android
                                ? l10n.storeGooglePlay
                                : l10n.storeAppStore,
                          ),
                          selected: _chosen.contains(platform),
                          showCheckmark: false,
                          onSelected: (_) => _toggle(platform),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(l10n.launchWhereHint, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.xl,
                Gap.lg,
                Gap.xl,
                Gap.xs,
              ),
              child: Row(
                children: [
                  Icon(section.icon, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    section.title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: .6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final step in section.steps)
              _StepRow(
                step: step,
                number: ++number,
                isNext: steps.indexOf(step) == next,
              ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.lg),
            child: SetupHelpCard(),
          ),
        ],
      ),
    );
  }

  /// The last step of a store: the release itself, open once the app has
  /// everything that store needs.
  LaunchStep _publish(
    BuildContext context,
    Platform platform,
    AppProject? ready,
    bool done,
  ) {
    final l10n = context.l10n;
    final android = platform == Platform.android;
    return LaunchStep(
      icon: Icons.rocket_launch_outlined,
      title: android ? l10n.launchPublishPlay : l10n.launchPublishAppStore,
      body: ready == null && !done
          ? l10n.launchPublishWaiting
          : android
          ? l10n.launchPublishPlayBody
          : l10n.launchPublishAppStoreBody,
      minutes: android ? 10 : 15,
      done: done,
      action: l10n.startRelease,
      primary: true,
      onTap: ready == null
          ? null
          : () => showStartReleaseSheet(context, ready, platform: platform),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.isNext,
  });

  final LaunchStep step;
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
    final Widget button;
    if (step.done) {
      button = Text(
        l10n.setupDoneLabel,
        style: theme.textTheme.labelLarge?.copyWith(color: scheme.tertiary),
      );
    } else if (step.primary) {
      button = FilledButton.icon(
        onPressed: step.onTap,
        icon: const Icon(Icons.rocket_launch_outlined, size: 18),
        label: Text(step.action),
      );
    } else if (isNext) {
      button = FilledButton(onPressed: step.onTap, child: Text(step.action));
    } else {
      button = OutlinedButton(onPressed: step.onTap, child: Text(step.action));
    }
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
            if (!step.done && step.minutes != null) ...[
              const SizedBox(width: Gap.sm),
              AppPill(label: l10n.launchMinutes(step.minutes!)),
            ],
          ],
        ),
        if (!step.done) ...[
          const SizedBox(height: 2),
          Text(step.body, style: theme.textTheme.bodySmall),
          if (step.needs case final needs?) ...[
            const SizedBox(height: 2),
            Text(
              needs,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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
