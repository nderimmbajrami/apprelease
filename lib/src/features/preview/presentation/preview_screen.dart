import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../../apps/data/apps_repository.dart';
import '../../apps/domain/app_project.dart';
import '../../auth/data/auth_repository.dart';
import '../../credentials/presentation/credential_guide.dart';
import '../../releases/domain/release.dart';
import '../../releases/presentation/releases_controller.dart';

/// What the `sources` bucket takes. A project without its build folder is
/// a few megabytes; with it, hundreds.
const maxSourceZipBytes = 50 * 1024 * 1024;

/// "My Shop (1).zip" → "My Shop".
String appNameFromZip(String fileName) => fileName
    .replaceAll(RegExp(r'\.zip$', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s*\(\d+\)$'), '')
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .trim();

/// "See it on my phone": upload a Flutter project as a zip and get an
/// Android app and an iPhone link back, each as a QR code. For people who
/// built an app with AI and have neither Git nor store accounts.
///
/// With [appId] the zip becomes a new version of an app uploaded before.
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({this.appId, super.key});

  final String? appId;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  final _name = TextEditingController();
  PlatformFile? _file;
  String? _error;
  bool _nameEdited = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    final l10n = context.l10n;
    setState(() {
      _file = file;
      _error = !file.name.toLowerCase().endsWith('.zip')
          ? l10n.previewNotZip
          : file.size > maxSourceZipBytes
          ? l10n.previewTooLarge((file.size / 1048576).round())
          : null;
      if (!_nameEdited) _name.text = appNameFromZip(file.name);
    });
  }

  Future<void> _build(AppProject? existing) async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    final bytes = _file?.bytes;
    if (user == null) return;
    if (bytes == null) {
      setState(() => _error = l10n.previewChooseFirst);
      return;
    }
    if (_error != null) return;
    setState(() => _busy = true);

    final apps = ref.read(appsRepositoryProvider);
    var app =
        existing ??
        AppProject(
          id: newId(),
          teamId: user.teamId ?? user.id,
          name: _name.text.trim().isEmpty
              ? appNameFromZip(_file!.name)
              : _name.text.trim(),
          repoUrl: '',
          platforms: const {Platform.android},
          createdAt: DateTime.now(),
        );
    String? failure;
    String? releaseId;
    try {
      final path = await apps.uploadSource(app, Uint8List.fromList(bytes));
      app = app.copyWith(sourceZip: path);
      if (existing == null) await apps.addApp(app);
      final releases = ref.read(releasesControllerProvider.notifier);
      releaseId = await releases.startRelease(
        app: app,
        track: ReleaseTrack.preview,
        versionName: Release.autoVersion,
      );
      if (releaseId == null) {
        final error = ref.read(releasesControllerProvider).error;
        failure = switch (error) {
          PreviewsNotEnabled() => l10n.previewNotEnabled,
          ReleaseLimitReached() => l10n.releaseLimitReached,
          _ => l10n.previewFailed,
        };
        // An app that never built anything would only confuse the list.
        if (existing == null) await apps.deleteApp(app.id);
      }
    } on Object {
      failure = l10n.previewUploadFailed;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure;
    });
    if (releaseId != null) {
      context.goNamed(
        AppRoute.release.name,
        pathParameters: {'appId': app.id, 'releaseId': releaseId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final existing = widget.appId == null
        ? null
        : ref.watch(appByIdProvider(widget.appId!));
    final file = _file;

    Widget step(int number, String text) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: scheme.secondaryContainer,
            child: Text('$number', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: Gap.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return PageBody(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          PageHeader(
            title: Text(
              existing == null
                  ? l10n.previewTitle
                  : l10n.previewNewVersionTitle(existing.name),
            ),
            subtitle: Text(l10n.previewSubtitle),
          ),
          const SizedBox(height: Gap.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.previewHowTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: Gap.md),
                step(1, l10n.previewHow1),
                step(2, l10n.previewHow2),
                step(3, l10n.previewHow3),
                step(4, l10n.previewHow4),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existing == null) ...[
                  TextField(
                    controller: _name,
                    enabled: !_busy,
                    onChanged: (_) => _nameEdited = true,
                    decoration: InputDecoration(
                      labelText: l10n.previewName,
                      helperText: l10n.previewNameHelper,
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                ],
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.folder_zip_outlined, size: 18),
                      label: Text(l10n.previewChoose),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Text(
                        file == null
                            ? l10n.previewNoFile
                            : '${file.name} · ${(file.size / 1048576).toStringAsFixed(1)} MB',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: Gap.md),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Gap.lg),
                Wrap(
                  spacing: Gap.md,
                  runSpacing: Gap.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _build(existing),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.phone_iphone, size: 18),
                      label: Text(
                        _busy ? l10n.previewUploading : l10n.previewBuild,
                      ),
                    ),
                    const SetupHelpButton(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            l10n.previewNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
