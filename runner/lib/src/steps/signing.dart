import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';

/// Turns the credentials a workflow names into files and environment
/// variables, for the duration of one build.
class SigningFiles {
  SigningFiles({
    required this.api,
    required this.log,
    required this.stepId,
    required this.secretsKey,
  });

  final SupabaseApi api;
  final LogSink log;
  final String stepId;
  final String secretsKey;

  static const _dirKey = 'AR_SIGNING_DIR';

  Future<Directory> _dir(Map<String, String> env) async {
    final existing = env[_dirKey];
    if (existing != null) return Directory(existing);
    final dir = await Directory.systemTemp.createTemp('apprelease-signing-');
    env[_dirKey] = dir.path;
    return dir;
  }

  Future<Map<String, dynamic>> _credential(Map<String, dynamic> release, String name) async {
    final all = await api.credentials(release['team_id'] as String);
    return all.firstWhere(
      (c) => c['name'] == name,
      orElse: () => throw StepFailed('Credential "$name" referenced in apprelease.yaml does not exist'),
    );
  }

  /// `android_signing: [upload_keystore]` → AR_KEYSTORE_PATH and friends.
  Future<void> prepareAndroid({
    required Map<String, dynamic> release,
    required WorkflowConfig workflow,
    required Map<String, String> env,
  }) async {
    if (workflow.androidSigning.isEmpty) {
      await log('No android_signing in the workflow; the build signs itself or stays unsigned', stepId: stepId, level: 'warning');
      return;
    }
    final credential = await _credential(release, workflow.androidSigning.first);
    final secret = await api.readSecret(credential['id'] as String, secretsKey);
    final dir = await _dir(env);
    final path = p.join(dir.path, secret.fileName ?? 'upload.keystore');
    File(path).writeAsBytesSync(secret.fileBytes!);
    env['AR_KEYSTORE_PATH'] = path;
    env['AR_KEYSTORE_PASSWORD'] = secret.fields['keystorePassword'] ?? '';
    env['AR_KEY_ALIAS'] = secret.fields['keyAlias'] ?? '';
    env['AR_KEY_PASSWORD'] = secret.fields['keyPassword'] ?? '';
    log
      ..mask(env['AR_KEYSTORE_PASSWORD']!)
      ..mask(env['AR_KEY_PASSWORD']!);
    await log('Keystore ${credential['name']} written to \$AR_KEYSTORE_PATH', stepId: stepId);
  }

  /// `ios_signing:` → certificate + profile in a temporary keychain, and the
  /// export options plist as AR_EXPORT_OPTIONS.
  Future<void> prepareIos({
    required Map<String, dynamic> release,
    required WorkflowConfig workflow,
    required Map<String, String> env,
  }) async {
    final signing = workflow.iosSigning;
    if (signing.isEmpty) throw StepFailed('ios_signing is missing from the workflow');

    final all = await api.credentials(release['team_id'] as String);
    final key = all.firstWhere(
      (c) => c['kind'] == 'appStoreConnectKey',
      orElse: () => throw StepFailed('No App Store Connect API key under Credentials'),
    );
    final secret = await api.readSecret(key['id'] as String, secretsKey);
    final dir = await _dir(env);

    // altool and the App Store Connect API both look here for the .p8.
    final keysDir = Directory(p.join(dir.path, 'private_keys'))..createSync();
    final keyId = secret.fields['keyId']!;
    final p8 = p.join(keysDir.path, 'AuthKey_$keyId.p8');
    File(p8).writeAsBytesSync(secret.fileBytes!);
    env['AR_ASC_KEY_ID'] = keyId;
    env['AR_ASC_ISSUER_ID'] = secret.fields['issuerId']!;
    env['AR_ASC_KEY_PATH'] = p8;
    env['API_PRIVATE_KEYS_DIR'] = keysDir.path;

    final bundleIds = switch (signing['bundle_identifier']) {
      final List list => [for (final b in list) '$b'],
      final Object single => ['$single'],
      _ => <String>[],
    };
    final distribution = '${signing['distribution_type'] ?? 'app_store'}';

    // Automatic signing: Xcode resolves the certificate and profile through
    // the API key. The export options tell `flutter build ipa` what to make.
    final method = switch (distribution) {
      'ad_hoc' => 'ad-hoc',
      'development' => 'development',
      _ => 'app-store-connect',
    };
    final plist = p.join(dir.path, 'ExportOptions.plist');
    File(plist).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>$method</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>destination</key><string>export</string>
</dict>
</plist>
''');
    env['AR_EXPORT_OPTIONS'] = plist;
    // xcodebuild picks these up for cloud signing.
    env['AR_XCODE_AUTH_FLAGS'] =
        '-allowProvisioningUpdates -authenticationKeyPath $p8 -authenticationKeyID $keyId -authenticationKeyIssuerID ${secret.fields['issuerId']}';
    await log('Signing files ready for ${bundleIds.join(', ')} · $distribution', stepId: stepId);
  }

  /// `groups: [google_play]` → the service account JSON as a variable the
  /// publishing section references by `$GOOGLE_PLAY_SERVICE_ACCOUNT`.
  Future<void> loadGroups({
    required Map<String, dynamic> release,
    required WorkflowConfig workflow,
    required Map<String, String> env,
  }) async {
    final all = await api.credentials(release['team_id'] as String);
    for (final group in workflow.groups) {
      final match = all.where((c) => c['name'] == group);
      if (match.isEmpty) continue;
      final credential = match.first;
      if (credential['kind'] != 'googlePlayServiceAccount') continue;
      final secret = await api.readSecret(credential['id'] as String, secretsKey);
      final dir = await _dir(env);
      final path = p.join(dir.path, 'google-play.json');
      File(path).writeAsStringSync(secret.fields['json']!);
      env['GOOGLE_PLAY_SERVICE_ACCOUNT'] = secret.fields['json']!;
      env['AR_GOOGLE_PLAY_JSON'] = path;
      final parsed = jsonDecode(secret.fields['json']!) as Map;
      log.mask('${parsed['private_key']}');
      await log('Loaded group $group (${parsed['client_email']})', stepId: stepId);
    }
  }

  /// Removes everything that was written for this build.
  static Future<void> cleanUp(Map<String, String> env) async {
    final path = env.remove(_dirKey);
    if (path == null) return;
    final dir = Directory(path);
    if (dir.existsSync()) await dir.delete(recursive: true);
    for (final key in ['AR_KEYSTORE_PASSWORD', 'AR_KEY_PASSWORD', 'GOOGLE_PLAY_SERVICE_ACCOUNT']) {
      env.remove(key);
    }
  }
}
