import 'package:yaml/yaml.dart';

/// One workflow out of apprelease.yaml, read for the release being built.
class WorkflowConfig {
  WorkflowConfig({
    required this.id,
    required this.name,
    required this.flutter,
    required this.androidSigning,
    required this.iosSigning,
    required this.groups,
    required this.vars,
    required this.versioningSource,
    required this.scripts,
    required this.artifacts,
    required this.publishing,
    this.maxBuildDuration = const Duration(minutes: 60),
  });

  final String id;
  final String name;
  final String flutter;
  final List<String> androidSigning;
  final Map<String, dynamic> iosSigning;
  final List<String> groups;
  final Map<String, String> vars;
  final String versioningSource;
  final List<({String name, String script})> scripts;
  final List<String> artifacts;
  final Map<String, dynamic> publishing;
  final Duration maxBuildDuration;

  /// What the console would have written into apprelease.yaml for this app,
  /// built from its settings and the team's credentials, for the repository
  /// that has no such file. The app's own credential of a kind comes first,
  /// then a shared one, then any.
  static WorkflowConfig defaults({
    required String platform,
    required String track,
    required Map<String, dynamic> app,
    required List<Map<String, dynamic>> credentials,
  }) {
    Map<String, dynamic>? first(String kind) {
      Map<String, dynamic>? shared, other;
      for (final c in credentials) {
        if (c['kind'] != kind) continue;
        if (c['app_id'] == app['id']) return c;
        if (c['app_id'] == null) {
          shared ??= c;
        } else {
          other ??= c;
        }
      }
      return shared ?? other;
    }

    final flutter = '${app['flutter_version'] ?? 'stable'}';
    if (platform == 'android') {
      final keystore = first('androidKeystore');
      final play = first('googlePlayServiceAccount');
      return WorkflowConfig(
        id: 'console-android-$track',
        name: '${app['name']} · Android',
        flutter: flutter,
        androidSigning: [if (keystore != null) '${keystore['name']}'],
        iosSigning: const {},
        groups: [if (play != null) '${play['name']}'],
        vars: {'PACKAGE_NAME': '${app['android_package_name'] ?? ''}'},
        versioningSource: play != null ? 'google_play' : 'manual',
        scripts: const [
          (
            name: 'Build app bundle',
            script:
                r'flutter build appbundle --release --build-number=$AR_BUILD_NUMBER',
          ),
        ],
        artifacts: const [
          'build/**/outputs/**/*.aab',
          'build/**/outputs/**/mapping.txt',
        ],
        publishing: {
          if (play != null)
            'google_play': {'track': track, 'submit_as_draft': false},
        },
      );
    }
    final asc = first('appStoreConnectKey');
    return WorkflowConfig(
      id: 'console-ios-$track',
      name: '${app['name']} · iOS',
      flutter: flutter,
      androidSigning: const [],
      iosSigning: {
        'distribution_type': 'app_store',
        'bundle_identifier': '${app['ios_bundle_id'] ?? ''}',
      },
      groups: const [],
      vars: const {},
      versioningSource: asc != null ? 'app_store_connect' : 'manual',
      scripts: const [
        (
          name: 'Build ipa',
          script:
              r'flutter build ipa --release --build-number=$AR_BUILD_NUMBER --export-options-plist=$AR_EXPORT_OPTIONS',
        ),
      ],
      artifacts: const ['build/ios/ipa/*.ipa'],
      publishing: {
        if (asc != null)
          'app_store_connect': {
            'submit_to_testflight': track == 'testflight',
            'submit_to_app_store': track == 'appStore',
          },
      },
      maxBuildDuration: const Duration(minutes: 90),
    );
  }

  /// Parses the file and picks the workflow for [platform] and [track]:
  /// first an exact id like `android-production`, then any workflow whose
  /// signing section matches the platform, then the first one.
  static WorkflowConfig? select(
    String yaml, {
    required String platform,
    required String track,
  }) {
    final doc = loadYaml(yaml);
    if (doc is! Map || doc['workflows'] is! Map) return null;
    final workflows = (doc['workflows'] as Map).cast<String, dynamic>();
    if (workflows.isEmpty) return null;

    String? chosen;
    for (final candidate in [
      '$platform-$track',
      platform,
      '$platform-workflow',
    ]) {
      if (workflows.containsKey(candidate)) {
        chosen = candidate;
        break;
      }
    }
    chosen ??= workflows.keys.firstWhere((key) {
      final env = (workflows[key] as Map?)?['environment'] as Map?;
      if (env == null) return false;
      return platform == 'android'
          ? env.containsKey('android_signing')
          : env.containsKey('ios_signing');
    }, orElse: () => workflows.keys.first);

    return _parse(chosen, (workflows[chosen] as Map).cast<String, dynamic>());
  }

  static WorkflowConfig _parse(String id, Map<String, dynamic> raw) {
    final env = ((raw['environment'] as Map?) ?? const {})
        .cast<String, dynamic>();
    final versioning = ((raw['versioning'] as Map?) ?? const {})
        .cast<String, dynamic>();
    return WorkflowConfig(
      id: id,
      name: (raw['name'] as String?) ?? id,
      flutter: '${env['flutter'] ?? 'stable'}',
      androidSigning: [
        for (final s in (env['android_signing'] as List?) ?? const []) '$s',
      ],
      iosSigning: ((env['ios_signing'] as Map?) ?? const {})
          .cast<String, dynamic>(),
      groups: [for (final g in (env['groups'] as List?) ?? const []) '$g'],
      vars: {
        for (final e in ((env['vars'] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      versioningSource: '${versioning['source'] ?? 'manual'}',
      scripts: [
        for (final s in (raw['scripts'] as List?) ?? const [])
          (name: '${(s as Map)['name'] ?? 'script'}', script: '${s['script']}'),
      ],
      artifacts: [
        for (final a in (raw['artifacts'] as List?) ?? const []) '$a',
      ],
      publishing: ((raw['publishing'] as Map?) ?? const {})
          .cast<String, dynamic>(),
      maxBuildDuration: Duration(
        minutes: (raw['max_build_duration'] as int?) ?? 60,
      ),
    );
  }
}
