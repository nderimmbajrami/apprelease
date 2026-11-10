import 'package:apprelease/src/features/apps/domain/app_project.dart';
import 'package:apprelease/src/features/credentials/domain/credential.dart';
import 'package:apprelease/src/features/releases/domain/readiness.dart';
import 'package:apprelease/src/features/releases/domain/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final app = AppProject(
    id: 'a',
    teamId: 't',
    name: 'Shop',
    repoUrl: 'https://github.com/acme/shop',
    androidPackageName: 'com.acme.shop',
    iosBundleId: 'com.acme.shop',
    createdAt: DateTime(2026, 11, 10),
  );
  Credential cred(
    CredentialKind kind, {
    String? appId,
    Map<String, String> meta = const {},
  }) => Credential(
    id: kind.name,
    teamId: 't',
    kind: kind,
    name: kind.name,
    appId: appId,
    meta: meta,
    createdAt: DateTime(2026, 11, 10),
  );

  test('each platform offers its QA build next to the store tracks', () {
    expect(
      ReleaseTrack.forPlatform(Platform.android),
      contains(ReleaseTrack.qa),
    );
    expect(
      ReleaseTrack.forPlatform(Platform.ios),
      contains(ReleaseTrack.qaTestflight),
    );
    // The stores stay the first choice in the dialog.
    expect(ReleaseTrack.forPlatform(Platform.android).first.isQa, isFalse);
    expect(ReleaseTrack.forPlatform(Platform.ios).first.isQa, isFalse);
  });

  test('a QA build ends with Send to QA; Android uploads to no store', () {
    final android = pipelineSteps(
      Platform.android,
      'r',
      track: ReleaseTrack.qa,
    );
    expect(android, hasLength(7));
    expect(android[4].name, 'Build APK');
    expect(android.last.name, 'Send to QA');
    expect(android.any((s) => s.name.contains('Upload')), isFalse);

    final ios = pipelineSteps(
      Platform.ios,
      'r',
      track: ReleaseTrack.qaTestflight,
    );
    expect(ios, hasLength(8));
    expect(ios[6].name, 'Upload to TestFlight');
    expect(ios.last.name, 'Send to QA');
    expect(ios.last.id, 'r-7');

    // A store release is what it was.
    expect(
      pipelineSteps(
        Platform.android,
        'r',
        track: ReleaseTrack.internal,
      ).last.name,
      'Upload to Google Play',
    );
  });

  test('a push rule carries the QA tracks', () {
    const rule = PushRule(
      branch: 'ready-for-qa',
      platforms: {Platform.android, Platform.ios},
      trackAndroid: 'qa',
      trackIos: 'qaTestflight',
    );
    final back = PushRule.fromJson(rule.toJson());
    expect((back.trackAndroid, back.trackIos), ('qa', 'qaTestflight'));
    expect(
      ReleaseTrack.parse(back.trackAndroid, Platform.android).isQa,
      isTrue,
    );
  });

  test('a track this console does not know reads as the first of its '
      'platform', () {
    expect(
      ReleaseTrack.parse('nightly', Platform.ios),
      ReleaseTrack.testflight,
    );
    expect(ReleaseTrack.parse(null, Platform.android), ReleaseTrack.internal);
  });

  test('an Android QA build needs Slack, not Google Play', () {
    final keystore = cred(CredentialKind.androidKeystore);
    expect(
      [
        for (final c in Readiness.checks(app, Platform.android, [
          keystore,
        ], track: ReleaseTrack.qa))
          if (!c.ok) c.item,
      ],
      [ReadinessItem.slack],
    );
    expect(
      Readiness.checks(app, Platform.android, [
        keystore,
        cred(CredentialKind.slack),
      ], track: ReleaseTrack.qa).every((c) => c.ok),
      isTrue,
    );
    // A channel linked to another app is that app's.
    expect(
      Readiness.checks(app, Platform.android, [
        keystore,
        cred(CredentialKind.slack, appId: 'other'),
      ], track: ReleaseTrack.qa).every((c) => c.ok),
      isFalse,
    );
    // A store release is checked as before.
    expect(
      Readiness.missing(app, Platform.android, [keystore]).single.item,
      ReadinessItem.googlePlay,
    );
  });

  test('an iOS QA build needs the App Store Connect key and Slack', () {
    expect(
      [
        for (final c in Readiness.checks(
          app,
          Platform.ios,
          const [],
          track: ReleaseTrack.qaTestflight,
        ))
          if (!c.ok) c.item,
      ],
      [ReadinessItem.appStoreConnect, ReadinessItem.slack],
    );
  });

  test('connections say where they point', () {
    expect(
      cred(CredentialKind.slack, meta: {'channel': 'C0123ABCDEF'}).summary,
      'channel C0123ABCDEF',
    );
    expect(
      cred(
        CredentialKind.jira,
        meta: {'site': 'https://acme.atlassian.net', 'status': 'Ready for QA'},
      ).summary,
      'acme.atlassian.net · → Ready for QA',
    );
    expect(CredentialKind.slack.needsFile, isFalse);
    expect(CredentialKind.jira.isPerApp, isTrue);
  });
}
