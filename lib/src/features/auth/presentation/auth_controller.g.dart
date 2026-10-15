// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True from the moment a registration completes until the setup checklist
/// has been shown once. The router reads it to send a new account there
/// instead of to the dashboard.

@ProviderFor(FreshSignUp)
final freshSignUpProvider = FreshSignUpProvider._();

/// True from the moment a registration completes until the setup checklist
/// has been shown once. The router reads it to send a new account there
/// instead of to the dashboard.
final class FreshSignUpProvider extends $NotifierProvider<FreshSignUp, bool> {
  /// True from the moment a registration completes until the setup checklist
  /// has been shown once. The router reads it to send a new account there
  /// instead of to the dashboard.
  FreshSignUpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'freshSignUpProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$freshSignUpHash();

  @$internal
  @override
  FreshSignUp create() => FreshSignUp();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$freshSignUpHash() => r'72acfe33412fb242bc0fa2fceab72b1d857df6ee';

/// True from the moment a registration completes until the setup checklist
/// has been shown once. The router reads it to send a new account there
/// instead of to the dashboard.

abstract class _$FreshSignUp extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Drives the sign-in / sign-up forms. State is the in-flight request, not the
  /// session — the session lives in [authStateChangesProvider].
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'6681897081d9c87d4cbd966a9d765cf2215a3d5f';

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].

abstract class _$AuthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
