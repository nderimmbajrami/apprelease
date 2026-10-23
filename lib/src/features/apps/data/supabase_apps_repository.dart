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
    await _write((row) => _client.from(_table).insert(row), app);
    _touch();
    return app;
  }

  @override
  Future<void> updateApp(AppProject app) async {
    await _write(
      (row) => _client.from(_table).update(row).eq('id', app.id),
      app,
    );
    _touch();
  }

  /// Writes the row; on a database that predates `trigger_rules`, writes it
  /// again without that column so the rest still saves (first rule only).
  Future<void> _write(
    Future<void> Function(Map<String, dynamic> row) write,
    AppProject app,
  ) async {
    final row = _toRow(app);
    try {
      await write(row);
    } on PostgrestException catch (e) {
      final missing =
          e.code == 'PGRST204' || e.message.contains('trigger_rules');
      if (!missing) rethrow;
      await write(row..remove('trigger_rules'));
    }
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
    triggerEnabled: (row['trigger_enabled'] as bool?) ?? false,
    pushRules: _rulesFromRow(row),
    triggerTags: (row['trigger_tags'] as bool?) ?? false,
    webhookSecret: (row['webhook_secret'] as String?) ?? '',
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
    'trigger_enabled': app.triggerEnabled,
    'trigger_rules': [for (final r in app.pushRules) r.toJson()],
    // The single-branch columns mirror the first rule.
    if (app.pushRules.isNotEmpty) ...{
      'trigger_branch': app.pushRules.first.branch,
      'trigger_platforms': [
        for (final p in app.pushRules.first.platforms) p.name,
      ],
      'trigger_track_android': app.pushRules.first.trackAndroid,
      'trigger_track_ios': app.pushRules.first.trackIos,
    },
    'trigger_tags': app.triggerTags,
  };

  /// `trigger_rules`, or one rule from the old single-branch columns.
  static List<PushRule> _rulesFromRow(Map<String, dynamic> row) {
    final rules = row['trigger_rules'];
    if (rules is List && rules.isNotEmpty) {
      return [for (final r in rules) PushRule.fromJson(r as Map)];
    }
    return [
      PushRule.fromJson({
        'branch': row['trigger_branch'],
        'platforms': row['trigger_platforms'],
        'track_android': row['trigger_track_android'],
        'track_ios': row['trigger_track_ios'],
      }),
    ];
  }
}
