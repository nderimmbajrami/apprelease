/// Auth errors the UI knows how to translate.
enum AuthFailure {
  invalidCredentials,
  emailAlreadyUsed,
  weakPassword,
  network,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.detail]);

  final AuthFailure failure;
  final String? detail;

  @override
  String toString() =>
      'AuthException(${failure.name}${detail == null ? '' : ': $detail'})';
}
