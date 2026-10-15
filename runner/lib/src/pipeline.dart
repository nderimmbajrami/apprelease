import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'api.dart';
import 'config.dart';
import 'steps/checkout.dart';
import 'steps/publish.dart';
import 'steps/signing.dart';
import 'steps/versioning.dart';

/// Streams a release's log to Supabase, with secrets masked.
class LogSink {
  LogSink(this._api, this._releaseId);

  final SupabaseApi _api;
  final String _releaseId;
  final _secrets = <String>[];
  var _seq = 0;

  /// Anything added here is replaced by *** in every line that follows.
  void mask(String value) {
    if (value.length >= 4) _secrets.add(value);
  }

  Future<void> call(String text, {String? stepId, String level = 'info'}) {
    var safe = text;
    for (final secret in _secrets) {
      safe = safe.replaceAll(secret, '***');
    }
    stdout.writeln('[${level.padRight(7)}] $safe');
    return _api.appendLog(
      releaseId: _releaseId,
      seq: _seq++,
      text: safe,
      stepId: stepId,
      level: level,
    );
  }
}

class StepFailed implements Exception {
  StepFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

class Cancelled implements Exception {}

/// Runs one release from checkout to publish, reporting every step.
class Pipeline {
  Pipeline({
    required this.api,
    required this.release,
    required this.app,
    required this.secretsKey,
    required this.workspace,
  }) : log = LogSink(api, release['id'] as String);

  final SupabaseApi api;
  final Map<String, dynamic> release;
  final Map<String, dynamic> app;
  final String secretsKey;
  final Directory workspace;
  final LogSink log;

  String get releaseId => release['id'] as String;
  String get platform => release['platform'] as String;
  late final List<Map<String, dynamic>> steps = [
    for (final s in (release['release_steps'] as List? ?? const []))
      (s as Map).cast<String, dynamic>(),
  ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  /// Environment handed to every script. Grows as steps add to it.
  final env = <String, String>{'CI': 'true'};
  late Directory buildDir;
  late WorkflowConfig workflow;
  final artifacts = <String>[];

  Future<void> run() async {
    final started = DateTime.now();
    if (steps.length < 7) {
      await api.updateRelease(releaseId, {
        'status': 'failed',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'error_message': 'Release has ${steps.length} steps, expected 7',
      });
      await log(
        'Release has ${steps.length} steps, expected 7',
        level: 'error',
      );
      return;
    }
    await log(
      'Runner claimed release #${release['number']} · ${app['name']} · $platform',
    );
    try {
      await _step(0, _checkout);
      await _step(1, _toolchain);
      await _step(2, _packages);
      if (platform == 'android') {
        await _step(3, _versioning);
        await _step(4, _buildScripts);
        await _step(5, _androidSigningCheck);
        await _step(6, _publish);
      } else {
        await _step(3, _iosSigning);
        await _step(4, _versioning);
        await _step(5, _buildScripts);
        await _step(6, _publish);
      }
      await api.updateRelease(releaseId, {
        'status': 'succeeded',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'artifacts': [for (final a in artifacts) p.basename(a)],
      });
      await log(
        'Released ${release['version_name']} (${env['AR_BUILD_NUMBER']}) · ${DateTime.now().difference(started).inSeconds}s',
        level: 'success',
      );
    } on Cancelled {
      await _skipRemaining();
      await api.updateRelease(releaseId, {
        'status': 'cancelled',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
      });
      await log('Cancelled by user', level: 'warning');
    } catch (error) {
      await _skipRemaining();
      await api.updateRelease(releaseId, {
        'status': 'failed',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'error_message': '$error'.split('\n').first,
      });
      await log('$error', level: 'error');
    } finally {
      // Whatever happened, the keys do not stay on disk.
      await SigningFiles.cleanUp(env);
    }
  }

  // ------------------------------------------------------------------ steps

  Future<void> _step(
    int index,
    Future<void> Function(String stepId) body,
  ) async {
    if (await api.cancelRequested(releaseId)) throw Cancelled();
    final step = steps[index];
    final id = step['id'] as String;
    await api.updateStep(id, {
      'status': 'running',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });
    try {
      await body(id);
      await api.updateStep(id, {
        'status': 'succeeded',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      await api.updateStep(id, {
        'status': 'failed',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<void> _skipRemaining() async {
    for (final step in steps) {
      if (step['status'] == 'pending' || step['status'] == 'running') {
        await api.updateStep(step['id'] as String, {'status': 'skipped'});
      }
    }
  }

  Future<void> _checkout(String stepId) async {
    buildDir = await Checkout(log: log, stepId: stepId).run(
      workspace: workspace,
      repoUrl: app['repo_url'] as String,
      branch: release['branch'] as String,
      releaseId: releaseId,
    );
    env['AR_BUILD_DIR'] = buildDir.path;
    env['AR_BUILD_ID'] = releaseId;
    env['AR_BRANCH'] = release['branch'] as String;
    final commit = await Checkout.commit(buildDir);
    env['AR_COMMIT'] = commit;
    env['AR_COMMIT_SHORT'] = commit.substring(0, 7);
    await api.updateRelease(releaseId, {'commit': commit.substring(0, 7)});

    final file = File(p.join(buildDir.path, 'apprelease.yaml'));
    if (!file.existsSync()) {
      throw StepFailed('apprelease.yaml not found in the repository root');
    }
    final selected = WorkflowConfig.select(
      file.readAsStringSync(),
      platform: platform,
      track: release['track'] as String,
    );
    if (selected == null) throw StepFailed('apprelease.yaml has no workflows');
    workflow = selected;
    env['AR_WORKFLOW'] = workflow.id;
    env.addAll(workflow.vars);
    await log(
      'apprelease.yaml found · workflow ${workflow.id}',
      stepId: stepId,
    );
  }

  Future<void> _toolchain(String stepId) async {
    if (workflow.flutter != 'stable' && workflow.flutter != 'fvm') {
      await log(
        'flutter version ${workflow.flutter} requested; using the installed one',
        stepId: stepId,
        level: 'warning',
      );
    }
    final version = await exec(
      'flutter',
      ['--version', '--machine'],
      stepId: stepId,
      quiet: true,
    );
    final parsed = jsonDecode(version) as Map;
    env['AR_FLUTTER_VERSION'] = '${parsed['frameworkVersion']}';
    await log(
      'Flutter ${parsed['frameworkVersion']} · ${parsed['channel']} · Dart ${parsed['dartSdkVersion']}',
      stepId: stepId,
    );
    if (platform == 'ios') {
      final xcode = await exec(
        'xcodebuild',
        ['-version'],
        stepId: stepId,
        quiet: true,
      );
      await log(xcode.trim().replaceAll('\n', ' · '), stepId: stepId);
    }
  }

  Future<void> _packages(String stepId) =>
      exec('flutter', ['pub', 'get'], stepId: stepId);

  Future<void> _versioning(String stepId) async {
    final next =
        await Versioning(
          api: api,
          log: log,
          stepId: stepId,
          secretsKey: secretsKey,
        ).next(
          source: workflow.versioningSource,
          release: release,
          app: app,
          workflow: workflow,
          env: env,
        );
    env['AR_BUILD_NUMBER'] = '$next';
    await api.updateRelease(releaseId, {'build_number': next});
    await log('AR_BUILD_NUMBER=$next', stepId: stepId, level: 'command');
  }

  Future<void> _iosSigning(String stepId) async {
    await SigningFiles(
      api: api,
      log: log,
      stepId: stepId,
      secretsKey: secretsKey,
    ).prepareIos(release: release, workflow: workflow, env: env);
  }

  Future<void> _androidSigningCheck(String stepId) async {
    // The keystore was materialised before the build scripts ran (Gradle
    // needs it); this step only verifies the bundle is signed.
    for (final artifact in artifacts.where(
      (a) => a.endsWith('.aab') || a.endsWith('.apk'),
    )) {
      await exec('jarsigner', ['-verify', artifact], stepId: stepId);
    }
  }

  Future<void> _buildScripts(String stepId) async {
    if (platform == 'android') {
      await SigningFiles(
        api: api,
        log: log,
        stepId: stepId,
        secretsKey: secretsKey,
      ).prepareAndroid(release: release, workflow: workflow, env: env);
    }
    await SigningFiles(
      api: api,
      log: log,
      stepId: stepId,
      secretsKey: secretsKey,
    ).loadGroups(release: release, workflow: workflow, env: env);

    for (final script in workflow.scripts) {
      await log('▶ ${script.name}', stepId: stepId, level: 'command');
      await exec('bash', [
        '-e',
        '-o',
        'pipefail',
        '-c',
        script.script,
      ], stepId: stepId);
      if (await api.cancelRequested(releaseId)) throw Cancelled();
    }
    artifacts.addAll(await collectArtifacts(buildDir, workflow.artifacts));
    for (final artifact in artifacts) {
      await log(
        'artifact ${p.relative(artifact, from: buildDir.path)}',
        stepId: stepId,
      );
    }
    if (artifacts.isEmpty) {
      throw StepFailed('No artifacts matched ${workflow.artifacts}');
    }
  }

  Future<void> _publish(String stepId) async {
    await Publish(
      api: api,
      log: log,
      stepId: stepId,
      secretsKey: secretsKey,
    ).run(release: release, workflow: workflow, env: env, artifacts: artifacts);
  }

  // ------------------------------------------------------------------ shell

  /// Runs a command in the build directory, streaming its output to the log.
  Future<String> exec(
    String executable,
    List<String> arguments, {
    required String stepId,
    bool quiet = false,
  }) async {
    if (!quiet) {
      await log(
        '\$ $executable ${arguments.join(' ')}',
        stepId: stepId,
        level: 'command',
      );
    }
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: buildDir.path,
      environment: {...Platform.environment, ...env},
    );
    final out = StringBuffer();
    Future<void> pipe(Stream<List<int>> stream, String level) => stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) async {
          out.writeln(line);
          if (!quiet) await log(line, stepId: stepId, level: level);
        });
    await Future.wait([
      pipe(process.stdout, 'info'),
      pipe(process.stderr, 'warning'),
    ]);
    final code = await process.exitCode;
    if (code != 0) throw StepFailed('$executable exited with code $code');
    return out.toString();
  }
}

/// Expands glob-ish patterns (`build/**/outputs/**/*.aab`) under [root].
Future<List<String>> collectArtifacts(
  Directory root,
  List<String> patterns,
) async {
  final found = <String>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: root.path);
    for (final pattern in patterns) {
      if (_globToRegExp(pattern).hasMatch(relative)) {
        found.add(entity.path);
        break;
      }
    }
  }
  return found;
}

/// Exposed for the tests.
RegExp globToRegExpForTest(String glob) => _globToRegExp(glob);

RegExp _globToRegExp(String glob) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (c == '*') {
      if (i + 1 < glob.length && glob[i + 1] == '*') {
        buffer.write('.*');
        i++;
        if (i + 1 < glob.length && glob[i + 1] == '/') i++;
      } else {
        buffer.write('[^/]*');
      }
    } else if (c == '?') {
      buffer.write('[^/]');
    } else {
      buffer.write(RegExp.escape(c));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}
