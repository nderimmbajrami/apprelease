import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n_extension.dart';
import '../core/widgets/empty_state.dart';
import 'app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoute.home.name),
          child: Text(l10n.backHome),
        ),
      ),
    );
  }
}
