import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/id.dart';
import '../../apps/data/apps_repository.dart';
import '../../apps/domain/app_project.dart';
import '../../auth/data/auth_repository.dart';
import '../data/releases_repository.dart';
import '../domain/release.dart';

part 'releases_controller.g.dart';

@riverpod
class ReleasesController extends _$ReleasesController {
  @override
  Future<void> build() async {}

  /// Queues a release and returns its id, or null when the write failed.
  Future<String?> startRelease({
    required AppProject app,
    required ReleaseTrack track,
    required String versionName,
    int? buildNumber,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    final existing = ref.read(releasesOfAppProvider(app.id));
    final id = newId();
    final release = Release(
      id: id,
      appId: app.id,
      teamId: app.teamId,
      number: existing.length + 1,
      platform: track.platform,
      track: track,
      versionName: versionName.trim(),
      buildNumber: buildNumber,
      branch: app.branch,
      startedByName: user.name.isEmpty ? user.email : user.name,
      createdAt: DateTime.now(),
      steps: pipelineSteps(track.platform, id),
    );
    final ok = await _run(() async {
      await ref.read(releasesRepositoryProvider).startRelease(release);
      await ref
          .read(appsRepositoryProvider)
          .updateApp(
            app.copyWith(
              releaseCount: existing.length + 1,
              lastReleaseAt: release.createdAt,
            ),
          );
    });
    return ok ? id : null;
  }

  Future<bool> cancelRelease(String releaseId) =>
      _run(() => ref.read(releasesRepositoryProvider).cancelRelease(releaseId));

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
