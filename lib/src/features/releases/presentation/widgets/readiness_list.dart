import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routing/app_routes.dart';
import '../../../apps/domain/app_project.dart';
import '../../../credentials/domain/credential.dart';
import '../../../credentials/presentation/add_credential_sheet.dart';
import '../../domain/readiness.dart';

/// The requirements of a release on one platform, each with its state and,
/// when missing, the one button that fixes it.
class ReadinessList extends StatelessWidget {
  const ReadinessList({
    required this.app,
    required this.checks,
    this.insideDialog = false,
    this.dense = false,
    super.key,
  });

  final AppProject app;
  final List<ReadinessCheck> checks;

  /// Settings fixes leave the page: close the dialog first.
  final bool insideDialog;

  /// Missing items only, tighter rows: for cards on the dashboard.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final shown = dense
        ? [
            for (final c in checks)
              if (!c.ok) c,
          ]
        : checks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in shown.indexed) ...[
          if (i > 0) SizedBox(height: dense ? 2 : Gap.xs),
          _Row(app: app, check: c, insideDialog: insideDialog, dense: dense),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.app,
    required this.check,
    required this.insideDialog,
    required this.dense,
  });

  final AppProject app;
  final ReadinessCheck check;
  final bool insideDialog;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (title, ok, missing) = switch (check.item) {
      ReadinessItem.repository => (
        l10n.readyRepository,
        l10n.readyRepositoryOk,
        l10n.readyRepositoryMissing,
      ),
      ReadinessItem.androidPackage => (
        l10n.readyAndroidPackage,
        l10n.readyAndroidPackageOk,
        l10n.readyAndroidPackageMissing,
      ),
      ReadinessItem.iosBundle => (
        l10n.readyIosBundle,
        l10n.readyIosBundleOk,
        l10n.readyIosBundleMissing,
      ),
      ReadinessItem.keystore => (
        l10n.readyKeystore,
        l10n.readyKeystoreOk,
        l10n.readyKeystoreMissing,
      ),
      ReadinessItem.googlePlay => (
        l10n.readyGooglePlay,
        l10n.readyGooglePlayOk,
        l10n.readyGooglePlayMissing,
      ),
      ReadinessItem.appStoreConnect => (
        l10n.readyAppStoreConnect,
        l10n.readyAppStoreConnectOk,
        l10n.readyAppStoreConnectMissing,
      ),
    };
    final isSetting = switch (check.item) {
      ReadinessItem.repository ||
      ReadinessItem.androidPackage ||
      ReadinessItem.iosBundle => true,
      _ => false,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Gap.md,
        vertical: dense ? 6 : Gap.sm + 2,
      ),
      decoration: BoxDecoration(
        color: check.ok
            ? Colors.transparent
            : scheme.errorContainer.withValues(alpha: .35),
        border: Border.all(
          color: check.ok
              ? scheme.outline
              : scheme.error.withValues(alpha: .45),
        ),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(
            check.ok ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: check.ok ? scheme.tertiary : scheme.error,
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (!dense)
                  Text(
                    check.ok ? ok : missing,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (!check.ok) ...[
            const SizedBox(width: Gap.sm),
            FilledButton.tonal(
              onPressed: () => _fix(context, isSetting),
              child: Text(isSetting ? l10n.readyFixSettings : l10n.readyFix),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _fix(BuildContext context, bool isSetting) async {
    if (isSetting) {
      final router = GoRouter.of(context);
      if (insideDialog) Navigator.of(context).pop();
      router.goNamed(
        AppRoute.appDetail.name,
        pathParameters: {'appId': app.id},
        queryParameters: {'tab': 'settings'},
      );
      return;
    }
    await showAddCredentialSheet(
      context,
      kind: switch (check.item) {
        ReadinessItem.keystore => CredentialKind.androidKeystore,
        ReadinessItem.googlePlay => CredentialKind.googlePlayServiceAccount,
        _ => CredentialKind.appStoreConnectKey,
      },
      appId: check.item == ReadinessItem.keystore ? app.id : null,
    );
  }
}
