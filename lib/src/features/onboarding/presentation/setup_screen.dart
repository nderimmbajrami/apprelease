import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/preferences/preferences_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../../apps/data/apps_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../credentials/data/credentials_repository.dart';
import '../../credentials/domain/credential.dart';
import '../../credentials/presentation/add_credential_sheet.dart';

/// The four things a release needs, as a checklist a new account lands on.
/// Each row opens the same wizard or sheet the rest of the console uses, so
/// nothing is entered twice.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    // Seen once: from now on the dashboard is the front door again. Written
    // after the frame, because a provider must not change while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(freshSignUpProvider.notifier).set(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final apps = ref.watch(appsStreamProvider).value ?? const [];
    final credentials = ref.watch(credentialsStreamProvider).value ?? const [];
    bool has(CredentialKind kind) => credentials.any((c) => c.kind == kind);

    final items = [
      (
        title: l10n.setupItemApp,
        body: l10n.setupItemAppBody,
        icon: Icons.apps_outlined,
        done: apps.isNotEmpty,
        onAdd: () => context.goNamed(AppRoute.appNew.name),
      ),
      (
        title: l10n.setupItemKeystore,
        body: l10n.setupItemKeystoreBody,
        icon: Icons.android,
        done: has(CredentialKind.androidKeystore),
        onAdd: () => showAddCredentialSheet(
          context,
          kind: CredentialKind.androidKeystore,
        ),
      ),
      (
        title: l10n.setupItemPlay,
        body: l10n.setupItemPlayBody,
        icon: Icons.shop_outlined,
        done: has(CredentialKind.googlePlayServiceAccount),
        onAdd: () => showAddCredentialSheet(
          context,
          kind: CredentialKind.googlePlayServiceAccount,
        ),
      ),
      (
        title: l10n.setupItemAsc,
        body: l10n.setupItemAscBody,
        icon: Icons.apple,
        done: has(CredentialKind.appStoreConnectKey),
        onAdd: () => showAddCredentialSheet(
          context,
          kind: CredentialKind.appStoreConnectKey,
        ),
      ),
    ];
    final done = items.where((i) => i.done).length;

    Future<void> finish() async {
      await ref.read(preferencesServiceProvider).writeSetupDismissed(true);
      if (context.mounted) context.goNamed(AppRoute.home.name);
    }

    return PageBody(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          PageHeader(
            title: Text(l10n.setupTitle),
            subtitle: Text(l10n.setupSubtitle),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            l10n.setupProgress(done, items.length),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: done / items.length,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: Gap.xl),
          for (final (index, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: _SetupRow(
                number: index + 1,
                title: item.title,
                body: item.body,
                icon: item.icon,
                done: item.done,
                onAdd: item.onAdd,
              ),
            ),
          const SizedBox(height: Gap.lg),
          if (done == items.length)
            Text(l10n.setupAllDone, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              FilledButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(l10n.setupFinish),
              ),
              const SizedBox(width: Gap.sm),
              if (done < items.length)
                TextButton(onPressed: finish, child: Text(l10n.setupSkip)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.done,
    required this.onAdd,
  });

  final int number;
  final String title;
  final String body;
  final IconData icon;
  final bool done;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: done ? scheme.tertiary : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: done
                ? Icon(Icons.check, size: 18, color: scheme.onTertiary)
                : Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. $title', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          if (done)
            Text(
              l10n.setupDoneLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.tertiary,
              ),
            )
          else
            OutlinedButton(onPressed: onAdd, child: Text(l10n.setupAdd)),
        ],
      ),
    );
  }
}
