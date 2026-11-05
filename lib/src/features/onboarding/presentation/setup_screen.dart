import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/preferences/preferences_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/page_body.dart';
import '../../../routing/app_routes.dart';
import '../../apps/data/apps_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../credentials/data/credentials_repository.dart';
import '../../releases/data/releases_repository.dart';
import 'launch_plan.dart';

/// Where a new account lands: the launch plan, store by store. Each row
/// opens the same wizard or form the rest of the console uses, so nothing
/// is entered twice.
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
    final apps = ref.watch(appsStreamProvider).value ?? const [];
    final releases = ref.watch(releasesStreamProvider).value ?? const [];
    final credentials = ref.watch(credentialsStreamProvider).value ?? const [];

    Future<void> finish() async {
      await ref.read(preferencesServiceProvider).writeSetupDismissed(true);
      if (context.mounted) context.goNamed(AppRoute.home.name);
    }

    return PageBody(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          LaunchPlan(
            apps: apps,
            releases: releases,
            credentials: credentials,
            title: l10n.setupTitle,
            note: l10n.setupSubtitle,
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              FilledButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(l10n.setupFinish),
              ),
              const SizedBox(width: Gap.sm),
              TextButton(onPressed: finish, child: Text(l10n.setupSkip)),
            ],
          ),
        ],
      ),
    );
  }
}
