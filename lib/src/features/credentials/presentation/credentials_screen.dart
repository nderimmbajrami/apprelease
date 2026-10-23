import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_title.dart';
import '../../apps/data/apps_repository.dart';
import '../../apps/domain/app_project.dart';
import '../data/credentials_repository.dart';
import '../domain/credential.dart';
import 'add_credential_sheet.dart';
import 'credentials_controller.dart';

/// Signing keys and store access, grouped by kind; keystores also by app.
class CredentialsScreen extends ConsumerWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final credentials = ref.watch(credentialsStreamProvider);
    final apps = ref.watch(appsStreamProvider).value ?? const <AppProject>[];

    return PageBody(
      child: AsyncValueWidget(
        value: credentials,
        data: (credentials) => ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            PageHeader(
              title: Text(l10n.credentialsTitle),
              subtitle: Text(l10n.credentialsSubtitle),
              actions: [
                FilledButton.icon(
                  onPressed: () => showAddCredentialSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCredential),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            if (credentials.isEmpty)
              EmptyState(
                icon: Icons.key_outlined,
                title: l10n.noCredentialsTitle,
                message: l10n.noCredentialsMessage,
                action: FilledButton.icon(
                  onPressed: () => showAddCredentialSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCredential),
                ),
              )
            else
              for (final kind in CredentialKind.values) ...[
                SectionTitle(
                  title: kindLabel(context, kind),
                  action: TextButton.icon(
                    onPressed: () =>
                        showAddCredentialSheet(context, kind: kind),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.addCredential),
                  ),
                ),
                if (kind == CredentialKind.androidKeystore)
                  _KeystoresByApp(
                    keystores: [
                      for (final c in credentials)
                        if (c.kind == kind) c,
                    ],
                    apps: apps,
                  )
                else
                  for (final credential in credentials.where(
                    (c) => c.kind == kind,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: _CredentialRow(credential: credential),
                    ),
                if (kind != CredentialKind.androidKeystore &&
                    credentials.every((c) => c.kind != kind))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg,
                        vertical: Gap.md,
                      ),
                      child: Text(
                        kindBody(context, kind),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                const SizedBox(height: Gap.lg),
              ],
          ],
        ),
      ),
    );
  }
}

/// Each Android app with its keystores, then the shared ones.
class _KeystoresByApp extends StatelessWidget {
  const _KeystoresByApp({required this.keystores, required this.apps});

  final List<Credential> keystores;
  final List<AppProject> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final known = {for (final a in apps) a.id};
    final androidApps = [
      for (final a in apps)
        if (a.hasAndroid || keystores.any((k) => k.appId == a.id)) a,
    ];
    final shared = [
      for (final k in keystores)
        if (k.appId == null || !known.contains(k.appId)) k,
    ];

    Widget header(String title, {String? appId}) => Padding(
      padding: const EdgeInsets.only(top: Gap.xs, bottom: Gap.xs),
      child: Row(
        children: [
          Icon(
            appId == null ? Icons.share_outlined : Icons.apps,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Gap.xs + 2),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (appId != null)
            TextButton.icon(
              onPressed: () => showAddCredentialSheet(
                context,
                kind: CredentialKind.androidKeystore,
                appId: appId,
              ),
              icon: const Icon(Icons.add, size: 15),
              label: Text(l10n.addCredential),
            ),
        ],
      ),
    );

    Widget row(Credential c) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: _CredentialRow(credential: c, apps: apps),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final app in androidApps) ...[
          header(app.name, appId: app.id),
          for (final k in keystores)
            if (k.appId == app.id) row(k),
          if (!keystores.any((k) => k.appId == app.id))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.lg,
                  vertical: Gap.md,
                ),
                child: Text(
                  l10n.noKeystoreForApp,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          const SizedBox(height: Gap.sm),
        ],
        if (shared.isNotEmpty) ...[
          header(l10n.credentialSharedKeys),
          for (final k in shared) row(k),
        ],
        if (androidApps.isEmpty && shared.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.md,
            ),
            child: Text(
              kindBody(context, CredentialKind.androidKeystore),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _CredentialRow extends ConsumerWidget {
  const _CredentialRow({required this.credential, this.apps = const []});

  final Credential credential;

  /// For keystores: the apps it can be linked to.
  final List<AppProject> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(Radii.sm + 2),
            ),
            child: Icon(
              kindIcon(credential.kind),
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(credential.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  [
                    if (credential.summary.isNotEmpty) credential.summary,
                    l10n.addedOn(formatDay(credential.createdAt)),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (credential.kind != CredentialKind.androidKeystore)
            OutlinedButton(
              onPressed: () => _check(context, ref),
              child: Text(l10n.checkCredential),
            ),
          if (credential.kind == CredentialKind.androidKeystore &&
              apps.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: l10n.linkToApp,
              icon: const Icon(Icons.link, size: 20),
              onSelected: (v) => ref
                  .read(credentialsControllerProvider.notifier)
                  .linkToApp(credential.id, v.isEmpty ? null : v),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    l10n.linkToApp,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                for (final app in apps)
                  CheckedPopupMenuItem(
                    value: app.id,
                    checked: credential.appId == app.id,
                    child: Text(app.name),
                  ),
                CheckedPopupMenuItem(
                  value: '',
                  checked: credential.appId == null,
                  child: Text(l10n.credentialShared),
                ),
              ],
            ),
          const SizedBox(width: Gap.xs),
          IconButton(
            tooltip: l10n.deleteCredential,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteCredential),
                  content: Text(l10n.deleteCredentialConfirm(credential.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(credentialsControllerProvider.notifier)
                    .deleteCredential(credential.id);
              }
            },
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

extension on _CredentialRow {
  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.checkingCredential)));
    final checks = await ref
        .read(credentialsControllerProvider.notifier)
        .check(credential.id);
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    if (checks == null) {
      final error = ref.read(credentialsControllerProvider).error;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkFailed('$error'))),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _CheckDialog(checks: checks, kind: credential.kind),
    );
  }
}

/// What Google said, one line per app, with the page that fixes it.
class _CheckDialog extends StatelessWidget {
  const _CheckDialog({required this.checks, required this.kind});

  final List<CredentialCheck> checks;
  final CredentialKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = kind == CredentialKind.appStoreConnectKey
        ? l10n.checkResultTitleAsc
        : l10n.checkResultTitle;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in checks)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      c.isOk ? Icons.check_circle : Icons.error_outline,
                      size: 20,
                      color: c.isOk ? scheme.tertiary : scheme.error,
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.package == '*'
                                ? l10n.checkResultTitle
                                : c.package,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(c.message, style: theme.textTheme.bodySmall),
                          if (c.link != null)
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(c.link!),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(l10n.checkFix),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

String kindLabel(BuildContext context, CredentialKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    CredentialKind.androidKeystore => l10n.kindAndroidKeystore,
    CredentialKind.googlePlayServiceAccount => l10n.kindGooglePlay,
    CredentialKind.appStoreConnectKey => l10n.kindAppStoreConnect,
  };
}

String kindBody(BuildContext context, CredentialKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    CredentialKind.androidKeystore => l10n.kindAndroidKeystoreBody,
    CredentialKind.googlePlayServiceAccount => l10n.kindGooglePlayBody,
    CredentialKind.appStoreConnectKey => l10n.kindAppStoreConnectBody,
  };
}

IconData kindIcon(CredentialKind kind) => switch (kind) {
  CredentialKind.androidKeystore => Icons.android,
  CredentialKind.googlePlayServiceAccount => Icons.shop_outlined,
  CredentialKind.appStoreConnectKey => Icons.apple,
};
