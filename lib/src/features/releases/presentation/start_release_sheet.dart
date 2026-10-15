import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../apps/domain/app_project.dart';
import '../domain/release.dart';
import 'releases_controller.dart';
import 'widgets/status_pill.dart';

/// Opens the sheet and returns the new release's id, or null.
Future<String?> showStartReleaseSheet(BuildContext context, AppProject app) {
  // A snackbar from the previous action would sit over the sheet's button.
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _StartReleaseSheet(app: app),
  );
}

class _StartReleaseSheet extends ConsumerStatefulWidget {
  const _StartReleaseSheet({required this.app});

  final AppProject app;

  @override
  ConsumerState<_StartReleaseSheet> createState() => _StartReleaseSheetState();
}

class _StartReleaseSheetState extends ConsumerState<_StartReleaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _version = TextEditingController(text: '1.0.0');
  final _buildNumber = TextEditingController();
  late Platform _platform = widget.app.hasAndroid
      ? Platform.android
      : Platform.ios;
  late ReleaseTrack _track = ReleaseTrack.forPlatform(_platform).first;

  @override
  void dispose() {
    _version.dispose();
    _buildNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = await ref
        .read(releasesControllerProvider.notifier)
        .startRelease(
          app: widget.app,
          track: _track,
          versionName: _version.text,
          buildNumber: int.tryParse(_buildNumber.text.trim()),
        );
    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final validators = Validators(l10n);
    final isBusy = ref.watch(releasesControllerProvider).isLoading;
    final platforms = [
      if (widget.app.hasAndroid) Platform.android,
      if (widget.app.hasIos) Platform.ios,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        Gap.sm,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.startRelease, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              l10n.releaseExplain(widget.app.branch),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Gap.xl),
            Text(l10n.releaseTarget, style: theme.textTheme.labelMedium),
            const SizedBox(height: Gap.sm),
            SegmentedButton<Platform>(
              showSelectedIcon: false,
              segments: [
                for (final platform in platforms)
                  ButtonSegment(
                    value: platform,
                    icon: Icon(
                      platform == Platform.android
                          ? Icons.android
                          : Icons.apple,
                      size: 16,
                    ),
                    label: Text(platform.label),
                  ),
              ],
              selected: {_platform},
              onSelectionChanged: (selection) => setState(() {
                _platform = selection.first;
                _track = ReleaseTrack.forPlatform(_platform).first;
              }),
            ),
            const SizedBox(height: Gap.lg),
            DropdownButtonFormField<ReleaseTrack>(
              initialValue: _track,
              decoration: InputDecoration(labelText: l10n.releaseTrack),
              items: [
                for (final track in ReleaseTrack.forPlatform(_platform))
                  DropdownMenuItem(
                    value: track,
                    child: Text(trackLabel(context, track)),
                  ),
              ],
              onChanged: (value) => setState(() => _track = value!),
            ),
            const SizedBox(height: Gap.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _version,
                    decoration: InputDecoration(labelText: l10n.releaseVersion),
                    validator: validators.versionName,
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: TextFormField(
                    controller: _buildNumber,
                    decoration: InputDecoration(
                      labelText: l10n.releaseBuildNumber,
                      hintText: 'auto',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.releaseBuildNumberHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: Gap.xl),
            FilledButton.icon(
              onPressed: isBusy ? null : _submit,
              icon: const Icon(Icons.rocket_launch_outlined, size: 18),
              label: Text(l10n.startRelease),
            ),
          ],
        ),
      ),
    );
  }
}
