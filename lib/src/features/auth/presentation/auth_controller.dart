import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';

part 'auth_controller.g.dart';

/// What happened when someone registered.
enum SignUpOutcome {
  /// Signed in straight away.
  signedIn,

  /// A code was mailed; the address has to be confirmed first.
  needsCode,

  failed,
}

/// True from the moment a registration completes until the setup checklist
/// has been shown once. The router reads it to send a new account there
/// instead of to the dashboard.
@Riverpod(keepAlive: true)
class FreshSignUp extends _$FreshSignUp {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

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

  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Raised before the session appears: the router redirects the moment
    // the auth stream emits, and it has to know this account is new.
    ref.read(freshSignUpProvider.notifier).set(true);
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password),
    );
    if (ref.mounted) {
      state = result.hasError
          ? AsyncError(result.error!, result.stackTrace!)
          : const AsyncData(null);
    }
    if (result.hasError) {
      ref.read(freshSignUpProvider.notifier).set(false);
      return SignUpOutcome.failed;
    }
    if (result.value == null) return SignUpOutcome.needsCode;
    await _welcome();
    return SignUpOutcome.signedIn;
  }

  /// Finishes a registration with the code from the confirmation mail.
  Future<bool> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    ref.read(freshSignUpProvider.notifier).set(true);
    final ok = await _run(
      () => ref
          .read(authRepositoryProvider)
          .verifySignUpCode(email: email, code: code),
    );
    if (ok) {
      await _welcome();
    } else {
      ref.read(freshSignUpProvider.notifier).set(false);
    }
    return ok;
  }

  Future<bool> resendSignUpCode(String email) =>
      _run(() => ref.read(authRepositoryProvider).resendSignUpCode(email));

  /// The welcome mail and the note to the team. Failing to send it must not
  /// stop the person from getting in.
  Future<void> _welcome() async {
    try {
      await ref.read(authRepositoryProvider).sendWelcomeMail();
    } catch (_) {}
  }

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
