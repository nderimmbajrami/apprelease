import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/widgets/app_pill.dart';
import '../../domain/release.dart';

/// The release state as a badge: colour and wording in one place.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final ReleaseStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      ReleaseStatus.queued => AppPill(
        label: l10n.statusQueued,
        icon: Icons.schedule,
        tone: PillTone.neutral,
      ),
      ReleaseStatus.running => AppPill(
        label: l10n.statusRunning,
        tone: PillTone.accent,
        pulse: true,
      ),
      ReleaseStatus.succeeded => AppPill(
        label: l10n.statusSucceeded,
        icon: Icons.check_circle,
        tone: PillTone.success,
      ),
      ReleaseStatus.failed => AppPill(
        label: l10n.statusFailed,
        icon: Icons.error,
        tone: PillTone.danger,
      ),
      ReleaseStatus.cancelled => AppPill(
        label: l10n.statusCancelled,
        icon: Icons.block,
        tone: PillTone.warning,
      ),
    };
  }
}

/// Where a release went, as words.
String trackLabel(BuildContext context, ReleaseTrack track) {
  final l10n = context.l10n;
  return switch (track) {
    ReleaseTrack.internal => l10n.trackInternal,
    ReleaseTrack.alpha => l10n.trackAlpha,
    ReleaseTrack.beta => l10n.trackBeta,
    ReleaseTrack.production => l10n.trackProduction,
    ReleaseTrack.testflight => l10n.trackTestflight,
    ReleaseTrack.appStore => l10n.trackAppStore,
  };
}
