import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/backend.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/release.dart';
import 'local_releases_repository.dart';
import 'supabase_releases_repository.dart';

part 'releases_repository.g.dart';

/// Releases and their logs.
abstract interface class ReleasesRepository {
  /// Every release of the team, newest first.
  Stream<List<Release>> watchReleases();

  Stream<Release?> watchRelease(String releaseId);

  Stream<List<LogLine>> watchLog(String releaseId);

  /// Queues a release. The runner picks it up from there.
  Future<Release> startRelease(Release release);

  Future<void> cancelRelease(String releaseId);

  /// Takes waiting releases out of the queue. One that started in the
  /// meantime is left alone.
  Future<void> removeFromQueue(List<String> releaseIds);

  /// Removes the releases of an app that is being deleted.
  Future<void> deleteReleasesOfApp(String appId);

  /// Whether any runner reported in recently. False means a queued release
  /// has nobody to build it.
  Stream<bool> watchRunnerOnline();

  /// The line in front of a queued release; null once it is no longer
  /// queued or not visible.
  Future<QueueInfo?> queueInfo(String releaseId);

  void dispose();
}

@Riverpod(keepAlive: true)
ReleasesRepository releasesRepository(Ref ref) {
  final repository = switch (ref.watch(backendProvider)) {
    Backend.local => LocalReleasesRepository(),
    Backend.supabase => SupabaseReleasesRepository(
      ref.watch(supabaseClientProvider),
    ),
  };
  ref.onDispose(repository.dispose);
  return repository;
}

@Riverpod(keepAlive: true)
Stream<List<Release>> releasesStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final teamId = user.teamId ?? user.id;
  return ref
      .watch(releasesRepositoryProvider)
      .watchReleases()
      .map(
        (rows) => [
          for (final r in rows)
            if (r.teamId == teamId) r,
        ],
      );
}

/// The releases of one app, newest first.
@riverpod
List<Release> releasesOfApp(Ref ref, String appId) => [
  for (final r in ref.watch(releasesStreamProvider).value ?? const [])
    if (r.appId == appId) r,
];

@riverpod
Stream<Release?> releaseStream(Ref ref, String releaseId) =>
    ref.watch(releasesRepositoryProvider).watchRelease(releaseId);

@riverpod
Stream<List<LogLine>> releaseLog(Ref ref, String releaseId) =>
    ref.watch(releasesRepositoryProvider).watchLog(releaseId);

/// The queue in front of one release, refreshed every 10 seconds while the
/// page that shows it is open.
@riverpod
Stream<QueueInfo?> releaseQueue(Ref ref, String releaseId) {
  final repository = ref.watch(releasesRepositoryProvider);
  final controller = StreamController<QueueInfo?>();
  Future<void> load() async {
    QueueInfo? info;
    try {
      info = await repository.queueInfo(releaseId);
    } catch (_) {
      info = null;
    }
    if (!controller.isClosed) controller.add(info);
  }

  unawaited(load());
  final timer = Timer.periodic(const Duration(seconds: 10), (_) => load());
  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
}

/// True while at least one build machine is reporting in.
@Riverpod(keepAlive: true)
Stream<bool> runnerOnline(Ref ref) =>
    ref.watch(releasesRepositoryProvider).watchRunnerOnline();
