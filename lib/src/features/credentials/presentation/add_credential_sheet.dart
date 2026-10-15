import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../domain/credential.dart';
import 'credentials_controller.dart';
import 'credentials_screen.dart';

Future<void> showAddCredentialSheet(
  BuildContext context, {
  CredentialKind? kind,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (context) => _AddCredentialSheet(initialKind: kind),
);

class _AddCredentialSheet extends ConsumerStatefulWidget {
  const _AddCredentialSheet({this.initialKind});

  final CredentialKind? initialKind;

  @override
  ConsumerState<_AddCredentialSheet> createState() =>
      _AddCredentialSheetState();
}

class _AddCredentialSheetState extends ConsumerState<_AddCredentialSheet> {
  final _formKey = GlobalKey<FormState>();
  late var _kind = widget.initialKind ?? CredentialKind.androidKeystore;
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
        ),
      ],
      CredentialKind.appStoreConnectKey => [
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
