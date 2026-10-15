import '../../apps/domain/app_project.dart';

/// Where a release is in its life.
enum ReleaseStatus {
  queued,
  running,
  succeeded,
  failed,
  cancelled;

  bool get isActive => this == queued || this == running;
  bool get isFinished => !isActive;
}

enum StepStatus { pending, running, succeeded, failed, skipped }

/// Where the build goes. The first four are Google Play tracks, the last two
/// App Store Connect destinations.
enum ReleaseTrack {
  internal(Platform.android),
  alpha(Platform.android),
  beta(Platform.android),
  production(Platform.android),
  testflight(Platform.ios),
  appStore(Platform.ios);

  const ReleaseTrack(this.platform);

  final Platform platform;

  static List<ReleaseTrack> forPlatform(Platform platform) => [
    for (final track in values)
      if (track.platform == platform) track,
  ];

  /// The value written to apprelease.yaml and the runner.
  String get yamlName => switch (this) {
    ReleaseTrack.appStore => 'app_store',
    _ => name,
  };
}

/// One stage of the pipeline, as the runner reports it.
class ReleaseStep {
  const ReleaseStep({
    required this.id,
    required this.name,
    required this.order,
    this.status = StepStatus.pending,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String name;
  final int order;
  final StepStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Duration? get duration => startedAt == null
      ? null
      : (finishedAt ?? DateTime.now()).difference(startedAt!);

  ReleaseStep copyWith({
    StepStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) => ReleaseStep(
    id: id,
    name: name,
    order: order,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
  );
}

enum LogLevel { info, command, warning, error, success }

/// One line of the live log.
class LogLine {
  const LogLine({
    required this.at,
    required this.text,
    this.stepId,
    this.level = LogLevel.info,
  });

  final DateTime at;
  final String text;
  final String? stepId;
  final LogLevel level;
}

/// A release: one run of the pipeline for one platform and track.
class Release {
  const Release({
    required this.id,
    required this.appId,
    required this.teamId,
    required this.number,
    required this.platform,
    required this.track,
    required this.versionName,
    required this.branch,
    required this.startedByName,
    required this.createdAt,
    this.buildNumber,
    this.status = ReleaseStatus.queued,
    this.commit = '',
    this.startedAt,
    this.finishedAt,
    this.steps = const [],
    this.artifacts = const [],
    this.errorMessage,
  });

  final String id;
  final String appId;
  final String teamId;

  /// Per app, counting from 1.
  final int number;

  final Platform platform;
  final ReleaseTrack track;

  /// `1.4.0`.
  final String versionName;

  /// Null until the runner fetched it from the store.
  final int? buildNumber;

  final ReleaseStatus status;
  final String branch;

  /// Short SHA, filled in after checkout.
  final String commit;

  final String startedByName;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<ReleaseStep> steps;

  /// File names the runner kept.
  final List<String> artifacts;

  /// Why it failed, in one line.
  final String? errorMessage;

  /// Pushed releases carry this until the runner has read pubspec.yaml.
  static const autoVersion = 'auto';

  /// `1.4.0 (57)` or `1.4.0` while the number is unknown.
  String get versionLabel {
    final name = versionName == autoVersion ? '…' : versionName;
    return buildNumber == null ? name : '$name ($buildNumber)';
  }

  Duration? get duration => startedAt == null
      ? null
      : (finishedAt ?? DateTime.now()).difference(startedAt!);

  /// The step that is running, or the one that failed.
  ReleaseStep? get currentStep {
    for (final step in steps) {
      if (step.status == StepStatus.running ||
          step.status == StepStatus.failed) {
        return step;
      }
    }
    return null;
  }

  Release copyWith({
    int? buildNumber,
    ReleaseStatus? status,
    String? commit,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<ReleaseStep>? steps,
    List<String>? artifacts,
    String? errorMessage,
  }) => Release(
    id: id,
    appId: appId,
    teamId: teamId,
    number: number,
    platform: platform,
    track: track,
    versionName: versionName,
    branch: branch,
    startedByName: startedByName,
    createdAt: createdAt,
    buildNumber: buildNumber ?? this.buildNumber,
    status: status ?? this.status,
    commit: commit ?? this.commit,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    steps: steps ?? this.steps,
    artifacts: artifacts ?? this.artifacts,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

/// The steps a platform's pipeline goes through, in order. The runner uses
/// the same list, so the console can draw the timeline before the runner
/// has even picked the release up.
List<ReleaseStep> pipelineSteps(Platform platform, String releaseId) {
  final names = switch (platform) {
    Platform.android => const [
      'Check out repository',
      'Set up Flutter',
      'Get packages',
      'Fetch build number from Google Play',
      'Build app bundle',
      'Sign with upload key',
      'Upload to Google Play',
    ],
    Platform.ios => const [
      'Check out repository',
      'Set up Flutter and Xcode',
      'Get packages',
      'Fetch signing files',
      'Fetch build number from App Store Connect',
      'Build ipa',
      'Upload to App Store Connect',
    ],
  };
  return [
    for (final (index, name) in names.indexed)
      ReleaseStep(id: '$releaseId-$index', name: name, order: index),
  ];
}
