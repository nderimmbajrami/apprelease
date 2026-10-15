import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_title.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

/// Profile, appearance, and the way out.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: ref.read(currentUserProvider)?.name ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateName(_name.text);
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
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
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).deleteOwnAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final validators = Validators(l10n);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final backend = ref.watch(backendProvider);
    final isBusy = ref.watch(authControllerProvider).isLoading;

    return PageBody(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          PageHeader(
            title: Text(l10n.settingsTitle),
            subtitle: Text(l10n.settingsSubtitle),
          ),
          const SizedBox(height: Gap.xl),
          SectionTitle(title: l10n.profile),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.fullName),
                    validator: validators.required,
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: InputDecoration(labelText: l10n.email),
                  ),
                  const SizedBox(height: Gap.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: isBusy ? null : _saveProfile,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.xl),
          SectionTitle(title: l10n.appearance),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(
                        Icons.brightness_auto_outlined,
                        size: 16,
                      ),
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined, size: 16),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 16),
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref
                      .read(themeModeControllerProvider.notifier)
                      .set(s.first),
                ),
                const SizedBox(height: Gap.lg),
                Text(
                  '${l10n.backendLabel}: ${backend == Backend.local ? l10n.backendLocal : l10n.backendSupabase}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.signOut),
          ),
          const SizedBox(height: Gap.xl),
          SectionTitle(title: l10n.dangerZone),
          AppCard(
            borderColor: theme.colorScheme.error.withValues(alpha: .4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountExplain,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Gap.md),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: Text(l10n.deleteAccount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
