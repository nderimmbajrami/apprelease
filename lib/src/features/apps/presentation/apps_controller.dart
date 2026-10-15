import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/id.dart';
import '../../auth/data/auth_repository.dart';
import '../data/apps_repository.dart';
import '../domain/app_project.dart';

part 'apps_controller.g.dart';

/// Adds, edits and removes applications.
@riverpod
class AppsController extends _$AppsController {
  @override
  Future<void> build() async {}

  /// Returns the new app's id, or null when the write failed.
  Future<String?> addApp({
    required String name,
    required String repoUrl,
    required String branch,
    required ProjectType projectType,
    required Set<Platform> platforms,
    required String androidPackageName,
    required String iosBundleId,
    required String flutterVersion,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    final app = AppProject(
      id: newId(),
      teamId: user.teamId ?? user.id,
      name: name.trim(),
      repoUrl: repoUrl.trim(),
      branch: branch.trim().isEmpty ? 'main' : branch.trim(),
      projectType: projectType,
      platforms: platforms,
      androidPackageName: androidPackageName.trim(),
      iosBundleId: iosBundleId.trim(),
      flutterVersion: flutterVersion.trim().isEmpty
          ? 'stable'
          : flutterVersion.trim(),
      createdAt: DateTime.now(),
    );
    final ok = await _run(() => ref.read(appsRepositoryProvider).addApp(app));
    return ok ? app.id : null;
  }

  Future<bool> updateApp(AppProject app) =>
      _run(() => ref.read(appsRepositoryProvider).updateApp(app));

  Future<bool> deleteApp(String appId) =>
      _run(() => ref.read(appsRepositoryProvider).deleteApp(appId));

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
