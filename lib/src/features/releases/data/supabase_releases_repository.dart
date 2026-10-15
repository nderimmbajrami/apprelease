import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_watch.dart';
import '../../apps/domain/app_project.dart';
import '../domain/release.dart';
import 'releases_repository.dart';

/// `releases` + `release_steps`, kept up to date by the runner; `release_logs`
/// streams line by line.
class SupabaseReleasesRepository implements ReleasesRepository {
  SupabaseReleasesRepository(this._client);

  final SupabaseClient _client;
  final _writes = StreamController<void>.broadcast();

  @override
  Stream<List<Release>> watchReleases() => watchQuery(
    client: _client,
    tables: const ['releases', 'release_steps'],
    refresh: _writes.stream,
    fetch: () async {
      final rows = await _client
          .from('releases')
          .select('*, release_steps(*)')
          .order('created_at', ascending: false);
      return [for (final row in rows) _fromRow(row)];
    },
  );

  @override
  Stream<Release?> watchRelease(String releaseId) => watchQuery(
    client: _client,
    tables: const ['releases', 'release_steps'],
    refresh: _writes.stream,
    filterColumn: 'id',
    filterValue: releaseId,
    fetch: () async {
      final row = await _client
          .from('releases')
          .select('*, release_steps(*)')
          .eq('id', releaseId)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    },
  );

  @override
  Stream<List<LogLine>> watchLog(String releaseId) => _client
      .from('release_logs')
      .stream(primaryKey: ['id'])
      .eq('release_id', releaseId)
      .order('seq', ascending: true)
      .map(
        (rows) => [
          for (final row in rows)
            LogLine(
              at: DateTime.parse(row['at'] as String),
              text: row['text'] as String,
              stepId: row['step_id'] as String?,
              level: LogLevel.values.byName(
                (row['level'] as String?) ?? 'info',
              ),
            ),
        ],
      );

  @override
  Future<Release> startRelease(Release release) async {
    await _client.from('releases').insert({
      'id': release.id,
      'app_id': release.appId,
      'team_id': release.teamId,
      'number': release.number,
      'platform': release.platform.name,
      'track': release.track.name,
      'version_name': release.versionName,
      'build_number': release.buildNumber,
      'status': release.status.name,
      'branch': release.branch,
      'started_by_name': release.startedByName,
    });
    await _client.from('release_steps').insert([
      for (final step in release.steps)
        {
          'id': step.id,
          'release_id': release.id,
          'name': step.name,
          'position': step.order,
          'status': step.status.name,
        },
    ]);
    _touch();
    return release;
  }

  @override
  Future<void> cancelRelease(String releaseId) async {
    // The runner notices the flag and stops; a queued release is simply
    // marked cancelled.
    await _client
        .from('releases')
        .update({'cancel_requested': true})
        .eq('id', releaseId);
    await _client
        .from('releases')
        .update({
          'status': ReleaseStatus.cancelled.name,
          'finished_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', releaseId)
        .eq('status', ReleaseStatus.queued.name);
    _touch();
  }

  @override
  Future<void> deleteReleasesOfApp(String appId) async {
    // Cascades through release_steps and release_logs.
    await _client.from('releases').delete().eq('app_id', appId);
    _touch();
  }

  @override
  void dispose() {
    unawaited(_writes.close());
  }

  void _touch() {
    if (!_writes.isClosed) _writes.add(null);
  }

  static Release _fromRow(Map<String, dynamic> row) {
    DateTime? when(String key) =>
        row[key] == null ? null : DateTime.parse(row[key] as String);
    final steps = [
      for (final s in (row['release_steps'] as List? ?? const []))
        ReleaseStep(
          id: s['id'] as String,
          name: s['name'] as String,
          order: s['position'] as int,
          status: StepStatus.values.byName(s['status'] as String),
          startedAt: s['started_at'] == null
              ? null
              : DateTime.parse(s['started_at'] as String),
          finishedAt: s['finished_at'] == null
              ? null
              : DateTime.parse(s['finished_at'] as String),
        ),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return Release(
      id: row['id'] as String,
      appId: row['app_id'] as String,
      teamId: row['team_id'] as String,
      number: row['number'] as int,
      platform: Platform.values.byName(row['platform'] as String),
      track: ReleaseTrack.values.byName(row['track'] as String),
      versionName: row['version_name'] as String,
      buildNumber: row['build_number'] as int?,
      status: ReleaseStatus.values.byName(row['status'] as String),
      branch: row['branch'] as String,
      commit: (row['commit'] as String?) ?? '',
      startedByName: (row['started_by_name'] as String?) ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      startedAt: when('started_at'),
      finishedAt: when('finished_at'),
      steps: steps,
      artifacts: [
        for (final a in (row['artifacts'] as List? ?? const [])) a as String,
      ],
      errorMessage: row['error_message'] as String?,
    );
  }
}
