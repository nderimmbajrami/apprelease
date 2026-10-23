import 'dart:io';

import 'package:apprelease_runner/runner.dart';

/// `dart run bin/runner.dart` — polls for queued releases and runs them.
///
/// Reads its settings from the environment (see .env.example). One process
/// runs one release at a time; start a second process for concurrency.
Future<void> main(List<String> args) async {
  // .env first, then the process environment on top: launchd (or a shell)
  // can run two processes from one folder, one per platform.
  final env = <String, String>{..._dotEnv(), ...Platform.environment};
  String need(String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      stderr.writeln('missing $key — see runner/.env.example');
      exit(2);
    }
    return value;
  }

  final runner = Runner(
    api: SupabaseApi(
      url: need('SUPABASE_URL'),
      serviceRoleKey: need('SUPABASE_SERVICE_ROLE_KEY'),
    ),
    secretsKey: need('SECRETS_KEY'),
    name: env['RUNNER_NAME'] ?? Platform.localHostname,
    platforms: (env['RUNNER_PLATFORMS'] ?? 'android,ios').split(','),
    // Absolute: scripts run inside the checkout, and artifact paths are
    // handed to tools from there.
    workspace: Directory(env['RUNNER_WORKSPACE'] ?? 'workspace').absolute,
    idFile: env['RUNNER_ID_FILE'] ?? '.runner-id',
  );

  if (args.contains('--once')) {
    final ran = await runner.runOne();
    exit(ran ? 0 : 3);
  }
  await runner.loop();
}

Map<String, String> _dotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return const {};
  final out = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq == -1) continue;
    out[trimmed.substring(0, eq).trim()] = trimmed
        .substring(eq + 1)
        .replaceAll(RegExp(r'\s+#.*$'), '')
        .trim();
  }
  return out;
}
