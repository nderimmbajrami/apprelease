import 'dart:io';

import 'package:path/path.dart' as p;

import '../pipeline.dart';

/// A fresh, shallow clone per release. Nothing from a previous build can
/// leak in, and the directory is removed once the release is done.
class Checkout {
  Checkout({required this.log, required this.stepId});

  final LogSink log;
  final String stepId;

  Future<Directory> run({
    required Directory workspace,
    required String repoUrl,
    required String branch,
    required String releaseId,
  }) async {
    final dir = Directory(p.join(workspace.path, releaseId));
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.parent.createSync(recursive: true);

    await log('\$ git clone --depth 1 --branch $branch ${_redact(repoUrl)} …', stepId: stepId, level: 'command');
    final result = await Process.run('git', [
      'clone',
      '--depth',
      '1',
      '--branch',
      branch,
      repoUrl,
      dir.path,
    ]);
    if (result.exitCode != 0) {
      throw StepFailed('git clone failed: ${result.stderr}'.trim());
    }
    await log('Checked out $branch', stepId: stepId);
    return dir;
  }

  static Future<String> commit(Directory dir) async {
    final result = await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: dir.path);
    return (result.stdout as String).trim();
  }

  /// `https://token@github.com/…` → `https://***@github.com/…`
  static String _redact(String url) =>
      url.replaceAllMapped(RegExp(r'://([^@/]+)@'), (m) => '://***@');
}
