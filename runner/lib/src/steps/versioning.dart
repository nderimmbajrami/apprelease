import 'dart:convert';
import 'dart:io';

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';
import '../stores/app_store_connect.dart';
import '../stores/google_play.dart';

/// Works out AR_BUILD_NUMBER: the store's highest build number plus one, or
/// the release's own sequence number when no store is configured.
class Versioning {
  Versioning({
    required this.api,
    required this.log,
    required this.stepId,
    required this.secretsKey,
  });

  final SupabaseApi api;
  final LogSink log;
  final String stepId;
  final String secretsKey;

  Future<int> next({
    required String source,
    required Map<String, dynamic> release,
    required Map<String, dynamic> app,
    required WorkflowConfig workflow,
    required Map<String, String> env,
  }) async {
    final explicit = release['build_number'] as int?;
    if (explicit != null) {
      await log('Build number $explicit set by hand', stepId: stepId);
      return explicit;
    }

    switch (source) {
      case 'google_play':
        final json = env['GOOGLE_PLAY_SERVICE_ACCOUNT'];
        final package = app['android_package_name'] as String;
        if (json == null || package.isEmpty) {
          await log(
            'google_play versioning needs the service account group and a package name; using the sequence number',
            stepId: stepId,
            level: 'warning',
          );
          break;
        }
        final play = GooglePlayClient(
          (jsonDecode(json) as Map).cast<String, dynamic>(),
        );
        await log(
          'Asking Google Play for the latest build number as ${play.clientEmail}',
          stepId: stepId,
        );
        final int latest;
        try {
          latest = await play.latestBuildNumber(package);
        } on Object catch (error) {
          // A QA build does not go to Google Play, so an app that is not
          // there yet (or a key Google does not accept yet) is no reason
          // to stop it.
          if (release['track'] != 'qa') rethrow;
          await log(
            'Google Play gave no build number '
            '(${'$error'.split('\n').first}); using the sequence number',
            stepId: stepId,
            level: 'warning',
          );
          break;
        }
        await log(
          'Latest build number on Google Play: $latest',
          stepId: stepId,
        );
        return latest + 1;

      case 'app_store_connect':
        final bundle = app['ios_bundle_id'] as String;
        final keyPath = env['AR_ASC_KEY_PATH'];
        if (keyPath == null || bundle.isEmpty) {
          await log(
            'app_store_connect versioning needs the API key and a bundle id; using the sequence number',
            stepId: stepId,
            level: 'warning',
          );
          break;
        }
        final asc = AppStoreConnectClient(
          issuerId: env['AR_ASC_ISSUER_ID']!,
          keyId: env['AR_ASC_KEY_ID']!,
          privateKeyPem: File(keyPath).readAsStringSync(),
        );
        final appId = await asc.appId(bundle);
        env['AR_ASC_APP_ID'] = appId;
        await _checkVersionIsOpen(asc, release, appId);
        final latest = await asc.latestBuildNumber(appId);
        await log(
          'Latest build number on App Store Connect: $latest',
          stepId: stepId,
        );
        return latest + 1;
    }

    final number = release['number'] as int;
    await log('Using the release sequence number $number', stepId: stepId);
    return number;
  }

  /// Apple refuses any build for a version at or below the last approved
  /// one, and only says so after the upload. Asked first, and a version
  /// that would be refused is moved past the approved one, so a customer
  /// who does not know the rule still gets a release.
  Future<void> _checkVersionIsOpen(
    AppStoreConnectClient asc,
    Map<String, dynamic> release,
    String appId,
  ) async {
    final String? approved;
    try {
      approved = await asc.highestApprovedVersion(appId);
    } on Object catch (error) {
      await log(
        'Could not check approved versions ($error); going on',
        stepId: stepId,
        level: 'warning',
      );
      return;
    }
    if (approved == null) return;
    await log('Highest approved App Store version: $approved', stepId: stepId);
    final version = release['version_name'] as String;
    if (compareVersions(version, approved) > 0) return;
    final next = nextVersionAfter(approved);
    await log(
      'Version $version is already approved on the App Store and Apple takes '
      'no new builds for it. Releasing as $next instead.',
      stepId: stepId,
      level: 'warning',
    );
    release['version_name'] = next;
    await api.updateRelease(release['id'] as String, {'version_name': next});
  }
}

/// The patch after [approved]: `1.1.1` → `1.1.2`, `2.0` → `2.0.1`.
String nextVersionAfter(String approved) {
  final parts = approved.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  parts[2] += 1;
  return parts.take(3).join('.');
}
