import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../apps/domain/app_project.dart';
import '../../credentials/data/credentials_repository.dart';
import '../data/releases_repository.dart';
import '../domain/readiness.dart';
import '../domain/release.dart';
import 'releases_controller.dart';
import 'widgets/readiness_list.dart';
import 'widgets/status_pill.dart';

/// Opens the release dialog and returns the new release's id, or null.
Future<String?> showStartReleaseSheet(BuildContext context, AppProject app) {
  // A snackbar from the previous action would sit over the dialog.
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  return showDialog<String>(
    context: context,
    builder: (context) => _StartReleaseDialog(app: app),
  );
}

/// Platform, then what the release needs (checked, with fixes), then where
/// it goes and which version. Start stays off until every check is green.
class _StartReleaseDialog extends ConsumerStatefulWidget {
  const _StartReleaseDialog({required this.app});

  final AppProject app;

  @override
  ConsumerState<_StartReleaseDialog> createState() =>
      _StartReleaseDialogState();
}

class _StartReleaseDialogState extends ConsumerState<_StartReleaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _version = TextEditingController(text: _lastVersion());
  final _buildNumber = TextEditingController();
  late Platform _platform = widget.app.hasAndroid
      ? Platform.android
      : Platform.ios;
  late ReleaseTrack _track = ReleaseTrack.forPlatform(_platform).first;

  /// The version of the app's newest release, so a rerun needs no typing.
  String _lastVersion() {
    for (final r in ref.read(releasesOfAppProvider(widget.app.id))) {
      if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(r.versionName)) {
        return r.versionName;
      }
    }
    return '1.0.0';
  }

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
          versionName: _version.text.trim(),
          buildNumber: int.tryParse(_buildNumber.text.trim()),
        );
    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final validators = Validators(l10n);
    final isBusy = ref.watch(releasesControllerProvider).isLoading;
    final credentials = ref.watch(credentialsStreamProvider).value ?? const [];
    final app = widget.app;
    final platforms = [
      if (app.hasAndroid) Platform.android,
      if (app.hasIos) Platform.ios,
    ];
    final checks = Readiness.checks(app, _platform, credentials);
    final missing = checks.where((c) => !c.ok).length;
    final ready = missing == 0;

    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.xl,
                  Gap.lg,
                  Gap.sm,
                  Gap.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Icon(
                        Icons.rocket_launch_outlined,
                        size: 20,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.startRelease,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '${app.name} · ${app.branch}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.xl,
                    Gap.lg,
                    Gap.xl,
                    Gap.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Label(l10n.releaseTarget, step: 1),
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
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(platform.label),
                                  if (!Readiness.ready(
                                    app,
                                    platform,
                                    credentials,
                                  )) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: scheme.error,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                        selected: {_platform},
                        onSelectionChanged: (selection) => setState(() {
                          _platform = selection.first;
                          _track = ReleaseTrack.forPlatform(_platform).first;
                        }),
                      ),
                      const SizedBox(height: Gap.xl),
                      _Label(l10n.startReleaseChecks, step: 2),
                      ReadinessList(
                        app: app,
                        checks: checks,
                        insideDialog: true,
                      ),
                      const SizedBox(height: Gap.xl),
                      _Label(l10n.startReleaseWhere, step: 3),
                      Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.sm,
                        children: [
                          for (final track in ReleaseTrack.forPlatform(
                            _platform,
                          ))
                            ChoiceChip(
                              label: Text(trackLabel(context, track)),
                              selected: track == _track,
                              onSelected: (_) => setState(() => _track = track),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _version,
                              decoration: InputDecoration(
                                labelText: l10n.releaseVersion,
                              ),
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
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return null;
                                final n = int.tryParse(t);
                                return n == null || n < 1
                                    ? l10n.invalidBuildNumber
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.releaseBuildNumberHint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Footer.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.xl,
                  Gap.md,
                  Gap.xl,
                  Gap.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ready ? l10n.readyAll : l10n.readyCount(missing),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ready ? scheme.tertiary : scheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: Gap.sm),
                    FilledButton.icon(
                      onPressed: isBusy || !ready ? null : _submit,
                      icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                      label: Text(l10n.startRelease),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.step});

  final String text;
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHigh,
            ),
            child: Text('$step', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: Gap.sm),
          Text(text, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
