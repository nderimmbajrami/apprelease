import '../../../core/utils/validators.dart';
import '../../apps/domain/app_project.dart';
import '../../credentials/domain/credential.dart';

/// Something a release needs before the runner can do anything useful.
enum ReadinessItem {
  repository,
  androidPackage,
  iosBundle,
  keystore,
  googlePlay,
  appStoreConnect,
}

class ReadinessCheck {
  const ReadinessCheck(this.item, {required this.ok});

  final ReadinessItem item;
  final bool ok;
}

/// What stands between an app and a release on one platform. Checked in
/// the console before a release is queued, so a customer never waits for a
/// build that was bound to fail at the first step.
abstract final class Readiness {
  static List<ReadinessCheck> checks(
    AppProject app,
    Platform platform,
    List<Credential> credentials,
  ) {
    bool has(CredentialKind kind) => credentials.any((c) => c.kind == kind);
    // A keystore linked to another app does not sign this one.
    final keystore = credentials.any(
      (c) =>
          c.kind == CredentialKind.androidKeystore &&
          (c.appId == null || c.appId == app.id),
    );
    bool goodId(String id) =>
        Validators.isApplicationId(id) && !Validators.isExampleId(id);

    return [
      ReadinessCheck(
        ReadinessItem.repository,
        ok: Validators.isRepoUrl(app.repoUrl),
      ),
      if (platform == Platform.android) ...[
        ReadinessCheck(
          ReadinessItem.androidPackage,
          ok: goodId(app.androidPackageName),
        ),
        ReadinessCheck(ReadinessItem.keystore, ok: keystore),
        ReadinessCheck(
          ReadinessItem.googlePlay,
          ok: has(CredentialKind.googlePlayServiceAccount),
        ),
      ] else ...[
        ReadinessCheck(ReadinessItem.iosBundle, ok: goodId(app.iosBundleId)),
        ReadinessCheck(
          ReadinessItem.appStoreConnect,
          ok: has(CredentialKind.appStoreConnectKey),
        ),
      ],
    ];
  }

  static List<ReadinessCheck> missing(
    AppProject app,
    Platform platform,
    List<Credential> credentials,
  ) => [
    for (final c in checks(app, platform, credentials))
      if (!c.ok) c,
  ];

  static bool ready(
    AppProject app,
    Platform platform,
    List<Credential> credentials,
  ) => missing(app, platform, credentials).isEmpty;
}
