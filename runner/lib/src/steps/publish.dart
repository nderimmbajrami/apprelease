import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';
import '../stores/app_store_connect.dart';
import '../stores/google_play.dart';

/// The last step: hand the artifact to the store named in `publishing`.
///
/// Google Play is the Android Publisher API, called directly. App Store
/// Connect is Apple's `xcrun altool` for the upload (the API has no upload
/// endpoint) and the App Store Connect API for everything after.
class Publish {
  Publish({
    required this.api,
    required this.log,
    required this.stepId,
    required this.secretsKey,
  });

  final SupabaseApi api;
  final LogSink log;
  final String stepId;
  final String secretsKey;

  Future<void> run({
    required Map<String, dynamic> release,
    required WorkflowConfig workflow,
    required Map<String, String> env,
    required List<String> artifacts,
  }) async {
    final platform = release['platform'] as String;
    if (platform == 'android') {
      await _googlePlay(release, workflow, env, artifacts);
    } else {
      await _appStoreConnect(release, workflow, env, artifacts);
    }
  }

  // ----------------------------------------------------------- google play

  Future<void> _googlePlay(
    Map<String, dynamic> release,
    WorkflowConfig workflow,
    Map<String, String> env,
    List<String> artifacts,
  ) async {
    final config = (workflow.publishing['google_play'] as Map?)
        ?.cast<String, dynamic>();
    if (config == null) {
      await log(
        'No google_play section under publishing; artifacts kept, nothing uploaded',
        stepId: stepId,
        level: 'warning',
      );
      return;
    }
    final bundle = artifacts.firstWhere(
      (a) => a.endsWith('.aab'),
      orElse: () => throw StepFailed('No .aab among the artifacts'),
    );
    final json = env['GOOGLE_PLAY_SERVICE_ACCOUNT'];
    if (json == null) {
      throw StepFailed(
        'google_play.credentials needs the service account group',
      );
    }
    final package = env['PACKAGE_NAME'] ?? '';
    if (package.isEmpty) {
      throw StepFailed('Set vars.PACKAGE_NAME in the workflow');
    }

    final track = '${config['track'] ?? release['track']}';
    final play = GooglePlayClient(
      (jsonDecode(json) as Map).cast<String, dynamic>(),
    );
    await log(
      'Uploading ${p.basename(bundle)} to Google Play · track $track',
      stepId: stepId,
    );
    final versionCode = await play.publishBundle(
      package: package,
      bundle: File(bundle),
      track: track,
      draft: config['submit_as_draft'] == true,
      rolloutFraction: (config['rollout_fraction'] as num?)?.toDouble(),
      inAppUpdatePriority: config['in_app_update_priority'] as int?,
      changesNotSentForReview: config['changes_not_sent_for_review'] == true,
      releaseNotes: _releaseNotes(env['AR_BUILD_DIR']!),
      releaseName: '${release['version_name']} (${env['AR_BUILD_NUMBER']})',
      onLog: (line) => log(line, stepId: stepId),
    );
    await log('Rolled out version code $versionCode to $track', stepId: stepId);
  }

  // ----------------------------------------------------- app store connect

  Future<void> _appStoreConnect(
    Map<String, dynamic> release,
    WorkflowConfig workflow,
    Map<String, String> env,
    List<String> artifacts,
  ) async {
    final config = (workflow.publishing['app_store_connect'] as Map?)
        ?.cast<String, dynamic>();
    if (config == null) {
      await log(
        'No app_store_connect section under publishing; artifacts kept, nothing uploaded',
        stepId: stepId,
        level: 'warning',
      );
      return;
    }
    final ipa = artifacts.firstWhere(
      (a) => a.endsWith('.ipa'),
      orElse: () => throw StepFailed('No .ipa among the artifacts'),
    );
    final keyId = env['AR_ASC_KEY_ID'];
    final issuer = env['AR_ASC_ISSUER_ID'];
    final keyPath = env['AR_ASC_KEY_PATH'];
    if (keyId == null || issuer == null || keyPath == null) {
      throw StepFailed('App Store Connect key is not loaded');
    }

    // 1. Upload with Apple's tool. altool reads the .p8 from
    //    API_PRIVATE_KEYS_DIR, which the signing step set.
    await log(
      'Uploading ${p.basename(ipa)} to App Store Connect',
      stepId: stepId,
    );
    await _xcrun([
      'altool',
      '--upload-app',
      '-f',
      ipa,
      '--type',
      'ios',
      '--apiKey',
      keyId,
      '--apiIssuer',
      issuer,
    ], env);

    final track = release['track'] as String;
    final submitTestflight =
        config['submit_to_testflight'] == true || track == 'testflight';
    final submitAppStore =
        config['submit_to_app_store'] == true || track == 'appStore';
    if (!submitTestflight && !submitAppStore) {
      await log('Uploaded. Nothing else requested.', stepId: stepId);
      return;
    }

    // 2. Everything after the upload goes through the API.
    final asc = AppStoreConnectClient(
      issuerId: issuer,
      keyId: keyId,
      privateKeyPem: File(keyPath).readAsStringSync(),
    );
    final appId =
        env['AR_ASC_APP_ID'] ?? await asc.appId(env['AR_BUNDLE_ID'] ?? '');
    final buildNumber = env['AR_BUILD_NUMBER']!;
    await log(
      'Waiting for App Store Connect to process build $buildNumber…',
      stepId: stepId,
    );
    final buildId = await asc.waitForBuild(
      appId: appId,
      buildNumber: buildNumber,
      onLog: (line) => log(line, stepId: stepId),
    );
    await log('Build $buildNumber processed', stepId: stepId);

    final notes = _releaseNotes(env['AR_BUILD_DIR']!);
    if (notes.isNotEmpty) {
      await asc.setWhatsNew(buildId, notes.values.first);
    }

    if (submitTestflight) {
      final groups = [
        for (final g in (config['beta_groups'] as List?) ?? const []) '$g',
      ];
      await asc.addToBetaGroups(
        appId: appId,
        buildId: buildId,
        groupNames: groups,
        onLog: (line) => log(line, stepId: stepId),
      );
      if (config['expire_previous_builds'] == true) {
        await asc.expireOtherBuilds(
          appId: appId,
          keepBuildId: buildId,
          versionName: release['version_name'] as String,
        );
        await log(
          'Expired the other TestFlight builds of ${release['version_name']}',
          stepId: stepId,
        );
      }
      await log(
        'Build $buildNumber is on TestFlight${groups.isEmpty ? '' : ' · ${groups.join(', ')}'}',
        stepId: stepId,
      );
    }

    if (submitAppStore) {
      await asc.submitForReview(
        appId: appId,
        buildId: buildId,
        versionName: release['version_name'] as String,
        releaseType: '${config['release_type'] ?? 'MANUAL'}',
        copyright: config['copyright'] as String?,
        onLog: (line) => log(line, stepId: stepId),
      );
    }
  }

  // ---------------------------------------------------------------- helpers

  /// `release_notes.txt` or `release_notes_<locale>.txt` in the repository
  /// root, keyed by BCP-47 locale.
  Map<String, String> _releaseNotes(String buildDir) {
    final notes = <String, String>{};
    final dir = Directory(buildDir);
    if (!dir.existsSync()) return notes;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == 'release_notes.txt') {
        notes['en-US'] = entity.readAsStringSync().trim();
      } else if (name.startsWith('release_notes_') && name.endsWith('.txt')) {
        final locale = name.substring('release_notes_'.length, name.length - 4);
        notes[locale] = entity.readAsStringSync().trim();
      }
    }
    notes.removeWhere((_, text) => text.isEmpty);
    return notes;
  }

  Future<void> _xcrun(List<String> args, Map<String, String> env) async {
    await log('\$ xcrun ${args.join(' ')}', stepId: stepId, level: 'command');
    final process = await Process.start(
      'xcrun',
      args,
      environment: {...Platform.environment, ...env},
    );
    Future<void> pipe(Stream<List<int>> stream, String level) => stream
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .forEach((line) async {
          if (line.trim().isNotEmpty) {
            await log(line, stepId: stepId, level: level);
          }
        });
    await Future.wait([
      pipe(process.stdout, 'info'),
      pipe(process.stderr, 'warning'),
    ]);
    final code = await process.exitCode;
    if (code != 0) throw StepFailed('xcrun altool exited with code $code');
  }
}
