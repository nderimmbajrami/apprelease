import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../apps/data/apps_repository.dart';
import '../domain/credential.dart';
import 'credentials_controller.dart';
import 'credentials_screen.dart';

Future<void> showAddCredentialSheet(
  BuildContext context, {
  CredentialKind? kind,
  String? appId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (context) => _AddCredentialSheet(initialKind: kind, appId: appId),
);

class _AddCredentialSheet extends ConsumerStatefulWidget {
  const _AddCredentialSheet({this.initialKind, this.appId});

  final CredentialKind? initialKind;
  final String? appId;

  @override
  ConsumerState<_AddCredentialSheet> createState() =>
      _AddCredentialSheetState();
}

class _AddCredentialSheetState extends ConsumerState<_AddCredentialSheet> {
  final _formKey = GlobalKey<FormState>();
  late var _kind = widget.initialKind ?? CredentialKind.androidKeystore;
  late String? _appId = widget.appId;
  final _name = TextEditingController();
  final _keystorePassword = TextEditingController();
  final _keyAlias = TextEditingController();
  final _keyPassword = TextEditingController();
  final _json = TextEditingController();
  final _issuerId = TextEditingController();
  final _keyId = TextEditingController();
  PlatformFile? _file;
  String? _fileError;

  @override
  void dispose() {
    for (final c in [
      _name,
      _keystorePassword,
      _keyAlias,
      _keyPassword,
      _json,
      _issuerId,
      _keyId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final extensions = switch (_kind) {
      CredentialKind.androidKeystore => ['jks', 'keystore'],
      CredentialKind.appStoreConnectKey => ['p8'],
      CredentialKind.googlePlayServiceAccount => ['json'],
    };
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _fileError = null;
      if (_kind == CredentialKind.googlePlayServiceAccount &&
          _file!.bytes != null) {
        _json.text = utf8.decode(_file!.bytes!);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final needsFile = _kind != CredentialKind.googlePlayServiceAccount;
    if (needsFile && _file?.bytes == null) {
      setState(() => _fileError = l10n.fileRequired);
      return;
    }

    final meta = <String, String>{};
    final fields = <String, String>{};
    switch (_kind) {
      case CredentialKind.androidKeystore:
        meta['fileName'] = _file!.name;
        meta['alias'] = _keyAlias.text.trim();
        fields['keystorePassword'] = _keystorePassword.text;
        fields['keyAlias'] = _keyAlias.text.trim();
        fields['keyPassword'] = _keyPassword.text;
      case CredentialKind.googlePlayServiceAccount:
        final Map<String, dynamic> parsed;
        try {
          parsed = jsonDecode(_json.text) as Map<String, dynamic>;
        } catch (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.invalidJson)));
          return;
        }
        meta['email'] = (parsed['client_email'] as String?) ?? '';
        meta['projectId'] = (parsed['project_id'] as String?) ?? '';
        fields['json'] = _json.text;
      case CredentialKind.appStoreConnectKey:
        meta['issuerId'] = _issuerId.text.trim();
        meta['keyId'] = _keyId.text.trim();
        meta['fileName'] = _file!.name;
        fields['issuerId'] = _issuerId.text.trim();
        fields['keyId'] = _keyId.text.trim();
    }

    final ok = await ref
        .read(credentialsControllerProvider.notifier)
        .addCredential(
          kind: _kind,
          name: _name.text,
          appId: _kind == CredentialKind.androidKeystore ? _appId : null,
          meta: meta,
          secret: CredentialSecret(
            fileBytes: _file?.bytes,
            fileName: _file?.name,
            fields: fields,
          ),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.credentialAdded)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final validators = Validators(l10n);
    final isBusy = ref.watch(credentialsControllerProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        Gap.sm,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addCredential, style: theme.textTheme.headlineSmall),
              const SizedBox(height: Gap.lg),
              DropdownButtonFormField<CredentialKind>(
                initialValue: _kind,
                items: [
                  for (final kind in CredentialKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(kindLabel(context, kind)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _kind = value!;
                  _file = null;
                  _fileError = null;
                }),
              ),
              const SizedBox(height: 6),
              Text(kindBody(context, _kind), style: theme.textTheme.bodySmall),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.credentialName,
                  helperText: l10n.credentialNameHint,
                ),
                validator: validators.required,
              ),
              if (_kind == CredentialKind.androidKeystore) ...[
                const SizedBox(height: Gap.lg),
                DropdownButtonFormField<String?>(
                  initialValue: _appId,
                  decoration: InputDecoration(
                    labelText: l10n.credentialApp,
                    helperText: l10n.credentialAppHelper,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.credentialShared),
                    ),
                    for (final app
                        in ref.watch(appsStreamProvider).value ?? const [])
                      DropdownMenuItem(value: app.id, child: Text(app.name)),
                  ],
                  onChanged: (v) => setState(() => _appId = v),
                ),
              ],
              const SizedBox(height: Gap.lg),
              ..._fieldsFor(_kind, validators),
              const SizedBox(height: Gap.xl),
              FilledButton.icon(
                onPressed: isBusy ? null : _submit,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text(l10n.addCredential),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _fieldsFor(CredentialKind kind, Validators validators) {
    final l10n = context.l10n;
    final filePicker = _FilePickerField(
      label: switch (kind) {
        CredentialKind.androidKeystore => '.jks / .keystore',
        CredentialKind.appStoreConnectKey => l10n.privateKeyP8,
        CredentialKind.googlePlayServiceAccount => '.json',
      },
      file: _file,
      error: _fileError,
      onPick: _pickFile,
    );
    return switch (kind) {
      CredentialKind.androidKeystore => [
        filePicker,
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _keystorePassword,
          decoration: InputDecoration(labelText: l10n.keystorePassword),
          obscureText: true,
          validator: validators.required,
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _keyAlias,
                decoration: InputDecoration(labelText: l10n.keyAlias),
                validator: validators.required,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: TextFormField(
                controller: _keyPassword,
                decoration: InputDecoration(labelText: l10n.keyPassword),
                obscureText: true,
                validator: validators.required,
              ),
            ),
          ],
        ),
      ],
      CredentialKind.googlePlayServiceAccount => [
        _PlayGuide(json: _json.text),
        const SizedBox(height: Gap.lg),
        filePicker,
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _json,
          decoration: InputDecoration(
            labelText: l10n.serviceAccountJson,
            hintText: l10n.serviceAccountJsonHint,
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12.5),
          validator: validators.required,
          onChanged: (_) => setState(() {}),
        ),
      ],
      CredentialKind.appStoreConnectKey => [
        const _AscGuide(),
        const SizedBox(height: Gap.lg),
        TextFormField(
          controller: _issuerId,
          decoration: InputDecoration(labelText: l10n.issuerId),
          validator: validators.required,
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _keyId,
          decoration: InputDecoration(labelText: l10n.keyId),
          validator: validators.required,
        ),
        const SizedBox(height: Gap.md),
        filePicker,
      ],
    };
  }
}

/// A "choose file" row that shows what was picked.
class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.label,
    required this.file,
    required this.onPick,
    this.error,
  });

  final String label;
  final PlatformFile? file;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: error == null ? scheme.outline : scheme.error,
            ),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  file == null
                      ? label
                      : l10n.fileChosen(
                          file!.name,
                          '${(file!.size / 1024).toStringAsFixed(1)} KB',
                        ),
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton(onPressed: onPick, child: Text(l10n.chooseFile)),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

/// The four Google steps, with links that become exact once the JSON is in:
/// the API page for their project and the email to invite.
class _PlayGuide extends StatelessWidget {
  const _PlayGuide({required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String? project;
    String? email;
    try {
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      project = parsed['project_id'] as String?;
      email = parsed['client_email'] as String?;
    } catch (_) {}

    Widget step(
      int n,
      String text, {
      String? linkLabel,
      String? url,
      Widget? extra,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$n',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodySmall),
                if (url != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: Text(linkLabel ?? url),
                  ),
                ?extra,
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.playGuideTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.sm),
          step(
            1,
            l10n.playGuide1,
            linkLabel: l10n.playGuide1Link,
            url:
                'https://console.cloud.google.com/iam-admin/serviceaccounts/create',
          ),
          step(2, l10n.playGuide2),
          step(
            3,
            l10n.playGuide3,
            linkLabel: project == null
                ? l10n.playGuide3LinkGeneric
                : l10n.playGuide3Link(project),
            url: project == null
                ? 'https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com'
                : 'https://console.developers.google.com/apis/api/androidpublisher.googleapis.com/overview?project=$project',
          ),
          step(
            4,
            l10n.playGuide4,
            linkLabel: l10n.playGuide4Link,
            url: 'https://play.google.com/console/developers',
            extra: email == null
                ? null
                : Row(
                    children: [
                      Expanded(
                        child: SelectionArea(
                          child: Text(
                            email,
                            style: theme.textTheme.mono.copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.copy,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: email!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.copied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                      ),
                    ],
                  ),
          ),
          Text(l10n.playGuideAfter, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The Apple steps, with the two pages they happen on.
class _AscGuide extends StatelessWidget {
  const _AscGuide();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget step(int n, String text, {String? linkLabel, String? url}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Gap.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: theme.textTheme.bodySmall),
                    if (url != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 15),
                        label: Text(linkLabel ?? url),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ascGuideTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.sm),
          step(
            1,
            l10n.ascGuide1,
            linkLabel: l10n.ascGuide1Link,
            url: 'https://appstoreconnect.apple.com/access/integrations/api',
          ),
          step(2, l10n.ascGuide2),
          step(3, l10n.ascGuide3),
          step(
            4,
            l10n.ascGuide4,
            linkLabel: l10n.ascGuide4Link,
            url: 'https://appstoreconnect.apple.com/apps',
          ),
          Text(l10n.ascGuideAfter, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
