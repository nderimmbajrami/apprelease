import 'dart:convert';
import 'dart:io';

import 'package:apprelease_runner/runner.dart';
import 'package:path/path.dart' as p;

/// `dart run tool/preview_local.dart <project.zip> [name]` — builds a
/// preview from a zip on this machine, without Supabase: the same unpack,
/// APK build, web build and publish the runner does, into `PREVIEW_DIR`
/// (default `./previews`) for `PREVIEW_BASE_URL` (default the local
/// server, `http://localhost:8787`).
///
/// For trying a project, or the preview server and its tunnel, before the
/// console is involved.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/preview_local.dart <zip> [name]');
    exit(2);
  }
  final zip = File(args.first).absolute;
  final settings = PreviewSettings(
    dir: Directory(Platform.environment['PREVIEW_DIR'] ?? 'previews').absolute,
    baseUrl: Uri.parse(
      Platform.environment['PREVIEW_BASE_URL'] ?? 'http://localhost:8787',
    ),
  );
  final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
  final api = _LocalApi(zip);
  final log = LogSink(api, id);
  final work = Directory.systemTemp.createTempSync('preview_local');
  late Directory project;

  Future<String> exec(
    String executable,
    List<String> arguments, {
    required String stepId,
  }) async {
    stdout.writeln('\$ $executable ${arguments.join(' ')}');
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: project.path,
    );
    final out = StringBuffer();
    await Future.wait([
      for (final stream in [process.stdout, process.stderr])
        stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
              out.writeln(line);
              stdout.writeln(line);
            }),
    ]);
    final code = await process.exitCode;
    if (code != 0) throw StepFailed('$executable exited with code $code');
    return out.toString();
  }

  final preview = Preview(api: api, log: log, settings: settings, exec: exec);
  try {
    project = await preview.unpack(
      sourcePath: zip.path,
      into: work,
      stepId: 'unpack',
    );
    await exec('flutter', ['pub', 'get'], stepId: 'packages');
    final apk = await preview.buildAndroid(project, 'android');
    final web = await preview.buildWeb(project, id, 'web');
    await preview.publish(
      releaseId: id,
      appName: args.length > 1 ? args[1] : p.basenameWithoutExtension(zip.path),
      apk: apk,
      web: web,
      stepId: 'publish',
    );
  } on StepFailed catch (error) {
    stderr.writeln('failed: $error');
    exitCode = 1;
  } finally {
    await log.flush();
    work.deleteSync(recursive: true);
  }
}

/// Stands in for Supabase: the zip comes from disk, nothing is written.
class _LocalApi extends SupabaseApi {
  _LocalApi(this.zip) : super(url: '', serviceRoleKey: '');

  final File zip;

  @override
  Future<int> downloadSource(String path, File into) async {
    zip.copySync(into.path);
    return into.lengthSync();
  }

  @override
  Future<void> updateRelease(String id, Map<String, dynamic> patch) async {}

  @override
  Future<void> appendLogs(List<Map<String, dynamic>> rows) async {}
}
