/// What a credential is for.
enum CredentialKind {
  androidKeystore,
  googlePlayServiceAccount,
  appStoreConnectKey;

  /// The yaml section the credential belongs under.
  String get yamlRole => switch (this) {
    CredentialKind.androidKeystore => 'android_signing',
    CredentialKind.googlePlayServiceAccount => 'google_play',
    CredentialKind.appStoreConnectKey => 'app_store_connect',
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
  });

  final String id;
  final String teamId;
  final CredentialKind kind;

  /// The reference name used in apprelease.yaml, e.g. `upload_keystore`.
  final String name;

  final DateTime createdAt;

  /// Non-secret facts worth showing: key alias, fingerprint, issuer id,
  /// key id, service account email, file name.
  final Map<String, String> meta;

  /// A one-line description for the list.
  String get summary => switch (kind) {
    CredentialKind.androidKeystore => [
      meta['fileName'],
      if (meta['alias'] != null) 'alias ${meta['alias']}',
    ].whereType<String>().join(' · '),
    CredentialKind.googlePlayServiceAccount => meta['email'] ?? '',
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
