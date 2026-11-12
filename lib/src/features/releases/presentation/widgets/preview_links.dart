import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/release.dart';

/// What a finished preview hands over: the Android app and the iPhone
/// link, each as a QR code to scan with the phone's camera.
class PreviewLinks extends StatelessWidget {
  const PreviewLinks({required this.release, super.key});

  final Release release;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final apk = release.previewApkUrl;
    final web = release.previewWebUrl;
    if (apk == null && web == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.previewReadyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(l10n.previewReadyBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: Gap.lg),
          Wrap(
            spacing: Gap.xl,
            runSpacing: Gap.xl,
            children: [
              if (apk != null)
                _QrTile(
                  icon: Icons.android,
                  title: l10n.previewAndroidTitle,
                  body: l10n.previewAndroidBody,
                  url: apk,
                ),
              if (web != null)
                _QrTile(
                  icon: Icons.phone_iphone,
                  title: l10n.previewIphoneTitle,
                  body: l10n.previewIphoneBody,
                  url: web,
                ),
            ],
          ),
          if (web == null) ...[
            const SizedBox(height: Gap.lg),
            Text(l10n.previewNoWeb, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  const _QrTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String body;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: Gap.sm),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: Gap.md),
          // Always dark on white: a camera reads nothing else reliably,
          // whatever the console's theme.
          Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: QrImageView(
              data: url,
              size: 200,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              semanticsLabel: title,
            ),
          ),
          const SizedBox(height: Gap.md),
          Text(body, style: theme.textTheme.bodySmall),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: url));
                  messenger.showSnackBar(SnackBar(content: Text(l10n.copied)));
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: Text(l10n.previewCopyLink),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.previewOpenLink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
