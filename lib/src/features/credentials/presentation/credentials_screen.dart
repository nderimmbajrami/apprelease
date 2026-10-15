import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_title.dart';
import '../data/credentials_repository.dart';
import '../domain/credential.dart';
import 'add_credential_sheet.dart';
import 'credentials_controller.dart';

/// Signing keys and store access, grouped by kind.
class CredentialsScreen extends ConsumerWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final credentials = ref.watch(credentialsStreamProvider);

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
                for (final credential in credentials.where(
                  (c) => c.kind == kind,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: _CredentialRow(credential: credential),
                  ),
                if (credentials.every((c) => c.kind != kind))
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

class _CredentialRow extends ConsumerWidget {
  const _CredentialRow({required this.credential});

  final Credential credential;

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
