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

  /// A Git URL the runner can clone: https://, git@ or ssh://.
  String? repoUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    final ok = RegExp(
      r'^(https?://|git@|ssh://)[\w.@:/~-]+(\.git)?/?$',
    ).hasMatch(trimmed);
    return ok ? null : l10n.invalidRepoUrl;
  }

  /// `com.example.app` — reverse-domain, at least two segments.
  String? applicationId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.fieldRequired;
    final ok = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_-]*)+$',
    ).hasMatch(trimmed);
    return ok ? null : l10n.invalidApplicationId;
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
