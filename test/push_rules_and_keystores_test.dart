import 'package:apprelease/src/features/apps/domain/app_project.dart';
import 'package:apprelease/src/features/config/domain/release_config.dart';
import 'package:apprelease/src/features/credentials/domain/credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a push rule survives the trip through the database json', () {
    const rule = PushRule(
      branch: 'release/*',
      platforms: {Platform.android, Platform.ios},
      trackAndroid: 'beta',
      trackIos: 'appStore',
    );
    final back = PushRule.fromJson(rule.toJson());
    expect(back.branch, 'release/*');
    expect(back.platforms, {Platform.android, Platform.ios});
    expect(back.trackAndroid, 'beta');
    expect(back.trackIos, 'appStore');
  });

  test('the defaults send develop to testers and main to the stores', () {
    final dev = PushRule.defaults.first, prod = PushRule.defaults.last;
    expect((dev.branch, dev.trackAndroid, dev.trackIos), (
      'develop',
      'internal',
      'testflight',
    ));
    expect((prod.branch, prod.trackAndroid, prod.trackIos), (
      'main',
      'production',
      'appStore',
    ));
  });

  test('the yaml signs with the app\'s own keystore, not another app\'s', () {
    final app = AppProject(
      id: 'mekauto',
      teamId: 't',
      name: 'mekauto',
      repoUrl: 'https://github.com/acme/mekauto.git',
      androidPackageName: 'app.mekauto.mobile',
      platforms: const {Platform.android},
      createdAt: DateTime(2026, 10, 23),
    );
    Credential keystore(String name, String? appId) => Credential(
      id: name,
      teamId: 't',
      kind: CredentialKind.androidKeystore,
      name: name,
      appId: appId,
      createdAt: DateTime(2026, 10, 16),
    );
    final yaml = ReleaseConfig(
      app: app,
      credentials: [
        keystore('upload_keystore', 'baurapport'),
        keystore('mekauto_upload_keystore', 'mekauto'),
      ],
    ).toYaml();
    expect(yaml, contains('- mekauto_upload_keystore'));
    expect(yaml, isNot(contains('- upload_keystore')));
  });
}
