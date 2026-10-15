import 'dart:async';
import 'dart:math';

import '../../../core/data/in_memory_table.dart';
import '../../apps/domain/app_project.dart';
import '../domain/release.dart';
import 'releases_repository.dart';

/// In-memory releases with a simulated runner: a queued release starts after
/// a moment, walks through its steps and writes a plausible log, so the
/// console can be tried without a backend and the tests have something that
/// moves.
class LocalReleasesRepository implements ReleasesRepository {
  LocalReleasesRepository({
    List<Release>? seed,
    this.stepDuration = const Duration(milliseconds: 1800),
    this.failEveryNth = 0,
  }) : _releases = InMemoryTable(seed ?? demoReleases()) {
    for (final release in _releases.rows) {
      _logs[release.id] = InMemoryTable(_seedLog(release));
    }
  }

  /// How long one step takes in the simulation.
  final Duration stepDuration;

  /// Makes every n-th simulated release fail at the build step, so the
  /// failure path can be seen. 0 means never.
  final int failEveryNth;

  final InMemoryTable<Release> _releases;
  final _logs = <String, InMemoryTable<LogLine>>{};
  final _timers = <String, List<Timer>>{};
  var _started = 0;

  static List<Release> demoReleases() {
    final now = DateTime.now();
    Release done({
      required String id,
      required int number,
      required Platform platform,
      required ReleaseTrack track,
      required String version,
      required int build,
      required Duration ago,
      ReleaseStatus status = ReleaseStatus.succeeded,
      String? error,
    }) {
      final started = now.subtract(ago);
      final steps = pipelineSteps(platform, id);
      final failedAt = status == ReleaseStatus.failed ? 5 : -1;
      var t = started;
      final timed = <ReleaseStep>[];
      for (final step in steps) {
        final took = Duration(seconds: 20 + (step.order * 37) % 90);
        if (step.order == failedAt) {
          timed.add(
            step.copyWith(
              status: StepStatus.failed,
              startedAt: t,
              finishedAt: t.add(took),
            ),
          );
          t = t.add(took);
        } else if (failedAt != -1 && step.order > failedAt) {
          timed.add(step.copyWith(status: StepStatus.skipped));
        } else {
          timed.add(
            step.copyWith(
              status: StepStatus.succeeded,
              startedAt: t,
              finishedAt: t.add(took),
            ),
          );
          t = t.add(took);
        }
      }
      return Release(
        id: id,
        appId: 'app-demo',
        teamId: 'user-demo',
        number: number,
        platform: platform,
        track: track,
        versionName: version,
        buildNumber: build,
        branch: 'main',
        commit: id.hashCode.toRadixString(16).padLeft(7, '0').substring(0, 7),
        startedByName: 'Demo Developer',
        createdAt: started,
        startedAt: started.add(const Duration(seconds: 4)),
        finishedAt: t,
        status: status,
        steps: timed,
        artifacts: status == ReleaseStatus.succeeded
            ? [platform == Platform.android ? 'app-release.aab' : 'Runner.ipa']
            : const [],
        errorMessage: error,
      );
    }

    return [
      done(
        id: 'rel-demo-1',
        number: 1,
        platform: Platform.android,
        track: ReleaseTrack.internal,
        version: '1.3.0',
        build: 55,
        ago: const Duration(days: 12),
      ),
      done(
        id: 'rel-demo-2',
        number: 2,
        platform: Platform.ios,
        track: ReleaseTrack.testflight,
        version: '1.3.1',
        build: 88,
        ago: const Duration(days: 3),
        status: ReleaseStatus.failed,
        error:
            'xcodebuild: error: No profiles for '
            "'com.acme.shop' were found",
      ),
      done(
        id: 'rel-demo-3',
        number: 3,
        platform: Platform.android,
        track: ReleaseTrack.production,
        version: '1.3.1',
        build: 56,
        ago: const Duration(hours: 20),
      ),
    ];
  }

  @override
  Stream<List<Release>> watchReleases() => _releases.watch().map(
    (rows) => [...rows]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Stream<Release?> watchRelease(String releaseId) => watchReleases().map(
    (rows) => rows.cast<Release?>().firstWhere(
      (r) => r!.id == releaseId,
      orElse: () => null,
    ),
  );

  @override
  Stream<List<LogLine>> watchLog(String releaseId) =>
      (_logs[releaseId] ??= InMemoryTable()).watch();

  @override
  Future<Release> startRelease(Release release) async {
    _releases.insert(release);
    _logs[release.id] = InMemoryTable();
    _started += 1;
    final shouldFail = failEveryNth > 0 && _started % failEveryNth == 0;
    _simulate(release, shouldFail: shouldFail);
    return release;
  }

  @override
  Future<void> cancelRelease(String releaseId) async {
    _stopTimers(releaseId);
    final release = _releases.find((r) => r.id == releaseId);
    if (release == null || release.status.isFinished) return;
    _update(
      release.copyWith(
        status: ReleaseStatus.cancelled,
        finishedAt: DateTime.now(),
        steps: [
          for (final step in release.steps)
            step.status == StepStatus.pending ||
                    step.status == StepStatus.running
                ? step.copyWith(
                    status: StepStatus.skipped,
                    finishedAt: DateTime.now(),
                  )
                : step,
        ],
      ),
    );
    _log(releaseId, 'Cancelled by user', level: LogLevel.warning);
  }

  @override
  Future<void> deleteReleasesOfApp(String appId) async {
    for (final release in _releases.rows.where((r) => r.appId == appId)) {
      _stopTimers(release.id);
      _logs.remove(release.id)?.dispose();
    }
    _releases.delete((r) => r.appId == appId);
  }

  @override
  void dispose() {
    for (final id in _timers.keys.toList()) {
      _stopTimers(id);
    }
    for (final log in _logs.values) {
      log.dispose();
    }
    _releases.dispose();
  }

  // ----------------------------------------------------------- simulation

  void _simulate(Release release, {required bool shouldFail}) {
    final timers = _timers[release.id] = [];
    final lineGap = stepDuration ~/ 4;
    var at = const Duration(milliseconds: 600);

    void schedule(Duration delay, void Function() action) {
      timers.add(
        Timer(delay, () {
          if (_releases.find((r) => r.id == release.id) == null) return;
          action();
        }),
      );
    }

    // The runner picks it up.
    schedule(at, () {
      final commit = Random(
        release.id.hashCode,
      ).nextInt(0xFFFFFFF).toRadixString(16).padLeft(7, '0');
      _update(
        _current(release.id).copyWith(
          status: ReleaseStatus.running,
          startedAt: DateTime.now(),
          commit: commit,
        ),
      );
      _log(release.id, 'Runner mac-m2-01 claimed release #${release.number}');
    });

    final steps = release.steps;
    final failAt = shouldFail ? 4 : -1;

    for (final step in steps) {
      final stepStart = at + const Duration(milliseconds: 200);
      schedule(
        stepStart,
        () => _setStep(release.id, step.id, StepStatus.running),
      );
      final lines = _linesFor(release, step);
      for (final (i, line) in lines.indexed) {
        schedule(
          stepStart + lineGap * (i + 1),
          () => _log(release.id, line.$1, stepId: step.id, level: line.$2),
        );
      }
      final stepEnd = stepStart + stepDuration;
      if (step.order == failAt) {
        schedule(stepEnd, () {
          _log(
            release.id,
            'Execution failed for task \':app:bundleRelease\'. Exit code 1',
            stepId: step.id,
            level: LogLevel.error,
          );
          _setStep(release.id, step.id, StepStatus.failed);
          final current = _current(release.id);
          _update(
            current.copyWith(
              status: ReleaseStatus.failed,
              finishedAt: DateTime.now(),
              errorMessage: 'Build app bundle failed with exit code 1',
              steps: [
                for (final s in current.steps)
                  s.order > step.order
                      ? s.copyWith(status: StepStatus.skipped)
                      : s,
              ],
            ),
          );
        });
        return;
      }
      schedule(
        stepEnd,
        () => _setStep(release.id, step.id, StepStatus.succeeded),
      );
      if (step.order == 3) {
        // Build number arrives with the versioning step.
        schedule(stepEnd, () {
          final build = 56 + release.number;
          _update(_current(release.id).copyWith(buildNumber: build));
        });
      }
      at = stepEnd;
    }

    schedule(at + const Duration(milliseconds: 200), () {
      final current = _current(release.id);
      _update(
        current.copyWith(
          status: ReleaseStatus.succeeded,
          finishedAt: DateTime.now(),
          artifacts: [
            release.platform == Platform.android
                ? 'app-release.aab'
                : 'Runner.ipa',
          ],
        ),
      );
      final where = switch (release.track) {
        ReleaseTrack.testflight => 'TestFlight',
        ReleaseTrack.appStore => 'App Store review',
        _ => 'Google Play · ${release.track.name}',
      };
      _log(
        release.id,
        'Released ${current.versionLabel} to $where',
        level: LogLevel.success,
      );
    });
  }

  List<(String, LogLevel)> _linesFor(Release release, ReleaseStep step) {
    final isAndroid = release.platform == Platform.android;
    return switch (step.order) {
      0 => [
        ('git clone --depth 1 --branch ${release.branch} …', LogLevel.command),
        (
          'Checked out ${release.branch} @ ${_current(release.id).commit}',
          LogLevel.info,
        ),
        (
          'apprelease.yaml found · workflow ${isAndroid ? 'android' : 'ios'}-${release.track.yamlName}',
          LogLevel.info,
        ),
      ],
      1 => [
        ('Flutter 3.41.2 · stable · Dart 3.11.0', LogLevel.info),
        if (!isAndroid) ('Xcode 26.0 · CocoaPods 1.16.2', LogLevel.info),
        ('flutter doctor -v', LogLevel.command),
        ('No issues found', LogLevel.info),
      ],
      2 => [
        ('flutter pub get', LogLevel.command),
        ('Resolving dependencies… (2.1s)', LogLevel.info),
        ('Got dependencies', LogLevel.info),
      ],
      3 =>
        isAndroid
            ? [
                (
                  'Querying Google Play for the latest build number…',
                  LogLevel.info,
                ),
                (
                  'Latest build number on all tracks: ${55 + release.number}',
                  LogLevel.info,
                ),
                ('AR_BUILD_NUMBER=${56 + release.number}', LogLevel.command),
              ]
            : [
                (
                  'Fetching signing files from App Store Connect…',
                  LogLevel.info,
                ),
                (
                  'Distribution certificate: Apple Distribution (valid)',
                  LogLevel.info,
                ),
                (
                  'Provisioning profile: app_store · ${release.appId == 'app-demo' ? 'com.acme.shop' : 'bundle id'}',
                  LogLevel.info,
                ),
              ],
      4 =>
        isAndroid
            ? [
                (
                  'flutter build appbundle --release --build-number=${56 + release.number}',
                  LogLevel.command,
                ),
                ('Running Gradle task \'bundleRelease\'…', LogLevel.info),
                (
                  '✓ Built build/app/outputs/bundle/release/app-release.aab (38.4MB)',
                  LogLevel.info,
                ),
              ]
            : [
                (
                  'Querying App Store Connect for the latest build number…',
                  LogLevel.info,
                ),
                ('AR_BUILD_NUMBER=${88 + release.number}', LogLevel.command),
              ],
      5 =>
        isAndroid
            ? [
                (
                  'Keystore upload_keystore written to \$AR_KEYSTORE_PATH',
                  LogLevel.info,
                ),
                ('jarsigner -verify app-release.aab', LogLevel.command),
                ('jar verified.', LogLevel.info),
              ]
            : [
                (
                  'flutter build ipa --release --export-options-plist=\$AR_EXPORT_OPTIONS',
                  LogLevel.command,
                ),
                ('Running pod install…', LogLevel.info),
                (
                  '✓ Built IPA to build/ios/ipa/Runner.ipa (61.2MB)',
                  LogLevel.info,
                ),
              ],
      _ =>
        isAndroid
            ? [
                (
                  'Uploading app-release.aab to Google Play · track ${release.track.name}',
                  LogLevel.info,
                ),
                ('Edit committed', LogLevel.info),
              ]
            : [
                (
                  'xcrun altool --upload-app -f Runner.ipa --type ios',
                  LogLevel.command,
                ),
                ('Upload complete · waiting for processing…', LogLevel.info),
                (
                  'Build processed · added to beta group "Beta testers"',
                  LogLevel.info,
                ),
              ],
    };
  }

  Release _current(String id) => _releases.find((r) => r.id == id)!;

  void _update(Release release) =>
      _releases.upsert((r) => r.id == release.id, release);

  void _setStep(String releaseId, String stepId, StepStatus status) {
    final release = _current(releaseId);
    final now = DateTime.now();
    _update(
      release.copyWith(
        steps: [
          for (final step in release.steps)
            step.id == stepId
                ? step.copyWith(
                    status: status,
                    startedAt: status == StepStatus.running ? now : null,
                    finishedAt: status == StepStatus.running ? null : now,
                  )
                : step,
        ],
      ),
    );
  }

  void _log(
    String releaseId,
    String text, {
    String? stepId,
    LogLevel level = LogLevel.info,
  }) => (_logs[releaseId] ??= InMemoryTable()).insert(
    LogLine(at: DateTime.now(), text: text, stepId: stepId, level: level),
  );

  void _stopTimers(String releaseId) {
    for (final timer in _timers.remove(releaseId) ?? const <Timer>[]) {
      timer.cancel();
    }
  }

  static List<LogLine> _seedLog(Release release) {
    final lines = <LogLine>[];
    for (final step in release.steps) {
      if (step.startedAt == null) continue;
      lines.add(
        LogLine(
          at: step.startedAt!,
          stepId: step.id,
          text: step.name,
          level: LogLevel.command,
        ),
      );
      if (step.status == StepStatus.failed) {
        lines.add(
          LogLine(
            at: step.finishedAt!,
            stepId: step.id,
            text: release.errorMessage ?? 'Failed',
            level: LogLevel.error,
          ),
        );
      } else {
        lines.add(
          LogLine(
            at: step.finishedAt!,
            stepId: step.id,
            text: 'Done',
            level: LogLevel.info,
          ),
        );
      }
    }
    if (release.status == ReleaseStatus.succeeded) {
      lines.add(
        LogLine(
          at: release.finishedAt!,
          text: 'Released ${release.versionLabel}',
          level: LogLevel.success,
        ),
      );
    }
    return lines;
  }
}
