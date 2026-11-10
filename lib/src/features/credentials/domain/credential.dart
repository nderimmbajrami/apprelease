/// What a credential is for.
enum CredentialKind {
  androidKeystore,
  googlePlayServiceAccount,
  appStoreConnectKey,

  /// A file the build needs that the repository leaves out
  /// (google-services.json, GoogleService-Info.plist, .env), with the path
  /// where the runner writes it before building.
  buildFile,

  /// A Slack bot and the channel QA builds are posted to.
  slack,

  /// A Jira site and the status tickets move to when a QA build went out.
  jira;

  /// Kinds that belong to one app (or are shared), not to the team as such.
  bool get isPerApp =>
      this == androidKeystore || this == buildFile || isQaConnection;

  /// Where a QA build is announced, not something that signs or uploads.
  bool get isQaConnection => this == slack || this == jira;

  /// Whether the secret is a file (the others are typed or pasted).
  bool get needsFile =>
      this == androidKeystore ||
      this == appStoreConnectKey ||
      this == buildFile;

  /// Whether the console can test it against the service it belongs to.
  bool get canCheck =>
      this == googlePlayServiceAccount ||
      this == appStoreConnectKey ||
      isQaConnection;

  /// The yaml section the credential belongs under.
  String get yamlRole => switch (this) {
    CredentialKind.androidKeystore => 'android_signing',
    CredentialKind.googlePlayServiceAccount => 'google_play',
    CredentialKind.appStoreConnectKey => 'app_store_connect',
    CredentialKind.buildFile => 'files',
    CredentialKind.slack => 'slack',
    CredentialKind.jira => 'jira',
  };
}

/// A signing key or store access, known to the console by its public facts
/// only. The secret itself (keystore bytes, JSON key, .p8) is written once
/// through [CredentialSecret] and never read back by the console; only the
/// runner decrypts it.
class Credential {
  const Credential({
    required this.id,
    required this.teamId,
    required this.kind,
    required this.name,
    required this.createdAt,
    this.meta = const {},
    this.appId,
  });

  final String id;
  final String teamId;
  final CredentialKind kind;

  /// The app this key belongs to; null when shared between apps.
  final String? appId;

  /// The reference name used in apprelease.yaml, e.g. `upload_keystore`.
  final String name;

  final DateTime createdAt;

  /// Non-secret facts worth showing: key alias, fingerprint, issuer id,
  /// key id, service account email, file name.
  final Map<String, String> meta;

  Credential withApp(String? appId) => Credential(
    id: id,
    teamId: teamId,
    kind: kind,
    name: name,
    createdAt: createdAt,
    meta: meta,
    appId: appId,
  );

  /// A one-line description for the list.
  String get summary => switch (kind) {
    CredentialKind.androidKeystore => [
      meta['fileName'],
      if (meta['alias'] != null) 'alias ${meta['alias']}',
    ].whereType<String>().join(' · '),
    CredentialKind.googlePlayServiceAccount => meta['email'] ?? '',
    CredentialKind.buildFile => meta['path'] ?? meta['fileName'] ?? '',
    CredentialKind.slack => [
      if ((meta['channel'] ?? '').isNotEmpty) 'channel ${meta['channel']}',
    ].join(),
    CredentialKind.jira => [
      if ((meta['site'] ?? '').isNotEmpty)
        meta['site']!.replaceFirst(RegExp(r'^https?://'), ''),
      if ((meta['status'] ?? '').isNotEmpty) '→ ${meta['status']}',
    ].join(' · '),
    CredentialKind.appStoreConnectKey => [
      if (meta['keyId'] != null) 'key ${meta['keyId']}',
      if (meta['issuerId'] != null) 'issuer ${_short(meta['issuerId']!)}',
    ].join(' · '),
  };

  static String _short(String value) =>
      value.length <= 12 ? value : '${value.substring(0, 8)}…';
}

/// The secret half of a credential, in transit from the form to the backend.
/// Never stored on the client.
class CredentialSecret {
  const CredentialSecret({
    this.fileBytes,
    this.fileName,
    this.fields = const {},
  });

  /// Keystore bytes or the .p8 contents.
  final List<int>? fileBytes;
  final String? fileName;

  /// Passwords, the JSON key, issuer and key ids.
  final Map<String, String> fields;
}

/// One line of a connection check: a package and what Google said about it.
class CredentialCheck {
  const CredentialCheck({
    required this.package,
    required this.status,
    required this.message,
    this.link,
  });

  final String package;

  /// `ok`, `api_disabled`, `not_invited`, `unknown_package`, `invalid_key`,
  /// `no_apps` or `error`.
  final String status;
  final String message;

  /// Where to fix it, when there is such a page.
  final String? link;

  bool get isOk => status == 'ok';
}
