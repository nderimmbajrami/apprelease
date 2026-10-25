import 'package:apprelease/src/core/utils/validators.dart';
import 'package:apprelease/src/features/apps/domain/app_project.dart';
import 'package:apprelease/src/features/credentials/domain/credential.dart';
import 'package:apprelease/src/features/releases/domain/readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a repository address must name one repository', () {
    for (final ok in [
      'https://github.com/acme/shop-app',
      'https://github.com/acme/shop-app.git',
      'git@github.com:acme/shop-app.git',
      'https://gitlab.com/group/sub/app',
      'ssh://git@host:2222/acme/app.git',
    ]) {
      expect(Validators.isRepoUrl(ok), isTrue, reason: ok);
    }
    for (final bad in [
      'https://github.com',
      'https://github.com/',
      'https://github.com/acme',
      'github.com/acme/app',
      'acme/app',
    ]) {
      expect(Validators.isRepoUrl(bad), isFalse, reason: bad);
    }
  });

  test('com.example ids are the template, not an app', () {
    expect(Validators.isExampleId('com.example.app'), isTrue);
    expect(Validators.isExampleId('app.mekauto.mobile'), isFalse);
  });

  final app = AppProject(
    id: 'a',
    teamId: 't',
    name: 'Github.com',
    repoUrl: 'https://github.com',
    androidPackageName: 'com.example.app',
    iosBundleId: 'com.example.app',
    createdAt: DateTime(2026, 10, 26),
  );
  Credential cred(CredentialKind kind, {String? appId}) => Credential(
    id: kind.name,
    teamId: 't',
    kind: kind,
    name: kind.name,
    appId: appId,
    createdAt: DateTime(2026, 10, 26),
  );

  test('the screenshot case: nothing is ready on Android', () {
    final missing = Readiness.missing(app, Platform.android, const []);
    expect(
      [for (final m in missing) m.item],
      [
        ReadinessItem.repository,
        ReadinessItem.androidPackage,
        ReadinessItem.keystore,
        ReadinessItem.googlePlay,
      ],
    );
  });

  test('a real app with its keys is ready', () {
    final real = app.copyWith(
      repoUrl: 'https://github.com/acme/shop-app',
      androidPackageName: 'com.acme.shop',
      iosBundleId: 'com.acme.shop',
    );
    final creds = [
      cred(CredentialKind.androidKeystore, appId: 'a'),
      cred(CredentialKind.googlePlayServiceAccount),
      cred(CredentialKind.appStoreConnectKey),
    ];
    expect(Readiness.ready(real, Platform.android, creds), isTrue);
    expect(Readiness.ready(real, Platform.ios, creds), isTrue);
  });

  test('another app\'s keystore does not sign this one', () {
    final real = app.copyWith(
      repoUrl: 'https://github.com/acme/shop-app',
      androidPackageName: 'com.acme.shop',
    );
    final creds = [
      cred(CredentialKind.androidKeystore, appId: 'other'),
      cred(CredentialKind.googlePlayServiceAccount),
    ];
    expect(
      [
        for (final m in Readiness.missing(real, Platform.android, creds))
          m.item,
      ],
      [ReadinessItem.keystore],
    );
  });
}
