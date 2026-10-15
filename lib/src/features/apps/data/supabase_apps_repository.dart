import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_watch.dart';
import '../domain/app_project.dart';
import 'apps_repository.dart';

class SupabaseAppsRepository implements AppsRepository {
  SupabaseAppsRepository(this._client);

  static const _table = 'apps';

  final SupabaseClient _client;
  final _writes = StreamController<void>.broadcast();

  @override
  Stream<List<AppProject>> watchApps() => watchQuery(
    client: _client,
    tables: const [_table, 'releases'],
    refresh: _writes.stream,
    fetch: () async {
      // Row level security returns exactly the caller's team's apps.
      final rows = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      return [for (final row in rows) _fromRow(row)];
    },
  );

  @override
  Future<AppProject> addApp(AppProject app) async {
    await _client.from(_table).insert(_toRow(app));
    _touch();
    return app;
  }

  @override
  Future<void> updateApp(AppProject app) async {
    await _client.from(_table).update(_toRow(app)).eq('id', app.id);
    _touch();
  }

  @override
  Future<void> deleteApp(String appId) async {
    await _client.from(_table).delete().eq('id', appId);
    _touch();
  }

  @override
  void dispose() {
    unawaited(_writes.close());
  }

  void _touch() {
    if (!_writes.isClosed) _writes.add(null);
  }

  static AppProject _fromRow(Map<String, dynamic> row) => AppProject(
    id: row['id'] as String,
    teamId: row['team_id'] as String,
    name: row['name'] as String,
    repoUrl: row['repo_url'] as String,
    branch: (row['branch'] as String?) ?? 'main',
    projectType: ProjectType.values.byName(
      (row['project_type'] as String?) ?? 'flutter',
    ),
    platforms: {
      for (final p in (row['platforms'] as List?) ?? const ['android', 'ios'])
        Platform.values.byName(p as String),
    },
    androidPackageName: (row['android_package_name'] as String?) ?? '',
    iosBundleId: (row['ios_bundle_id'] as String?) ?? '',
    flutterVersion: (row['flutter_version'] as String?) ?? 'stable',
    createdAt: DateTime.parse(row['created_at'] as String),
    releaseCount: (row['release_count'] as int?) ?? 0,
    lastReleaseAt: row['last_release_at'] == null
        ? null
        : DateTime.parse(row['last_release_at'] as String),
  );

  static Map<String, dynamic> _toRow(AppProject app) => {
    'id': app.id,
    'team_id': app.teamId,
    'name': app.name,
    'repo_url': app.repoUrl,
    'branch': app.branch,
    'project_type': app.projectType.name,
    'platforms': [for (final p in app.platforms) p.name],
    'android_package_name': app.androidPackageName,
    'ios_bundle_id': app.iosBundleId,
    'flutter_version': app.flutterVersion,
  };
}
