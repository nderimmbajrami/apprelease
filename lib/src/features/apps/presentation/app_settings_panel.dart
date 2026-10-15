import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../routing/app_routes.dart';
import '../../releases/data/releases_repository.dart';
import '../domain/app_project.dart';
import 'apps_controller.dart';

/// The fields the runner reads, editable in place, and the delete button.
class AppSettingsPanel extends ConsumerStatefulWidget {
  const AppSettingsPanel({required this.app, super.key});

  final AppProject app;

  @override
  ConsumerState<AppSettingsPanel> createState() => _AppSettingsPanelState();
}

class _AppSettingsPanelState extends ConsumerState<AppSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.app.name);
  late final _repoUrl = TextEditingController(text: widget.app.repoUrl);
  late final _branch = TextEditingController(text: widget.app.branch);
  late final _flutterVersion = TextEditingController(
    text: widget.app.flutterVersion,
  );
  late final _packageName = TextEditingController(
    text: widget.app.androidPackageName,
  );
  late final _bundleId = TextEditingController(text: widget.app.iosBundleId);
  late var _platforms = {...widget.app.platforms};

  @override
  void dispose() {
    for (final c in [
      _name,
      _repoUrl,
      _branch,
      _flutterVersion,
      _packageName,
      _bundleId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_platforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pickAtLeastOnePlatform)),
      );
      return;
    }
    final ok = await ref
        .read(appsControllerProvider.notifier)
        .updateApp(
          widget.app.copyWith(
            name: _name.text.trim(),
            repoUrl: _repoUrl.text.trim(),
            branch: _branch.text.trim(),
            flutterVersion: _flutterVersion.text.trim(),
            platforms: _platforms,
            androidPackageName: _packageName.text.trim(),
            iosBundleId: _bundleId.text.trim(),
          ),
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.appSaved)));
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteApp),
        content: Text(l10n.deleteAppConfirm(widget.app.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(releasesRepositoryProvider)
        .deleteReleasesOfApp(widget.app.id);
    final ok = await ref
        .read(appsControllerProvider.notifier)
        .deleteApp(widget.app.id);
    if (ok && mounted) context.goNamed(AppRoute.apps.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final validators = Validators(l10n);
    final isBusy = ref.watch(appsControllerProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        AppCard(
          padding: const EdgeInsets.all(Gap.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.appSettingsExplain, style: theme.textTheme.bodySmall),
                const SizedBox(height: Gap.lg),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.appName),
                  validator: validators.required,
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _repoUrl,
                  decoration: InputDecoration(labelText: l10n.repoUrl),
                  validator: validators.repoUrl,
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _branch,
                        decoration: InputDecoration(labelText: l10n.branch),
                        validator: validators.required,
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: TextFormField(
                        controller: _flutterVersion,
                        decoration: InputDecoration(
                          labelText: l10n.flutterVersion,
                        ),
                        validator: validators.required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.lg),
                CheckboxListTile(
                  value: _platforms.contains(Platform.android),
                  onChanged: (on) => setState(() {
                    _platforms = {..._platforms};
                    on!
                        ? _platforms.add(Platform.android)
                        : _platforms.remove(Platform.android);
                  }),
                  secondary: const Icon(Icons.android),
                  title: Text(l10n.platformAndroid),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_platforms.contains(Platform.android))
                  Padding(
                    padding: const EdgeInsets.only(left: 56, bottom: Gap.md),
                    child: TextFormField(
                      controller: _packageName,
                      decoration: InputDecoration(
                        labelText: l10n.androidPackageName,
                      ),
                      validator: validators.applicationId,
                    ),
                  ),
                CheckboxListTile(
                  value: _platforms.contains(Platform.ios),
                  onChanged: (on) => setState(() {
                    _platforms = {..._platforms};
                    on!
                        ? _platforms.add(Platform.ios)
                        : _platforms.remove(Platform.ios);
                  }),
                  secondary: const Icon(Icons.apple),
                  title: Text(l10n.platformIos),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_platforms.contains(Platform.ios))
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: TextFormField(
                      controller: _bundleId,
                      decoration: InputDecoration(labelText: l10n.iosBundleId),
                      validator: validators.applicationId,
                    ),
                  ),
                const SizedBox(height: Gap.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : _save,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.xl),
        AppCard(
          borderColor: theme.colorScheme.error.withValues(alpha: .4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dangerZone, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      l10n.deleteAppConfirm(widget.app.name),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.md),
              OutlinedButton.icon(
                onPressed: isBusy ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.deleteApp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
