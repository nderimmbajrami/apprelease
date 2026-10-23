import 'dart:async';
import 'dart:io';

import 'api.dart';
import 'pipeline.dart';

/// Polls the queue and runs releases one after another.
class Runner {
  Runner({
    required this.api,
    required this.secretsKey,
    required this.name,
    required this.platforms,
    required this.workspace,
    this.pollInterval = const Duration(seconds: 5),
    this.idFile = '.runner-id',
  });

  final SupabaseApi api;
  final String secretsKey;
  final String name;
  final List<String> platforms;
  final Directory workspace;
  final Duration pollInterval;

  /// Where the stable id is kept. One file per process when a machine runs
  /// several (`.runner-id-android`, `.runner-id-ios`).
  final String idFile;

  /// Stable across restarts of the same machine, so the console can show one
  /// runner rather than a new one every boot.
  late final String id = _stableId();

  Future<void> loop() async {
    stdout.writeln(
      'runner $name ($id) · ${platforms.join(', ')} · polling every ${pollInterval.inSeconds}s',
    );
    // Alive every 30 s, also in the middle of a long build, so the console
    // can tell a busy machine from one that is off.
    Future<void> beat() async {
      try {
        await api.heartbeat(runnerId: id, name: name, platforms: platforms);
      } catch (error) {
        stderr.writeln('heartbeat failed: $error');
      }
    }

    await beat();
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => beat());
    try {
      while (true) {
        final ran = await runOne();
        if (!ran) await Future<void>.delayed(pollInterval);
      }
    } finally {
      timer.cancel();
    }
  }

  /// Claims and runs one release. Returns false when the queue was empty.
  Future<bool> runOne() async {
    final release = await api.claimRelease(runnerId: id, platforms: platforms);
    if (release == null) return false;
    // The claim returns the row alone; the steps come separately.
    release['release_steps'] = await api.steps(release['id'] as String);
    final app = await api.app(release['app_id'] as String);
    final pipeline = Pipeline(
      api: api,
      release: release,
      app: app,
      secretsKey: secretsKey,
      workspace: workspace,
    );
    await pipeline.run();
    return true;
  }

  String _stableId() {
    final file = File(idFile);
    if (file.existsSync()) return file.readAsStringSync().trim();
    final id = _uuid();
    file.writeAsStringSync(id);
    return id;
  }

  static String _uuid() {
    final r = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(14, '0');
    final h = Platform.localHostname.hashCode.toRadixString(16).padLeft(8, '0');
    final raw = (r + h + '0' * 32).substring(0, 32);
    return '${raw.substring(0, 8)}-${raw.substring(8, 12)}-4${raw.substring(13, 16)}-a${raw.substring(17, 20)}-${raw.substring(20, 32)}';
  }
}
