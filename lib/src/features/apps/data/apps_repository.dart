import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/backend.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/app_project.dart';
import 'local_apps_repository.dart';
import 'supabase_apps_repository.dart';

part 'apps_repository.g.dart';

/// The applications a team has registered.
abstract interface class AppsRepository {
  Stream<List<AppProject>> watchApps();
  Future<AppProject> addApp(AppProject app);
  Future<void> updateApp(AppProject app);
  Future<void> deleteApp(String appId);
  void dispose();
}

@Riverpod(keepAlive: true)
AppsRepository appsRepository(Ref ref) {
  final repository = switch (ref.watch(backendProvider)) {
    Backend.local => LocalAppsRepository(),
    Backend.supabase => SupabaseAppsRepository(
      ref.watch(supabaseClientProvider),
    ),
  };
  ref.onDispose(repository.dispose);
  return repository;
}

/// Every app of the signed-in team, newest first.
@Riverpod(keepAlive: true)
Stream<List<AppProject>> appsStream(Ref ref) {
  // Tied to the session: the provider outlives a sign-out, and the next
  // account must not see the previous one's list.
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final teamId = user.teamId ?? user.id;
  return ref
      .watch(appsRepositoryProvider)
      .watchApps()
      .map(
        (apps) => [
          for (final a in apps)
            if (a.teamId == teamId) a,
        ],
      );
}

/// One app by id, or null while the list loads or when it is gone.
@riverpod
AppProject? appById(Ref ref, String appId) {
  final apps = ref.watch(appsStreamProvider).value ?? const [];
  for (final app in apps) {
    if (app.id == appId) return app;
  }
  return null;
}
