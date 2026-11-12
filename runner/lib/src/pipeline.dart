import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'api.dart';
import 'config.dart';
import 'steps/checkout.dart';
import 'steps/ios_version.dart';
import 'steps/preview.dart';
import 'steps/publish.dart';
import 'steps/qa.dart';
import 'steps/signing.dart';
import 'steps/versioning.dart';
import 'stores/app_store_connect.dart';

/// Streams a release's log to Supabase, with secrets masked. Lines are sent
/// in batches a few times a second: one request per line made `pub get`
/// crawl and flooded the console with one event per line.
class LogSink {
  LogSink(this._api, this._releaseId);

  final SupabaseApi _api;
  final String _releaseId;
  final _secrets = <String>[];
  final _pending = <Map<String, dynamic>>[];
  Timer? _timer;
  Future<void>? _inFlight;
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
    _pending.add({
      'release_id': _releaseId,
      'seq': _seq++,
      'step_id': stepId,
      'level': level,
      'text': safe,
    });
    if (_pending.length >= 50) {
      unawaited(flush());
    } else {
      _timer ??= Timer(
        const Duration(milliseconds: 250),
        () => unawaited(flush()),
      );
    }
    return Future.value();
  }

  /// Sends what is waiting, in order: one batch in flight at a time.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    while (_pending.isNotEmpty) {
      if (_inFlight != null) {
        await _inFlight;
        continue;
      }
      final batch = List.of(_pending);
      _pending.clear();
      _inFlight = _api.appendLogs(batch).catchError((Object error) {
        stderr.writeln('log write failed: $error');
      });
      await _inFlight;
      _inFlight = null;
    }
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
    this.preview,
  }) : log = LogSink(api, release['id'] as String);

  final SupabaseApi api;
  final Map<String, dynamic> release;
  final Map<String, dynamic> app;
  final String secretsKey;
  final Directory workspace;
  final LogSink log;

  /// Where previews are published; null on a machine not set up for them.
  final PreviewSettings? preview;

  String get releaseId => release['id'] as String;
  String get platform => release['platform'] as String;
  late final List<Map<String, dynamic>> steps = [
    for (final s in (release['release_steps'] as List? ?? const []))
      (s as Map).cast<String, dynamic>(),
  ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  /// Environment handed to every script. Grows as steps add to it.
  final env = <String, String>{
    'CI': 'true',
    // One fresh Gradle per build. The shared daemon survived from build to
    // build and crashed its JVM every few runs on the Mac; a cold start
    // costs seconds, a crash costs the release.
    'GRADLE_OPTS': '-Dorg.gradle.daemon=false',
  };

  /// Steps that reached a final state, so a failure later does not mark
  /// them as skipped.
  final _finished = <String>{};
  late Directory buildDir;
  late WorkflowConfig workflow;
  final artifacts = <String>[];

  Future<void> run() async {
    final started = DateTime.now();
    // A QA build ends with "Send to QA": on Android in place of the upload
    // to Google Play, on iOS after the upload to TestFlight.
    final qa = isQaTrack(release['track']);
    final isPreview = isPreviewTrack(release['track']);
    final expected = isPreview
        ? 6
        : qa && platform == 'ios'
        ? 8
        : 7;
    if (steps.length < expected) {
      await api.updateRelease(releaseId, {
        'status': 'failed',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'error_message':
            'Release has ${steps.length} steps, expected $expected',
      });
      await log(
        'Release has ${steps.length} steps, expected $expected',
        level: 'error',
      );
      return;
    }
    await log(
      'Runner claimed release #${release['number']} · ${app['name']} · $platform',
    );
    try {
      if (isPreview) {
        await _step(0, _previewUnpack);
        await _step(1, _toolchain);
        await _step(2, _packages);
        await _step(3, _previewAndroid);
        await _step(4, _previewWeb);
        await _step(5, _previewPublish);
      } else {
        await _step(0, _checkout);
        await _step(1, _toolchain);
        await _step(2, _packages);
        if (platform == 'android') {
          await _step(3, _versioning);
          await _step(4, _buildScripts);
          await _step(5, _androidSigningCheck);
          await _step(6, qa ? _sendToQa : _publish);
        } else {
          await _step(3, _iosSigning);
          await _step(4, _versioning);
          await _step(5, _buildScripts);
          await _step(6, _publish);
          if (qa) await _step(7, _sendToQa);
        }
      }
      await api.updateRelease(releaseId, {
        'status': 'succeeded',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'artifacts': [for (final a in artifacts) p.basename(a)],
      });
      await log(
        isPreview
            ? 'Preview of ${release['version_name']} is ready · ${DateTime.now().difference(started).inSeconds}s'
            : '${qa ? 'Sent to QA:' : 'Released'} ${release['version_name']} (${env['AR_BUILD_NUMBER']}) · ${DateTime.now().difference(started).inSeconds}s',
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
      await log.flush();
      // Whatever happened, neither the keys nor the source stay on disk.
      await SigningFiles.cleanUp(env);
      // Nor does an uploaded zip stay in storage: built or not, the next
      // build starts with a new upload.
      final source = '${app['source_zip'] ?? ''}';
      if (isPreview && source.isNotEmpty) {
        try {
          await api.deleteSource(source);
        } catch (error) {
          stderr.writeln('could not remove the uploaded zip: $error');
        }
      }
      try {
        final dir = Directory(p.join(workspace.path, releaseId));
        await _keepCrashLogs(dir);
        if (dir.existsSync()) await dir.delete(recursive: true);
      } catch (error) {
        stderr.writeln('could not remove checkout: $error');
      }
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
      _finished.add(id);
      await api.updateStep(id, {
        'status': 'succeeded',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      _finished.add(id);
      await api.updateStep(id, {
        'status': 'failed',
        'finished_at': DateTime.now().toUtc().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<void> _skipRemaining() async {
    for (final step in steps) {
      final id = step['id'] as String;
      if (!_finished.contains(id)) {
        await api.updateStep(id, {'status': 'skipped'});
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
    _commitMessage = await Checkout.message(buildDir);
    await _writeBuildFiles(stepId);
    await _readVersion(stepId);
    if (env['AR_BRANCH']!.startsWith('v') &&
        RegExp(r'^v?\d+\.\d+\.\d+').hasMatch(env['AR_BRANCH']!)) {
      env['AR_TAG'] = env['AR_BRANCH']!;
    }

    // apprelease.yaml is for teams that want to change the build. Without
    // it, the settings from the console are the workflow: most customers
    // never need the file.
    final file = File(p.join(buildDir.path, 'apprelease.yaml'));
    final track = release['track'] as String;
    if (file.existsSync()) {
      final selected = WorkflowConfig.select(
        file.readAsStringSync(),
        platform: platform,
        track: track,
      );
      if (selected == null && track == 'qa') {
        workflow = WorkflowConfig.defaults(
          platform: platform,
          track: track,
          app: app,
          credentials: await api.credentials(release['team_id'] as String),
        );
        await log(
          'apprelease.yaml has no android-qa workflow: building the QA APK '
          'with the settings from the console',
          stepId: stepId,
        );
      } else if (selected == null) {
        throw StepFailed(
          'apprelease.yaml has no workflows. Remove the file to build with '
          'the settings from the console, or add a workflow to it.',
        );
      }
      if (selected != null) {
        workflow = selected;
        await log(
          'apprelease.yaml found · workflow ${workflow.id}',
          stepId: stepId,
        );
      }
    } else {
      workflow = WorkflowConfig.defaults(
        platform: platform,
        track: track,
        app: app,
        credentials: await api.credentials(release['team_id'] as String),
      );
      await log(
        'No apprelease.yaml in the repository: building with the settings '
        'from the console (${workflow.name} → $track)',
        stepId: stepId,
      );
    }
    env['AR_WORKFLOW'] = workflow.id;
    env.addAll(workflow.vars);
  }

  /// A pushed release or a preview has no version yet; pubspec.yaml knows
  /// it.
  Future<void> _readVersion(String stepId) async {
    if (release['version_name'] != 'auto') return;
    final pubspec = File(p.join(buildDir.path, 'pubspec.yaml'));
    final match = pubspec.existsSync()
        ? RegExp(
            r'^version:\s*(\d+\.\d+\.\d+)',
            multiLine: true,
          ).firstMatch(pubspec.readAsStringSync())
        : null;
    final version = match?.group(1) ?? '0.0.0';
    release['version_name'] = version;
    await api.updateRelease(releaseId, {'version_name': version});
    await log('Version $version from pubspec.yaml', stepId: stepId);
  }

  // ---------------------------------------------------------------- preview

  late final Preview _preview = Preview(
    api: api,
    log: log,
    settings: preview!,
    exec: exec,
  );
  File? _previewApk;
  Directory? _previewWebDir;

  /// The uploaded zip, or the repository of an app that has one: either
  /// can be previewed.
  Future<void> _previewUnpack(String stepId) async {
    if (preview == null) {
      throw StepFailed(
        'This build machine is not set up for previews: PREVIEW_DIR and '
        'PREVIEW_BASE_URL are missing from its settings.',
      );
    }
    final source = '${app['source_zip'] ?? ''}';
    if (source.isNotEmpty) {
      buildDir = await _preview.unpack(
        sourcePath: source,
        into: Directory(p.join(workspace.path, releaseId)),
        stepId: stepId,
      );
    } else {
      buildDir = await Checkout(log: log, stepId: stepId).run(
        workspace: workspace,
        repoUrl: app['repo_url'] as String,
        branch: release['branch'] as String,
        releaseId: releaseId,
      );
    }
    env['AR_BUILD_DIR'] = buildDir.path;
    env['AR_BUILD_ID'] = releaseId;
    await _writeBuildFiles(stepId);
    await _readVersion(stepId);
  }

  Future<void> _previewAndroid(String stepId) async {
    _previewApk = await _preview.buildAndroid(buildDir, stepId);
  }

  Future<void> _previewWeb(String stepId) async {
    _previewWebDir = await _preview.buildWeb(buildDir, releaseId, stepId);
  }

  Future<void> _previewPublish(String stepId) async {
    artifacts.addAll(
      await _preview.publish(
        releaseId: releaseId,
        appName: '${app['name']}',
        apk: _previewApk!,
        web: _previewWebDir,
        stepId: stepId,
      ),
    );
  }

  /// Files the build needs that the repository leaves out
  /// (google-services.json, .env): kept encrypted under Credentials and
  /// written into the checkout here. They go when the checkout goes.
  Future<void> _writeBuildFiles(String stepId) async {
    final all = await api.credentials(release['team_id'] as String);
    for (final c in all) {
      if (c['kind'] != 'buildFile') continue;
      if (c['app_id'] != null && c['app_id'] != app['id']) continue;
      final meta = (c['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
      final path = '${meta['path'] ?? ''}'.trim();
      if (path.isEmpty || path.startsWith('/') || path.contains('..')) {
        await log(
          'Build file "${c['name']}": path "$path" is not inside the repository; skipped',
          stepId: stepId,
          level: 'warning',
        );
        continue;
      }
      final secret = await api.readSecret(c['id'] as String, secretsKey);
      final bytes = secret.fileBytes;
      if (bytes == null) continue;
      final file = File(p.join(buildDir.path, path));
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      await log(
        'Wrote $path (${bytes.length} bytes) from Credentials',
        stepId: stepId,
      );
    }
  }

  Future<void> _toolchain(String stepId) async {
    // A preview has no workflow: it builds with the installed Flutter.
    final isPreview = isPreviewTrack(release['track']);
    if (!isPreview &&
        workflow.flutter != 'stable' &&
        workflow.flutter != 'fvm') {
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
    // The store credentials have to be in place before the store is asked.
    await _loadSecrets(stepId);
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
    if (platform == 'ios') await _writeXcodeVersion(stepId, next);
    await _writeVersion(stepId, release['version_name'] as String, next);
  }

  /// A project with its version typed into Xcode builds that version, not
  /// the one in pubspec.yaml: a release moved past an approved version
  /// would still upload the approved one and be refused. The fixed number
  /// is treated like the project's own version (never lowered) and then
  /// set to what is being released.
  Future<void> _writeXcodeVersion(String stepId, int build) async {
    final pbxproj = File(
      p.join(buildDir.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    final plist = File(p.join(buildDir.path, 'ios', 'Runner', 'Info.plist'));
    final pbxText = pbxproj.existsSync() ? pbxproj.readAsStringSync() : null;
    final plistText = plist.existsSync() ? plist.readAsStringSync() : null;
    final fixed = xcodeFixedVersion(pbxproj: pbxText, plist: plistText);
    if (fixed == null) return;

    var version = release['version_name'] as String;
    if (compareVersions(fixed, version) > 0) {
      await log(
        'The Xcode project has version $fixed, above $version; releasing '
        'as $fixed',
        stepId: stepId,
      );
      version = fixed;
      release['version_name'] = fixed;
      await api.updateRelease(releaseId, {'version_name': fixed});
    }
    if (pbxText != null) {
      pbxproj.writeAsStringSync(setPbxprojVersion(pbxText, version, build));
    }
    if (plistText != null) {
      plist.writeAsStringSync(setPlistVersion(plistText, version, build));
    }
    await log(
      'The version is fixed in the Xcode project ($fixed) instead of coming '
      'from pubspec.yaml; set to $version ($build) for this build',
      stepId: stepId,
    );
  }

  /// `flutter build` takes the version from pubspec.yaml; the release's own
  /// version (typed in the console, or moved past an approved one) has to
  /// be written there to reach the store.
  Future<void> _writeVersion(String stepId, String version, int build) async {
    final pubspec = File(p.join(env['AR_BUILD_DIR']!, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return;
    final text = pubspec.readAsStringSync();
    final line = RegExp(r'^version:.*$', multiLine: true);
    // Never lower it: a version typed in the console that is behind the
    // project's own gives way to the project's.
    final own = RegExp(
      r'^version:\s*(\d+(?:\.\d+)*)',
      multiLine: true,
    ).firstMatch(text)?.group(1);
    if (own != null && compareVersions(own, version) > 0) {
      await log(
        'pubspec.yaml already has $own, above $version; releasing as $own',
        stepId: stepId,
      );
      version = own;
      release['version_name'] = own;
      await api.updateRelease(releaseId, {'version_name': own});
    }
    final updated = setPubspecVersion(text, version, build);
    if (updated == text) return;
    pubspec.writeAsStringSync(updated);
    await log(
      'pubspec.yaml: ${line.firstMatch(text)?.group(0) ?? 'no version'} → version: $version+$build',
      stepId: stepId,
    );
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

  /// Keystore and variable groups, materialised once per release.
  var _secretsLoaded = false;

  Future<void> _loadSecrets(String stepId) async {
    if (_secretsLoaded) return;
    _secretsLoaded = true;
    final files = SigningFiles(
      api: api,
      log: log,
      stepId: stepId,
      secretsKey: secretsKey,
    );
    if (platform == 'android') {
      await files.prepareAndroid(
        release: release,
        workflow: workflow,
        env: env,
      );
    }
    await files.loadGroups(release: release, workflow: workflow, env: env);
  }

  Future<void> _buildScripts(String stepId) async {
    await _loadSecrets(stepId);

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

  /// The last commit's message, read at checkout: a QA build takes the
  /// ticket keys from it.
  var _commitMessage = '';

  Future<void> _sendToQa(String stepId) async {
    await SendToQa(
      api: api,
      log: log,
      stepId: stepId,
      secretsKey: secretsKey,
    ).run(
      release: release,
      app: app,
      env: env,
      artifacts: artifacts,
      commitMessage: _commitMessage,
    );
  }

  /// A JVM crash leaves an hs_err file in the checkout; its head is worth
  /// more in the release log than in a directory about to be deleted.
  Future<void> _keepCrashLogs(Directory dir) async {
    if (!dir.existsSync()) return;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File ||
          !p.basename(entity.path).startsWith('hs_err_pid')) {
        continue;
      }
      final head = (await entity.readAsLines()).take(40).join('\n');
      await log(
        'JVM crash log ${p.basename(entity.path)}:\n$head',
        level: 'warning',
      );
    }
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
    var lastOutput = DateTime.now();
    Future<void> pipe(Stream<List<int>> stream, String level) => stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) async {
          out.writeln(line);
          lastOutput = DateTime.now();
          if (!quiet) await log(line, stepId: stepId, level: level);
        });
    // Gradle and Xcode say nothing for minutes while they compile. A line a
    // minute tells the reader the build is alive, not stuck.
    final ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      final silent = DateTime.now().difference(lastOutput);
      if (!quiet && silent >= const Duration(seconds: 55)) {
        unawaited(
          log(
            '… still running, no output for ${silent.inMinutes} min',
            stepId: stepId,
          ),
        );
      }
    });
    try {
      await Future.wait([
        pipe(process.stdout, 'info'),
        pipe(process.stderr, 'warning'),
      ]);
    } finally {
      ticker.cancel();
    }
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

/// [pubspec] with its `version:` line set to `[version]+[build]`, added
/// when missing.
String setPubspecVersion(String pubspec, String version, int build) {
  final line = RegExp(r'^version:.*$', multiLine: true);
  final value = 'version: $version+$build';
  if (line.hasMatch(pubspec)) return pubspec.replaceFirst(line, value);
  return '$value\n$pubspec';
}
