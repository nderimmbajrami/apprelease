import 'dart:io';

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';

/// The last step: hand the artifact to the store named in `publishing`.
///
/// Google Play goes through the `google-play` CLI, App Store Connect through
/// `xcrun altool` for the upload and the `app-store-connect` CLI for
/// TestFlight groups and App Store submission. Both CLIs come from
/// `pip install codemagic-cli-tools`.
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
    final publishing = workflow.publishing;
    final platform = release['platform'] as String;
    final track = release['track'] as String;

    if (platform == 'android') {
      final config = (publishing['google_play'] as Map?)?.cast<String, dynamic>();
      if (config == null) {
        await log('No google_play section under publishing; artifacts kept, nothing uploaded', stepId: stepId, level: 'warning');
        return;
      }
      final bundle = artifacts.firstWhere(
        (a) => a.endsWith('.aab'),
        orElse: () => throw StepFailed('No .aab among the artifacts'),
      );
      final json = env['AR_GOOGLE_PLAY_JSON'];
      if (json == null) throw StepFailed('google_play.credentials needs the service account group');
      await log('Uploading ${bundle.split('/').last} to Google Play · track $track', stepId: stepId);
      await _exec('google-play', [
        'bundles',
        'publish',
        '--bundle', bundle,
        '--track', track,
        '--credentials', '@file:$json',
        if (config['submit_as_draft'] == true) '--draft',
        if (config['rollout_fraction'] != null) ...['--rollout-fraction', '${config['rollout_fraction']}'],
        if (config['in_app_update_priority'] != null) ...['--in-app-update-priority', '${config['in_app_update_priority']}'],
        if (config['changes_not_sent_for_review'] == true) '--changes-not-sent-for-review',
      ], env);
      await log('Rolled out to $track', stepId: stepId);
      return;
    }

    final config = (publishing['app_store_connect'] as Map?)?.cast<String, dynamic>();
    if (config == null) {
      await log('No app_store_connect section under publishing; artifacts kept, nothing uploaded', stepId: stepId, level: 'warning');
      return;
    }
    final ipa = artifacts.firstWhere(
      (a) => a.endsWith('.ipa'),
      orElse: () => throw StepFailed('No .ipa among the artifacts'),
    );
    final keyId = env['AR_ASC_KEY_ID'];
    final issuer = env['AR_ASC_ISSUER_ID'];
    if (keyId == null || issuer == null) throw StepFailed('App Store Connect key is not loaded');

    await log('Uploading ${ipa.split('/').last} to App Store Connect', stepId: stepId);
    await _exec('xcrun', [
      'altool', '--upload-app', '-f', ipa, '--type', 'ios',
      '--apiKey', keyId, '--apiIssuer', issuer,
    ], env);

    final groups = [for (final g in (config['beta_groups'] as List?) ?? const []) '$g'];
    final submitTestflight = config['submit_to_testflight'] == true || track == 'testflight';
    final submitAppStore = config['submit_to_app_store'] == true || track == 'appStore';
    if (submitTestflight || submitAppStore) {
      await log('Waiting for App Store Connect to process the build…', stepId: stepId);
      await _exec('app-store-connect', [
        'publish',
        '--path', ipa,
        '--issuer-id', issuer,
        '--key-id', keyId,
        '--private-key', '@file:${env['AR_ASC_KEY_PATH']}',
        '--skip-package-upload',
        if (submitTestflight) '--testflight',
        for (final g in groups) ...['--beta-group', g],
        if (config['expire_previous_builds'] == true) '--expire-build-submitted-for-review',
        if (submitAppStore) '--app-store',
        if (submitAppStore && config['release_type'] != null) ...['--release-type', '${config['release_type']}'],
      ], env);
    }
    await log(submitAppStore ? 'Submitted for App Store review' : 'Build is on TestFlight${groups.isEmpty ? '' : ' · ${groups.join(', ')}'}', stepId: stepId);
  }

  Future<void> _exec(String executable, List<String> args, Map<String, String> env) async {
    await log('\$ $executable ${args.join(' ')}', stepId: stepId, level: 'command');
    final Process process;
    try {
      process = await Process.start(executable, args, environment: {...Platform.environment, ...env});
    } on ProcessException {
      throw StepFailed('$executable is not installed on this runner (pip install codemagic-cli-tools)');
    }
    await for (final line in process.stdout.transform(const SystemEncoding().decoder)) {
      for (final l in line.trimRight().split('\n')) {
        if (l.isNotEmpty) await log(l, stepId: stepId);
      }
    }
    await for (final line in process.stderr.transform(const SystemEncoding().decoder)) {
      for (final l in line.trimRight().split('\n')) {
        if (l.isNotEmpty) await log(l, stepId: stepId, level: 'warning');
      }
    }
    final code = await process.exitCode;
    if (code != 0) throw StepFailed('$executable exited with code $code');
  }
}
