import '../../../core/data/in_memory_table.dart';
import '../domain/app_project.dart';
import 'apps_repository.dart';

/// In-memory applications, seeded with one demo app so the console has
/// something to show.
class LocalAppsRepository implements AppsRepository {
  LocalAppsRepository({List<AppProject>? seed})
    : _table = InMemoryTable(seed ?? [demoApp]);

  static final demoApp = AppProject(
    id: 'app-demo',
    teamId: 'user-demo',
    name: 'Acme Shop',
    repoUrl: 'https://github.com/acme/shop-app.git',
    branch: 'main',
    androidPackageName: 'com.acme.shop',
    iosBundleId: 'com.acme.shop',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    releaseCount: 2,
    lastReleaseAt: DateTime.now().subtract(const Duration(hours: 20)),
  );

  final InMemoryTable<AppProject> _table;

  @override
  Stream<List<AppProject>> watchApps() => _table.watch().map(
    (rows) => [...rows]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<AppProject> addApp(AppProject app) async {
    _table.insert(app);
    return app;
  }

  @override
  Future<void> updateApp(AppProject app) async =>
      _table.upsert((row) => row.id == app.id, app);

  @override
  Future<void> deleteApp(String appId) async =>
      _table.delete((row) => row.id == appId);

  @override
  void dispose() => _table.dispose();
}
