/// What kind of project the repository holds.
enum ProjectType {
  flutter,
  reactNative;

  String get label => switch (this) {
    ProjectType.flutter => 'Flutter',
    ProjectType.reactNative => 'React Native',
  };
}

/// A store the app ships to.
enum Platform {
  android,
  ios;

  String get label => switch (this) {
    Platform.android => 'Android',
    Platform.ios => 'iOS',
  };
}

/// An application registered on AppRelease: the repository and what to build
/// from it. Credentials and releases hang off it by id.
class AppProject {
  const AppProject({
    required this.id,
    required this.teamId,
    required this.name,
    required this.repoUrl,
    required this.createdAt,
    this.branch = 'main',
    this.projectType = ProjectType.flutter,
    this.platforms = const {Platform.android, Platform.ios},
    this.androidPackageName = '',
    this.iosBundleId = '',
    this.flutterVersion = 'stable',
    this.releaseCount = 0,
    this.lastReleaseAt,
  });

  final String id;
  final String teamId;
  final String name;
  final String repoUrl;
  final String branch;
  final ProjectType projectType;
  final Set<Platform> platforms;

  /// `com.example.app` — needed to read the build number from Google Play.
  final String androidPackageName;

  /// `com.example.app` — needed for automatic iOS signing.
  final String iosBundleId;

  /// `stable`, `beta`, `master`, a version, or `fvm`.
  final String flutterVersion;

  final DateTime createdAt;

  /// Denormalised for the list; the releases table is the truth.
  final int releaseCount;
  final DateTime? lastReleaseAt;

  bool get hasAndroid => platforms.contains(Platform.android);
  bool get hasIos => platforms.contains(Platform.ios);

  /// `acme/app` out of `https://github.com/acme/app.git`.
  String get repoShortName {
    final cleaned = repoUrl.replaceAll(RegExp(r'\.git/?$'), '');
    final parts = cleaned.split(RegExp(r'[/:]')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.length < 2) return cleaned;
    return '${list[list.length - 2]}/${list.last}';
  }

  /// A url-ish id for the yaml workflow names: "acme-app".
  String get slug => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  AppProject copyWith({
    String? name,
    String? repoUrl,
    String? branch,
    ProjectType? projectType,
    Set<Platform>? platforms,
    String? androidPackageName,
    String? iosBundleId,
    String? flutterVersion,
    int? releaseCount,
    DateTime? lastReleaseAt,
  }) => AppProject(
    id: id,
    teamId: teamId,
    name: name ?? this.name,
    repoUrl: repoUrl ?? this.repoUrl,
    branch: branch ?? this.branch,
    projectType: projectType ?? this.projectType,
    platforms: platforms ?? this.platforms,
    androidPackageName: androidPackageName ?? this.androidPackageName,
    iosBundleId: iosBundleId ?? this.iosBundleId,
    flutterVersion: flutterVersion ?? this.flutterVersion,
    createdAt: createdAt,
    releaseCount: releaseCount ?? this.releaseCount,
    lastReleaseAt: lastReleaseAt ?? this.lastReleaseAt,
  );
}
