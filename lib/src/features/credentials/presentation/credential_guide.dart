import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/credential.dart';

/// Where to get a credential, in a few steps, with the full guide, a video
/// and a person to help one tap away.
class CredentialGuide extends StatelessWidget {
  const CredentialGuide({required this.kind, super.key});

  final CredentialKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (minutes, steps, note, doc, video) = switch (kind) {
      CredentialKind.androidKeystore => (
        5,
        [
          l10n.guideKeystore1,
          l10n.guideKeystore2,
          l10n.guideKeystore3,
          l10n.guideKeystore4,
        ],
        l10n.guideKeystoreNote,
        'android-signing',
        'flutter android create upload keystore jks',
      ),
      CredentialKind.googlePlayServiceAccount => (
        10,
        [
          l10n.guidePlay1,
          l10n.guidePlay2,
          l10n.guidePlay3,
          l10n.guidePlay4,
          l10n.guidePlay5,
        ],
        l10n.guidePlayNote,
        'google-play',
        'google play console service account json key api access',
      ),
      CredentialKind.buildFile => (
        1,
        [l10n.guideFile1, l10n.guideFile2, l10n.guideFile3],
        l10n.guideFileNote,
        'flutter',
        'flutter firebase google-services.json android setup',
      ),
      CredentialKind.appStoreConnectKey => (
        5,
        [
          l10n.guideAsc1,
          l10n.guideAsc2,
          l10n.guideAsc3,
          l10n.guideAsc4,
          l10n.guideAsc5,
        ],
        l10n.guideAscNote,
        'app-store',
        'app store connect api key p8 issuer id key id',
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Theme(
        // No divider lines around the open tile.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(kind),
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
          leading: const Icon(Icons.lightbulb_outline, size: 20),
          title: Text(l10n.guideTitle, style: theme.textTheme.titleSmall),
          subtitle: Text(
            l10n.guideMinutes(minutes),
            style: theme.textTheme.bodySmall,
          ),
          children: [
            for (final (i, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: scheme.secondaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: SelectableText(
                        step,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs, bottom: Gap.md),
              child: Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _open('${AppConfig.docsUrl}$doc/'),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(l10n.guideFull),
                ),
                OutlinedButton.icon(
                  onPressed: () => _open(
                    'https://www.youtube.com/results?search_query='
                    '${Uri.encodeQueryComponent(video)}',
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(l10n.guideVideo),
                ),
                const SetupHelpButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mails us for a setup session; the customer's mail app opens prefilled.
class SetupHelpButton extends StatelessWidget {
  const SetupHelpButton({this.filled = false, super.key});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final label = Text(context.l10n.guideWithUs);
    const icon = Icon(Icons.support_agent, size: 18);
    void onPressed() => _open(AppConfig.setupHelpMailto);
    return filled
        ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
        : TextButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

/// The offer of a setup session, for the launch checklist.
class SetupHelpCard extends StatelessWidget {
  const SetupHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Wrap(
        spacing: Gap.lg,
        runSpacing: Gap.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.setupHelpTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(l10n.setupHelpBody, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SetupHelpButton(filled: true),
        ],
      ),
    );
  }
}

/// What happens to a secret once saved, said where it is handed over.
class CredentialSecurityNote extends StatelessWidget {
  const CredentialSecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: scheme.tertiary),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.credentialSecurityTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.credentialSecurityBody,
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _open(
                    '${AppConfig.siteUrl}/privacy/#how-your-keys-are-protected',
                  ),
                  child: Text(l10n.credentialSecurityMore),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
