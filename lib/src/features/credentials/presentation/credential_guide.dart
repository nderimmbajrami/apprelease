import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/credential.dart';

/// What the Slack app is created from: its name, its bot and the two
/// permissions a QA build needs. JSON, which Slack's manifest box takes on
/// either of its tabs.
const slackAppManifest = '''
{
  "display_information": { "name": "AppRelease" },
  "features": { "bot_user": { "display_name": "AppRelease" } },
  "oauth_config": { "scopes": { "bot": ["chat:write", "files:write"] } }
}''';

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
    // Text to copy, by the index of the step it belongs to.
    final snippets = switch (kind) {
      CredentialKind.slack => const {2: slackAppManifest},
      _ => const <int, String>{},
    };
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
      CredentialKind.slack => (
        5,
        [
          l10n.guideSlack1,
          l10n.guideSlack2,
          l10n.guideSlack3,
          l10n.guideSlack4,
          l10n.guideSlack5,
          l10n.guideSlack6,
          l10n.guideSlack7,
          l10n.guideSlack8,
        ],
        l10n.guideSlackNote,
        'qa-builds',
        'slack create app bot token oauth scopes chat:write files:write',
      ),
      CredentialKind.jira => (
        5,
        [
          l10n.guideJira1,
          l10n.guideJira2,
          l10n.guideJira3,
          l10n.guideJira4,
          l10n.guideJira5,
          l10n.guideJira6,
          l10n.guideJira7,
          l10n.guideJira8,
        ],
        l10n.guideJiraNote,
        'qa-builds',
        'jira cloud create api token atlassian account',
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

    // A Material, not a DecoratedBox: the tile inside draws its ink on the
    // nearest Material, and a painted box in between would hide it.
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepText(step),
                          if (snippets[i] case final snippet?)
                            _Snippet(snippet),
                        ],
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

/// A step's text, with the web addresses in it as links that open in a new
/// tab. Only an address with a path counts (api.slack.com/apps), so a file
/// name like google-services.json stays plain text.
class _StepText extends StatefulWidget {
  const _StepText(this.text);

  final String text;

  @override
  State<_StepText> createState() => _StepTextState();
}

class _StepTextState extends State<_StepText> {
  static final _address = RegExp(
    r'(?<![\w.@/-])(?:https://)?(?:[a-z0-9-]+\.)+(?:com|net|org|io|dev|store)/[^\s,)]*[^\s,).:;]',
  );

  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.text;
    _clear();
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _address.allMatches(text)) {
      final shown = m.group(0)!;
      final url = shown.startsWith('https://') ? shown : 'https://$shown';
      final tap = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(tap);
      spans
        ..add(TextSpan(text: text.substring(at, m.start)))
        ..add(
          TextSpan(
            text: shown,
            recognizer: tap,
            mouseCursor: SystemMouseCursors.click,
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
        );
      at = m.end;
    }
    spans.add(TextSpan(text: text.substring(at)));
    return SelectableText.rich(
      TextSpan(children: spans),
      style: theme.textTheme.bodySmall,
    );
  }
}

/// A block of text a step asks the customer to paste somewhere, with a
/// button that copies all of it.
class _Snippet extends StatelessWidget {
  const _Snippet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: Gap.sm),
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.xs, Gap.xs, Gap.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.sm),
              child: SelectableText(
                text.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.copy,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_outlined, size: 18),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: text.trim()));
              messenger.showSnackBar(SnackBar(content: Text(l10n.copied)));
            },
          ),
        ],
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
