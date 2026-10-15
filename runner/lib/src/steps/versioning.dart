import 'dart:convert';
import 'dart:io';

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';

/// Works out AR_BUILD_NUMBER.
///
/// `google_play` asks the Play Developer API through `fastlane`'s
/// `supply`-free sibling: a small Python helper is not shipped, so the
/// query goes through the `google-play` CLI if present and otherwise falls
/// back to the release's own sequence number. `app_store_connect` uses
/// `xcrun altool`'s sibling `app-store-connect` when present. Both CLIs are
/// the Codemagic ones (`pip install codemagic-cli-tools`); they are the most
/// reliable open-source way to talk to the two store APIs and the runner
/// shells out to them rather than re-implementing OAuth and JWT signing.
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
        final json = env['AR_GOOGLE_PLAY_JSON'];
        final package = app['android_package_name'] as String;
        if (json == null || package.isEmpty) {
          await log('google_play versioning needs the service account group and a package name; using the sequence number', stepId: stepId, level: 'warning');
          break;
        }
        final latest = await _run('google-play', ['get-latest-build-number', '--package-name', package, '--credentials', '@file:$json']);
        if (latest != null) {
          await log('Latest build number on Google Play: $latest', stepId: stepId);
          return latest + 1;
        }
      case 'app_store_connect':
        final bundle = app['ios_bundle_id'] as String;
        final keyId = env['AR_ASC_KEY_ID'];
        if (keyId == null || bundle.isEmpty) {
          await log('app_store_connect versioning needs the API key and a bundle id; using the sequence number', stepId: stepId, level: 'warning');
          break;
        }
        final appId = await _run('app-store-connect', ['get-latest-app-store-build-number', '--bundle-id', bundle, '--issuer-id', env['AR_ASC_ISSUER_ID']!, '--key-id', keyId, '--private-key', '@file:${env['AR_ASC_KEY_PATH']}']);
        final testflight = await _run('app-store-connect', ['get-latest-testflight-build-number', '--bundle-id', bundle, '--issuer-id', env['AR_ASC_ISSUER_ID']!, '--key-id', keyId, '--private-key', '@file:${env['AR_ASC_KEY_PATH']}']);
        final latest = [appId ?? 0, testflight ?? 0].reduce((a, b) => a > b ? a : b);
        if (appId != null || testflight != null) {
          await log('Latest build number on App Store Connect: $latest', stepId: stepId);
          return latest + 1;
        }
    }
    final number = release['number'] as int;
    await log('Using the release sequence number $number', stepId: stepId);
    return number;
  }

  /// Runs one of the store CLIs and reads the number it prints. Null when
  /// the CLI is missing or the call fails; the caller falls back.
  Future<int?> _run(String executable, List<String> args) async {
    try {
      final result = await Process.run(executable, args);
      if (result.exitCode != 0) {
        await log('$executable: ${(result.stderr as String).trim()}', stepId: stepId, level: 'warning');
        return null;
      }
      final text = (result.stdout as String).trim();
      return int.tryParse(text) ?? int.tryParse(jsonDecode(text).toString());
    } on ProcessException {
      await log('$executable is not installed (pip install codemagic-cli-tools)', stepId: stepId, level: 'warning');
      return null;
    }
  }
}
