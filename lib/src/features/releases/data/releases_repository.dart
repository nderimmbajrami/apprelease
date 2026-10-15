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

  /// Removes the releases of an app that is being deleted.
  Future<void> deleteReleasesOfApp(String appId);

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
