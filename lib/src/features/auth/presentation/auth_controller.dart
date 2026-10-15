import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';

part 'auth_controller.g.dart';

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) =>
      _run(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUp(name: name, email: email, password: password),
  );

  Future<bool> updateName(String name) =>
      _run(() => ref.read(authRepositoryProvider).updateName(name));

  Future<bool> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<bool> deleteOwnAccount() =>
      _run(() => ref.read(authRepositoryProvider).deleteOwnAccount());

  /// Runs [action], reporting progress through [state]. The mounted check
  /// matters because a screen may navigate away while the request is in
  /// flight.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
