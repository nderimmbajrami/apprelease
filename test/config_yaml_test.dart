import 'package:apprelease/src/features/apps/domain/app_project.dart';
import 'package:apprelease/src/features/config/domain/release_config.dart';
import 'package:apprelease/src/features/credentials/domain/credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final app = AppProject(
    id: 'a',
    teamId: 't',
    name: 'Acme Shop',
    repoUrl: 'https://github.com/acme/shop.git',
    androidPackageName: 'com.acme.shop',
    iosBundleId: 'com.acme.shop',
    createdAt: DateTime(2026, 10, 15),
  );

  Credential cred(CredentialKind kind, String name) => Credential(
    id: name,
    teamId: 't',
    kind: kind,
    name: name,
    createdAt: DateTime(2026, 10, 15),
  );

  test(
    'without credentials the signing sections are commented placeholders',
    () {
      final yaml = ReleaseConfig(app: app).toYaml();
      expect(yaml, contains('android-production:'));
      expect(yaml, contains('ios-testflight:'));
      expect(yaml, contains('# android_signing: add an Android keystore'));
      expect(
        yaml,
        contains('# app_store_connect: add an App Store Connect API key'),
      );
      expect(ReleaseConfig(app: app).isComplete, isFalse);
    },
  );

  test('with every credential the file is complete and references them', () {
    final config = ReleaseConfig(
      app: app,
      credentials: [
        cred(CredentialKind.androidKeystore, 'upload_keystore'),
        cred(CredentialKind.googlePlayServiceAccount, 'google_play'),
        cred(CredentialKind.appStoreConnectKey, 'asc_key'),
      ],
    );
    final yaml = config.toYaml();
    expect(config.isComplete, isTrue);
    expect(yaml, contains('      android_signing:\n        - upload_keystore'));
    expect(yaml, contains('      groups:\n        - google_play'));
    expect(yaml, contains('source: google_play'));
    expect(yaml, contains('bundle_identifier: com.acme.shop'));
    expect(yaml, contains('source: app_store_connect'));
    expect(yaml, contains('--build-number=\$AR_BUILD_NUMBER'));
    expect(yaml, isNot(contains('#  android_signing')));
  });

  test('an Android-only app gets no iOS workflow', () {
    final yaml = ReleaseConfig(
      app: app.copyWith(platforms: {Platform.android}),
    ).toYaml();
    expect(yaml, isNot(contains('ios-testflight')));
  });
}
