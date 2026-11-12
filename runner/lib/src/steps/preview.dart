import 'dart:io';

import 'package:path/path.dart' as p;

import '../api.dart';
import '../pipeline.dart';

/// The track of a preview: an uploaded project built into an Android APK
/// and a web version, published as two links. Nothing goes to a store.
const previewTrack = 'preview';

bool isPreviewTrack(Object? track) => track == previewTrack;

/// Where previews are published. The runner writes them into [dir]; that
/// folder is reachable from the internet at [baseUrl], however it is
/// served: `bin/serve_previews.dart` behind a tunnel, or a web host the
/// folder is synced to.
class PreviewSettings {
  PreviewSettings({required this.dir, required Uri baseUrl, this.keepDays = 7})
    : baseUrl = baseUrl.path.endsWith('/')
          ? baseUrl
          : baseUrl.replace(path: '${baseUrl.path}/');

  final Directory dir;

  /// Always ends with a slash.
  final Uri baseUrl;

  /// Previews older than this are deleted when the next one is published.
  final int keepDays;

  /// From `PREVIEW_DIR`, `PREVIEW_BASE_URL` and `PREVIEW_KEEP_DAYS`; null
  /// when the machine is not set up for previews.
  static PreviewSettings? fromEnv(Map<String, String> env) {
    final dir = env['PREVIEW_DIR'] ?? '';
    final url = Uri.tryParse(env['PREVIEW_BASE_URL'] ?? '');
    if (dir.isEmpty || url == null || !url.hasScheme || url.host.isEmpty) {
      return null;
    }
    return PreviewSettings(
      dir: Directory(dir).absolute,
      baseUrl: url,
      keepDays: int.tryParse(env['PREVIEW_KEEP_DAYS'] ?? '') ?? 7,
    );
  }

  /// The public address of one release's folder, with a trailing slash.
  Uri urlFor(String releaseId) =>
      baseUrl.replace(path: '${baseUrl.path}$releaseId/');
}

/// The folder that holds the Flutter project inside an unpacked zip: the
/// shallowest one with a pubspec.yaml, at most [maxDepth] folders down.
/// People zip the project folder itself, its parent, or its contents.
Directory? findProjectRoot(Directory dir, {int maxDepth = 3}) {
  var level = [dir];
  for (var depth = 0; depth <= maxDepth && level.isNotEmpty; depth++) {
    level.sort((a, b) => a.path.compareTo(b.path));
    for (final candidate in level) {
      if (File(p.join(candidate.path, 'pubspec.yaml')).existsSync()) {
        return candidate;
      }
    }
    level = [
      for (final parent in level)
        for (final child in parent.listSync(followLinks: false))
          if (child is Directory && !_skipped.contains(p.basename(child.path)))
            if (!p.basename(child.path).startsWith('.')) child,
    ];
  }
  return null;
}

const _skipped = {'__MACOSX', 'build', 'node_modules', 'ios', 'android'};

/// `name:` out of a pubspec, for `flutter create`, which otherwise takes
/// the folder's name and refuses one like "My App".
String? pubspecName(String pubspec) => RegExp(
  r'^name:\s*([a-z_][a-z0-9_]*)',
  multiLine: true,
).firstMatch(pubspec)?.group(1);

/// A file name for the APK that is safe in a link: "My Shop!" → "my-shop".
String previewSlug(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'app' : slug;
}

/// Whether the Android project signs its release build with a key that is
/// not in the upload: the usual `key.properties` set-up, without the file.
/// Such a project cannot build a release APK here; a debug one installs.
bool releaseSigningMissing(Directory project) {
  if (File(p.join(project.path, 'android', 'key.properties')).existsSync()) {
    return false;
  }
  for (final name in const ['build.gradle', 'build.gradle.kts']) {
    final gradle = File(p.join(project.path, 'android', 'app', name));
    if (gradle.existsSync() &&
        gradle.readAsStringSync().contains('key.properties')) {
      return true;
    }
  }
  return false;
}

/// The steps of a preview that are not shared with a release.
class Preview {
  Preview({
    required this.api,
    required this.log,
    required this.settings,
    required this.exec,
  });

  final SupabaseApi api;
  final LogSink log;
  final PreviewSettings settings;

  /// Runs a command in the project folder (the pipeline's own `exec`).
  final Future<String> Function(
    String executable,
    List<String> arguments, {
    required String stepId,
  })
  exec;

  /// Downloads the uploaded zip and unpacks it under [into]. Returns the
  /// project folder inside.
  Future<Directory> unpack({
    required String sourcePath,
    required Directory into,
    required String stepId,
  }) async {
    if (into.existsSync()) into.deleteSync(recursive: true);
    into.createSync(recursive: true);
    final zip = File(p.join(into.path, 'source.zip'));
    final int size;
    try {
      size = await api.downloadSource(sourcePath, zip);
    } on ApiException {
      // A zip is removed once its build is over.
      throw StepFailed(
        'The uploaded zip is no longer stored. Upload the project again '
        'to build it.',
      );
    }
    await log(
      'Downloaded the project (${(size / 1048576).toStringAsFixed(1)} MB)',
      stepId: stepId,
    );
    final src = Directory(p.join(into.path, 'src'))..createSync();
    final result = await Process.run('unzip', [
      '-q',
      '-o',
      zip.path,
      '-d',
      src.path,
    ]);
    zip.deleteSync();
    // unzip ends with 1 for warnings (odd file names); the files are there.
    if (result.exitCode > 1) {
      throw StepFailed(
        'The uploaded file could not be opened as a zip. Compress the '
        'project folder again and upload it once more.',
      );
    }
    final root = findProjectRoot(src);
    if (root == null) {
      throw StepFailed(
        'No Flutter project in the zip: there is no pubspec.yaml. Zip the '
        'folder that contains pubspec.yaml and upload that.',
      );
    }
    // What the author's own computer built is stale here, and large.
    for (final stale in const ['build', '.dart_tool']) {
      final dir = Directory(p.join(root.path, stale));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
    await log(
      'Project found in ${p.relative(root.path, from: src.path)}'.replaceAll(
        ' in .',
        ' at the top of the zip',
      ),
      stepId: stepId,
    );
    return root;
  }

  /// Builds the APK and returns it.
  Future<File> buildAndroid(Directory project, String stepId) async {
    await _ensurePlatform(project, 'android', stepId);
    final debug = releaseSigningMissing(project);
    if (debug) {
      await log(
        'The project signs its release build with a key that is not in the '
        'upload (android/key.properties). Building a debug app: it '
        'installs and runs, a little slower than the real one.',
        stepId: stepId,
        level: 'warning',
      );
    }
    final mode = debug ? 'debug' : 'release';
    await exec('flutter', ['build', 'apk', '--$mode'], stepId: stepId);
    final apk = File(
      p.join(
        project.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-$mode.apk',
      ),
    );
    if (!apk.existsSync()) {
      throw StepFailed('The build finished without an APK.');
    }
    return apk;
  }

  /// Builds the web version for the address it will be served from.
  /// Returns its folder, or null when the project cannot run in a browser:
  /// the Android app is still worth handing over.
  Future<Directory?> buildWeb(
    Directory project,
    String releaseId,
    String stepId,
  ) async {
    try {
      await _ensurePlatform(project, 'web', stepId);
      await exec('flutter', [
        'build',
        'web',
        '--release',
        '--base-href',
        '${settings.urlFor(releaseId).path}web/',
      ], stepId: stepId);
    } on StepFailed catch (error) {
      await log(
        'The web version could not be built ($error), so there is no '
        'iPhone link this time. A project that uses a plugin without web '
        'support is the usual reason. The Android app is not affected.',
        stepId: stepId,
        level: 'warning',
      );
      return null;
    }
    final out = Directory(p.join(project.path, 'build', 'web'));
    return out.existsSync() ? out : null;
  }

  /// Copies what was built to the published folder and returns the paths
  /// there: the APK, and the web folder when there is one.
  Future<List<String>> publish({
    required String releaseId,
    required String appName,
    required File apk,
    required Directory? web,
    required String stepId,
  }) async {
    _removeOld();
    final target = Directory(p.join(settings.dir.path, releaseId));
    if (target.existsSync()) target.deleteSync(recursive: true);
    target.createSync(recursive: true);

    final published = <String>[];
    final apkTarget = p.join(target.path, '${previewSlug(appName)}.apk');
    apk.copySync(apkTarget);
    published.add(apkTarget);
    final url = settings.urlFor(releaseId);
    await log(
      'Android app: $url${p.basename(apkTarget)}',
      stepId: stepId,
      level: 'success',
    );
    if (web != null) {
      final webTarget = Directory(p.join(target.path, 'web'));
      _copy(web, webTarget);
      published.add(webTarget.path);
      await log('iPhone link: ${url}web/', stepId: stepId, level: 'success');
    }
    await api.updateRelease(releaseId, {'preview_url': '$url'});
    await log(
      'Both stay online for ${settings.keepDays} days.',
      stepId: stepId,
    );
    return published;
  }

  /// A project made for one platform lacks the others' folders; `flutter
  /// create` adds them without touching the code.
  Future<void> _ensurePlatform(
    Directory project,
    String platform,
    String stepId,
  ) async {
    if (Directory(p.join(project.path, platform)).existsSync()) return;
    final name = pubspecName(
      File(p.join(project.path, 'pubspec.yaml')).readAsStringSync(),
    );
    await log('The project has no $platform folder; adding it', stepId: stepId);
    await exec('flutter', [
      'create',
      '--platforms=$platform',
      if (name != null) ...['--project-name', name],
      '.',
    ], stepId: stepId);
  }

  void _removeOld() {
    if (!settings.dir.existsSync()) return;
    final limit = DateTime.now().subtract(Duration(days: settings.keepDays));
    for (final entry in settings.dir.listSync(followLinks: false)) {
      if (entry is Directory && entry.statSync().modified.isBefore(limit)) {
        try {
          entry.deleteSync(recursive: true);
        } catch (error) {
          stderr.writeln('could not remove old preview ${entry.path}: $error');
        }
      }
    }
  }

  static void _copy(Directory from, Directory to) {
    to.createSync(recursive: true);
    for (final entry in from.listSync(recursive: true, followLinks: false)) {
      final target = p.join(to.path, p.relative(entry.path, from: from.path));
      if (entry is Directory) {
        Directory(target).createSync(recursive: true);
      } else if (entry is File) {
        File(target).parent.createSync(recursive: true);
        entry.copySync(target);
      }
    }
  }
}
