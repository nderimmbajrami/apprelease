import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../routing/app_routes.dart';
import '../../apps/domain/app_project.dart';
import '../../credentials/data/credentials_repository.dart';
import '../domain/release_config.dart';

/// The generated apprelease.yaml for an app, with a copy button.
class ConfigPanel extends ConsumerWidget {
  const ConfigPanel({required this.app, super.key});

  final AppProject app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final credentials = ref.watch(credentialsStreamProvider).value ?? const [];
    final config = ReleaseConfig(app: app, credentials: credentials);
    final yaml = config.toYaml();

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        Text(l10n.configExplain, style: theme.textTheme.bodySmall),
        if (!config.isComplete) ...[
          const SizedBox(height: Gap.md),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    l10n.configMissingCredentials,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => context.goNamed(AppRoute.credentials.name),
                  child: Text(l10n.navCredentials),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppColors.lineDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  Gap.lg,
                  Gap.sm,
                  Gap.sm,
                  Gap.sm,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.lineDark)),
                ),
                child: Row(
                  children: [
                    Text(
                      'apprelease.yaml',
                      style: theme.textTheme.mono.copyWith(
                        color: AppColors.mutedDark,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: yaml));
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(l10n.copy),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: SelectionArea(
                  child: Text(
                    yaml,
                    style: theme.textTheme.mono.copyWith(
                      color: AppColors.inkDark,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
