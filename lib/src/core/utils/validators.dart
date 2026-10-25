import '../../../l10n/app_localizations.dart';

/// Form validators bound to the active locale.
class Validators {
  const Validators(this.l10n);

  final AppL10n l10n;

  String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null;

  String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    return valid ? null : l10n.invalidEmail;
  }

  String? password(String? value) {
    if (value == null || value.isEmpty) return l10n.fieldRequired;
    return value.length < 8 ? l10n.passwordTooShort : null;
  }

  /// A Git URL that names one repository: host, owner and name.
  /// `https://github.com` alone, or a profile page, is not cloneable.
  static bool isRepoUrl(String value) => RegExp(
    // The host ends at the first slash (or colon for git@), so ".com" can
    // never pass for an owner.
    r'^(?:https?://[\w.-]+(?::\d+)?/|ssh://[\w.@-]+(?::\d+)?/|git@[\w.-]+:/?)'
    r'[\w.~-]+(?:/[\w.~-]+)+?(?:\.git)?/?$',
  ).hasMatch(value.trim());

  String? repoUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    return isRepoUrl(trimmed) ? null : l10n.invalidRepoUrl;
  }

  /// The template ids Flutter generates; no store accepts them.
  static bool isExampleId(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('com.example.') || v == 'com.example';
  }

  static bool isApplicationId(String value) => RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_-]*)+$',
  ).hasMatch(value.trim());

  /// `com.example.app` — reverse-domain, at least two segments.
  String? applicationId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    if (!isApplicationId(trimmed)) return l10n.invalidApplicationId;
    return isExampleId(trimmed) ? l10n.exampleApplicationId : null;
  }

  /// `1.4.0` — semantic version without build number.
  String? versionName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    return RegExp(r'^\d+\.\d+\.\d+$').hasMatch(trimmed)
        ? null
        : l10n.invalidVersion;
  }
}
