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
        final latest = await play.latestBuildNumber(package);
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
}
