import 'package:flutter/widgets.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../domain/auth_failure.dart';

/// The sentence shown for an auth error.
String authErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AuthException) {
    return switch (error.failure) {
      AuthFailure.invalidCredentials => l10n.invalidCredentials,
      AuthFailure.emailAlreadyUsed => l10n.emailAlreadyUsed,
      AuthFailure.weakPassword => l10n.weakPassword,
      AuthFailure.network => l10n.networkError,
      AuthFailure.unknown => error.detail ?? l10n.unknownError,
    };
  }
  return l10n.unknownError;
}
